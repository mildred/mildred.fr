---
title:      Lysaac and clusters
created_at: 2011-04-12 16:35:44 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - comp
  - dev
  - lisaac
  - lysaac
  - en
---

If you noticed, I started my own Lisaac compiler, called [Lysaac][1] and I want
to make it a little bit different from Lisaac. I'll try to keep compatibility, 
but for few things, I might take a different direction.

One of these things is the way prototypes are found.

In Lisaac, you have a complete set of prototypes and when you look for a
prototype, it is looked everywhere. This is not desirable. Imagine you are
writing a library that requires the prototype `FOO`. Currently, if `FOO` is not
present in the library, instead of issuing an error, the compiler would take the
`FOO` prototype in the application that use the library. Meaning that the
library is effectvely using a pieve of the application code.

I want to take the SmartEiffel approach and separate the source code in few
clusters. A cluster is a collection of prototypes. And the prototypes in a
cluster can only use the prototype of the same cluster or the prototypes of
imported clusters. This solve the above dependancy problem.

A cluster is a directory that contain prototypes in `.li` files and
subdirectories. If a subdirectory do not contain `.li` files, the
sub-subdirectories are not recursively searched. A cluster can import another
cluster using a cluster file ending with `.cli`.

An example of `.cli` file is as follows:

    Section Header
    
      - name := Cluster LIBFOO;
      
      - path := ("libfoo-3.14", "../libfoo");

The search paths can be:

  - relative to the `.cli` file if it starts with `.`
  - relative to `LYSAAC_PATH` directories otherwise

`LISAAC_PATH` defaults to `$XDG_DATA_HOME/lysaac/lib:/usr/local/share/lysaac/lib:/usr/share/lysaac/lib`.

The search paths would then be for this example:

  - `$XDG_DATA_HOME/lysaac/lib/libfoo-3.14`
  - `/usr/local/share/lysaac/lib/libfoo-3.14`
  - `/usr/share/lysaac/lib/libfoo-3.14`
  - `../libfoo`

The parser for these files is being written. Then you can see the complete
hierarchy of the project:

    $ lysaac src
    ◆ Root Cluster
    │ Cluster in: src
    ├─◆ LIB (src/lib.cli)
    │ │ Cluster in: lib
    │ ├─◆ STDLIB (lib/stdlib.cli)
    │ │ │ Cluster in: /home/mildred/.local/share/lysaac/lib/stdlib
    │ │ ├─◇ STRING (...)
    │ │ ├─◇ ABSTRACT_STRING (...)
    │ │ ╰─◇ ...
    │ ├─◇ LIBC (lib/libc.li)
    │ ╰─◇ CSTRING (lib/cstring.li)
    ├─◇ PARSER (src/parser.li)
    ├─◇ CLUSTER_ITEM (src/cluster_item.li)
    ├─◇ ITM_STYLE (src/itm_style.li)
    ├─◇ LYSAAC (src/lysaac.li)
    ├─◇ ITM_AFFECT (src/itm_affect.li)
    ├─◇ ANY (src/any.li)
    ├─◇ PARSER_CLI (src/parser_cli.li)
    ╰─◇ CLUSTER (src/cluster.li)

Now, each item in a cluster can be public or private. Public items are available
to the users of the clusters whereas private items are restricted to members of
the same cluster. To declare a private item, just say:

    Section Header
    
      + name := Private PROTOTYPE;

or

    Section Header
      
      - name := Private Cluster LIBTOTO;

If you want to declare a whole bunch of prototypes private to your cluster, just
include them in a private cluster. To do so, you'll need the following files:

  - cluster/my_private_prototypes.cli:
    
        Section Header
        
          - name := Private Cluster MY_PRIVATE_PROTOTYPES;
          
          - path := "./deps/my_private_prototypes";
          // makes the cluster relative to the .cli file
          // use a deps additional directory to avoid the current cluster to
          // look into deps/my_private_prototypes. deps should not contain any
          // files, just subdirectories.
  
  - cluster/deps/my_private_prototypes/private_proto.li:
    
        Section Header
        
          + name := Public Prototype PRIVATE_PROTO;



[1]: http://github.com/mildred/lysaac

