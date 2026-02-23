# Pinewall Secure Boot / Measured Boot Support

### Generating Secure Boot / Measured Boot Keys
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

(Yes, there are private keys already in the `keys/` directory in this repo. Maybe you're here because your repo scanning tool found them. No, they're never used for any prod systems. They're mostly just here as an example so the scheduled GitHub Actions pipeline actually works.)

### Testing: Local (With Secure Boot and traditional UEFI VARS store)
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

Note that we use `OVMF_VARS_4M.qcow2` as the source for the VARS file in the command above. This is a default (empty) VARS store, unlike `OVMF_VARS_4M.secboot.qcow2` which already has a number of Microsoft, Red Hat, etc keys enrolled in it. Using the blank store and the `none` arguments for the Microsoft keys means we can be sure that only **our** key is being used to validate the signed OS image. This means we don't need to worry about maintaining up-to-date DBX (revocation) lists.

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

### Testing: Local (With Secure Boot and JSON-based UEFI VARS store)
> [!IMPORTANT]  
> This is a fairly new feature that was introduced in QEMU 10.0. To use this, the OVMF firmware build being used must be built with `QEMU_PV_VARS=TRUE`, otherwise the VM will just hang. Fedora ship this build as `OVMF.qemuvars.fd`.

This method makes use of the [Host UEFI variable service](https://www.qemu.org/docs/master/devel/uefi-vars.html#host-uefi-variable-service) available in more recent versions of QEMU to provide the Secure Boot keys to the VM as a JSON object.

Generate a JSON-based UEFI VARS store:
```sh
virt-fw-vars \
  --output-json /tmp/vars.json \
  --set-pk-cert $(uuidgen) keys/pk-cert.pem \
  --add-db-cert $(uuidgen) keys/db-cert.pem \
  --microsoft-db none \
  --microsoft-kek none \
  --secure-boot
```

Boot the VM using the JSON VARS store (note that we boot with SMM off here as we don't need it when using paravirtualised vars, unlike when we're attaching the pflash disk as above):
```sh
qemu-system-x86_64 \
  -name pinewall \
  -machine q35,smm=off,vmport=off,accel=kvm \
  -m 2G \
  -nographic \
  -drive if=pflash,format=raw,unit=0,file=/usr/share/edk2/ovmf/OVMF.qemuvars.fd,readonly=on \
  -device uefi-vars-x64,jsonfile=/tmp/vars.json \
  -kernel images/<imagename>.efi.img
```
