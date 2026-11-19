set ignore-comments

# Build config and run our VM using the `config/example`
# directory if we haven't overridden the variable
run config_dir='example':
    just efivars {{config_dir}}
    just qemu {{config_dir}}

# Update Pinewall EFI image on-disk
update:
    ./scripts/update.sh

efivars config_dir='example':
    ./scripts/efivars.sh "{{config_dir}}"

qemu config_dir='example':
    ./scripts/qemu.sh "{{config_dir}}"
