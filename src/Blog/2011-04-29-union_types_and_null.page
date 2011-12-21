---
title:      Union types and null
created_at: 2011-04-29 09:56:47 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - comp
  - dev
  - lisaac
  - lysaac
---

Look at this:

`object.li`

    Section Header
    
      + name := Singleton NULL;
      
    Section Public
    
      - is_null :BOOLEAN <- FALSE;

`null.li`

    Section Header
    
      + name := Singleton NULL;
      
    Section Inherit
    
      - parent :OBJECT := OBJECT;
    
    Section Public
    
      - is_null :BOOLEAN <- TRUE;

`union.li`

    Section Header
    
      + name := UNION;
      
    Section Inherit
    
      - parent :OBJECT := OBJECT;

`union.1.li`

    Section Header
    
      + name := Expanded UNION(E);
      
      - import := E;
      
    Section Inherit
    
      - parent :UNION := UNION;
    
    Section Public
    
      + element:E;
      - set_element e:E <- (element := e;);

      - when o:T do blc:{o:T;} <-
      (
        (o = E).if {
          blc.value element;
        };
      );
      
      - from_e e:E :SELF <-
      ( + res :SELF;
        res := clone;
        res.set_element e;
        res
      );

`union.2.li`

    Section Header
    
      + name := Expanded UNION(E, F...);
      
    Section Inherit
    
      + parent_e :UNION(E);
      + parent_next :UNION(F...);

    Section Public

      - when o:T do blc:{o:T;} <-
      (
        (o = E).if {
          parent_e.when o do blc;
        } else {
          parent_next.when o do blc;
        };
      );
      
`use.li`

    Section Header
    
      + name := USE;
      
    Section Public
    
      - accept_object_or_null obj:UNION(USE,NULL) <-
      (
        obj
        .when NULL do { o:NULL;
          ? { o.is_null };
        }
        .when USE do { o:USE;
          ? { o.is_null.not };
        };
      );

