#!/bin/bash
NUM_OF_HD=2
for i in `seq 1 ${NUM_OF_HD}`; do
    DEVC=`expr ${i} + 97`
    DEV=`printf "/dev/vd\x$(printf %x $DEVC)"`
    parted $DEV mklabel gpt
    parted $DEV mkpart primary ext4 2048s 100%
    mkfs.ext4 ${DEV}1
    mkdir -p /data/0${i}
    mount -t ext4 ${DEV}1 /data/0${i}
done
cat << EOF >> /etc/fstab
/dev/vdb1     /data/01     ext4    defaults 0 1
/dev/vdc1     /data/02     ext4    defaults 0 1
EOF
