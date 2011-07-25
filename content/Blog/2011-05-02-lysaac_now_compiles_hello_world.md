---
title:      Lysaac now compiles Hello World!
created_at: 2011-05-02 12:04:17 +02:00
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

This is great: Here is the source files:

`c/cstring.li`
    
    Section Header
    
      + name := Reference CSTRING;
      
      - role := String; // const char*
      - type := Integer 8;
      
`c/main.li`

    Section Header
    
      + name := MAIN;
    
    Section Public
    
      - puts str:CSTRING <- External `puts`;
    
      - main <-
      (
        puts "Hello World";
      );

You type `lysaac compile c >c.bc` and you get the following LLVM assembly code:

`c.bc`

    @0 = private constant [12 x i8] c"Hello World\00"
    
    
    declare void @puts (i8*)
    
    define void @main () {
      %1 = getelementptr [12 x i8]* @0, i32 0, i32 0
      tail call void @puts(i8* %1)
      ret void
    }

And you can execute it using the standard LLVM tools:

    $ llvm-as < c.bc | lli
    Hello World
    $

Isn't that great ?

