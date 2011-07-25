---
title:      Lysaac annotations
created_at: 2011-04-29 09:40:10 +02:00
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

Because I'm using an open world assumption, I need the compiler to generate
annotations on units it compiles, so when it sees them again, it knows what it
does (or does not) internally.

I was looking at [a LLVM video][video] this morning (VMKit precisely) and the
person talked about an interesting optimization. What if we could allocate
objects in stack instead of the heap. This would save time when creating the
object. Then we wouldn't be tempted to avoid creating new objects for fear of
memory leaks (there is not garbage collector in lisaac currently) and
performance penalty.

This is the same thing as aliased variables in Ada.

An object can be allocated on the stack if:

  - it is not returned by the function.
  - it is not stored on the heap by the function.
  - it is not used in a called function that would store a pointer to this
    object on the heap.

So, when the compiler compiles a cluster, it has to generate an annotation file
containing for each argument in each code slot whether the argument is
guaranteed to remain on the stack or if it might be stored on the heap. If an
argument is guaranteed to stay on the stack, we can allocate it on the stack.
When the function will return, the only instances would be located in the
current stack frame.

[video]: http://www.youtube.com/watch?v=ryfw9_-Hnb0
