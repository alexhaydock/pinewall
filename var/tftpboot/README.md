### Source of content for this repo

### syslinux
```
sudo dnf install syslinux

mkdir -p ./var/tftpboot/

cp -v /usr/share/syslinux/{pxelinux.0,menu.c32,vesamenu.c32,ldlinux.c32,libcom32.c32,libutil.c32} ./var/tftpboot/
```

### Secure Boot shim
```
sudo dnf install shim-x64 grub2-efi-x64

mkdir -p ./var/tftpboot/uefi

sudo cp -v /boot/efi/EFI/redhat/shimx64.efi ./var/tftpboot/uefi/

# shim always wants the grub executable in the TFTP root regardless of where the shim is located
# See: https://github.com/rhboot/shim/issues/111#issuecomment-522791605
sudo cp -v /boot/efi/EFI/redhat/grubx64.efi ./var/tftpboot/

```

### Kernel and initrd
```
mkdir -p ./var/tftpboot/f34

wget https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/images/pxeboot/initrd.img -o ./var/tftpboot/f34/initrd.img

wget https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/34/Everything/x86_64/os/images/pxeboot/vmlinuz -o ./var/tftpboot/f34/vmlinuz
```

### TODO
* Don't run `tftp` as root.
* Secure Boot support by loading shim instead.
