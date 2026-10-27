{
  lib,
  callPackage,
  runCommand,
  makeWrapper,
  python314,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}: let
  workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

  lock = lib.importTOML ./uv.lock;
  version = (lib.findFirst (p: p.name == "atopile") null lock.package).version;

  pythonSet = (callPackage pyproject-nix.build.packages {python = python314;}).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      (workspace.mkPyprojectOverlay {sourcePreference = "wheel";})
      (final: prev: {
        atopile = prev.atopile.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + ''
              substituteInPlace $out/${final.python.sitePackages}/atopile/cli/create.py \
                --replace-fail "        return project_path" "$(cat <<'EOF'
                      for p in [project_path, *project_path.rglob("*")]:
                          if not p.is_symlink():
                              p.chmod(p.stat().st_mode | 0o200)
                      return project_path
              EOF
              )"
            '';
        });
      })
    ]
  );

  venv = pythonSet.mkVirtualEnv "atopile-env-${version}" workspace.deps.default;
in
  runCommand "atopile-${version}" {
    inherit version;
    pname = "atopile";
    nativeBuildInputs = [makeWrapper];
    passthru = {inherit venv;};
    meta = {
      description = "Design circuit boards with code";
      homepage = "https://atopile.io";
      changelog = "https://github.com/atopile/atopile/releases";
      license = lib.licenses.mit;
      mainProgram = "ato";
      platforms = ["x86_64-linux" "aarch64-darwin"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  } ''
    mkdir -p $out/bin
    makeWrapper ${venv}/bin/ato $out/bin/ato
  ''
