---
title:      "HMP: HTTP Message Protocol (0.1)"
created_at: 2011-05-09 14:40:00 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - comp
  - en
  - dev
---

FAQ
---

  * **What is HMP:** It is a messaging protocol destined to replace e-mails.

  * **Why replace e-mails:** Because it is full of spam and unmaintainable. This
    alternative is lighter and easier to implement than a full SMTP server with
    SPAM management.

  * **Why use HTTP:** I'm not fan of putting everything over HTTP but it has its
    advantages:
    
      - It has a security layer (HTTPS)
      - It is (relatively) simple and implemented everywhere
      - It manages content-types and different types of requests
      - It is extensible
      - It goes easily through proxys and NATs
      - It allows multiplexing many different resources on the same server
      
    In the long run, perhaps we should move away from HTTP as:
    
      - It is too associated with the web
      - It doesn't allow initiative from the server.

    WebSockets could be a good alternative one day.

  * **How do I get my messages:** Not specified, although you could possibly
    authenticate using a standard HTTP method to the same resource as your
    address and issue a GET command.
    
  * **Does this allows a web implementation:** Yes, it will need to be further
    specified but if the server detects a browser request (without the HMP
    headers) on the resource, it could issue a web-page with a form.
    
  * **Is the message format specified**: no, it needs to be. I plan on using
    JSON.

  * **Do you plan an implementation:** Yes, using probably node.js or Lua.
  
  * **What prompted this:** The Tor network doesn't have any standard messaging
    system. I don't believe SMTP is suited for that.
    
  * **Why write this spec, you have no code to back this up:** because I like
    writing specs, and it's a way for me to remind me to write the code, and to
    tell me how I should write it. I might not get the time to write this as
    soon as I want.

What is a hmp address
---------------------

Scheme:

    [hmp:]server[:port][/path]

Example:

    hmp:gmail.com:80/user
    gmail.com:80/user
    gmail.com/user

    domain.org/u/alicia

Translation to HTTPS resources
------------------------------

A HMP address can directly be translated to an HTTPS resource. The standard
scheme translates to:

    https://server:port/path

Message sending overview
------------------------

To send a message from `domain.org/alicia` to `users.net/~bob`, the sequence is:

  - Connection to users.net:

        [1] POST https://users.net/~bob
        [1] HMP-Pingback: 235
        [1] HMP-From: domain.org/alicia
        [1] Content: message-content

  - users.net opens a connection to domain.org

        [2] GET https://domain.org/alicia
        [2] HMP-Pingback: 235
        [2] HMP-Method: MD5

  - domain.org responds to users.net

        [2] HMP-Hash: ef0167eca19bb2d4c8dfe4c3803cc204
        [2] Status: 200

  - users.net responds to the original sender
  
        [1] Status: 200

Headers to the POST request
---------------------------

The POST request is the request used to post a message. It contains two specific
headers:

  - HMP-From: The address the message is sent from

  - HMP-Pingback: A sequence number that uniquely identifies the message for the
    sender. it needs not be unique, as long as at ont point in time, there are
    only one message corresponding to this ID.

Particular status codes:

  - 200 in case of success
  
  - 403 in case the From address could not be authenticated


From address authentication, pingpack
-------------------------------------

In order to avoid SPAM, the sender must be authenticated when the message is
sent. For this reason, before accepting or rejecting the request, the server
must initiate a pingback procedure to the sender.

First, the From address is converted to an HTTPS resource and a GET connection
is initiated. The specific request-headers are:

  - HMP-Pingback: the pingback sequence number from the previous request

  - HMP-Method: method for verifying the originating message. The only specified
    method is "MD5"

### MD5 Method ###

In case the message is recognized, the from server responds with the following
header:

  - HMP-Hash: MD5 hash of the content of the message identified by the pingback
    identifier

The status code can be:

  - 200 in case the message was recognized

  - 404 in case the message was not found

If the MD5 sum corresponds to the message received and a success code was given,
the from is verified and the message can be sent.