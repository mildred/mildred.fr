--- 
title:      Freedombox Connectivity
created_at: 2011-03-23 09:21:20.127362 +01:00
excerpt:
kind:       article
publish:    true
tags:
  - en
  - freedombox
  - comp
--- 

Suppose we want to have an E-Mail server on the freedombox. We need connectivity
for SMTP, the ability to accept inbound connections. Which is impossible behind
a NAT.

For E-Mails we also need a MX record in the DNS ... This is a problem if the
network is completely hostile. In which case, the only solution is to have a
somewhat P2P DNS database shared on freedombox. Access would then not be
possible from the Internet.

Now, more likely, we are only going to have access to a dynamix DNS, which is
fine. The DNS would store records A, AAAA and MX. Perhaps some others. Still, we
need not to rely on them too much and have the ability to communicate from
freedombox to another even if there is no DNS for us.

So ... it comes down to the firewall and NAT restrictions.

I suppose we could:

* First, autoconfigure IPv4 and IPv6

* Try opening NAT ports using UPnP

* Check the IP connectivity. We suppose IPv6 is accessible from the Internet and
  we look to see if the IPv4 is in a range that is routable (not in a private
  non-routable range).

  Additionally, we could ask a service on the Internet to test our connectivity
  if such a service is available. Both for IPv4 and IPv6.

* If we don't have an IPv6 connectivity, open a tunnel to the IPv6 Internet.
  Either Toredo or a manually configured tunnel if available.

* Update our DNS record

So now, we have at least IPv6 available ... and we can at least communicate with
the v6 Internet.
