--- 
title:      Aliasing Strings in Lisaac
created_at: 2010-09-06 09:13:44.364009 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - fr
  - comp
  - lisaac
  - dev
---

En Lisaac, il y a trois types de chaînes de caractères: `ABSTRACT_STRING` qui
sert de parent à `STRING` et `STRING_CONSTANT`.

*   Le prototype `ABSTRACT_STRING` contient les méthodes de bases pour toutes
    les chaînes de caractères, utile à leur manipulation. C'est une *classe
    abstraite* qui sert à la manipulation en lecture seule de toute chaîne de
    caractères.

*   `STRING` est un prototype qui introduit des méthodes de modification, comme
    l'ajout d'une autre chaîne en fin. Il est très pratique en tant que buffer
    pour construire une chaîne.

*   Vous l'aurez deviné, les `STRING_CONSTANT` sont des chaînes constantes qu'on
    ne peux pas modifier (non mutables). Ce n'est pas techniquement impossible,
    il vaut cependant mieux éviter. Ces `STRING_CONSTANT` correspondent en fait
    aux chaînes littérales incluses dans le segment DATA de l'exécutable généré.
    Ainsi, toutes ces chaînes sont obligatoirement terminées par `'\0'`
    contrairement aux autres chaînes.

    Une autre particularité est que les chaînes `STRING_CONSTANT` sont générées
    par le compilateur, qui va s'assurer qu'il n'y aura pas deux chaînes
    différentes compilées dans le programme avec le même contenu.

Quelle conclusion peut on en tirer quant à la comparaison entre chaînes ?

1.  Il est nécessaire de comparer les chaînes caractère à caractère pour
    s'assurer de leur égalité

2.  Dans le cas des `STRING_CONSTANT`, il est possible de ne faire qu'une
    comparaison de pointeurs.

Bien sûr, la méthode n°2 est beaucoup plus rapide, Si possible, on aimerait
pouvoir l'utiliser tout le temps. Dans le cas du compilateur Lisaac, les
performances étant tellement critiques (nous avons affaire à un algorithme
exponentiel) que Benoît s'est arrangé pour toujours faire une comparaison de
pointeurs. Comment ?

Tout simplement en transformant les chaînes classiques en `STRING_CONSTANT`.
Cela est fait en construisant de toute pièces l'objet `STRING_CONSTANT` en
copiant les données contenues dans n'importe quelle autre chaîne. Et pour
s'assurer de l'unicité de la chaîne, il est nécesaire au préalable de vérifier
que la chaîne `STRING_CONSTANT` n'existe pas déjà.

Pour cela, toutes les chaînes utiles dans le compilateur à tout instant se
trouvent dans un prototype `ALIAS_STR`. Pour les utiliser, on fait juste
référence au nom du slot dans `ALIAS_STR`. Ces chaînes sont de plus insérées
au démarrage du compilateur dans l'ensemble `SET(ABSTRACT_STRING)` qui contient
toutes les chaînes constantes.

Cela reste une manipulation lourde (il est nécessaire d'insérer à la main toutes
les chaînes constantes qu'on utilise quelque part dans le compilateur dans cet
ensemble de chaînes) réservée au compilateur Lisaac. La conversion entre
`ABSTRACT_STRING` et `STRING_CONSTANT` reste explicite et alourdit le code. J'ai
eu donc envie de généraliser cela en l'implémentant en bibliothèque.

Avec les systèmes d'auto-import et auto-export, la conversion peut être très
facile. Il restait cependant le problème délicat de référencer toutes les
`STRING_CONSTANT` du segment DATA et de les insérer dans l'ensemble des chaînes.
Pour cela il faut ajouter un système d'introspection qui permet au programme de
parcourir toutes les chaînes constantes compilées. J'ai pensé à plusieurs
solutions:

*   Ajouter trois externals pour respectivement avoir la borne basse du tableau
    des chaînes compilées, la borne haute, et un moyen d'obtenir la chaîne à un
    indice donné. Cela s'est avéré trop compliqué dans la mesure où les
    externals sont évalués lors du depending pass et que les chaînes constantes
    ne sont connues que lors de l'executong pass (voire à la toute fin de
    l'exécution du compilateur).

    Il aurait donc fallu ajouter une instruction pour évaluer la borne haute et
    basse, et évaluer la *n*<sup>ième</sup> chaîne. Puisque le paramètre est
    tout sauf une constante entière, cela voudrait dire construire un bloc
    conditionnel `SWITCH`. Trop complexe.

*   Seconde solution, fournir ldans deux externals le nombre de chaînes et un
    pointeur vers un `NATIVE_ARRAY(STRING_CONSTANT)`. C'était la solution la
    plus prometteuse, mais cela aurait complexifié la génération de code.

    En effet, `NATIVE_ARRAY(STRING_CONSTANT)` se traduit en type C par
    `STRING_CONSTANT**`. J'ai pensé au début que construire le code C suivant
    suffirait:

        STRING_CONSTANT* __string = {
          {12, "123456789012"},
          ...
          NULL
        };

    Sauf que cette construction est invalide en C, nous avons affaire à un
    tableau de `Expanded STRING_CONSTANT`, et le marqueur `NULL` ne compile donc
    pas en C. J'aurais donc pu créer le tableau à part, mais je n'avais pas
    envie.

    Ce qui aurait été possible:

        __STRING_CONSTANT __string_1 = {12, "123456789012"};
        ...

        __STRING_CONSTANT* __string[] = {
          __string_1,
          ...
          NULL
        };

*   Dernière solution, la liste chaînée. Chaque chaîne est liée par un pointeur
    à la chaîne précédante, et un unique external est généré pour avoir le haut
    de la liste. Au final, cela ne prend pas plus de place qu'un tableau et
    permet plus de possibilités (comme par exemple de faire rentrer dans la
    liste des chaînes construites après coup). Le code C généré ressemble à:

        __STRING_CONSTANT __string_1 = {STRING_CONSTANT__, 12, "123456789012"};
        __STRING_CONSTANT __string_2 = {&__string_1,       12, "123456789013"};
        __STRING_CONSTANT __string_3 = {&__string_2,       12, "123456789014"};
        __STRING_CONSTANT* __string_first = &__string_3;

    La première chaîne est liée au prototype (qui est lié à `NULL`) et les
    chaînes suivantes sont liées à celles d'avant. Un symbole spécial représente
    le haut de la pile qui est très simplement disponnible avec un external.
    C'est la solution que j'ai retenue.

Une fois le compilateur modifié, il faut modifier la bibliothèque standard. Au
début, j'ai eu pour approche d'utiliser la liste chaînée comme ensemble de
chaînes uniques au lieu d'un `HASHED_SET`. Mais les performances ont été
tellement déplorables que j'en suis revenu à l'ensemble de hash.

Les modifications sont presque prêtes, et il va être nécessaire d'introduire
deux commits de bootstrap (un commit pour introduire la fonctionnalité dans le
compilateur, l'autre avec une bibliothèque standard modifiée et le compilateur
qui délègue l'aliasing à la bibliothèque).

Il reste quelques problèmes à corriger, et ce sera prêt.

Mildred.


