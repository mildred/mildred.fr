--- 
title:      Section Interface
created_at: 2011-02-11 18:54:11.698599 +01:00
excerpt:
kind:       article
publish:    true
tags:
  - en
  - comp
  - lisaac
--- 

I had an idea about inheritance, comming from Eiffel and my today's work in Ada
Object Oriented Programming in embedded software. I am working on a software
that is going to be embedded in an ADIRU (Air Data Inertial Reference Unit) in
the final assembly line (not on air). This software is about implementing a
protocol to let the test operator test the connections in the aircraft.

Embedded software means memory constraints. Basically, that means I can only
allocate new objects when the application is starting up. When the application
is running (with a scheduler), it is no longer possible to create new objects.
This is bad for me because I just want to create different objects at runtime
that have a different behaviour. The objects all have the same size in byte, the
same data. There is just a function that is inherited.

Next, I thought of Eiffel ...

And then about what is inheritance. I can think of two aspects of inheritance:

* Behaviour inheritance: you just want the same behaviour as your parent. This
is the `Section Insert`
* Interface inheritance: you just want the polymorphism

When you think about it, the two aspects complements each other. The traditional
inheritance is just the combinaison of the two. So I thought that could be a
great idea to separate them. Bundeling them together would just help programmers
mistakenly inherit for an object, even if they obly want polymorphism or
behavior inheritance alone.

There is another trap: extend an object that you already inherited. You might
add some features/methods/slots that you don't necessarily want in herited
prototypes. You end up cluttering the inherited objects a lot. So I thought that
a good rule would be to forbid the inheritance from an implementation and force
inheritance from interfaces.

**And, how to do that nicely in Lisaac?**

With the new `Section Interface`

The Section Interface would define an interface for the current prototype. It
would contain slots and their contracts that are going to be inherited. Slots
not defined here will not be available for inheritance. And if there is no
Section Interface, no inheritance will be possible.

In short terms, it means that if you use the Strict version of the prototype (or
if the compiler can infer you are doing so), you can use the slots in the
Section Public. Else, you are limited to the Section Interface.

**Cool things with interfaces**

Just as in eiffel, if you have two slots that conflicts when inherited like in
the following code:

    Section Header

      + name := BAG(T);

    Section Interface

      - count :INTEGER;
      - lower :INTEGER;
      - upper :INTEGER;

      - owner :PERSON;

<!--  -->

    Section Header

      + name := SHOP;

    Section Inherit

      - tomatos :BAG(TOMATOS);
      - eggs    :BAG(EGGS);

    Section Interface

      //
      // You can rename the slots:
      //

      - tomatos_count <- tomatos.count;
      - tomatos_lower <- tomatos.lower;
      - tomatos_upper <- tomatos.upper;

      - eggs_count <- eggs.count;
      - eggs_lower <- eggs.lower;
      - eggs_upper <- eggs.upper;

      //
      // Or reimplement them:
      // (if there is a conflict, it should be present in the interface tell the
      //  compiler that you thought of reimplementing it.)
      //

      - owner :PERSON;

    Section Public

      - owner :PERSON <-
      (
        ? { eggs.person = tomatos.person };
        tomatos.owner
      );

This will tell the compiler that when the SHOP transforms into a BAG(TOMATOS)
through polymorphism, it should use the `tomatos_count` instead of `count`. This
will also tell that the owner of both the tomatos and eggs is the same and
implemented in SHOP.

**How to inherit?**

For behaviour inheritance:

    Section Insert

      - parent1 :Expanded P1;
      - parent2 :P2 := P2;
      + parent3 :Expanded P3;
      + parent4 :P4 := P4;

For interface inheritance (the two forms are equivalent)

    Section Inherit

      - parent1 :Interface P1;
      + parent2 :Interface P2;

For both (if there is no default values for forms 2 and 4 the compiler should
issue a warning):

    Section Inherit

      - parent1 :Expanded P1;
      - parent2 :P2 := P2;
      + parent3 :Expanded P3;
      + parent4 :P4 := P4;
