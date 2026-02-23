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
      "aarch64-linux"
    ];

    # Helper to provide system-specific attributes
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import inputs.nixpkgs {inherit system;};
          }
      );
  in {
    devShells = forEachSupportedSystem (
      {pkgs}: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            apko
            bubblewrap
            jinja2-cli
            just
            melange
            opentofu
            systemdUkify
          ];

          env = {
            # Configure Pinewall version here
            IMAGEVERSION = "1.0.0";
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
