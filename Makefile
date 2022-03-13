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

# Note: We don't actually need to run all the Pi container build processes as root, but if we don't then the final
# step, which needs root because it involves making filesystems and mounting loop devices, will fail because the
# localhost/pinewall image won't exist for Podman to use.
rpi:
	mkdir -p "$(shell pwd)/output"
	# Build Pi image content
	sudo podman build --arch=arm64 -f Dockerfile_image -t localhost/pinewall .
	# Copy Pi .tar.gz to output/ directory (can skip this step if we only want the packed .img and .img.gz files)
	#sudo podman run --arch=arm64 --rm -it -v "$(shell pwd)/output:/tmp/output:Z" localhost/pinewall
	# Build Pi actual image (.img) and copy to output/ directory
	#sudo podman run --arch=arm64 --rm -it --privileged -v "$(shell pwd)/output:/tmp/output:Z" --entrypoint ./imagepack.sh localhost/pinewall
