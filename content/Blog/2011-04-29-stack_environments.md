---
title:      Stack environments
created_at: 2011-04-29 09:52:05 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - en
  - comp
  - dev
  - lisaac
  - lysaac
---

Stack environment would be an argument passed implicitely to every function in
the code. It would contain global policy. In particular the `MEMORY` object that
lets you allocate memory. If you want to change the allocation policy, you just
have to change the current environment, and all functions you call will use the
new policy.

We could allow user defined objects like that, not just system objects.

We could also manage errors that way. An error flag could be stored in the
environment. Set by the calee and tested by the caller.

