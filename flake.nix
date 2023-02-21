{
  description = "Lunatic runtime";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay/stable";
      inputs = {
        flake-utils.follows = "flake-utils";
      };
    };

    lunatic-git = {
      url = "github:lunatic-solutions/lunatic";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, rust-overlay, lunatic-git, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rust-bin-override = pkgs.rust-bin.stable."1.66.1".default.override {
          targets = [ "wasm32-wasi" ];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rust-bin-override;
    
        lunatic = craneLib.buildPackage {
          pname = "lunatic";
          src = lunatic-git;
          buildInputs = [
            pkgs.pkgconfig
            pkgs.openssl
          ];
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        };
      in
      {
        packages.default = lunatic;
        rust-bin = rust-bin-override;

        apps.default = flake-utils.lib.mkApp {
          drv = lunatic;
        };

        checks = {
          inherit lunatic;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks;

          nativeBuildInputs = with pkgs; [
            lunatic
            rust-bin-override
            openssl
            pkg-config
          ];
        };
      });
}
