--- 
title:      How I Would Want BLOCKs in Lisaac
created_at: 2011-01-26 22:22:12.631849 +01:00
excerpt:
kind:       article
publish:    true
tags:
  - en
  - comp
  - lisaac
--- 

Remind me to post about this again ...

Syntax:

    BLOCK_PROTO{IN,IN;OUT,OUT}

BLOCK_PROTO.li

    Section Header

      + name := BLOCK_PROTO;

      - how_to_allocate <- clone;

    Section Public

      // Notice there is no + slots as these are generated by the compiler and
      // accessed through internals.

      - parameter i:INTEGER :E <- Internal;

      - upvalues :UPVALUES <- Internal;

      - ptr :POINTER <- Internal;

UPVALUES.li contains the upvalues variables that might be shared by several
BLOCKs.

Blocks needs to be objects in the heap to make it possible to pass them around.
Upvalues also needs to be on the heap.
