---
title:      "Bug 660340 - Due to constant threats on privacy, epiphany should allow the user to have multiple separate session running"
created_at: 2011-09-28 10:42:04 +02:00
excerpt:
author:     Mildred
kind:       article
publish:    true
tags:
  - en
  - comp
  - privacy
---

Here is my [Bug 660340](https://bugzilla.gnome.org/show_bug.cgi?id=660340). I
created it after looking at the recent facebook 'enhancements' that makes
privacy even more precious ([article in French](http://linuxfr.org/news/facebook-f8-timeline-musiquevid%C3%A9o-ticker-boutons-et-les-cons%C3%A9quences-pour-le-web)).

We need to quickly find a way to preserve our privacy on the Internet.


Hi,

With the recent threats of the various big internet companies on our privacy,
it would be a great enhancement if epiphany allowed to have separate navigation
contexts (cookies, HTML5 storage, cache) at will, and easily.

Some companies, especially facebook, and I suppose Google could do that as
well, can use all kind of methods to track a user usiquely. using cache, HTML5
storage or cookies. I wonder if they can use the cache as well, but I heard it
could be prevented. Firefox does.

One solution to counter these privacy threats is to have a different browser,
or different browser profile, for each of the web sites we load. This is
however very inconvenient, and it should made easily possible.

First let define the concept of session. A session is almost like a separate
instance of the browser. It share bookmark and preferences with other session,
but have separate cache, separate set of cookies and separate HTML5 DOM
storage.

I imagine the following behaviour, based on the document.domain of the toplevel
document:

 -  If a page is loaded without referrer, and the domain is not associated with
    an existing session, start a new session for that domain

 -  If a page is loaded without referrer, and the domain is a domain that is
    already associated with an existing session, then prompt non intrusively:

        "You already opened a session on example.com."
        Choices: [  Start a new session    ▼ ] [Use this session]
                 [[ New anonymous session   ]]
                 [  Replace existing session ]

    If the session is started anonymously, it would not be considered for reuse

 -  If a page is loaded using a link from an existing window/tab, and the
domain
    is the same, then share the session

 -  If a page is loaded using a link from an existing window/tab, and the
domain
    is NOT the same and, then a non intrusive message is displayed:

        "You are now visiting example2.com. Do you want to continue your session
        from example1.com?"
        Choices: [  Start a new session    ▼ ] [Share previous session]

    The "Start a new session" dropdown menu changes if the example2.com is
    already associated with a session or not. If example2.com is associated
    with a session:

         [[ New anonymous session            ]]
         [  Replace example2.com session      ]
         [  Use existing example2.com session ]

    If example2.com is not associated with a session:

         [[ New anonymous session    ]]
         [  New example2.com session  ]

The choices in [[xxx]] (as opposed to [xxx]) is the most privacy enhancing one,
and would be the default if the user choose in the preferences

    [x] allow me not to be tracked

The messages are non intrusive, they can be displayed as a banner on top of the
page. The page is first loaded with the default choice, and if the user decides
to use the other choice, the page will be reloaded accordingly (or the session
will be reassigned).

This setting can traditionally be used to set the do not track header

Every settings should have a setting "do not prompt me again" that could be
reset at some point.


About embedded content: Because toplevel pages do not share the same session
(toplevel page opened at example.com have a different session than toplevel
page opened at blowmyprivacy.org), if a page from example.com have embedded
content from blowmyprivacy.org, the embedded content would not be able to track
the user, except within the example.com website.


It is possible to imagine global settings that would hide some complexity:

    [ ] When I load a page, always associate it with its existing session.
    [ ] When I switch website, always reuse the existing session of the new
        website.

This user interface might seem complex at first, but it is far less complex
than letting the user deal with different browser profiles by hand.
Unfortunately, I don't think we can abstract privacy that easily. Keep in mind
that all of these settings would be enabled only if the user choose to enable
privacy settings.

I am ready to contribute to the implementation of this highly important feature
(important for our future and our privacy). Do you think an extension might be
able to do all of that, or do you think the browser code should be modified?

Further possible enhancements:

 -  Add another choice for anonymous sessions using Tor (or I2P)

 -  Add the possibility to have multiple session registered with the same
    domain. This would enable the user to have different profiles for the same
    website.
