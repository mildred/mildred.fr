---
title:      "Tracker: the Desktop Search Engine"
created_at: 2011-10-19 11:30:32 +02:00
excerpt:
author:     Shanti
kind:       article
publish:    false
tags:
  - meta tracker
  - en
  - comp
  - dev
  - work
---

Working for AdaCore, I had to implement a search engine for their internal bug
tracking system. I learned a lot by implementing that and I wanted to share what
I learned with you.

[Tracker](http://projects.gnome.org/tracker/) is a [GNOME](http://gnome.org)
project that aims at having a desktop search engine, like Spotlight for Mac OS
X. You put in some keywords and you get a list of relevant files. No need to
navigate your filesystem to get the last report you created and want to modify.
That's also what is powering the last application in GNOME 3.2:
[Gnome Documents](https://live.gnome.org/GnomeDocuments).

All it does is that it monitors your filesystem for new files, and files you might change. And for every file, it will parse them and extract metadata. Metadata will be collected in one giant database organized using the [Nepomuk ontologies](http://www.semanticdesktop.org/ontologies/). There is a standardised query language at the W3C: [SPARQL](http://www.w3.org/TR/rdf-sparql-query/). It's all tied up with RFD and the semantic web. But instead of having a semantic web, we have a semantic desktop.

The database consist of statements that have three parts:

 -  A subject: generally a unique identifier, UUID. Can be any valid URI
 -  A verb: a property to the object
 -  A complement: a value associated to this property
 
This is all there is. There is a special verb "a" that makes it possible to define the type of the subject. The list of available types is available at Nepomuk and the available properties for an object of a given type is also listed in the Nepomik Ontologies.

We also have punctuation. `.` for the end of a sentance, ',' to have different complements for a same verb (or associate multiple values to the same property) and ';' to use a different verb on the same subject. We could say:

    ?toto a                 nco:Contact, Person ;
          nco:firstName    "Toto" ;
          nco:lastName     "LaTornade" ;
          nco:emailAddress "toto@latornade.name", "toto@comp.com" .

It reads: Toto is a contact and a person, his first name is Toto, his last name
is LaTornade, his e-mail addresses are toto@latornade.name and toto@comp.com.

When you understand that, you're all set. In this database, we have two kind of
actors:

 -  Consumers: these are the application that use this information. It's the
    Documents application, the search engine interface that let you search for
    files, ...

 -  Producers: these are the applications that feed the database. It can be file
    parsers (extractors), processes that monitor your IMAP mailbox, processes
    that monitor Facebook, Google Docs, ... You also have applications that
    requires user input. For example nautilus, the GNOME fila manager, has an
    extension that lets you add tags to your files. These tags are stored in the
    Tracker database.

All I had to do is write a consumer which will be the search interface for the
bug tracker and a producer that enter data into the database. Next post will
talk about this in more details.

