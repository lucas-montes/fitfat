{
  description = "fitfat my fitness app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    sce.url = "github:crocoder-dev/shared-context-engineering";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    sce,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        # Android SDK / NDK derivations require accepting Google's license.
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        android = import ./nix/android.nix {inherit pkgs;};
        devShells = import ./nix/devshells.nix {
          inherit pkgs android;
          sce = sce.packages.${system}.default;
        };
      in {
        devShells = {
          default = devShells.default;
        };
      }
    );
}
