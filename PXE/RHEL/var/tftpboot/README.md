### Source of content for this repo

### grub.cfg
Based on: https://docs.fedoraproject.org/en-US/fedora/rawhide/install-guide/advanced/Network_based_Installations/

To make sure that `grubx64.efi` automatically loads `grub.cfg` and presents the menu options at boot, it needs to be in the place that the grub binary looks for it.

We can find this out with a combination of `strings grubx64.efi | grep cfg` and through running `echo $prefix` from a grub prompt booted over PXE (if we're able to get that far).

By default, it seems like the `grubx64.efi` binary from Fedora looks at `/grub.cfg` for config files. This is prepended with the TFTP server prefix which we can find with `echo $prefix` (which looks like: `(tftp,10.10.10.1)/EFI/redhat`).

All in all, this amounts to:
```
(tftp,10.10.10.1)/EFI/redhat/grub.cfg
```

So on the TFTP server, we need to make sure our grub config is located at `/var/tftpboot/EFI/redhat/grub.cfg`.

### Secure Boot shim & GRUB binary
Download RPMs from Red Hat DVD mouted on our PXE server:
* http://10.10.10.1/tools/rhel-mounted/BaseOS/Packages/shim-x64-15.4-2.el8_1.x86_64.rpm
* http://10.10.10.1/tools/rhel-mounted/BaseOS/Packages/grub2-efi-x64-2.02-99.el8.x86_64.rpm

Use the packages above as the source of shimx64.efi and grubx64.efi

### Kernel and initrd
Download these directly from the Red Hat DVD mounted on our PXE server.
* http://10.10.10.1/tools/rhel-mounted/images/pxeboot/initrd.img
* http://10.10.10.1/tools/rhel-mounted/images/pxeboot/vmlinuz

### TODO
* Don't run `tftp` as root.
