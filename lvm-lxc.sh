#! /usr/bin/env bash

set -x

sudo cp -f lxc-rackos-minimal /usr/share/lxc/templates/lxc-rackos-minimal

sudo /sbin/vgremove lxc &>/dev/null
sudo /sbin/pvremove /dev/loop0 &>/dev/null
sudo /sbin/losetup -d /dev/loop0 &>/dev/null
sudo rm -f /tmp/test.img &>/dev/null
sudo rm -f /tmp/lxc.log &>/dev/null
sudo lxc-destroy -n test &>/dev/null

function tear_down() {
    sudo lxc-stop -n test &>/dev/null
    sudo lxc-destroy -n test &>/dev/null
    sudo /sbin/vgremove lxc &>/dev/null
    sudo /sbin/pvremove /dev/loop0 &>/dev/null
    sudo /sbin/losetup -d /dev/loop0 &>/dev/null
    sudo rm -f /tmp/test.img &>/dev/null
    sudo rm -f /tmp/lxc.log &>/dev/null
    # Just in case
    sudo rm -f /tmp/garbage &>/dev/null
}

# Create disk iamge for lvm 
/bin/dd if=/dev/zero of=/tmp/test.img bs=1024 count=10240
sudo /sbin/losetup /dev/loop0 /tmp/test.img

# Create lvm parition and volume group
sudo /sbin/pvcreate /dev/loop0
sudo /sbin/vgcreate lxc /dev/loop0

# Create lxc instance
sudo lxc-create -t rackos-minimal -n test -B lvm --fssize 8M -l DEBUG -o /tmp/lxc.log
sudo lxc-start -d -n test -l DEBUG -o /tmp/lxc.log

sudo lxc-ls | grep -q test
if [ $? -ne 0 ]; then
    set +x
    cat /tmp/lxc.log
    tear_down
    exit 1
fi

sudo lxc-attach -n test -P /var/lib/lxc/test -- cat /proc/self/mounts
sudo lxc-attach -n test -P /var/lib/lxc/test -- /bin/df 
sudo lxc-attach -n test -P /var/lib/lxc/test -- rm -f /tmp/garbage
sudo lxc-attach -n test -P /var/lib/lxc/test -- /bin/dd if=/dev/zero of=/tmp/garbage bs=1025 count=10240

