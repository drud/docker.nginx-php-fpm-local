#!/bin/bash

> files/etc/passwd
> files/etc/group

for i in {0..60000}; do
    echo "uid_$i:x:$i:$i:/home:/bin/bash" >>files/etc/passwd
    echo "gid_$i:x:$i:" >> files/etc/group
done
