set ignore-comments

export PROXMOX_VE_USERNAME := "root@pam"
export TF_VAR_deployment_host_ip := "192.168.200.160"

[working-directory: 'config']
config:
    test -f melange.rsa || melange keygen
    melange build --signing-key melange.rsa --arch amd64 pinewall-config.yaml

[working-directory: 'image']
image:
    #!/usr/bin/env bash
    set -euo pipefail
    # Calculate UKI filename based on env vars in shell
    UKIFILENAME="${IMAGENAME}_${IMAGEVERSION}.efi.img"
    # Create build and rebuild tempdirs
    build_tmp="$(mktemp -d)"
    rebuild_tmp="$(mktemp -d)"
    # Ensure cleanup if the process exits
    trap 'rm -rf "${build_tmp}" ; rm -rf "${rebuild_tmp}"' EXIT
    # DEBUG: echo status
    echo "Build dir: ${build_tmp}"
    echo "Repacking dir: ${rebuild_tmp}"
    # Build minirootfs tar file
    apko build-minirootfs pinewall.yaml ${build_tmp}/pinewall.tar
    # Extract tar file
    tar \
    --exclude=dev \
    --exclude=media/cdrom \
    --exclude=media/floppy \
    --exclude=media/usb \
    --exclude=mnt \
    --exclude=srv \
    --exclude=sys \
    -xf ${build_tmp}/pinewall.tar -C ${rebuild_tmp}
    # Process tar file deterministically into initramfs
    # We need root mostly so we can write /bin/bbsuid
    # which is the SUID wrapper for BusyBox functions
    # like `mount`, `umount` etc. We can't remove it
    # since it's a dependency of alpine-base.
    sudo sh -c "cd ${rebuild_tmp} && \
    chmod 755 ${rebuild_tmp} && \
    find . -exec touch -h -t 197001010000 {} + && \
    find . -path './boot' -prune -o -print | \
    cpio -o -H newc --owner=0:0 | \
    gzip -n > ${build_tmp}/initramfs"
    # Build initramfs and kernel into UKI
    ukify build \
    --output "images/${UKIFILENAME}" \
    --cmdline "rdinit=/sbin/init console=ttyS0 psi=1" \
    --linux "${rebuild_tmp}/boot/vmlinuz-virt" \
    --initrd "${build_tmp}/initramfs"
    # Update corresponding Terraform deployment files
    just update-tf

[working-directory: 'terraform']
deploy:
    # Start local webserver to host the images we've built for Proxmox to grab
    just start-webserver
    trap 'podman stop apko-image-deploy' EXIT

    # Import Proxmox vars from local disk only for pinewall-private
    # (no TPM on X260 deployment host), then deploy
    . ~/.ssh/pve_cursedrouter.sh && \
    tofu init && \
    tofu fmt && \
    tofu apply

[working-directory: 'image']
update-lockfile:
    # Update apko lockfile
    # Sadly does not work for apko build-minirootfs, only for apko build
    #apko lock --ignore-signatures pinewall.yaml

[working-directory: 'terraform']
update-tf:
    #!/usr/bin/env bash
    set -euo pipefail
    # Calculate UKI filename based on env vars in shell
    UKIFILENAME="${IMAGENAME}_${IMAGEVERSION}.efi.img"
    jinja2 templates/terraform-base.tf.j2 \
    -D prox_url="${PROXURL}" \
    -D prox_selfsigned="${PROXSELFSIGNED}" > terraform-base.tf
    jinja2 templates/terraform-vm.tf.j2 \
    -D prox_node_name="${PROXNODE}" \
    -D vm_hostname="${IMAGENAME}" \
    -D uki_filename="${UKIFILENAME}" \
    -D wan_if="${PROXWAN}" \
    -D lan_if="${PROXLAN}" \
    -D prox_vmid="${PROXVMID}" > terraform-vm.tf

start-webserver:
    # Start local webserver to host the images we've built for Proxmox to grab
    podman stop apko-image-deploy 2>/dev/null || true
    podman rm apko-image-deploy 2>/dev/null || true
    podman run -d --rm -v "$PWD"/image/images:/usr/share/nginx/html/images:ro,z \
    --name apko-image-deploy \
    -p 8080:80 \
    docker.io/library/nginx:alpine
