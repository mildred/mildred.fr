---
title: "HTTP/HTML subset for respecting privacy"
date: 2015-01-24
---
We can use HTTBy default, HTTP and HTML is not very respecting of our privacy. But, we could make it way better. Let's imagine that out there, there will be some privacy-respecting web servers and browers, how could we do that?

- A privacy respecting browser should follow as much as possible the privacy subset of HTTP/HTML, and warn when websites do not respect this.
- The browser should sandbox web views that are not affiliated. History, cookies, and every setting should not be shared at all.
- The server should use HTTP2 Push to push the assets (including external assets) of a web page served. Any assets that are not part of the push would be considered as not found by the privacy respecting browser.
- The browser will not attempt to fetch any resource that is not part of the HTTP2 Push
- When validating a form, performing a XMLHttpRequest or any network access (html refresh, ...), the browser should tell the user (as all old browsers did) "The website is attempting to send information" with the choice to view the information, allow or deny. The browser must not allow to discard the dialog for future cases.
- The browser should have an API to allow to bundle multiple network requests together so only one dialog is prompted to the user
- HTTP redirects should also push the redirected location, else the page will fail to load
- The browser should use a minimal set of headers while performing the request (no user agent or content negociation)
- Links should not be followed without asking the user for confirmation unless the link href has not been touched by JavaScript. One solution for that is to build a list of all the links at page startup before running any javascript, and see if the link is on the list, later, when following the link. This list could also be sent by the server on HTTP headers or on the `<head>` section.
