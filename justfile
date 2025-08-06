set ignore-comments
# quiet mode does not ship in Ubuntu 24.04's version of `just`
#set quiet

# Because we're setting variables directly in our recipes
set shell := ["bash", "-cu"]

help:
    echo ''
    echo 'Available commands:'
    echo ''
    echo '  just build  - Build Pinewall'
    echo '  just deploy - Deploy Pinewall'
    echo ''

build:
    mkdir -p "$PWD"/images
    # Mounts a tmpfs in /tmp in the container as this is where
    # Ansible will do our build (ansible.builtin.tempfile)
    podman run --rm -it -v "$PWD":/mnt:z \
        --entrypoint /bin/sh \
        --workdir /mnt \
        --mount="type=tmpfs,tmpfs-size=512M,destination=/tmp" \
        docker.io/library/alpine:latest \
            -c 'apk --no-cache add ansible && \
            ansible-playbook build.yml'

deploy:
    # Start local webserver to host the images we've built for Proxmox to grab
    podman stop pinewall-image-deploy 2>/dev/null || true
    podman rm pinewall-image-deploy 2>/dev/null || true
    podman run -d --rm -v "$PWD"/images:/usr/share/nginx/html/images:ro,z \
        --name pinewall-image-deploy \
        -p 8080:80 \
        docker.io/library/nginx:alpine

    # Deploy using OpenTofu
    # (after discovering Proxmox creds from TPM and the IP of our local machine)
    export PROXMOX_VE_USERNAME="root@pam" && \
    export PROXMOX_VE_PASSWORD="$(sudo tpm2 rsadecrypt -c 0x81010001 ~/.ssh/tpm-$(hostname)/api_key_prox_rtr.enc)" && \
    export TF_VAR_deployment_host_ip="$(ip -4 addr show dev "$(ip route show default | awk '/default/ {print $5}')" | awk '/inet / {print $2}' | cut -d/ -f1)" && \
    cd "$PWD/terraform" && \
    podman run -it --rm -v "$PWD":/mnt:z \
        --env PROXMOX_VE_USERNAME \
        --env PROXMOX_VE_PASSWORD \
        --env TF_VAR_deployment_host_ip \
        --workdir /mnt \
        --entrypoint /bin/sh \
        ghcr.io/opentofu/opentofu:latest -c \
            'tofu init && tofu fmt && tofu apply'

    # Stop local webserver container
    podman stop pinewall-image-deploy || true
