#! /usr/bin/env python

import os
import sys
import time


# MAKE SURE YOU TURN OFF SWAP!!!!
# swapoff -a

class Cgroup(object):
    PATH = '/sys/fs/cgroup'

    def __init__(self, name, subsystem=None, parent=None):
        self.name = name
        self.subsystem = subsystem
        self.parent = parent

    def create(self):
        if not os.path.exists(self.path):
            os.mkdir(self.path)

    def destroy(self):
        if os.path.exists(self.path):
            os.rmdir(self.path)

    def add_task(self, pid):
        with open(os.path.join(self.path, 'tasks'), 'a') as f:
            f.write(pid)

    def remove_task(self, pid):
        tasks = os.path.join(self.path, 'tasks')
        if os.path.exists(tasks):
            os.remove(tasks)

    def write(self, key, value):
        with open(os.path.join(self.path, key), 'w') as f:
            f.write(value)

    def clear(self, key):
        entry = os.path.join(self.path, key)
        if os.path.exists(entry):
            os.remove(entry)

    def finalize(self):
        subsystem_path = os.path.join(self.PATH, self.subsystem)
        if os.path.exists(subsystem_path):
            os.rmdir(subsystem_path)

    @property
    def path(self):
        if self.parent:
            return os.path.join(self.parent.path, self.name)
        elif self.subsystem:
            subsystem_path = os.path.join(self.PATH, self.subsystem)
            if not os.path.exists(subsystem_path):
                os.mkdir(subsystem_path)
            return os.path.join(self.PATH, self.subsystem, self.name)
        else:
            raise Exception('Need parent or subsystem')


def child():
    time.sleep(1)
    print 'child'
    MB = 1024 ** 2 
    s = 'c' * 2 * MB
    print s
    print len(s)
    sys.exit(0)


def parent(outer, inner, pid):
    print 'parent'
    pid = str(pid)
    try:
        inner.add_task(pid)
        os.wait()
    finally:
        inner.remove_task(pid)

def main():
    outer = Cgroup('outer', subsystem='memory')
    outer.create()

    inner = Cgroup('inner', parent=outer)
    inner.create()

    try:
        outer.write('memory.limit_in_bytes', '1M')
        pid = os.fork()

        if pid == 0:
            child()
        else:
            parent(outer, inner, pid)
    except:
        inner.remove_task(pid)
        inner.destroy()
        outer.clear('memory.limit_in_bytes')
        outer.destroy()
        raise
    finally:
        outer.finalize()


if __name__ == "__main__":
    main()
