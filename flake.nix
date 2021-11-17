{
  description = "Flake for git-work";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        cargoToml = (builtins.fromTOML (builtins.readFile ./Cargo.toml));
        name = "${cargoToml.package.name}";
      in
      {
        # nix build
        packages.${name} = pkgs."${name}";
        defaultPackage = self.packages.${name};

        # nix run
        apps.${name} = flake-utils.lib.mkApp {
          inherit name;
          drv = self.packages.${name};
        };
        defaultApp = self.apps.${name};

        # nix develop
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust toolchain.
            rust-bin.stable.latest.default

            # Additional cargo subcommands.
            cargo-edit
            cargo-expand
          ];
        };
      }
    );
}
