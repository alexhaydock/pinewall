.PHONY: trap deps overlay x86 rpi

trap:
	echo "Error! Please specify 'make deps', 'make overlay, 'make x86' or 'make rpi' directly."

deps:
	sudo dnf install podman qemu qemu-user-static

overlay:
	mkdir -p "$(shell pwd)/overlays"
	podman build -f Dockerfile_overlay -t pinewall-overlay .
	podman run --rm -it -v "$(shell pwd)/overlays:/tmp/overlays:Z" pinewall-overlay ./genapkovl-pinewall.sh

x86:
	mkdir -p "$(shell pwd)/images"
	podman build --arch=amd64 -f Dockerfile_image -t localhost/pinewall-x86 .
	podman run --arch=amd64 --rm -it -v "$(shell pwd)/images:/tmp/images:Z" --tmpfs "/tmp/cache" --env PROFILENAME=pinewall_x86 --env TARGETARCH=x86_64 localhost/pinewall-x86 ./imagebuild.sh

rpi:
	mkdir -p "$(shell pwd)/images"
	podman build --arch=arm64 -f Dockerfile_image -t localhost/pinewall-rpi .
	podman run --arch=arm64 --rm -it -v "$(shell pwd)/images:/tmp/images:Z" --tmpfs "/tmp/cache" --env PROFILENAME=pinewall_rpi --env TARGETARCH=aarch64 localhost/pinewall-rpi ./imagebuild.sh
