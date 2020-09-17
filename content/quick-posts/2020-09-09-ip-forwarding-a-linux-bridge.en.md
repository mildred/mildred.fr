---
title: "IP Forwarding winth a Linux bridge"
date: 2020-09-09
---

## Background

I maintain a mail server at home, and to get its public IP address,
I have a VPN on it (so it is independent on how I connect to the Internet).
Recently I decided to update my home network router so I could connect directly
to the server (instead of going out to the internet and back in via the VPN). I
just added a static route to the public IP to using the private IP as gateway.

The only problem is that on the mail server, in order to be flexible how it is
connected to the network, the LAN IP address is configured on a bridge network
device where the physical device is part of. There are a few VLAN tricks too.

An ascii-art diagram:

    -----[ enp1s0 ]-----------------------------------------------
             |
             |                            [tun0] 193.33.56.74
         [ bridge ] 192.168.5.16

## The problem

When an IP packet with the destination IP set to the public IP
(193.33.56.74 in the diagram) arrives on the physical network, it never gets to
the bridge device. When I tcpdump `enp1s0`, I see the packet, when I tcpdump
`bridge` the packet does not appear.

This is because the bridge address only has the LAN IP address and not the
public IP address. Even though I have IP forwarding in place, it does not work.

## The solution

The trick is to add to `sysctl.conf`

    # bridge forward
    net.bridge.bridge-nf-call-arptables=0
    net.bridge.bridge-nf-call-iptables=0

And this can only work if the correct kernel module is loaded at boot time:

    # /etc/modules-load.d/bridge-forward.conf
    br_netfilter

## Details about bridge configuration

For reference, this is how I configure the bridge with systemd-networkd:

`en.network`:

    [Match]
    Name=en* !en*.610 !en*u*

    [Network]
    Bridge=bridge

    [BridgeVLAN]
    VLAN=1
    PVID=1
    EgressUntagged=1

    [BridgeVLAN]
    VLAN=610

`bridge.netdev`:

    [NetDev]
    Name=bridge
    Kind=bridge

    [Bridge]
    DefaultPVID=1
    VLANFiltering=yes

`bridge.network`:

    [Match]
    Name=bridge

    [Network]
    VLAN=lan
    VLAN=vlan610

    [BridgeVLAN]
    VLAN=1

    [BridgeVLAN]
    VLAN=610

`lan.netdev`:

    [NetDev]
    Name=lan
    Kind=vlan

    [VLAN]
    Id=1

`lan.network`:

    [Match]
    Name=lan

    [Network]
    #DHCP=ipv4
    Address=192.168.5.16/24
    Gateway=192.168.5.1
    DNS=X.X.X.X
    DNS=X.X.X.X

(`vlan610.netdev` and `vlan610.network` not shown)
