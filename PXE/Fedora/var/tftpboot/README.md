### Source of content for this repo

### grub.cfg
Based on: https://docs.fedoraproject.org/en-US/fedora/rawhide/install-guide/advanced/Network_based_Installations/

To make sure that `grubx64.efi` automatically loads `grub.cfg` and presents the menu options at boot, it needs to be in the place that the grub binary looks for it.

We can find this out with a combination of `strings grubx64.efi | grep cfg` and through running `echo $prefix` from a grub prompt booted over PXE (if we're able to get that far).

By default, it seems like the `grubx64.efi` binary from Fedora looks at `/grub.cfg` for config files. This is prepended with the TFTP server prefix which we can find with `echo $prefix` (which looks like: `(tftp,10.10.10.1)/EFI/fedora`).

All in all, this amounts to:
```
(tftp,10.10.10.1)/EFI/fedora/grub.cfg
```

So on the TFTP server, we need to make sure our grub config is located at `/var/tftpboot/EFI/fedora/grub.cfg`.

### Secure Boot shim & GRUB binary
Start Fedora container:
```
podman run --rm -it -v "$(pwd)/var/tftpboot:/host:rw,Z" fedora:34
```

Inside container:
```
dnf install -y shim-x64 grub2-efi-x64

cp -v /boot/efi/EFI/fedora/{shimx64.efi,grubx64.efi} /host
```

### Kernel and initrd
```
mkdir -p ./var/tftpboot/f34

wget https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/images/pxeboot/initrd.img -O ./var/tftpboot/f34/initrd.img

wget https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/images/pxeboot/vmlinuz -O ./var/tftpboot/f34/vmlinuz
```

### TODO
* Don't run `tftp` as root.
