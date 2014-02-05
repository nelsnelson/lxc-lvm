#! /usr/bin/env bash

silently() { "$@" &>/dev/null; }

sudo cp -f lxc-rackos-minimal /usr/share/lxc/templates/lxc-rackos-minimal

tear_down() {
    sudo /sbin/vgremove -f lxc
    sudo /sbin/pvremove /dev/loop0
    sudo /sbin/losetup -d /dev/loop0
    sudo rm -f /tmp/test.img
    sudo rm -f /tmp/lxc.log
    sudo rm -f /tmp/lxc-test-config
    # Just in case
    sudo rm -f /tmp/garbage
}

exec &>/dev/null
sudo lxc-stop -n test
sudo lxc-destroy -n test
exec &>/dev/tty
silently tear_down

set -x
# Create disk iamge for lvm 
/bin/dd if=/dev/zero of=/tmp/test.img bs=1024 count=10240
sudo /sbin/losetup /dev/loop0 /tmp/test.img

# Create lvm parition and volume group
sudo /sbin/pvcreate /dev/loop0
sudo /sbin/vgcreate lxc /dev/loop0

# Create lxc instance
sudo lxc-create -t rackos-minimal -n test -f /var/lib/lxc/test/config -B lvm --fssize 8M -l DEBUG -o /tmp/lxc.log
sudo lxc-start -d -n test -f /var/lib/lxc/test/config -P /var/lib/lxc/test -l DEBUG -o /tmp/lxc.log
set +x

sudo lxc-ls | grep -q test
if [ $? -ne 0 ]; then
    cat /tmp/lxc.log
    tear_down
    exit 1
fi

set -x
sudo lxc-attach -n test -P /var/lib/lxc/test -- cat /proc/self/mounts
sudo lxc-attach -n test -P /var/lib/lxc/test -- /bin/df 
sudo lxc-attach -n test -P /var/lib/lxc/test -- rm -f /tmp/garbage
sudo lxc-attach -n test -P /var/lib/lxc/test -- /bin/dd if=/dev/zero of=/tmp/garbage bs=1025 count=10240
set +x

silently tear_down

