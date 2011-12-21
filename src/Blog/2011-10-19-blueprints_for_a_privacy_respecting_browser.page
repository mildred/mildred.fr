---
title:      "Blueprints for a Privacy Respecting Browser"
created_at: 2011-10-19 10:21:14 +02:00
excerpt:
author:     Mildred Ki'Lya
kind:       article
publish:    true
tags:
  - comp
  - dev
  - en
  - web
  - privacy
---

What is this all about: web privacy. We are tracked everywhere, and i'd like to
help if possible. So, let's design a web browser that for once respects your
privacy.

Main features:

 -  Each website has its own cookie jar, its own cache and its own HTML5 local
    storage
 -  History related css attributes are disabled
 -  External plugins are only enabled on demand
 -  Support for Tor/I2P is enabled by default
 -  You have complete control over who receives what information
 -  Let's you control in the settings if you want to allow referrers or not.
 -  The contextual menu let's you open links anonymously (no referrer, anonymous
    session)

The browser is bundled with a particular UI that let you control everything
during your browsing session. it is non intrusive and makes the best choice by
default. I am thinking of a notification bar that shows at the bottom. I noticed
that this place is not intrusive when I realized that the search bar in Firefox
was most of the time open, even if most of the time I didn't use it.

First, let's define a session:

 -  A session can be used my more than one domain at the same time.
 -  A session is associated to a specific cache storage
 -  A session is associated to a specific HTML5 storage
 -  A session is associated to a specific cookie jar
 -  A session acn be closed. When it is closed, session cookies are deleted from
    the session
 -  A session can be reopened. All long lasting cookies, cache, HTML5 storage
    and such is then used again.
 -  A session can be anonymous. In such a case, the session is deleted
    completely when it is closed.
 -  A session is associated to none, one or more domains. These domains are the
    domains the end user can see in the address bar, not the sub items in the
    page.

Sessions are like Firefox profiles. If you iopen a new session, it's like you
opened a new Firefox profile you just created. Because people will never create
a different Firefox profile for each site.

If we want to protect privacy, when a link is opened, a new session should be
created each time. To make it usable to browse web sites, it is made possible to
share sessions in specific cases. Let's define the cases where it might be
intelligent to share a profile:

 -  You click a link or submit a form and expect to still be logged-in in the
    site you are viewing. You don't care if you follow a link to an external
    page.
    
    User Interface: If the link matches one of the domains of the session, then
    keep the session. No UI. If the user wanted a new session, the "Open
    anonymously" entry in the context menu exists. A button on the toolbar might
    be available to enter a state where we always want to open links
    anonymously.
    
    If the link points to another domain, then open the link in a new session
    unless "Open in the same session" was specified in the context menu. The UI
    contains:
    
        We Protected your privacy by separating <domain of the new site> from
        the site you were visiting previously (<domain of the previous site>).
        
        Choices: [ (1) Create a new anonymous session          | ▼ ]
                 | (2) Continue session from <previous domain> |
                 | (3) Use a previous session for <new domain> |
                 | (4) Use session from bookmark "<name>"      |
    
    The first choice is considered the default and the page is loaded with it.
    If the user chooses a new option, then the page is reloaded.
    
    If the user chooses (2), the page is reloaded with the previous session and
    the user will be asked if "Do you want <old domain> and <new domain> to have
    access to the same private information about you?". Answers are Yes, No and
    Always. If the answer is Always, then in the configuration, the two domains
    are considered one and the same.
    
    The choice (3) will use the most recent session for the new domain. It might
    be a session currently in use or a session in the history.
    
    There are as many (4) options as there are bookmarks for the new domain. If
    different bookmarks share a single session, only one bookmark is shown. This
    choice will load the session from the bookmark.
    
    If (3) and (4) are the same sessions, and there is only one bookmark (4),
    then the (4) option is left out.

 -  You use a bookmark and expect to continue the session you had for this
    bookmark (webmails)
    
    The session is simpely stored in the bookmark. When saving a bookmark, there
    is an option to store the session with it or not.
    
        [X] Do not save any personal information with this bookmark

 -  You open a new URL and you might want reuse a session that was opened for
    this URL.
    
    The User Interface allows you to restore the session:
    
        We protected your privacy by not sending any personal information to
        <domain>. If you want <domain> to receive private information, please
        select:
        
        Choices: [ Do not send private information     | ▼ ]
                 | Use a previous session for <domain> |
                 | Use session from bookmark "<name>"  |

If you can see other use cases, please comment on that.

From these use cases, I can infer three kind of sessions:

 -  Live sessions, currently in use
 -  Saved sessions, associated to a bookmark
 -  Closed sessions in the past, accessible using history. Collected after a too
    long time.

Now, how to implement that? I was thinking of QtWebKit as I already worked with
Qt and it's easy to work with.

 -  We have a main widget: `QWebView`. We want to change the session when a new
    page is loaded. So we hook up with the signal `loadStarted`.
 -  We prevent history related CSS rules by implementing `QWebHistoryInterface`,
    more specifically, we store the history necessary to implement
    `QWebHistoryInterface` in the session.
 -  We change the cache by implementing `QAbstractNetworkCache` and setting it
    using `view->page()->networkAccessManager()->setCache(...)`
 -  We change the cookie jar by implementing `QNetworkCookieJar` and setting it
    using `view->page()->networkAccessManager()->setCookieJar(...)`
 -  Change the local storage path using a directory dedicated for the session
    and using `view->page()->settings()->setLocalStoragePath(QString)`

After all that, we'll have to inspect the resulting browser to determine if
there are still areas where we fail at protecting privacy.
