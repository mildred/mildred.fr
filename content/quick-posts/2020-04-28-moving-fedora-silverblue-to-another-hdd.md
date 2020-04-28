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

### Copy the files

Before all, the GPT disk must contains a specific partition that will contain the GRUB boot loader, else you won't be able to install GRUB. You can set up this partition in parted with:

    # parted /dev/sdb
    (parted) print                                                            
    Model: ATA KINGSTON SUV500M (scsi)
    Disk /dev/sdb: 240GB
    Sector size (logical/physical): 512B/4096B
    Partition Table: gpt
    Disk Flags: 
    
    Number  Start   End     Size    File system  Name  Flags
     1      1049kB  17.8MB  16.8MB               grub
     3      17.8MB  1001MB  984MB   ext4
     2      1001MB  240GB   239GB
    (parted) help toggle                                                      
      toggle [NUMBER [FLAG]]                   toggle the state of FLAG on partition NUMBER
    
	    NUMBER is the partition number used by Linux.  On MS-DOS disk labels, the primary partitions number from 1 to 4, logical partitions
            from 5 onwards.
            FLAG is one of: boot, root, swap, hidden, raid, lvm, lba, hp-service, palo, prep, msftres, bios_grub, atvrecv, diag, legacy_boot,
            msftdata, irst, esp
    (parted) toggle 1 bios_grub
    (parted) quit

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

### Find important values to modify

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

The deployment id is `c0dcf72a27f8dd1e087fa4953b9e4e8bcf0d196fbcd781432281f33273d7633e.0`.

### update configuration

1.  Get in the deployment directory

    cd /media/mildred/system/fedora/ostree/deploy/fedora-workstation/deploy/c0dcf72a27f8dd1e087fa4953b9e4e8bcf0d196fbcd781432281f33273d7633e.0

2.  First thing, update /etc/fstab to change the partition UUIDs to account for the SSD partitions. The only partition that I kept on the HDD is the swap.

        vi ./etc/fstab

    Update all `UUID=*` lines with SSD partition UUIDs

3.  Get into the boot partition

        cd /media/mildred/boot

4.  Update the loader file (check it's the right file compared to the deployment you modified)

        vi loader/entries/ostree-2-fedora-workstation.conf
 
    Then, change again all the `UUID=*` strings to match your newer partitions. Beware, the `resume=` option should match your swap and `root=` should match your root partition.

5.  Update the GRUB configuration manually (because grub2-mkconfig cannot work, even in a chroot, because it will not be able to find the root device). Make sure you change the right entry again, using the same UUIDs as in the loader entry. Also update the `set root=` and `search` grub options with the physical address of the boot partition

        vi loader/grub.cfg

### Get into the chroot and install GRUB

Create a target mount point:

    mkdir /mnt/target
    mount /dev/mapper/luks-27948583-d046-42ae-bcee-e1394553e0b6 /mnt/target -o subvol=fedora
    cd /mnt/target

Let's go in the deployment directory to prepare for the chroot:
    
    cd ostree/deploy/fedora-workstation/deploy/c0dcf72a27f8dd1e087fa4953b9e4e8bcf0d196fbcd781432281f33273d7633e.0
    mount --bind /media/mildred/boot ./boot
    mount --bind /dev dev
    mount --bind /dev/pts dev/pts
    mount --bind /proc proc
    mount --bind /sys sys
    chroot .

Now, install GRUB:

    grub2-install /dev/sdb

### Reboot

Update BIOS boot device and choose the correct option in GRUB. After rebooting, regenerating the GRUB config might help to have something correct in the configuration files all the way.

References:

- [Forum topic on how to install GRUB from chroot](https://discussion.fedoraproject.org/t/recover-grub-after-reinstall-windows/9123)
- https://github.com/ostreedev/ostree/issues/1009#issuecomment-506503756
