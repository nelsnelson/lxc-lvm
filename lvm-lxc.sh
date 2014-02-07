#! /usr/bin/env bash

set -x

/bin/rm -f /tmp/lxc.log
/bin/rm -f /tmp/test.img
sudo /sbin/losetup -d /dev/loop0
sudo /sbin/vgremove lxc
sudo /sbin/pvremove /dev/loop0
sudo lxc-destroy -n test

# Create disk iamge for lvm 
/bin/dd if=/dev/zero of=/tmp/test.img bs=1024 count=10240
sudo /sbin/losetup /dev/loop0 /tmp/test.img

# Create lvm parition and volume group
sudo /sbin/pvcreate /dev/loop0
sudo /sbin/vgcreate lxc /dev/loop0

# Create lxc instance
sudo lxc-create -t minimal -n test -B lvm --fssize 8M -l DEBUG -o /tmp/lxc.log
sudo lxc-start -d -n test -l DEBUG -o /tmp/lxc.log
cat /tmp/lxc.log

sudo lxc-execute -n test -- cat /proc/self/mounts
sudo lxc-execute -n test -- rm -f /tmp/garbage; /bin/dd if=/dev/zero of=/tmp/garbage bs=1024 count=10240

# Cleanup
sudo lxc-stop -n test
sudo lxc-destroy -n test

