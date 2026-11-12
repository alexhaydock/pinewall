set ignore-comments

go:
    just efivars
    just qemu

efivars:
    sh scripts/efivars.sh

qemu:
    sh scripts/qemu.sh
