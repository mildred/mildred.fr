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

... to be continued ...
