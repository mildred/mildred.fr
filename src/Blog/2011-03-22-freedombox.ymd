--- 
title:      Freedombox
created_at: 2011-03-22 09:26:44.986870 +01:00
excerpt:
kind:       article
publish:    true
tags:
  - en
  - comp
  - freedombox
--- 

Yesterday, I realized that we all needed to protect our privacy and that we
might be facing something more than just ads. The solution, fortunately it was started: [Freedombox](http://www.freedomboxfoundation.org/)

There is a specific part I want to cover: protected communication channels.
Starting with E-Mails.

In the E-Mail world, GMail is the best, in my opinion, except that it is hoisted
on Google servers. How about having a private GMail on your freedombox ? What
are the use cases:

 *  We need to know which server sent the E-mail or tell the user if we can't
    know. Solutions exists like [DKIM](http://en.wikipedia.org/wiki/DomainKeys_Identified_Mail),
    [DomainKeys](http://en.wikipedia.org/wiki/DomainKeys) or [SPF](http://en.wikipedia.org/wiki/Sender_Policy_Framework).
    The solution liew with all of thesesolution, not merely just one.

    What we should see is before the E-mail a little line telling something
    like:

     -  We could not determine which server sent the E-Mail, it might be spam or
        scam.

     -  We could not determine which server sent the E-Mail, it appears to come
        from google.com but google.com generally signs outgoing E-mails. This is
        probably spam or scam.

     -  The E-Mail was sent from google.com

     -  The E-Mail was sent from toto31.freedombox.net and has been signed by
        sender@toto31.freedombox.net.

     -  The E-Mail was sent from toto31.freedombox.net and has been encrypted by
        sender@toto31.freedombox.net.

Now, the freedombox provides many services. For example we need to have a PGP
Key server. How do we advertise that? DNS was made for that. I was thinking
specifically about [Avahi](http://avahi.org/), providing Multicast-DNS on the
local network. I think we need to either transform Avahi into a full DNS server
that could run on the Freedombox or have it publish records in an existing DNS
server on the box. Why? Because services are already used to publish DNS records
using Avahi.

We also need to have a network of Freedombox to add redundancy to our DNS
servers. That could be implemented as a second part.
It would also be good if we could have a domain like freedombox.net where all
freedombox could have a free subdomain for free. Domain names are a necessity.

Now, what I want to do is simple:

 -  Buy a plug computer and install Freedombox on it
 -  Work on integrating a SMTP server that would
     -  send signed E-Mails
     -  receive E-Mails and filter them
 -  Integrate an IMAP server
 -  Integrate a PGP Key server
 -  Work on integration with DNS
 -  Work on a client that would sign e-mails, send them and open the inbox on
    IMAP

Now, it would be freat to have in all modern browsers a `dns:` scheme which
would present all the services of a specific server. For example it could tell
you:

 -  This server provides a web server. *Browse*
 -  This server provides a LDAP address book. *Browse* *Search*
 -  This server provides an XMPP server. *Sign-In*
 -  This server provides a SMTP server. *Send E-Mail*

This would be awesome.
