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

### Testing the image (locally)
It's easy to test the newly built image locally with QEMU:

```sh
qemu-system-x86_64 -m 2G -nographic -bios /usr/share/edk2/ovmf/OVMF_CODE.fd -kernel images/"$image" -device virtio-net,netdev=nic -netdev user,hostname=pinewall,id=nic
```

_Note:_ If you are not running Fedora, your distribution may put the UEFI OVMF image in a different location. You may need to update this before the command will work.

### Testing the image (Proxmox)
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
* Uses `proxmox_virtual_environment_file` to copy the latest discovered Pinewall EFI to the local ISO storage.
* Uses `proxmox_virtual_environment_vm` to configure a VM with our specific requirements.

You should probably be connected directly to the Proxmox MGMT interface if you try this deployment methodology. It probably won't go particularly well if you're accessing Proxmox _through_ the gateway VM you deploy with this, as subsequent deployments will destroy the existing VM _first_, before trying to copy the new image. Ask me how I know.
