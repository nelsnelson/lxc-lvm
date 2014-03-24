#! /usr/bin/env bash

sudo cp -f lxc-rackos-minimal /usr/share/lxc/templates/lxc-rackos-minimal

exec &>/dev/null
sudo lxc-stop -n test
sudo lxc-destroy -n test
sudo rm -f /tmp/lxc.log
exec &>/dev/tty

set -x
# Create lxc instance
sudo lxc-create -t rackos-minimal -n test -l TRACE -o /tmp/lxc.log
sudo lxc-start -d -n test -l TRACE -o /tmp/lxc.log
sudo lxc-ls
sudo lxc-info -n test -l TRACE -o /tmp/lxc.log
sudo lxc-attach -n test -- echo hello world
set +x

exec &>/dev/null
sudo rm -f /tmp/lxc.log
exec &>/dev/tty
