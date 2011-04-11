--- 
title:      Problèmes de Performance
created_at: 2010-09-15 14:08:30.485455 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - fr
  - comp
  - lisaac
  - dev
--- 

Ce post fait suite à mon [précédent post sur l'aliasing des chaînes de
caractères](/blog/2010/09/06/aliasing-strings-in-lisaac.html). Je disais que j'avais
presque fini, mais ce n'est sans doute pas le cas.

J'ai de gros problèmes de performance.

Rappelons ce que je cherche à faire :

* Ajouter une ou des primitives pour accéder aux `STRING_CONSTANT` compilées
* Ajouter le support de l'aliasing des chaînes de caractères dans la
  bibliothèque standard
* Remplacer l'aliasing des chaînes du compilateur (`ALIAS_STR`) par l'aliasing
  fait dans la bibliothèque standard.

La première étape est réalisée grâce aux listes chaînées. Les primitives de
compilation ont été ajoutées.

La modification de la bibliothèque standard est bien avancée. Comme cela
nécessite une nouvelle primitive du compilateur, il à fallu bootstrapper le
compilateur à nouveau.

Et maintenant, vient la dernière étape: supprimer l'aliasing du compilateur.
Pour cela, je commence par me compiler un compilateur Lisaac avec *la nouvelle
primitive* et *son support dans la bibliothèque standard*. Ce compilateur est
**extrêmement lent** (2h45 de bootstrap). En effet, l'aliasing est réalisé en double. Puis je
supprime le support de l'aliasing du compilateur et j'ai un gros problème:

* le compilateur en mode optimisé plante
* le compilateur en mode optimisé compilé avec gcc en mode debug ne plante pas
* le compilateur en mode debug ne plante pas

Je ne sais plus quoi faire ... et j'en suis là pour le moment. Je me demande si
c'est `-O2` ou `-fomit-frame-pointer` qui pose problème.

**Pour les problèmes d'optimisation,** je pense savoir un peu ce qui cloche.
Voici comment j'ai implémenté l'aliasing dans `STRING_CONSTANT`:


    Section Public

      - first_string :STRING_CONSTANT <- (first_string := `100`);
      // Il s'agit ici du pointeur de tête vers la liste chaînée au complet

      + next_string :STRING_CONSTANT := NULL;
      // Pointeur suivant de chaque STRING_CONSTANT vers la suivante (initialisé
      // par le compilateur)

    Section Private

      //
      // Aliasing String.
      //

      - bucket:SET(ABSTRACT_STRING) <-
      // Ensemble de toutes les chaînes. HASHED_SET est tout de même bien plus
      // performant qu'une liste chaînée non ordonnée.
      ( + sc :STRING_CONSTANT;
        bucket := HASHED_SET(ABSTRACT_STRING).create;

        sc := first_string;
        {(sc != STRING_CONSTANT) && {sc != NULL}}.while_do {
          bucket.fast_add sc;
          sc := sc.next_string;
        };

        bucket
      );

      - list_insert <-
      // On met quand même à jour la liste chaînée, ça peut servir.
      [
        -? { first_string != Self };
      ]
      (
        bucket.fast_add Self;
        next_string  := first_string;
        first_string := Self;
      );

    Section Public

      - new_intern p:NATIVE_ARRAY(CHARACTER) count nb_char:INTEGER :SELF<-
      // Do not use directly. WARNING: Use by c_string and c_argument (COMMAND_LINE).
      ( + sc, result:STRING_CONSTANT;

        sc := clone;
        sc.set_storage p count nb_char;
        result ?= bucket.reference_at sc;
        (result = NULL).if {
          result := sc;
          result.list_insert;
        };

        result
      );

En fait, j'ai pas du tout assuré !!!

J'ai deux slots code (`<-`) qui sont réinitialisés en données (`:=`). Cela veut
dire qu'à chaque fois que le slot est appelé, le compilateur va intéroger un
slot invisible auto-généré pour savoir si c'est la donnée qu'on veut ou le code.

En plus j'ai l'impression que la version de Lisaac que j'utilise pour compiler
(celle qui met 2h45) avait peut être une ancienne version de la lib ou
l'aliasing était fait par la liste chaînée non triée au lieu de `HASHED_SET`.
Bref, j'ai tout à revoir.

Mildred

