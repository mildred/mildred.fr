---
title: "Upgrade Fedora Silverblue 31 when you have rpmfusion packages"
date: 2019-11-27
draft: false
---

Like last time, here is how I performed my system upgrade. having rpmfusion
packages can block your upgrade with the following error message:

    # ostree remote gpg-import fedora -k /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-31-primary
    # rpm-ostree rebase fedora:fedora/31/x86_64/silverblue
    ...
    error: N’a pas pu depsolve la transaction; 2 problèmes détectés:
     Probléme 1: package rpmfusion-free-release-30-0.3.noarch requires system-release(30), but none of the providers can be installed
      - package generic-release-30-0.3.noarch requires generic-release-common = 30-0.3, but none of the providers can be installed
      - conflicting requests
      - nothing provides fedora-repos(30) needed by generic-release-common-30-0.3.noarch
     Probléme 2: package rpmfusion-nonfree-release-30-0.3.noarch requires system-release(30), but none of the providers can be installed
      - package generic-release-30-0.3.noarch requires generic-release-common = 30-0.3, but none of the providers can be installed
      - conflicting requests
      - nothing provides fedora-repos(30) needed by generic-release-common-30-0.3.noarch


Before you continue, you'll have to upgrade the rpmfusion repos... To prevent
unneeded reboot, you can do it manually:

    # sed -i.backup 's/\$releasever/31/g' /etc/yum.repos.d/rpmfusion*.repo

Then, upgrade:

    # wget https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-31.noarch.rpm
    # wget https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-31.noarch.rpm
    # rpm-ostree rebase fedora:fedora/31/x86_64/silverblue --uninstall atomic --uninstall rpmfusion-free-release-30-0.3.noarch --uninstall rpmfusion-nonfree-release-30-0.3.noarch --install rpmfusion-free-release-31.noarch.rpm --install rpmfusion-nonfree-release-31.noarch.rpm

I had to specify to remove atomic, which is a tool for deprecated Fedora Atomic
which I had installed and is no longer there.

After that, it should have worked, just reboot to Fedora 31.

Last thing, revert back the rpmfusion repo files modified above:

    # for f in /etc/yum.repos.d/rpmfusion-*.repo.backup; do echo mv $f ${f%.backup}; done

