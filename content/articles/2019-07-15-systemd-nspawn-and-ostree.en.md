---
title: "systemd-nspawn and OSTree"
date: 2019-07-15
draft: false
---

I run my servers and my laptop using Fedora Atomic. This is the next Fedora
CoreOS which is curently in devloppment. The current Fedora release is only
available through the Silverblue channel, so that's what I'm using currently. It
features atomic updates and clean package layering. You can easily rollback.

Now, I have a physical server to mess up with things locally, and I wanted to
create multiple virtual environments where I can test different things. In
particular I want to try a Rancher k3s deployment on bare metal. The only thing
is that physical machines are difficult to clone, so I wanted to setup some kind
of virtual environment on top of it to be able to start up a different OS
distribution later on without requiring me to buy a new machine and reconfigure
it from scratch.

instead of going the virtual machine route, I wanted to test systemd-nspawn and
systemd-machined to manage my "virtual" machines wuing `machinectl`. Also, I
wanted to boot an OSTree distribution both as host and guest. OSTree is nice
because it allows to share a single `/ostree` between various systems. here is
how I did it.

Create the OSTree deployment
----------------------------

You need to create a new OSTree deployment without impacting the host. First,
create a new OS inside your OSTree:

    [root@host host]# ostree admin os-init guest
    ostree/deploy/guest initialized as OSTree root

You now have a guest OS registered, but it does not have any deployment. A
deployment is a system image you layer on top of resident data (`/var`). To
create a deployment, you need an OSTree commit hash to reference it. Let's start
with the same commit as the host.

Let's view your deployments:

    [root@host host]# ostree admin status
      fedora 131642a5b3da24dc47f9ff8191f5856bbeced08275ea823fa543327fd20f4862.0 (staged)
        Version: 30.20190715.0
        origin: <unknown origin type>
    * fedora 8e721e68bfa7c813361f3067d202b2fd907634e192059451ffa8365ca5733224.0
        Version: 30.20190713.0
        origin: <unknown origin type>
      fedora 38a1f86b1168dda0e8ed80782afb3e56bb1918b1984c1dc0d7216f63f865a7a0.0 (rollback)
        Version: 30.20190701.0
        origin: <unknown origin type>

here you see I performed an updated (staged) but did not reboot to it. I also
have the current deployment and the rollback deployment. the hashes are not
commit ids yet. Perhaps there is another way to get the commit ids, but I did a
`rpm-ostree status` to get it:

    [root@host host]# rpm-ostree status
    State: idle
    AutomaticUpdates: disabled
    Deployments:
      ostree://fedora:fedora/30/x86_64/silverblue
                       Version: 30.20190715.0 (2019-07-15T00:36:07Z)
                    BaseCommit: fa23b170d892d78935de422064e73a84057119ea315257a9030dc7659e726a7b
                     StateRoot: fedora
                  GPGSignature: Valid signature by F1D8EC98F241AAF20DF69420EF3C111FCFC659B9
                          Diff: 11 upgraded, 1 added
               LayeredPackages: net-tools strace systemd-container tcpdump tmux

    ● ostree://fedora:fedora/30/x86_64/silverblue
                       Version: 30.20190713.0 (2019-07-13T00:38:50Z)
                    BaseCommit: f8aeed3ee64bddecb6ebfd382db9c4b19c5f5502cb24fdb4eed788b9c4558f62
                     StateRoot: fedora
                  GPGSignature: Valid signature by F1D8EC98F241AAF20DF69420EF3C111FCFC659B9
               LayeredPackages: net-tools systemd-container tcpdump tmux

      ostree://fedora:fedora/30/x86_64/silverblue
                       Version: 30.20190701.0 (2019-07-01T00:36:21Z)
                    BaseCommit: f5efad3126a7bc90b88c0a3ba382c15eb3119e123eef3b1f1e2c4a7f7480fcc1
                     StateRoot: fedora
                  GPGSignature: Valid signature by F1D8EC98F241AAF20DF69420EF3C111FCFC659B9
               LayeredPackages: net-tools tcpdump tmux

