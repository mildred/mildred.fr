---
title: Parce que le code est compilé
date: 2020-12-30T21:54:42.225Z
draft: true
---
Le choix d'un langage compilé est essentiel, et plus encore l'importance que le code soit compilé en langage machine. Java et consorts ne sont que des demi compilations car le code machine généré reste très haut niveau et loin des préoccupations du processeur.

Un langage compilé permet des optimisations impossibles aux langages interprétés. Que penser du Bash, du Perl ou de Ruby ? À chaque exécution, l'interpréteur est obligé de relire tout le code dans son entièreté et cela provoque un ralentissement obligatoire. PHP fut sans doute le pire dans sa configuration par défaut ou chaque chargement de page réexécurant tout l'interpréteur. Un langage compilé nous permet de nous affranchir de cela.

TODO:

- typage statique (car proche du code machine)