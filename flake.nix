{
  description = "Nix Flake for building Alpine bootable initramfs with apko";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    supportedSystems = [
      "x86_64-linux"
    ];

    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import inputs.nixpkgs {inherit system;};
          }
      );
  in {
    devShells = forEachSupportedSystem (
      {pkgs}: let
        apkoPatched = pkgs.stdenvNoCC.mkDerivation {
          # Pull in the patched version of apko I maintain downstream
          # which has lockfile support added for build-cpio.
          #
          # This is lazy and only works for x86_64 because it's a
          # prebuilt binary, but I'm hoping I don't need to do it for
          # too long and that the apko project accepts my PR to add
          # cpio locking support:
          #   https://github.com/chainguard-dev/apko/pull/2101
          pname = "apko";
          version = "b87f3ba-with-lockfile-support";
          src = pkgs.fetchurl {
            url = "https://github.com/alexhaydock/apko/releases/download/b87f3ba-with-lockfile/apko";
            sha256 = "sha256-LIJdAPRm47QZPyxmbCMiP/VuUx3jzkyyKSPYwP4WHnw=";
          };
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/apko
            chmod +x $out/bin/apko
          '';
        };
      in {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            apkoPatched
            bubblewrap
            jinja2-cli
            just
            melange
            opentofu
            sops
            systemdUkify
          ];

          env = {
            # Configure Pinewall version here
            IMAGENAME = "pinewall";
            # Configure Proxmox variables here
            PROXNODE = "proxnet";
            PROXSELFSIGNED = "false";
            PROXURL = "https://cursedrouter.infected.systems:8006/";
            PROXVMID = "200";
            # Configure the Proxmox interfaces
            # used for WAN and LAN respectively
            PROXWAN = "vmbr3";
            PROXLAN = "vmbr4";
          };
        };
      }
    );

    formatter = nixpkgs.lib.genAttrs supportedSystems (
      system: nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
