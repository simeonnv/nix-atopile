{
  description = "Nix flake and overlay for atopile, built from the official PyPI wheels";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    ...
  }: let
    inherit (nixpkgs) lib;

    systems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    mkAtopile = pkgs:
      pkgs.callPackage ./package.nix {
        inherit pyproject-nix uv2nix pyproject-build-systems;
      };
  in {
    overlays.default = final: _prev: {
      atopile = mkAtopile final;
    };

    packages = forAllSystems (pkgs: rec {
      atopile = mkAtopile pkgs;
      default = atopile;
    });
  };
}
