#!/usr/bin/env bash

function usage {
    echo "Usage : $0 kernel_image_path [ virtfs_path ]"
}

if [[ "$#" -lt 1 ]]; then
    usage
    echo "Looking for images :"
    RES=$(find .. -name bzImage -type f 2> /dev/null)
    if [[ -z $RES ]]; then
	echo "    none found"
    else
	echo $RES
    fi
    exit 1
elif [[ "$#" -gt 2 ]]; then
    usage
    exit 1
elif [[ "$#" -eq 2 ]]; then
    QEMU_VIRTFS_ARGS="-virtfs local,path=$2,mount_tag=host0,security_model=passthrough,id=host0"
fi

KERNEL_IMAGE_PATH=$1

set -x

make -C ./test

sudo mount linux.img mnt/
mkdir -p mnt/opt
sudo chown $USER mnt/opt
cp test/test mnt/opt
sudo cp -p /usr/local/lib/libkunwind* mnt/usr/local/lib/
cp -p ./start.sh mnt/opt
cp -p ./kunwind-debug.ko mnt/opt/
cp -p ./kunwind.ko mnt/opt/
sudo umount linux.img

qemu-system-x86_64 \
    -drive file=linux.img,index=0,media=disk,format=raw \
    -no-reboot \
    -nographic \
    -kernel $KERNEL_IMAGE_PATH \
    $QEMU_VIRTFS_ARGS \
    -append "root=/dev/sda rw init=/opt/start.sh console=ttyS0 panic=1" \
    -s

# starts gdb server on localhost:1234
# hook from client with: target remote localhost:1234