Let's take commit
`fa23b170d892d78935de422064e73a84057119ea315257a9030dc7659e726a7b` as a base
commit for our new `guest` deployment.

    [root@host host]# ostree admin deploy --not-as-default --os=guest fa23b170d892d78935de422064e73a84057119ea315257a9030dc7659e726a7b
    Relabeling /var (no stamp file 'var/.ostree-selabeled' found)
    Bootloader updated; bootconfig swap: yes; deployment count change: 0

You need to specify `--not-as-default` else when the host is going to reboot, it
will reboot to the guest deployment. That would not be nice.

Setup systemd-nspawn to start the guest
---------------------------------------

Because systemd-nspawn is accessing `/sysroot` and I believe SELinux is not
configured to allow that by default, you'll have to find a way for SELinux to
accept what we are doing. You can just test things out first by setting SELinux
to permissive mode:

    [root@host host]# setenforce Permissive

(you might want to configure this to keep it across reboots)

Now, you need to create a dropin to `systemd-nspawn@guest.service` to set up
option to systemd-nspawn:

    [root@host host]# cat /etc/systemd/system/systemd-nspawn@guest.service.d/10-service.conf
    [Service]
    ExecStart=
    Environment=SYSTEMD_NSPAWN_LOCK=0
    ExecStart=/bin/sh -xc ' \
            deployment=`ostree admin status | sed -ne \'s/. %i \\(\\S*\\)\\( .*\\)*$/\\1/; T; p; q\'`; \
            exec /usr/bin/systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth --settings=override --machine=%i \
            --directory=/sysroot \
            --bind /boot:/boot \
            --bind +/sysroot/ostree/deploy/%i/var:/var \
            --pivot-root /ostree/deploy/%i/deploy/$deployment:/sysroot \
            $SYSTEMD_NSPAWN_FLAGS \
            '
    RestartForceExitStatus=
    Restart=always
    RestartSec=3s

In particular:

- `-U` is removed because we do not want systemd-nspawn to update the UID/GID in
  /ostree. Unfortunately, this article does not cover how we can separate
  UIDs/GIDs between the host and the guest.

- `--directory=/sysroot` is telling systemd-nspawn to boot `/sysroot` as root
  directory. This is the filesystem root.

- `--bind /boot:/boot` is telling to keep the boot partition mounted. This is
  necessary for the ostree command-line to work (it looks for files in
  `/boot/loader/entries`)

- `--bind +/sysroot/ostree/deploy/%i/var:/var` is telling to mount the
  persistent `/var` directory. Else we would have a complete system read-only.

- `--pivot-root /ostree/deploy/%i/deploy/$deployment:/sysroot` is telling to
  pivot-root to the specific deployment (computed from the sed pipeline above)

- `Restart=always` and `RestartSec=3s` gives enough time to systemd-machined to
  deregister the machine so the machine can restart without errors (`Failed to
  register machine: Machine 'guest' already exists`)

With that, you can now enable and start the service, and you have a sub-machine
ready.

    [root@host host]# systemctl enable --now systemd-nspawn@guest.service
    [root@host host]# machinectl list
    MACHINE CLASS     SERVICE        OS     VERSION ADDRESSES
    guest   container systemd-nspawn fedora 30      -        

    2 machines listed.
    [root@host host]# machinectl shell guest
    Connected to machine guest. Press ^] three times within 1s to exit session.

    Welcome to Fedora Silverblue. This terminal is running on the
    immutable host system. You may want to try out the Toolbox for a
    more traditional environment that allows package installation
    with DNF.

    For more information, see the documentation.

    [root@guest roothome]# ostree admin status
      fedora 8e721e68bfa7c813361f3067d202b2fd907634e192059451ffa8365ca5733224.0
        Version: 30.20190713.0
        origin: <unknown origin type>
    * guest fa23b170d892d78935de422064e73a84057119ea315257a9030dc7659e726a7b.0
        Version: 30.20190715.0
        origin refspec: fa23b170d892d78935de422064e73a84057119ea315257a9030dc7659e726a7b
      fedora 38a1f86b1168dda0e8ed80782afb3e56bb1918b1984c1dc0d7216f63f865a7a0.0
        Version: 30.20190701.0
        origin: <unknown origin type>

