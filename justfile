set ignore-comments

# TODO: This is probably too hard-coded to my own deployment
#       infra, but people can update this if they need to
export PROXMOX_VE_USERNAME := "root@pam"
export TF_VAR_deployment_host_ip := "192.168.200.160"

build:
    just config
    just lock
    just image

[working-directory: 'config']
config:
    test -f melange.rsa || melange keygen
    melange build --signing-key melange.rsa --arch amd64 pinewall-config.yaml

[working-directory: 'image']
lock:
    apko lock --output ../apko.lock pinewall.yaml

[working-directory: 'image']
image:
    #!/usr/bin/env bash
    set -euo pipefail
    # Check if git tree is dirty (since we are using the commit ID
    # for versioning)
    just checkgit
    # Calculate UKI filename based on settings and current commit
    UKIFILENAME="${IMAGENAME}_$(git rev-parse --short HEAD).efi.img"
    # Create build and rebuild tempdirs
    build_tmp="$(mktemp -d)"
    # Ensure cleanup if the process exits
    trap 'rm -rf "${build_tmp}"' EXIT
    # DEBUG: echo status
    echo "Build dir: ${build_tmp}"
    # Build cpio file
    #
    # I previously used build-minirootfs here to build a tar-based
    # minirootfs and then unpacked-and-repacked it for the final
    # image, but there's an undocumented `build-cpio` command in
    # apko that we can use to do this more robustly:
    # https://github.com/chainguard-dev/apko/pull/1177
    apko build-cpio --lockfile ../apko.lock pinewall.yaml ${build_tmp}/initramfs
    # Extract just the kernel from image so we can build it into UKI
    cpio -D ${build_tmp} -id "boot/vmlinuz-lts" < ${build_tmp}/initramfs
    # Build initramfs and kernel into UKI
    ukify build \
    --output "images/${UKIFILENAME}" \
    --cmdline "rdinit=/sbin/init console=ttyS0 psi=1" \
    --linux "${build_tmp}/boot/vmlinuz-lts" \
    --initrd "${build_tmp}/initramfs"
    # Update corresponding Terraform deployment files
    just update-tf

[working-directory: 'terraform']
deploy:
    #!/usr/bin/env bash
    set -euo pipefail
    # Start local webserver to host the images we've built for Proxmox to grab
    just start-webserver
    # Ensure cleanup if the process exits
    trap 'podman stop apko-image-deploy' EXIT
    # Import Proxmox vars from local disk only for pinewall-private
    # (no TPM on X260 deployment host), then deploy
    . ~/.ssh/pve_cursedrouter.sh && \
    tofu init && \
    tofu fmt && \
    tofu apply

[working-directory: 'terraform']
update-tf:
    #!/usr/bin/env bash
    set -euo pipefail
    # Check if git tree is dirty (since we are using the commit ID
    # for versioning)
    just checkgit
    # Calculate UKI filename based on env vars in shell
    UKIFILENAME="${IMAGENAME}_$(git rev-parse --short HEAD).efi.img"
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

checkgit:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! git diff-index --quiet HEAD --; then
    echo "Error: Working tree has uncommitted changes."
    echo "Please commit or stash them before continuing."
    exit 1
    fi
