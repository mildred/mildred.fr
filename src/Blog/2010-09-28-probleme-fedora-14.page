--- 
title:      Mise à jour périlleuse avec Fedora 14
created_at: 2010-09-28 14:03:55.772917 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - fr
  - comp
  - fedora
--- 

Tout commence à mon avis avec une simple mise à jour de mon installation
principale de Fedora: `sudo yum upgrade --skip-broken`. Tout semble bien se
passer et je continue à travailler.

    Sep 28 09:37:34 Updated: glibc-common-2.12.90-13.x86_64
    Sep 28 09:42:00 Updated: glibc-2.12.90-13.x86_64
    Sep 28 09:42:55 Updated: glibc-headers-2.12.90-13.x86_64
    Sep 28 09:51:07 Updated: selinux-policy-3.9.5-7.fc14.noarch
    Sep 28 09:53:27 Updated: nscd-2.12.90-13.x86_64
    Sep 28 09:55:02 Updated: gdb-7.2-15.fc14.x86_64
    Sep 28 09:58:00 Updated: planner-0.14.4-26.fc14.x86_64
    Sep 28 10:01:25 Updated: gnome-user-share-2.30.1-1.fc14.x86_64
    Sep 28 10:10:48 Updated: selinux-policy-targeted-3.9.5-7.fc14.noarch
    Sep 28 10:11:04 Updated: glibc-devel-2.12.90-13.x86_64
    Sep 28 10:11:16 Updated: rpmdevtools-7.10-1.fc14.noarch
    Sep 28 10:12:34 Updated: glibc-debuginfo-2.12.90-13.x86_64
    Sep 28 10:12:58 Updated: glibc-2.12.90-13.i686


Soudain, plus rien ne marche. N'importe quelle commande me retourne un segfault,
j'essaie d'ouvrir un nouvel onglet dans mon émulateur de terminal, il se ferme
aussitôt. Je tente de me déconnecter pour me reconnecter, pensant que cela
résoudrait le problème, mais en me déconnectant, l'interface graphique tombe en
rade et sur la console, j'ai un message qui tourne en boucle concernant le
daemon abrt chargé d'enregistrer tous les crash pour en faire des rapports de
bugs. Je tente de redémarrer l'ordinateur, mais ça ne marche pas, alors je
l'arrête de force.

Je le redémarre, et ...

J'ai une erreur dans `/sbin/init`, un segfault qui à été localisé dans `ld.so`.
Je tente avec `init=/bin/sh` ou encore `selinux=0` sans résultat.

Je panique.

Comment faire ? Démarrer sur un système de secours bien sûr. Je resors une clef
USB que je pensait cassée, mais elle marche et j'arrive à booter sur une
Fedora 13 i686. Génial.

Je tente un `chroot /mnt/fedora /bin/init` ... bien sûr le format du binaire
n'est pas reconnu, c'est un binaire 64bits et le kernel de la clef USB est
32 bits uniquement.

Je tente un `yum --installroot=/mnt/fedora info glibc` et j'ai un problème de
versions de base de donnée qui ne correspond pas.

Conclusion, il me faut une clef USB avec Fedora 14 x86_64. Je commence à
télécharger l'image ISO et je passe en BitTorrent qui est bien plus rapide. Bien
sûr, je l'enregistre dans le dossier /home virtuel, donc au bout d'un moment, le
système est trop rempli et freeze. Je recommence en l'enregistrant sur un disque
dur externe et c'est bon.

Et là, il faut que je change le système qui se trouve sur ma clkef USB que je
suis en train d'utiliser. Chaud !

    dd if=F14.iso of=/dev/sdb bs=16M
    sync

Bien sûr, la commande sync ne marche plus. J’attend donc patiemment que la LED
de la clef USB s'arrête pour éteindre sauvagement l'ordinateur. Je le relance
avec le nouveau système et je peux enfin taper la commande qui va me sauver la
vie:

    yum --installroot=/mnt/fedora reinstall glibc

    Sep 28 11:42:43 Installed: glibc-2.12.90-13.x86_64
    Sep 28 11:42:57 Installed: glibc-2.12.90-13.i686
    (je dois préciser que l'ordinateur avait 2h de retard cart l'orloge système
     est réglée UTC, il était donc réellement 13:42)

J'avais essayé un `yum downgrade` mais ça prenait trop de temps et impactait
trop de packages. Je peux alors enfin faire un chroot sans segfault:

    chroot /mnt/fedora /bin/sh
    sh#

Miracle!

Je redémarre et tout rentre dans l'ordre.

Note: il s'agit du
[bug 638091](https://bugzilla.redhat.com/show_bug.cgi?id=638091)