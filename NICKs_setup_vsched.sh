#!/bin/bash

sudo tee /sys/fs/cgroup/cgroup.subtree_control <<< "+cpu"
sudo tee /sys/fs/cgroup/cgroup.subtree_control <<< "+cpuset"

if [ ! -d /sys/fs/cgroup/hi_prgroup ]; then
    sudo mkdir /sys/fs/cgroup/hi_prgroup
fi

if [ ! -d /sys/fs/cgroup/lw_prgroup ]; then
    sudo mkdir /sys/fs/cgroup/lw_prgroup
fi

sudo tee /sys/fs/cgroup/lw_prgroup/cgroup.type <<< "threaded"
sudo tee /sys/fs/cgroup/hi_prgroup/cgroup.type <<< "threaded"
sudo tee /sys/fs/cgroup/lw_prgroup/cpu.idle <<< "1"
sudo tee /sys/fs/cgroup/hi_prgroup/cpu.weight.nice <<< "-20"

(cd ./vtopology/ && sudo make)
(cd ./vcapacity/ && sudo make)
(cd ./vsched_kernel/custom_modules/ && sudo make)

# preempt_proc.ko not yet implemented - skipping insmod

(cd ./vsched_kernel/tools/lib/bpf && sudo make)
(cd ./vsched_kernel/tools/bpf/bpftool && sudo make)

sudo bash -c '
cd ./vsched_kernel/tools/bpf/vsched_bpf_hooks &&
../bpftool/bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
'

(cd ./vsched_kernel/tools/bpf/vsched_bpf_hooks && sudo make)
