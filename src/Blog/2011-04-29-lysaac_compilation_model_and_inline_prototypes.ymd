---
title:      Lysaac compilation model and inline prototypes
created_at: 2011-04-29 09:19:04 +02:00
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

In Lysaac, I choose to follow the open world assumption, like the majority of
programming languages out there, instead of the closed world assumption. There
are two main reasons:

  - First, I don't strive at creating an optimizing compiler, not yet at least.
    Closed world is useful for that, but I don't need it.
    
  - Second, open world assumption increases the complexity a lot. The Lisaac
    compiler uses an exponential algorithm, and will always hit a limit with
    big projects. With an open world, you can partition the complexity.

Because I still believe in global compilation, I decided that my compilation
unit would be the cluster instead of the prototype. That is, I'll compile a
cluster completely in one object file. That makes it possible to optimize things
like private prototypes.

This leaves a big performance problem for `BOOLEAN`s in particular. `BOOLEAN`,
`TRUE` and `FALSE` are prototypes in the standard library, and having an open
world assumption would require pasing to the `if then` slot function pointers.
I can't realisticly do that.

So, These prototypes could be marked as `Inline`. They are separated from their
cluster and gets compiled in every cluster that uses them. The syntax could be
quite simple:

    Section Header
    
      + name := Inline TRUE;

But, because each cluster is then free to compile it as it wants, there is a
problem of interoperability. How can you be sure that the `TRUE` in your cluster
is compiled the same way as in the neighbooring cluster you are using. As it is,
you can't pass `TRUE` object around clusters. Very annoying.

The solution would be to encode them and decode them manually. You could have:

    Section Header
    
      + name := Inline TRUE;
      
    Section Feature
    
      - inline_size :INTEGER := 0;

Take a more interesting example:

    Section Header
    
      + name := Inline Expanded BIT;
      
      - size := 1;
    
    Section Feature
    
      - inline_size :INTEGER := 1;
      - encode p:POINTER <-
      (
        p.to_native_array_of BIT.put bit to 0;
      );
      - decode p:POINTER <-
      (
        data := p.to_native_array_of BIT.item 0;
      );

This needs to be refined.

Additionally, `.cli` files could also contain the `Inline` keyword. In that
case, the cluster it reference will be compiled with the current cluster. That
could be useful for private clusters.

