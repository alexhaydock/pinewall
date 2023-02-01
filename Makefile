.PHONY: trap builddep overlay image

trap:
	echo "Error! Please specify 'make builddep', 'make overlay, or 'make image' directly."

builddep:
	sudo apt install podman qemu-user-static

overlay:
	mkdir -p "$(shell pwd)/overlays"
	podman build -f Dockerfile_overlay -t pinewall-overlay .
	podman run --rm -it -v "$(shell pwd)/overlays:/tmp/overlays:Z" pinewall-overlay ./genapkovl-pinewall.sh

image:
    # Remove existing image in local dir
	rm pinewall.img.gz || true
	# Build Pi image
	podman build --arch=arm64 -t localhost/pinewall .
	# Copy image to host machine
	podman rm pinewall || true
	podman create --name pinewall localhost/pinewall
	podman cp pinewall:/opt/pinewall.img.gz pinewall.img.gz
