---
title:      "Migration to Webgen"
created_at: 2012-02-28 11:07:07 +01:00
author:     Mildred Ki'Lya
kind:       article
publish:    true
tags:
  - comp
  - en
  - webgen
  - www

--- name:excerpt

I just moved the site to [webgen](https://github.com/mildred/webgen). For the
occasion, forked the project on github and improved a lot of things. As webgen
doesn't seem to be alive, I think I'll be the one maintaining it in the future.

I took the occasion to move my website over to my own web server, hosted at
home. If I ever find it unsuitable, I can very easily host my website elsewhere
as it is just a bunch of static pages.

More to come ...

--- name:content

Webgen allows me to split a post in two, an excerpt and a content. Perhaps the
name excerpt is ill chosen as currently it seems more like a teaser. Anyway.

I already improved or added the following features in webgen:

- an index content handler type which job is to list other pages' content and
  provide pagination. It also create atom and rss feeds.
- a tag content handler that creates index pages, thus creating pagination and
  feeds for each and every tag.
- ability to include other pages' content directly from within haml or erb.

Next, I'll want to:

- Have a cron job that updates the website automatically, or a git hook doing
  just that.
- Look at what I can do in terms of a gallery.
- Parse e-mails sent to a special mailbox to create blog post from them
  automatically

All of this is released open source.
