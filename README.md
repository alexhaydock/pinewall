![Pinewall Logo](logo.svg)

# Pinewall
My minimal Al**pine** Linux home fire**wall** / router. Optimised for running from RAM as a QEMU VM and for easy deployment of updates via Terraform.

Pinewall is built with the goal of running entirely from RAM, immutably. It builds into a single packed EFI binary which can be run directly with QEMU or, in theory, booted on physical UEFI-based hardware.

I deploy this in production to Proxmox using Terraform.

## Who is this for?
Me. (But feel free to use it!)

The core goals of this project are simplicity and minimalism. I want it to be my home router/gateway and nothing more. Pinewall is an opinionated project based on my own requirements. If I don't need something, I didn't include it.

But with that in mind, I've tried to document things as well as I can in this public repo and you're very welcome to fork the project and use it for your own needs.

## Is this a custom distro / a fork?
Not really.

This is based heavily on Alpine Linux's [alpine-make-rootfs](https://github.com/alpinelinux/alpine-make-rootfs) which does a lot of the heavy lifting of building a base Alpine Linux system for us. From there, I just inject all the relevant packages and configs required to build a competent home router and then pack the whole thing into a bootable [UKI](https://wiki.archlinux.org/title/Unified_kernel_image).

I owe a lot of the credit for the UKI packing code to Filippo Valsorda and his [frood](https://words.filippo.io/dispatches/frood/) project - which is very similar to this one but aims to be an immutable NAS instead.

## Hardware Support
Officially I only support `x86_64` based QEMU Virtual Machines. Specifically running on Proxmox, as that's how I'm running it in production.

But there's a good chance this will run on a wide range of `x86_64` hardware (if you build with the `lts` rather than `virt` kernel). If you build the EFI image in an `aarch64` environment there's a good chance it will "just work" on ARM hardware too as long as it can boot EFI binaries.

## Prerequisites
To deploy Pinewall, you will need:
* `podman` - to build images.
* `just` - to run the deployment script.
* `qemu` - (optional) to test built images.
* Proxmox - (optional) on a remote host to deploy to.

## Usage
### Adding custom config
The config presented in this repo is adapted from a fully-working config I use for one of my network deployments. With the exception of the use of RFC 5737 and RFC 3849 documentation IPs in place of my own public static addresses, this ought to boot and work just fine.

* Files go in `root/`
* Packages go in `packages`
* Service updates and user passwords go in `setup.sh`
* If you need to configure permissions or other things during early system boot, `root/etc/init.d/enforceperms` will probably help.

### Building a new image
You can build a new image with:

```sh
just build
```

During the build you should see some fairly comprehensive Ansible output as the various tasks are completed to compile the image. The finished EFI binaries end up in `images/` in the local working directory.

_Note:_ The use of the `.img` suffix here is largely cosmetic. I use that because the `bpg/proxmox` Terraform provider is only capable of operating on a restricted set of suffixes which it considers legitimate "images", and `.efi` is not one of them.

### Testing: Local (No Secure Boot)
It's easy to test the newly built image locally with QEMU (example uses Fedora).

Boot the image directly like this:
```sh
qemu-system-x86_64 \
  -name pinewall \
  -machine q35,smm=on,vmport=off,accel=kvm \
  -m 2G \
  -nographic \
  -drive if=pflash,format=qcow2,unit=0,file=/usr/share/edk2/ovmf/OVMF_CODE_4M.qcow2,readonly=on \
  -kernel images/<imagename>.efi.img
```

_Note:_ If you are not running Fedora, your distribution may put the UEFI OVMF image in a different location. You may need to update this before the command will work.

### Testing: Local (With Secure Boot)
See the "Generating Secure Boot / Measured Boot keys" section further down if you want to make use of this approach.

Install `virt-firmware`:
```sh
sudo dnf install -y python3-virt-firmware
```

Add the Secure Boot key we're signing our images with to the default blank `qcow2` VARS store, and toggle Secure Boot mode to enabled:
```sh
virt-fw-vars \
  --input /usr/share/edk2/ovmf/OVMF_VARS_4M.qcow2 \
  --output /tmp/vars.qcow2 \
  --set-pk-cert $(uuidgen) keys/pk-cert.pem \
  --add-db-cert $(uuidgen) keys/db-cert.pem \
  --microsoft-db none \
  --microsoft-kek none \
  --secure-boot
```

Note that we use `OVMF_VARS_4M.qcow2` as the source for the VARS file in the command above. This is a default (empty) VARS store, unlike `OVMF_VARS_4M.secboot.qcow2` which already has a number of Microsoft, Red Hat, etc keys enrolled in it. Using the blank store and the `none` arguments for the Microsoft keys means we can be sure that only **our** key is being used to validate the signed OS image.

Boot the image directly like this:
```sh
qemu-system-x86_64 \
  -name pinewall \
  -machine q35,smm=on,vmport=off,accel=kvm \
  -m 2G \
  -nographic \
  -drive if=pflash,format=qcow2,unit=0,file=/usr/share/edk2/ovmf/OVMF_CODE_4M.secboot.qcow2,readonly=on \
  -drive if=pflash,format=qcow2,unit=1,file=/tmp/vars.qcow2 \
  -kernel images/<imagename>.efi.img
```

### Testing: Proxmox
If you want to test on Proxmox, you can do much the same as the above, though you will need to create the VM with the `qm create` command.

This example will create a Proxmox VM with VM ID `123`, and a network interface bridged to `vmbr0` on VLAN 201. You can expand it as you desire.

Importantly, to test like this, you will need to copy the packed EFI binary from the `pinewall build` process over to a destination on the Proxmox host, which you can see is passed to QEMU directly using the `--args` flag.

```sh
qm create 123 --args '-kernel /var/lib/vz/template/iso/pinewall.efi.img' --balloon 0 --bios ovmf --cores 4 --memory 2048 --name pinewall -net0 virtio,bridge=vmbr0,tag=201 --onboot 1 -serial0 socket -vga serial0
```

### Production deployment (Terraform + Proxmox)
If you want a more robust production deployment (which is essentially a more automated version of the test process above) you can use Terraform:

```sh
just deploy
```

The `just` script isn't doing much here. Only discovering the latest built version of the Pinewall EFI image before calling `tofu apply`.

You will want to edit the Terraform VM template in `templates/` before running `just build` if you want to use this deployment method, but it should be easy to understand.

The code:
* Uses `proxmox_virtual_environment_download_file` to instruct Proxmox to download the compiled EFI image from this host using a temporary webserver.
* Uses `proxmox_virtual_environment_vm` to configure a VM with our specific requirements.

You should probably be connected directly to the Proxmox MGMT interface if you try this deployment methodology. It probably won't go particularly well if you're accessing Proxmox _through_ the gateway VM you deploy with this, as subsequent deployments will destroy the existing VM _first_, before trying to copy the new image. Ask me how I know.

### SBOM and Vulnerability Management
One of the benefits of running an image-based system is that we gain the ability to build an SBOM for our image, which can be run through a vulnerability checker such as [Grype](https://github.com/anchore/grype) periodically, including inside CI.

As part of the build process, Ansible invokes [Syft](https://github.com/anchore/syft/) to build an SBOM for our image in both CycloneDX and Syft formats.

We can run Grype from the main Pinewall directory, where it will pick up the default `.grype.yaml` (which excludes the `linux-kernel` package due to too many false positives), and the custom `.grype.tmpl` (which adds more columns to our output for additional context):

```sh
grype --distro "alpine:3.22" -o template -t .grype.tmpl --only-fixed sbom:images/pinewall.2025102701_sbom.syft.json
```

![Demo of the above Grype command running in an interactive terminal](grype-demo.gif)

This approach will show all vulnerabilities that have fixes available, and will include our full supply-chain - including, among other things, compiled Golang binaries which have upstream modules that need updating.

Seeing the full context of vulnerabilities in our supply-chain is useful, but not always actionable if fixes need to be deployed by upstream developers. For an approach that only shows _actionable_ vulnerabilities (i.e. ones with fixes which we could apply now via APK), we can run a command like the following:

```sh
grype --distro "alpine:3.22" -c .grype-ci.yaml --fail-on high --only-fixed sbom:images/pinewall.2025102701_sbom.syft.json
```

This version of the command will exclude Go modules from our output. It will also return a non-zero error code if any High or above severity vulnerabilities are detected in the image, making it quite useful to include in a scheduled CI pipeline run.

### Generating Secure Boot / Measured Boot keys
These keys are needed as part of the `ukify build` process.

With `ukify genkey`, we can generate the following keys in the `keys/` dir at the root of the repo:
* Secure Boot keys to sign the overall UKI for the UEFI firmware to boot
* PCR keys to sign the `enter-initrd` phase of the boot process
  * Normally we'd have a second key here for further phases like `leave-initrd`, but in Pinewall's design we never actually leave the initrd/initramfs so we can skip it
  * I'm also not actually using the PCR keys to sign anything (yet), since `ukify` depends on `systemd-measure` to do this, and it's predictably not packaged in Alpine. That can be a future TODO item.

```sh
ukify genkey \
  --secureboot-private-key=keys/db-priv.pem \
  --secureboot-certificate=keys/db-cert.pem \
  --pcr-private-key=keys/tpm2-pcr-initrd-priv.pem \
  --pcr-public-key=keys/tpm2-pcr-initrd-cert.pem
```

The Secure Boot keys generated above are Secure Boot DB keys. We also need to generate a Platform Key (PK) to provide the overall root-of-trust for our custom Secure Boot chain:
```sh
openssl req -newkey rsa:4096 -nodes -keyout keys/pk-priv.key -new -x509 -sha256 -days 3650 -subj "/CN=Pinewall Secure Boot PK/" -out keys/pk-cert.pem
```

In our setup, the PK functionally doesn't get used. It is required in the Secure Boot spec to validate any _updates_ provided to the Secure Boot DB or DBX. We won't be pushing any updates, as our machines are ephemeral and we'd just build a new VARS store if needed. We do need to add a PK regardless, otherwise Secure Boot will remain in Setup mode and won't actually do any enforcing. The _actual_ security in our chain is coming from enrolling the DB certificate, which is being used to validate our signed UKI.

We can validate that Secure Boot is working in our installed environment, and inspect our enrolled PK/DB keys with:
```sh
mokutil --sb-state && echo 'PK Keys:' && mokutil --pk | grep "Issuer:" && echo 'DB Keys:' && mokutil --db | grep "Issuer:"
```

(Yes, there are private keys already in the `keys/` directory in this repo. Maybe you're here because your repo scanning tool found them. No, they're never used for any prod systems. They're mostly just here as an example so the scheduled GitHub Actions pipeline.)
