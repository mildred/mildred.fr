---
title: "Comment faire du web aujourd'hui ? (brouillon)"
date: 2017-12-05
draft: false
---

Comment faire du web aujourd'hui ? Une vraie question qui mérite qu'on s'y attarde un peu. Nous na parlons pas ici de pages documentaires qui sont l'origine du web, mais des applications web. Une sorte de chimère qui s'est développée de manière organique au dessus des navigateurs, outils servant à la base pour parcourir des bases documentaires.

Qualifions maintenant cette interrogations que nous avons formulé ? Comment faire du web ? Ce que nous cherchons à savoir ici, c'est comment écrire des applications web en gardant la simplicité originale de ce que le web représente. Point de framework compliqués, nous cherchons une solution à base de bibliothèques dédiées a une seule tâche.

Une autre propriété du web, c'est la séparation des objectifs. Depuis ses débuts, il sépare la structure sémantique du document (HTML) avec son apparence (les styles CSS) et également ses effets (les scripts). Rien n'est mélangé à tort et à travers. Il est possible de prendre un même document et lui appliquer des styles et scripts différents. De la même manière, pour une application web, nous chercherons a voir comment séparer ses différents aspects.

Pour résumer, voici une simple liste de ce que nous cherchons :

    Orienté composent : c'est la base du HTML, des balises réutilisables
    Une stack technique simple: pas de jQuery, Javascript vanilla marche bien, pas d'extensions comme JSX qui nécessite des compilateurs comme babel
    Pas de templates : c'est la porte ouverte a toutes les failles XSS. On utilise un DOM a la place.
    rapide et léger

Ce critères nous emmènent bien loin de framework tout compris comme Angular. Au contraire, les techniques à base de virtual DOM semblent être intéressantes par leur rapidité d'exécution. L'idée du vitual DOM est de compacter tous les changements faits à la vue dans une structure de donnée, le VDOM, qui est ensuite comparé au DOM du navigateur. Et les changements, si il y en a, sont appliquées en une fois, évitant ainsi au navigateur de faire des rendus intermédiaire de la page.

TODO: trouver une référence pour expliquer les avantages du VDOM dans Firefox

React est la référence en ce qui concerne le Virtual DOM. Ce ne sera pas notre choix. En effet, il est relativement lourd, peu isolé dans ses fonctionnalités et nécessite des extensions (JSX) nécessitant de compiler le code javascript.

Ce que nous voulons, ici, c'est une bibliothèque ne s'occupant que du Virtual DOM. Le templating serait fourni par une autre bibliothèque indépendante. Il en existe bon nombre, et notre choix s'est porté sur citojs qui est léger, très rapide, et dont le format du DOM est un simple JSON, facile a adapter pour notre moteur de template.

TODO: continuer
