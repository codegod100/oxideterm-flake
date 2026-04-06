{
  description = "OxideTerm - A modern SSH terminal client built with Rust and Tauri";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://codegod100.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "codegod100.cachix.org-1:LZFL5VrR644WUjleS3bLbVeOdzlXqzKznQWvD5MVthA="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    oxideterm-src = {
      url = "github:AnalyseDeCircuit/oxideterm";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust-overlay, crane, oxideterm-src }:
    let
      inherit (nixpkgs) lib;
      
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      
      forAllSystems = lib.genAttrs supportedSystems;
      
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        }
      );
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" "rust-analyzer" ];
          };
          
          nodejs = pkgs.nodejs_22;
          pnpm = pkgs.pnpm;
          
          tauriDeps = with pkgs; [
            pkg-config
            cmake
            glib
            gtk3
            libsoup_3
            webkitgtk_4_1
            librsvg
            gdk-pixbuf
            cairo
            pango
            harfbuzz
            atk
            openssl
            libappindicator-gtk3
            libayatana-appindicator
            zlib
            zstd
          ];
          
          platformDeps = with pkgs;
            lib.optionals stdenv.isLinux [
              alsa-lib
              udev
              libdrm
              mesa
              vulkan-loader
              wayland
              libxkbcommon
              libx11
              libxcursor
              libxi
              libxrandr
              libxcb
            ]
            ++ lib.optionals stdenv.isDarwin [
              xcbuild
              libiconv
              darwin.apple_sdk.frameworks.Security
              darwin.apple_sdk.frameworks.CoreFoundation
              darwin.apple_sdk.frameworks.CoreServices
              darwin.apple_sdk.frameworks.AppKit
              darwin.apple_sdk.frameworks.WebKit
              darwin.apple_sdk.frameworks.Cocoa
              darwin.apple_sdk.frameworks.LocalAuthentication
            ];
          
          commonDeps = with pkgs; [
            rustToolchain
            nodejs
            pnpm
            gnumake
            gcc
            git
            jq
            curl
            wget
          ];
          
          devShellPackages = commonDeps ++ tauriDeps ++ platformDeps;
          
          isLinux = pkgs.stdenv.isLinux;
        in
        {
          default = pkgs.mkShell {
            name = "oxideterm-dev";
            buildInputs = devShellPackages;
            
            shellHook = ''
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║              OxideTerm Development Environment             ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "Rust version: $(rustc --version)"
              echo "Node version: $(node --version)"
              echo "pnpm version: $(pnpm --version)"
              echo ""
              echo "Project structure:"
              echo "  - src/          : React frontend source"
              echo "  - src-tauri/    : Tauri Rust backend"
              echo "  - cli/          : CLI companion (oxt)"
              echo "  - agent/        : Remote agent for IDE mode"
              echo ""
              echo "Quick start:"
              echo "  1. pnpm install          - Install dependencies"
              echo "  2. pnpm tauri dev        - Run development server"
              echo ""
              
              export LIBRARY_PATH="${pkgs.lib.makeLibraryPath (tauriDeps ++ platformDeps)}''${LIBRARY_PATH:+:$LIBRARY_PATH}"
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (tauriDeps ++ platformDeps)}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
              export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" (tauriDeps ++ platformDeps)}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
              
              ${lib.optionalString isLinux ''
                export WEBKIT_DISABLE_COMPOSITING_MODE=1
                if [ -d /run/opengl-driver ]; then
                  export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/dri
                fi
              ''}
            '';
          };
          
          rust = pkgs.mkShell {
            name = "oxideterm-rust";
            buildInputs = [ rustToolchain ] ++ tauriDeps ++ platformDeps;
            shellHook = ''
              export LIBRARY_PATH="${pkgs.lib.makeLibraryPath (tauriDeps ++ platformDeps)}''${LIBRARY_PATH:+:$LIBRARY_PATH}"
              export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" (tauriDeps ++ platformDeps)}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
              echo "Rust-only development environment for OxideTerm"
            '';
          };
        }
      );
      
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          craneLib = crane.mkLib pkgs;
          
          rustToolchain = pkgs.rust-bin.stable.latest.default;
          
          tauriDeps = with pkgs; [
            pkg-config
            cmake
            glib
            gtk3
            libsoup_3
            webkitgtk_4_1
            librsvg
            gdk-pixbuf
            cairo
            pango
            harfbuzz
            atk
            openssl
            libappindicator-gtk3
            libayatana-appindicator
            zlib
            zstd
          ];
          
          platformDeps = with pkgs;
            lib.optionals stdenv.isLinux [
              alsa-lib
              udev
              libdrm
              mesa
              vulkan-loader
              wayland
              libxkbcommon
              libx11
              libxcursor
              libxi
              libxrandr
              libxcb
            ]
            ++ lib.optionals stdenv.isDarwin [
              xcbuild
              libiconv
              darwin.apple_sdk.frameworks.Security
              darwin.apple_sdk.frameworks.CoreFoundation
              darwin.apple_sdk.frameworks.CoreServices
              darwin.apple_sdk.frameworks.AppKit
              darwin.apple_sdk.frameworks.WebKit
              darwin.apple_sdk.frameworks.Cocoa
              darwin.apple_sdk.frameworks.LocalAuthentication
            ];
          
          # Common build inputs for all Rust packages
          commonBuildInputs = tauriDeps ++ platformDeps;
          commonNativeBuildInputs = [ pkgs.pkg-config rustToolchain ];
          
          # CLI package using crane
          oxide-cli = let
            src = pkgs.stdenv.mkDerivation {
              name = "oxide-cli-src-fixed";
              
              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
              outputHash = "sha256-lWnuteye4gyjfaSBIraKtszlrc8COIMHeUd/YWuuluE=";
              
              nativeBuildInputs = [ rustToolchain pkgs.cargo pkgs.rustc pkgs.cacert ];
              
              buildCommand = ''
                cp -r ${oxideterm-src}/cli $out
                chmod -R +w $out
                cd $out
                cargo update
              '';
            };
            
            cargoVendor = craneLib.vendorCargoDeps { inherit src; };
          in craneLib.buildPackage {
            pname = "oxide-cli";
            version = "1.1.0-beta.5";
            
            inherit src cargoVendor;
            
            nativeBuildInputs = commonNativeBuildInputs;
            buildInputs = commonBuildInputs;
            
            doCheck = false;
            
            meta = with pkgs.lib; {
              description = "CLI companion for OxideTerm";
              homepage = "https://oxideterm.app";
              license = licenses.gpl3Only;
              platforms = platforms.linux ++ platforms.darwin;
            };
          };
          
          # Agent package using crane
          oxideterm-agent = let
            src = pkgs.stdenv.mkDerivation {
              name = "oxideterm-agent-src-fixed";
              
              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
              outputHash = "sha256-cnt4sHbqADT5JqUKfUQ+Xl8DKM1Dj8wQ3HqfekC3WeQ=";
              
              nativeBuildInputs = [ rustToolchain pkgs.cargo pkgs.rustc pkgs.cacert ];
              
              buildCommand = ''
                cp -r ${oxideterm-src}/agent $out
                chmod -R +w $out
                cd $out
                cargo update
              '';
            };
            
            cargoVendor = craneLib.vendorCargoDeps { inherit src; };
          in craneLib.buildPackage {
            pname = "oxideterm-agent";
            version = "0.12.1";
            
            inherit src cargoVendor;
            
            nativeBuildInputs = commonNativeBuildInputs;
            buildInputs = commonBuildInputs;
            
            doCheck = false;
            
            meta = with pkgs.lib; {
              description = "Lightweight remote agent for OxideTerm IDE mode";
              homepage = "https://oxideterm.app";
              license = licenses.gpl3Only;
              platforms = platforms.linux ++ platforms.darwin;
            };
          };
          
          # Full Tauri app - IFD-free using rustPlatform
          oxideterm = let
            nodejs = pkgs.nodejs_22;
            pnpm = pkgs.pnpm;
            
            # Build frontend (FOD - but isolated, doesn't cause IFD in Rust build)
            frontend = pkgs.stdenv.mkDerivation {
              name = "oxideterm-frontend";
              
              outputHashAlgo = "sha256";
              outputHashMode = "recursive";
              outputHash = "sha256-HB+ZayFSYfNydc4//PjntfoBxycCqdWCE8Z2k04Z6Kc=";
              
              nativeBuildInputs = [ nodejs pnpm pkgs.cacert ];
              
              buildCommand = ''
                cp -r ${oxideterm-src} source
                chmod -R +w source
                cd source
                
                export HOME=$TMPDIR
                export PNPM_HOME=$TMPDIR/.pnpm
                export PATH="$PNPM_HOME:$PATH"
                pnpm config set store-dir $TMPDIR/pnpm-store
                
                pnpm install --frozen-lockfile
                pnpm build
                
                mkdir -p $out
                cp -r dist/* $out/ 2>/dev/null || cp -r build/* $out/ 2>/dev/null || true
                cp -r src-tauri $out/
              '';
            };
            
            # Prepare source - IFD-free!
            tauriSrc = pkgs.runCommand "oxideterm-tauri-src" {} ''
              mkdir -p $out/dist
              cp -r ${frontend}/* $out/
              
              for item in $out/*; do
                name=$(basename "$item")
                if [ "$name" != "src-tauri" ] && [ "$name" != "dist" ] && [ -e "$item" ]; then
                  cp -r "$item" $out/dist/ 2>/dev/null || true
                fi
              done
              
              chmod -R +w $out/src-tauri
              cp ${./cargo-locks/tauri-Cargo.lock} $out/src-tauri/Cargo.lock
            '';
            
          in pkgs.rustPlatform.buildRustPackage {
            pname = "oxideterm";
            version = "1.1.0-beta.5";
            
            src = tauriSrc + "/src-tauri";
            
            # IFD-free: use cargoHash instead of cargoLock
            cargoHash = "sha256-hXF4O3kWOzlvgr0jupvuxR2pNUmYnGWfjep/XShqK44=";
            
            nativeBuildInputs = commonNativeBuildInputs ++ [ nodejs pnpm ];
            buildInputs = commonBuildInputs;
            
            # Disable check phase (needs display)
            doCheck = false;
            
            # Tauri-specific build
            buildPhase = ''
              export HOME=$TMPDIR
              cargo build --release --offline
            '';
            
            installPhase = ''
              mkdir -p $out/bin
              cp target/release/oxideterm $out/bin/
            '';
            
            meta = with pkgs.lib; {
              description = "A modern SSH terminal client built with Rust and Tauri";
              homepage = "https://oxideterm.app";
              license = licenses.gpl3Only;
              platforms = platforms.linux;
            };
          };
        in
        {
          inherit oxideterm oxide-cli oxideterm-agent;
          default = oxideterm;
        }
      );
    };
}
