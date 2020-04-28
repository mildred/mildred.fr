---
title: "Upgrade Fedora Silverblue 32 when you have rpmfusion packages"
date: 2020-04-27
draft: false
---

As with [previous article](/quick-posts/2019-11-27-upgrade-to-fedora-silverblue-31-with-rpmfusion-repos/), here is the procedure to upgrade to Fedora 32 if you have RPMFusion installed (same procedure):

1.  Check the repository for Fedora 32 is there:

        sudo ostree remote refs fedora

2. Download rpmfusion repositories:

        wget https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-branched.noarch.rpm
        wget https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-branched.noarch.rpm

    (you can omit nonfree)

3. Update .repo files to next fedora version:

        sudo sed -i.backup 's/\$releasever/32/g' /etc/yum.repos.d/rpmfusion*.repo

4. Start rebasing replacing rpmfusion packages. Here I also removed old packages
   I don't use any more and installed `docker-compose`.

        sudo rpm-ostree rebase fedora:fedora/32/x86_64/silverblue --install docker-compose

   I also removed git related packages because it caused an error like ``

        Forbidden base package replacements:
          git-core 2.26.0-1.fc32 -> 2.26.2-1.fc32 (updates)
        This likely means that some of your layered packages have requirements on newer or older versions of some base packages. Doing `rpm-ostree cleanup -m` and `rpm-ostree upgrade` first may help. For more details, see: https://github.com/projectatomic/rpm-osResolving dependencies... done
        error: Some base packages would be replaced

5. Restore repo files from backup:

    sudo sh -c 'for f in /etc/yum.repos.d/rpmfusion-*.repo.backup; do mv $f ${f%.backup}; done'

