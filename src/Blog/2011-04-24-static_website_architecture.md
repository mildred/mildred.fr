---
title:      Static website architecture
created_at: 2011-04-24 21:13:46 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - en
  - website
---

This website is made of static pages. I see two good reasons for that: first,
there is no need to recompute endlessly the same information. Then, with static
pages, you can leave your web site online forever without having it defaced.

So, how to create a modern web site with that? First, I have to start with what
I want:

  - A blog, with the recent posts on the front page
  - An atom feed with the recent posts as well
  - Older posts on other pages
  - Each posts categorized in tags
  - Each tag having a page with posts in it
  - The tags pages must have atom feeds as well
  - And tag pages must be splitted in pages
  - Posts can have comments, anyone can add a comment

This can be achieved using an off-line compiler that creates a hierarchy of HTML
files. Many of these compilers exists, I choose [nanoc](http://nanoc.stoneship.org),
but I had to customize it, mostly using [nanoc3_blog](http://github.com/mgutz/nanoc3_blog).

Some features can be easily provided:

  - The atom feed can be created using a helper included in nanoc
  - The tags can be easily crafted using page attributes.
  - Tag pages can be created on the fly using a hand-made helper
  - Pagination can be done the same way

Now, a word about design:

**Pagination,** this is frowned upon by the nanoc author as demonstrated on the
[guide](http://nanoc.stoneship.org/docs/6-guides/#paginating-articles):

> First, a word of caution: I am not a fan of paginating items. Even though
> pagination is fairly easy to do in nanoc, I recommend not doing it, for one
> specific reason. Every time an object is added to a paginated collection, one
> object shifts from one page to the next. When a paginated page is bookmarked,
> it may show entirely different content a month later, and when a paginated
> page turns up as a result on a search engine, it may no longer contain the
> content that the person was looking for anymore. To avoid these issues, I
> recommend creating separate pages for each category, tag or year. Having said
> all this, I’ll nonetheless show you how to do pagination in nanoc, so you can
> get an idea of how it can be done.

In order to avoid having the object shifting pages, the most simple solution is
to have the pages remain static. Say you want to have 10 items per page, the
first page starts empty until it has 10 items. When an 11th item is added, a
second page is created with one element. For blogs, it might seem to be in
reverse order, but for archives, this is not a bad solution.

The pagination system must be uniform and available for any page on the website.
This way, the index page and tag page can have the same pagination system. The
pagination system must also support creating atom feeds. This way, we can have
a feed for the whole blog and a feed per tag. In nanoc, this can be done using
alternative representations for an item.

**Comments,** can be done using JavaScript. For a first solution, this is
acceptable, even though having a solution working with user agents without
javascript is a goal. For this, we can use jQuery and XmlHttpRequest. Because
the server only provides static pages, XmlHttpRequest, having a same-origin
policy, will refuse to work. There are several solutions:

  - Proxy the foreign resource on the local server. This unfortunately requires
    `mod_proxy` which is not available on my server.
  - Another solution is to use [Cross Origin Resource Sharing][cors], a W3C
    recommendation that is still a draft unfortunately, but is started to be
    implemented.
  - Or to use an iframe with a page of the foreign server, and use the
    postMessage method to communicate with it, for example with the
    [easyXDM][easyxdm] library.
  - Or use HTML `<form>` element to post the comment on the the API server. The
    server would then include the comment on the static page and publish it.
    This unfortunately requires a server with more than a simple php scripting
    ability. I don't have this.

For now, I am using the XmlHttpRequest solution with the CORS mechanism on the
API server to allow communication. Here is where I'd like to move:

  - First, integrate [easyXDM][easyxdm] for wider browser compatibility, at the
    cost of the design.
  - Then, use a variation of the static HTML form.

For the static form, here is what i'm thinking of:

  - First, the client can POST the form on the PAI server. If XmlHttpRequest
    with CORS is available, this can be done using Ajax, else we have to deal
    with a page reload.
  - The server would store this message on the database with a unique UUID.
  - Other clients can access this message accessing the API server as usual.
  - Frequently, on my computer, I would dump the messages on the API server
    database and put them in a local yaml file. Comments i'd like to remove can
    then be removed here.
  - When the site is regenerated, a nanoc helper would read this yaml file and
    put comments statically in the page. The page would then be published and
    comments would be available to users without javascript.
  - The script that fetches comments would ignore received comments that are
    already present statically on the page, based on the UUID.

This way, comments would be available for everyone.

  
[cors]: http://www.w3.org/TR/cors/
[easyxdm]: https://github.com/oyvindkinsey/easyXDM/
