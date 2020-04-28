---
title: "Upgrade Fedora Silverblue when you have rpmfusion packages"
date: 2019-04-07
draft: false
---

Upgrading Fedora Silverblue should be as easy as rebasing rpm-ostree to the new
fedora ostree branch. It should be easy performed with:

    sudo ostree remote gpg-import fedora-workstation -k /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-30-primary
    sudo rpm-ostree rebase fedora-workstation:fedora/30/x86_64/silverblue

However, when you have RPMFusion layered packages, this can become a bit more
complex, as rpm-ostree will try to layer fedora-29 packages on top of a
fedora-30 ostree branch. This should fail with something like:

    error: cannot update repo 'rpmfusion-free-updates': Cannot prepare internal mirrorlist: file "repomd.xml" was not found in metalink

The solution is to install the RPMFusion repository for fedora 30 on top of the fedora 30 ostree branch, and then have rpm-ostree will layer correctly the packages on top of that.

`rpm-ostree status` shows for me:

    ● ostree://fedora-workstation:fedora/29/x86_64/silverblue
                   Version: 29.20190331.0 (2019-03-31T01:09:00Z)
                BaseCommit: 6973b513b3475e749d37e9957bd4e38563c92487f501b42c8ce3857fe745fd7c
              GPGSignature: Valid signature by 5A03B4DD8254ECA02FDA1637A20AA56B429476B4
           LayeredPackages: ansible atomic bluecap bwrap-oci claws-mail claws-mail-plugins
                            fedora-toolbox ffmpeg-libs git-gui gitk gnome-tweak-tool
                            gstreamer-plugins-bad hledger htop hugin iotop jq neovim oathtool pass
                            picocom podman-docker rkt smartmontools stow strace sway thunderbird
                            weston zsh
             LocalPackages: rpmfusion-free-release-29-1.noarch

`/etc` is persistent, so you can update the rpmfusion repository information to get the fedora 30 version. Modify `/etc/yum.repos.d/rpmfusion*.repo` files to reference fedora 30 instead of fedora 29.

First, remove the locally installed `rpmfusion-free-release-29-1.noarch` package that contains the dnf repository for rpmfusion:

    rpm-ostree uninstall rpmfusion-free-release-29-1.noarch


For that, you need to have executed the `ostree remote gpg-import` command above, then you need to remove the rpmfusion repository

    sudo rpm-ostree rebase --cache-only fedora-workstation:fedora/30/x86_64/silverblue
