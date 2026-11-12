![Pinewall Logo](logo.svg)

# Pinewall
My minimal Al**pine** Linux home fire**wall** / router. Optimised for running from RAM as a QEMU VM and for easy deployment of updates via Terraform.

Pinewall is built with the goal of running entirely from RAM, immutably. It uses `apko` and `ukify` to build a single packed EFI binary which can be run directly with QEMU. Custom config is injected at runtime by passing EFI variables to the VM.

## Who is this for?
Me. (But feel free to use it!)

The core goals of this project are simplicity and minimalism. I want it to be my home router/gateway and nothing more. Pinewall is an opinionated project based on my own requirements. If I don't need something, I didn't include it.

But with that in mind, I've tried to document things as well as I can in this public repo and you're very welcome to fork the project and use it for your own needs.

## Usage
### The image
Pinewall is built as a distribution of Alpine, with a set of router-optimised packages. It is built and published in my [pinewall-image](https://github.com/alexhaydock/pinewall-image) repo.

The image is signed for Secure Boot using Pinewall keys as part of the GitHub Actions build process. The `*_vars.json` file published alongside Pinewall releases contains the Secure Boot signing keychain.

### Custom config
Custom config is applied to Pinewall at runtime by injecting it into the QEMU VM using paravirtualised EFI variables.

Config can be added to the `overlay/` directory in this repo, and built into the JSON-based EFI variable store with:
```sh
just efivars
```

Services can be enabled in Pinewall by adding them to the comma-separated list in the `SERVICES` environment variable in `scripts/efivars.sh`. Services can be disabled by removing them from the list.

### Running
Pinewall can be run with QEMU as follows:
```sh
just qemu
```

You will probably want to update `scripts/qemu.sh` to bind to the appropriate bridge interfaces or pass the relevant NICs through for your setup if this is a production deployment.

### Inspiration and thanks
* [alpine-make-rootfs](https://github.com/alpinelinux/alpine-make-rootfs)
* Filippo Valsorda's [frood](https://words.filippo.io/dispatches/frood/) "immutable NAS" project
* Vasil Zlatanov's [pinewall-config](https://github.com/vaskozl/pinewall-config) project which took my original `alpine-make-rootfs` code and uplifted it to use `apko`, which I promptly stole back to reintegrate into this repo
* [cloud-init](https://cloud-init.io/), which inspired the "inject config to VM at runtime" approach I eventually settled on
