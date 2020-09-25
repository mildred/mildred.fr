---
title: "Installation de LiberSign pour Linux pour utilisation de i-parapheur"
date: 2020-09-23
---

**Note :** Wine n'a pas de support USB, donc le certificat USB ne sera pas
reconnu... Ceci est donc inutile.

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
        passthrough=false
        passthrough_out=true
        single=true

        mkdir -p ~/.run
        fifo="$(mktemp -u ~/.run/org.adullact.libersign.XXXXXXXX.fifo)"
        mkfifo "$fifo.in"
        mkfifo "$fifo.out"
        mkfifo "$fifo.sig"
        touch "$fifo.continue"
        log="$HOME/.run/org.adullact.libersign.log"
        id=$$

        if $single; then
          rm -f "$fifo.in"
        fi

        exec 4<&0 5>&1 </dev/null >"$log" 2>>"$log" 0<&-

        echo "$id: FIFO are $fifo.*"
        trap clean_fifo 0
        clean_fifo(){
          set +e
          rm -f "$fifo.in" "$fifo.out"
          echo "$id: rm -f $fifo.in $fifo.out $fifo.sig $fifo.continue"
        }


        if $passthrough; then
          cat <&4 >"$fifo.in" & in=$!
        else
          (
            continue=false
            echo "$id: wait for toolbox to be ready"
            :>"$fifo.sig" # Wait for toolbox binary to start

            exec 6>"$fifo.in"
            while true; do
              len=$(head -c 4 <&4 | od -An -t u4 | xargs)
              if [ -z "$len" ]; then
                if $single; then
                  rm -f "$fifo.in"
                  :>"$fifo.sig" # Wait for toolbox binary to start
                fi
                echo "$id: No more messages: quit"
                exec 6>&-
                break
              elif $continue && $single; then
                exec 6>&-
                echo "$id: wait for toolbox to be ready"
                :>"$fifo.sig" # Wait for toolbox binary to start

                exec 6>"$fifo.in"
              fi
              msg="$(head -c $len <&4)"
              echo "$id: message $len $msg"

              binlen=$(printf %08x $len)
              binlen_le="\x${binlen:6:2}\x${binlen:4:2}\x${binlen:2:2}\x${binlen:0:2}"

              if $single; then
                touch "$fifo.continue"
              fi

              #printf '%b%s' "$binlen_le" "$msg" | hexdump -C
              printf '%b%s' "$binlen_le" "$msg" >&6
              echo "$id: message sent"
              continue=true
            done
          ) & in=$!
        fi

        if $passthrough_out; then
          cat <"$fifo.out" >&5 & out=$!
        else
          (
            exec 7<"$fifo.out"
            while false; do
              len=$(head -c 4 <&7 | od -An -t u4 | xargs)
              if [ -z "$len" ]; then
                echo "$id: No more responses: quit"
                break
              fi
              echo "$id: response $len"
              msg="$(head -c $len <&7)"
              echo "$id: response $len $msg"

              binlen=$(printf %08x 76)
              binlen_le="\x${binlen:6:2}\x${binlen:4:2}\x${binlen:2:2}\x${binlen:0:2}"
              #printf '%b%s' "$binlen_le" "$msg" | hexdump -C
              printf '%b%s' "$binlen_le" "$msg" >&5
            done
          ) & out=$!
        fi

        toolbox run -c app-wine sh -c '
          cd ~/.wine/drive_c/users/$(whoami)/Local\ Settings/Application\ Data/LiberSign/;
          export WINEDEBUG=-all;
          id="$0"
          fifo="$1";
          exec 4>"$fifo.out"
          while [ -e "$fifo.continue" ]; do
            echo "$id: toolbox starting"
            rm -f "$fifo.continue"
            echo "$id: toolbox ready"
            :<"$fifo.sig" # Signal ready
            rm -f "$fifo.sig"
            mkfifo "$fifo.sig"
            echo "$id: wine ./jre/bin/libersign -jar ./NativeHost.jar"
            wine ./jre/bin/libersign -jar ./NativeHost.jar <"$fifo.in" >&4
          done
          echo "$id: toolbox stopped"
        ' "$id" "$fifo" & job=$!

        wait $in $out $job
        exit $?



    Puis

        chmod +x /home/mildred/.mozilla/native-messaging-hosts/org.adullact.libersign.sh
