.PHONY: trap deps overlay x86 rpi

trap:
	echo "Error! Please specify 'make deps', 'make overlay, 'make x86' or 'make rpi' directly."

deps:
	sudo dnf install podman qemu qemu-user-static

overlay:
	mkdir -p "$(shell pwd)/overlays"
	podman build -f Dockerfile_overlay -t pinewall-overlay .
	podman run --rm -it -v "$(shell pwd)/overlays:/tmp/output:Z" pinewall-overlay ./genapkovl-pinewall.sh

x86:
	mkdir -p "$(shell pwd)/output"
	podman build --arch=amd64 -f Dockerfile_image -t localhost/pinewall .
	podman run --arch=amd64 --rm -it -v "$(shell pwd)/output:/tmp/output:Z" localhost/pinewall

rpi:
	mkdir -p "$(shell pwd)/output"
	podman build --arch=arm64 -f Dockerfile_image -t localhost/pinewall .
	podman run --arch=arm64 --rm -it -v "$(shell pwd)/output:/tmp/output:Z" localhost/pinewall
	sudo podman build --arch=arm64 -f Dockerfile_imagepack -t localhost/pinewall-rpi-imagepack .
	sudo podman run --arch=arm64 --rm -it --privileged -v "$(shell pwd)/output:/tmp/output:Z" localhost/pinewall-rpi-imagepack ./imagepack.sh
