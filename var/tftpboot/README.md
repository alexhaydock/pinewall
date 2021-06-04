### Source of content for this repo

### syslinux
```
sudo dnf install syslinux

mkdir -p ./var/tftpboot/

cp -v /usr/share/syslinux/{pxelinux.0,menu.c32,vesamenu.c32,ldlinux.c32,libcom32.c32,libutil.c32} ./var/tftpboot/
```

### Secure Boot shim
Start Fedora container:
```
podman run --rm -it -v "$(pwd)/var/tftpboot/uefi:/host:rw,Z" fedora:34
```

Inside container:
```
sudo dnf install -y shim-x64 grub2-efi-x64

sudo cp -v /boot/efi/EFI/fedora/{shimx64.efi,grubx64.efi} /host
```

### Kernel and initrd
```
mkdir -p ./var/tftpboot/f34

wget https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/images/pxeboot/initrd.img -O ./var/tftpboot/f34/initrd.img

wget https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/images/pxeboot/vmlinuz -O ./var/tftpboot/f34/vmlinuz
```

### TODO
* Don't run `tftp` as root.
* Secure Boot support by loading shim instead.
