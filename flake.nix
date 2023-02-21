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
    
        lunatic-unstable = craneLib.buildPackage {
          pname = "lunatic";
          src = lunatic-git;
          buildInputs = [
            pkgs.pkgconfig
            pkgs.openssl
          ];
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        };
        
        lunatic = craneLib.buildPackage {
          src = (craneLib.downloadCargoPackage {
            name = "lunatic-runtime";
            version = "0.12.0";
            checksum = "598719917850e75b2b040a5b13f21696d06493c1098173d0fdab007a3d8b5169";
            source = "registry+https://github.com/rust-lang/crates.io-index";
          });
        };

        mkLunaticDevShell = lunatic-dep: pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks;

          nativeBuildInputs = with pkgs; [
            lunatic-dep
            rust-bin-override
            openssl
            pkg-config
          ];
        };
      in
      {
        rust-bin = rust-bin-override;

        packages = {
          default = lunatic;
          unstable = lunatic-unstable;
        };

        apps = {
          default = flake-utils.lib.mkApp {
            drv = lunatic;
          };

          unstable = flake-utils.lib.mkApp {
            drv = lunatic-unstable;
          };
        };

        checks = {
          inherit lunatic lunatic-unstable;
        };

        devShells = {
          default = mkLunaticDevShell lunatic;
          unstable = mkLunaticDevShell lunatic-unstable;
        };
      });
}