You will also need to enable `machines.target`:

    [root@host host]$ systemctl enable machines.target
    Created symlink /etc/systemd/system/multi-user.target.wants/machines.target → /usr/lib/systemd/system/machines.target.


Configure network bridge
------------------------

To make the guest machine accessible from the network, it needs to be bridged
(or otherwise connected) to the host network. By default a network interface
pair is created but left unconfigured. We'll see how to bridge it to the host
network.

First, you need to create a bridge on the host. We'll use systemd-networkd which
is suitable for servers. Ensure it is enabled and started:

    [root@host host]# systemctl status systemd-networkd
    ● systemd-networkd.service - Network Service
       Loaded: loaded (/usr/lib/systemd/system/systemd-networkd.service; enabled; vendor preset: disabled)
       Active: active (running) since Mon 2019-07-15 14:34:30 CEST; 22s ago

Then you need to create a bridge device:

    [root@host host]# cat /etc/systemd/network/br0.netdev
    [NetDev]
    Name=br0
    Kind=bridge

Assign the upstream network interfaces to the bridge (beware, if you have static
DHCP rules, the host MAC address will change to the MAC address of the bridge,
which is deterministic):

    [root@host host]# cat /etc/systemd/network/br0-bind.network
    [Match]
    Name=en*

    [Network]
    Bridge=br0

And enable DHCP on the bridge:

    [root@host host]# cat /etc/systemd/network/br0.network
    [Match]
    Name=br0

    [Network]
    DHCP=ipv4

And add a systemd-nspawn flag to bridge the machine:

    [root@host host]# cat /etc/systemd/system/systemd-nspawn@guest.service.d/10-flags.conf
    [Service]
    Environment=SYSTEMD_NSPAWN_FLAGS=--network-bridge=br0

Then, you can restart `systemd-networkd` and `systemd-nspawn@guest`.

In case you want to run Kubernetes in it
----------------------------------------

Short answer: it's difficult and need further work

You need to make a few changes. First, you need to disable conntrack tweaking in
kube-proxy. kube-proxy be default attempts to tweak the nf_conntrack kernel
module, which is not possible in the nspawn jail because
`/sys/module/nf_conntrack/parameters/hashsize` does not exists. Add to the
kube-proxy command-line:

    --conntrack-max-per-core=0

If you use btrfs, you may have problems with kubelet which cannot find device
major and minor number for its data directories. I had a strange error like
`Failed to start ContainerManager failed to get rootfs info: failed to get
device for dir "/var/lib/rancher/k3s/agent/kubelet": could not find device with
major: 0, minor: 44 in cached partitions map` which followed a warning `stat
failed on /dev/sda5 with error: no such file or directory`.

What kubelet is doing (in fact it's delegated to cadvisor) is it's trying to
find the device number for the data directory. If the device major number is 0,
it means that the mount point is a device-less mount point. In this case, a
btrfs subvolume. To get the proper device, it detects if the filesystem is btrfs
and is looking up the device number of the btrfs device itself (`/dev/sda5` in
my case). Because systemd-nspawn mask the block devices, it fails.

The solution is to add to the systemd-nspawn command-line before the pivot root:

    --bind /dev:/dev

To get `/proc/sys` writeable, you need to start systemd-nspawn with:

    Environment=SYSTEMD_NSPAWN_API_VFS_WRITABLE=1

Then, you'll have a problem because the cgroups hierarchy is read-only. This is
because cgroups-v1 cannot be delegated properly and there might be conflicts.
cgroups-v2 might help there but it's still early.