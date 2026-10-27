# nix-atopile

Up-to-date [atopile](https://atopile.io) overlay for Nix (`x86_64-linux`, `aarch64-darwin`).

```nix
{
  inputs.nix-atopile.url = "github:simeonnv/nix-atopile";

  outputs = {nixpkgs, nix-atopile, ...}: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ({pkgs, ...}: {
          nixpkgs.overlays = [nix-atopile.overlays.default];
          environment.systemPackages = [pkgs.atopile];
        })
      ];
    };
  };
}
```
