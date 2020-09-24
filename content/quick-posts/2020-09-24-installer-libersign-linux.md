---
title: "Installation de LiberSign pour Linux pour utilisation de i-parapheur"
date: 2020-09-23
---

Nous utiliserons une toolbox avec Fedora pour installer le logiciel compagnon en
utilisant Wine afin de faire fonctionner LiberSign.

- Lire la [documentation](https://www.cc-saulnois.fr/extranet/libersign.php)

- Installer l'[extension](https://libersign.libriciel.fr/extension.xpi)

- Télécharger [libersign.exe](https://libersign.libriciel.fr/libersign.exe)

- Créer une toolbox wine :

        toolbox create -c app-wine
        toolbox enter -c app-wine
        sudo dnf install zsh wine

- Installer `libersign.exe` dans la toolbox :

        wine ./libersign.exe

    LiberSign est installé dans `~/.wine/drive_c/users/$(whoami)/Local\ Settings/Application\ Data/LiberSign/`

- Créer un manifest `~/.mozilla/native-messaging-hosts/org.adullact.libersign.json` :

        {
          "name": "org.adullact.libersign",
          "description": "Chrome Native Messaging LiberSign Extension",
          "path": "/home/mildred/.mozilla/native-messaging-hosts/org.adullact.libersign.sh",
          "type": "stdio",
          "allowed_extensions": [
            "@libersign"
          ]
        }

- Créer le script `/home/mildred/.mozilla/native-messaging-hosts/org.adullact.libersign.sh` :

        #!/bin/sh

        set -e

        mkdir -p ~/.run
        fifo="$(mktemp -u ~/.run/org.adullact.libersign.XXXXXXXX.fifo)"
        touch "$fifo.in"
        touch "$fifo.out"

        ( cat >"$fifo.in" ) <&0 &
        reader=$!
        ( tail -f "$fifo.out" ) >&1 &
        writer=$!

        trap 'set +e; kill $reader 2>/dev/null; kill $writer 2>/dev/null; rm -f "$fifo.{in,out}"' 0
        toolbox run -c app-wine sh -c '
          cd ~/.wine/drive_c/users/$(whoami)/Local\ Settings/Application\ Data/LiberSign/;
          export WINEDEBUG=-all;
          fifo="$0";
          exec wine ./jre/bin/libersign -jar ./NativeHost.jar <"$fifo.in" >"$fifo.out"
        ' "$fifo"

        exit $?


    Puis

        chmod +x /home/mildred/.mozilla/native-messaging-hosts/org.adullact.libersign.sh
