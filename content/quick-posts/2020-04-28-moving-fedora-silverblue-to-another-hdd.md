---
title: "Move Fedora Silverblue on another hard drive"
date: 2020-04-28
draft: false
---

Hello, Today, I received a SSD (mSATA) that I installed in my computer in
addition to the spinning hard drive I have. I want to move the Fedora system off
to the SSD for better performance. I'll try it and explain what I did.

My setup uses an ext4 boot partition and a btrfs system partition with a
`fedora` subvolume for the OSTree system, and a `home` subvolume for the
homedirs. it doesn't do LURKS encryption, and I want to add this in the process.

First, I installed the SSD, booter off the hard drive as before, formatted the
SSD with a 1GB ext4 boot partition and the rest as a btrfs partition all using
gnome-disks. Then, I am moving the subvolumes to the SSD using btrfs-send and
btrfs-receive:

1.  Mount the existing HDD root to a new directory, without mounting any
    subvolume:

        mkdir /mnt/sda6
        mount /dev/sda6 /mnt/sda6

2.  Create snapshots and checks that there is no child subvolume that I missed:

        cd /mnt/sda6
        sub snap -r fedora fedora@2020-04-28
        sub snap -r home home@2020-04-28
        btrfs sub list .

3.  Send over the snapshots to the SSD (which is mounted over
    `/media/mildred/system` in my case):

        btrfs send fedora@2020-04-28 | btrfs receive /media/mildred/system/
        btrfs send home@2020-04-28 | btrfs receive /media/mildred/system/

4.  Now, create a read-write subvolume for the system. I keep the read-only snapshots for now in case I continue to use the system on the HDD and I need to move the newest changes to the SSD (btrfs-send and btrfs-receive can make incremental copies using the snapshot I kept):

        cd /media/mildred/system/
        btrfs sub snap fedora@2020-04-28 fedora
        btrfs sub snap home@2020-04-28 home

Let's move the boot partition over too (SSD boot is mounted over
`/mildred/media/boot`):

    cp -a /boot/* /media/mildred/boot

Note, the SSD does not have any GRUB installed, and the partition references in
GRUB and in `/etc/fstab` must be off. I'll need to update this all to get the
system booting.

I will need the partition UUIDs to reconfigure the system. Here is how I get them (the first, sdb2, is system, the second, sdb1, is boot):

    # ls -l /dev/disk/by-uuid | grep sdb
    lrwxrwxrwx. 1 root root 10 28 avril 13:36 27948583-d046-42ae-bcee-e1394553e0b6 -> ../../sdb2
    lrwxrwxrwx. 1 root root 10 28 avril 13:36 365609fc-83cf-42ce-9ab9-c7a64547c227 -> ../../sdb1

I will also need to get the ostree ids for the booted system that I want to configure:

    # cat /media/mildred/boot/loader/entries/*
    title Fedora 32.20200424.n.0 (Silverblue) (ostree:1)
    version 1
    options resume=UUID=97b54b6f-9147-4879-953e-7619d9c012b6 rhgb quiet root=UUID=55c760d6-d020-4345-893b-839d00b5cff4 ostree=/ostree/boot.0/fedora-workstation/ab7bfac27a7cb9333c9fb1b234887f359ff0b5fb8fe357178a73e3bcf25e0ed3/0 rootflags=subvol=fedora rootflags=subvol=fedora
    linux /ostree/fedora-workstation-ab7bfac27a7cb9333c9fb1b234887f359ff0b5fb8fe357178a73e3bcf25e0ed3/vmlinuz-5.6.6-300.fc32.x86_64
    initrd /ostree/fedora-workstation-ab7bfac27a7cb9333c9fb1b234887f359ff0b5fb8fe357178a73e3bcf25e0ed3/initramfs-5.6.6-300.fc32.x86_64.img
    title Fedora 32.20200428.0 (Silverblue) (ostree:0)
    version 2
    options resume=UUID=97b54b6f-9147-4879-953e-7619d9c012b6 rhgb quiet root=UUID=55c760d6-d020-4345-893b-839d00b5cff4 ostree=/ostree/boot.0/fedora-workstation/e140f262f43397a4b27416a51bf82d9d09e06ae16489f56847b9813dbdfda04a/0 rootflags=subvol=fedora rootflags=subvol=fedora
    linux /ostree/fedora-workstation-e140f262f43397a4b27416a51bf82d9d09e06ae16489f56847b9813dbdfda04a/vmlinuz-5.6.6-300.fc32.x86_64
    initrd /ostree/fedora-workstation-e140f262f43397a4b27416a51bf82d9d09e06ae16489f56847b9813dbdfda04a/initramfs-5.6.6-300.fc32.x86_64.img

I'll only edit the `ostree:0` entry which is the latest system. Its boot id is `e140f262f43397a4b27416a51bf82d9d09e06ae16489f56847b9813dbdfda04a`. I'll need the ostree deployment id:

    # ls -l /media/mildred/system/fedora/ostree/boot.0/fedora-workstation/e140f262f43397a4b27416a51bf82d9d09e06ae16489f56847b9813dbdfda04a
    total 4
    lrwxrwxrwx. 1 root root 108 28 avril 12:17 0 -> ../../../deploy/fedora-workstation/deploy/c0dcf72a27f8dd1e087fa4953b9e4e8bcf0d196fbcd781432281f33273d7633e.0

The deployment id is `c0dcf72a27f8dd1e087fa4953b9e4e8bcf0d196fbcd781432281f33273d7633e.0`. Let's go in the deployment directory to prepare for the chroot:

    cd /media/mildred/system/fedora/ostree/deploy/fedora-workstation/deploy/c0dcf72a27f8dd1e087fa4953b9e4e8bcf0d196fbcd781432281f33273d7633e.0
    mount --bind /media/mildred/boot ./boot
    mount --bind /dev dev
    mount --bind /dev/pts dev/pts
    mount --bind /proc proc
    mount --bind /sys sys
    chroot .

Now, I'm inside the chroot. I'll need to change the UUID of the partitions in /etc/fstab and in grub configurations.

... to be continued ...

References:

- [Forum topic on how to install GRUB from chroot](https://discussion.fedoraproject.org/t/recover-grub-after-reinstall-windows/9123)
