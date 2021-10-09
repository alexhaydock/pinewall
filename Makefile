.PHONY: trap init x86 x86-debug rpi rpi-debug clean

trap:
	echo "Error! Please specify 'make init', 'make x86' or 'make rpi' directly."

init:
	sudo dnf install podman qemu qemu-user-static

overlay:
	mkdir -p "$(shell pwd)/overlays"
	podman build -f Dockerfile_x86 -t pinewall-x86 .
	podman run --rm -it -v "$(shell pwd)/overlays:/tmp/overlays:Z" pinewall-x86 ./genapkovl-pinewall.sh

x86:
	mkdir -p "$(shell pwd)/images"
	podman build -f Dockerfile_x86 -t pinewall-x86 .
	podman run --rm -it -v "$(shell pwd)/images:/tmp/images:Z" --tmpfs "/tmp/cache" pinewall-x86 ./imagebuild.sh

x86-debug:
	podman run --rm -it -v "$(shell pwd)/images:/tmp/images:Z" --tmpfs "/tmp/cache" --entrypoint /bin/ash pinewall-x86

rpi:
	mkdir -p "$(shell pwd)/images"
	podman build -f Dockerfile_aarch64 -t pinewall-rpi .
	podman run --rm -it -v "$(shell pwd)/images:/tmp/images:Z" --tmpfs "/tmp/cache" pinewall-rpi ./imagebuild.sh

rpi-debug:
	podman run --rm -it -v "$(shell pwd)/images:/tmp/images:Z" --tmpfs "/tmp/cache" --entrypoint /bin/ash pinewall-rpi

clean:
	sudo rm -rf ~/.config/containers ~/.local/share/containers /var/lib/containers
	sudo podman system prune --all --volumes
	podman system prune --all --volumes
