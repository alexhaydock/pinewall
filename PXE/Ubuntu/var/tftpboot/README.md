### Source of content for this repo

### grub.cfg
Based on (and updated for Ubuntu): https://docs.fedoraproject.org/en-US/fedora/rawhide/install-guide/advanced/Network_based_Installations/

To make sure that `grubx64.efi` automatically loads `grub.cfg` and presents the menu options at boot, it needs to be in the place that the grub binary looks for it.

We can find this out with a combination of `strings grubx64.efi | grep cfg` and through running `echo $prefix` from a grub prompt booted over PXE (if we're able to get that far).

By default, it seems like the `grubx64.efi` binary from Ubuntu looks at `/grub.cfg` for config files. This is prepended with the TFTP server prefix which we can find with `echo $prefix` (which looks like: `(tftp,10.10.10.1)/grub`).

All in all, this amounts to:
```
(tftp,10.10.10.1)/grub/grub.cfg
```

So on the TFTP server, we need to make sure our grub config is located at `/var/tftpboot/grub/grub.cfg`.

### Secure Boot shim & GRUB binary
Start Ubuntu container:
```
podman run --rm -it -v "$(pwd)/var/tftpboot:/host:rw,Z" ubuntu:20.04
```

Inside container:
```
apt update

cd /tmp

apt download shim-signed grub-efi-amd64-signed

mkdir /tmp/grub
dpkg-deb -R grub*.deb /tmp/grub
cp -v /tmp/grub/usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed /host/grubx64.efi

mkdir /tmp/shim
dpkg-deb -R shim*.deb /tmp/shim
cp -v /tmp/shim/usr/lib/shim/shimx64.efi.signed /host/shimx64.efi
```

### Kernel and initrd
```
mount -o loop ubuntu-20.04.2.0-desktop-amd64.iso /mnt/ubuntu/
cp -p /mnt/ubuntu/casper/vmlinuz ./var/tftpboot/
cp -p /mnt/ubuntu/casper/initrd ./var/tftpboot/
umount /mnt/ubuntu/
```

### TODO
* Don't run `tftp` as root.
