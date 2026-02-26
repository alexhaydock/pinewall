![Pinewall Logo](logo.svg)

# Pinewall
My minimal Al**pine** Linux home fire**wall** / router. Optimised for running from RAM as a QEMU VM and for easy deployment of updates via Terraform.

Pinewall is built with the goal of running entirely from RAM, immutably. It uses `apko` and `ukify` to build a single packed EFI binary which can be run directly with QEMU or, in theory, booted on physical UEFI-based hardware.

I deploy this in production to Proxmox using Terraform.

## Who is this for?
Me. (But feel free to use it!)

The core goals of this project are simplicity and minimalism. I want it to be my home router/gateway and nothing more. Pinewall is an opinionated project based on my own requirements. If I don't need something, I didn't include it.

But with that in mind, I've tried to document things as well as I can in this public repo and you're very welcome to fork the project and use it for your own needs.

## Usage
### Adding custom config
The config presented in this repo is adapted from a fully-working config I use for one of my network deployments. With the exception of the use of RFC 5737 and RFC 3849 documentation IPs in place of my own public static addresses, this ought to boot and work just fine.

* Configs go in [config/vendor/](./config/vendor/)
* Packages are declared in in [image/pinewall-packages.yaml](./image/pinewall-packages.yaml)
* Accounts are defined in in [image/pinewall-accounts.yaml](./image/pinewall-accounts.yaml)
* Services are managed through symlinks created by [image/pinewall-services.yaml](./image/pinewall-services.yaml)
* If you need to configure permissions or other things during early system boot, [enforceperms](./config/vendor/etc/init.d/enforceperms) will probably help.

### Entering a Nix development shell
Pinewall builds and development expect a Nix environment to be available. This is to ensure a declarative environment for package builds and deployment.

The Nix development environment is declared in [flake.nix](./flake.nix).

Enter a Nix shell with:
```sh
nix develop
```

### Building the config package
Pinewall layers all configs into the resulting Alpine image using a configuration package that gets built by `melange`.

The sources for this package are in the [config/](./config/) directory.

You can build this config package with:
```sh
just config
```

The built config package will be outputted as an Alpine package repository complete with APKINDEX file in [config/packages/](./config/packages/).

### Building a new image
Once the config package has been built, you can build a new image with:
```sh
just image
```

This will build a Pinewall image based on the `apko` recipes in the [image/](./image/) directory. The output from this command will be a single Unified Kernel Image that will appear in the [image/images/](./image/images/) directory.

### Testing the image locally
It's easy to test the newly built image locally with QEMU. This example is based on paths that assume a Fedora host:
```sh
# Copy a blank EFI variable store to a temp directory
cp -fv /usr/share/edk2/ovmf/OVMF_VARS_4M.qcow2 /tmp/OVMF_VARS_4M.qcow2

# Boot Pinewall in QEMU for testing
qemu-system-x86_64 \
  -name pinewall \
  -m 1G \
  -machine q35,smm=on,vmport=off,accel=kvm \
  -drive if=pflash,format=qcow2,unit=0,file=./OVMF_CODE_4M.qcow2,readonly=on \
  -drive if=pflash,format=qcow2,unit=1,file=/tmp/OVMF_VARS_4M.qcow2 \
  -kernel image/images/pinewall_1.0.0.efi.img \
  -nographic
```

**Note:** If you are not running Fedora, your distribution will most likely keep the OVMF_CODE and OVMF_VARS in a different location. You will need to find the right paths for them, as you do specifically need to use UEFI firmware to boot a Unified Kernel Image directly.

### Production deployment (Terraform + Proxmox)
If you want a more robust production deployment (which is essentially a more automated version of the test process above) you can use Terraform:
```sh
just deploy
```

You will want to edit the Terraform VM template in `terraform/templates/` before running `just build` to fit this to your own environment, but it ought to be fairly easy to understand.

The code:
* Uses `proxmox_virtual_environment_download_file` to instruct Proxmox to download the compiled EFI image from this host using a temporary webserver.
* Uses `proxmox_virtual_environment_vm` to configure a VM with our specific requirements.

You should probably be connected directly to the Proxmox management interface if you try this deployment methodology. It probably won't go particularly well if you're accessing Proxmox _through_ the gateway VM you deploy with this, as subsequent deployments will destroy the existing VM _first_, before trying to copy the new image. Ask me how I know.

### Reproducibility
> [!IMPORTANT]  
> Reproducible builds are under heavy development.

A core goal of Pinewall is to provide the ability to produce byte-for-byte reproducible images. Many of the architectural choices of the project are built around this goal.

Currently, Pinewall builds _should_ be byte-for-byte reproducible across short windows of time. However, once Alpine packages update upstream, new builds are likely to carry new package versions and their hashes will change.

I am considering building lockfile support for `apko`'s minirootfs build capability - an effort which would be tracked upstream as chainguard-dev/apko#2085.

### SBOM & vulnerability management
> [!IMPORTANT]  
> SBOM support is currently on-hold until chainguard-dev/apko#2084 is resolved in the upstream `apko` project being used to build Pinewall images.

See: [SBOM.md](./SBOM.md)

### Secure Boot / Measured Boot support
> [!IMPORTANT]  
> Secure Boot (and especially Measured Boot) support is under heavy development and review. I am aiming to streamline the method of signing and validating Pinewall images over time.

See: [SECURE-BOOT.md](./SECURE-BOOT.md)

### Inspiration and thanks
* [alpine-make-rootfs](https://github.com/alpinelinux/alpine-make-rootfs)
* Filippo Valsorda's [frood](https://words.filippo.io/dispatches/frood/) "immutable NAS" project
* Vasil Zlatanov's [pinewall-config](https://github.com/vaskozl/pinewall-config) project which took my original `alpine-make-rootfs` code and uplifted it to use `apko`, which I promptly stole back to reintegrate into this repo
