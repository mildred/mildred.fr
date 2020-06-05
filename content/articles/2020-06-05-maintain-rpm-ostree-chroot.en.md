---
title: "Maintain a rpm-ostree chroot"
date: 2020-06-05
draft: false
---

After having used containers for quite some time, I'm getting away from them
because they require an infrastructure quite complex to get a system running and
up to date. The ideal infrastructure should only depend on a few and controlled
upstreams, possibly mirrored on site to get it working offline, and the Docker
containers is the absolute opposite of that.

As a consequence, I am looking up at alternatives that uses traditional
distributiuon packages to work, and manual sandboxing with systemd directives or
small other tools to do the job.

The subject of this article is to learn how to maintain a chroot distribution,
and to do that I'll using `rpm-ostree` on top of a Fedora Silverblue
distribution. I'd gladly use Fedora CoreOS but their twaks in the base system
prevent package layerting to work properly (such as using `systemd-networkd` on
a server setup instead of `NetworkManager`). Also, for now this is still an
experiment that I'll run on my Silverblue laptop, so I can iron out the rough
edges without crashing my server.

I'll expand upon my previous article: [systemd-nspawn and
OSTree](/en/articles/2019-07-15-systemd-nspawn-and-ostree/)

Create an OS
------------

Just like previously, run `rpm-ostree status` to get your OSTree base commit and
initialize a new OS:

    ostree admin os-init guest
    ostree admin deploy --retain --not-as-default --os=guest fedora:fedora/32/x86_64/silverblue

(your ostree remote should be named `fedora`)

You should have an OS deployed in `/ostree/deploy/guest/deploy/*/`

First method to install layered packages and update the system
--------------------------------------------------------------

Now comes `rpm-ostree` and to layer new packages on top of this guest OS, run:

    rpm-ostree install --os=guest postfix

However, there is a drawback, on next reboot the guest will boot instead of the
host. You can workaround this by updating the deployment number (unlikely to
work):

    rpm-ostree kargs --os=guest --deploy-index=3
    rpm-ostree kargs --deploy-index=0

Second method: hack around ostree staged deployments
----------------------------------------------------

On OSTree, deployment can happen in two ways: direct deployment or staged
deployment. Staged deployment are deployments written to `/ostree` but not yet
written to the boot loader. It can be triggered using `ostree admin` `--staged`
option, and it is the default with rpm-ostree when running in an OSTree host.

The good news is that we need to avoid writing to the boot loader only if
running an OSTree system, so we can rely on the default from `rpm-ostree`.

The trick is that before updating the guest OSTree and deploying it, we save the
pending deployments (if there is any) so the host system will deploy as usual.
We perform the rpm-ostree operation. Then we restore the pending deployment from
the host and trash the pending deployment from the guest.

The drawback is that the deployment from the guest might be garbage collected.
The solution might be to pin the deployment. Except pinning works only for
deployments registered in the boot loader.

If there is already a staged deployment:

    mv /run/ostree/staged-deployment /run/ostree/staged-deployment.old
    rpm-ostree install --os=guest postfix
    mv /run/ostree/staged-deployment.old /run/ostree/staged-deployment

else:

    rpm-ostree install --os=guest postfix
    rm -f /run/ostree/staged-deployment

You could even use `ostree admin deploy --stage` in the first command above to
ensure that there is never any boot loader entry for your host, but you risk
getting your deployments pruned.

You can pin your deployment but `ostree admin pin` does work only for deployment
in the boot loader. You can manually add the pin to your deployment by modifying
the deployment file:

    DEPLOYMENT_NAME=$(tr '\0' '\n' </run/ostree/staged-deployment | sed -e '/./p; d' | sed -ne '/name/,/osname/ p' | sed -ne '2 p')
    cat >>/ostree/deploy/guest/deploy/$DEPLOYMENT_NAME.origin <<EOF
    [libostree-transient]
    pinned=true
    EOF

Not sure that can work though, as the deployment mignt not be even considered
pinned as it is not in the boot loader.

<!--
Note to the future: maybe `- -peer` runs the rpm-ostree code outside of the
daemon, and `systemd-run -p TemporaryFileSystem=/run/ostree` can be used to call
rpm-ostree isolated.
-->

Here is a wrapper that calls rpm-ostree, unstage the resulting deployment, and
pin it (it only works if the daemon uses the same mount namespace as the client,
you can use `--peer` for that):

    #!/bin/bash

    unwrap(){
      DEPLOYMENT_NAME=$(tr '\0' '\n' </run/ostree/staged-deployment | sed -e '/./p; d' | sed -ne '/name/,/osname/ p' | sed -ne '2 p')
      cat >>/ostree/deploy/guest/deploy/$DEPLOYMENT_NAME.origin <<EOF

    [libostree-transient]
    pinned=true
    EOF
    }

    if [[ $0 == wrapped-rpm-ostree ]]; then
      shift
      rpm-ostree "$@"
      res=$?
      unwrap
      exit $res
    fi

    systemd-run -t -p TemporaryFileSystem=/run/ostree "$0" wrapped-rpm-ostree "$@"


Alternate option to update the system: use `rpm-ostree compose`
---------------------------------------------------------------

This second method is the blessed way to work on OSTree commits without
deploying them. It can be used on a server to build a tree for clients to pull.
So the compose is done once on a central location.

This is however more complex and you need to write a treefile.
