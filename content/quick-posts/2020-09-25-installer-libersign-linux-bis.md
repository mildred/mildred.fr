---
title: "Faire fonctionner le i-parapheur avec Linux"
date: 2020-09-23
---

Solution simple, utiliser java :

  - `git clone https://github.com/mildred/docker-firefox-openjdk`
  - `cd docker-firefox-openjdk`
  - `./build.sh`
  - `./run.sh`

Seul problème, cela ne fonctionne pas...

Sinon, si vous avez envie de coder des trucs :

  - Télécharger le [driver de Chambersign](http://support.chambersign.fr/index.php?option=com_chambersign&task=autoconnect&p=dD00)

  - Décompresser dans un dossier les drivers et modifier le rpath

        patchelf --set-rpath "$PWD" libidolog.so
        patchelf --set-rpath "$PWD" libidop11.so
        patchelf --set-rpath "$PWD" libt_ias.so
        patchelf --set-rpath "$PWD" idocachesrv

  - Vérifier que vous avec toutes les bibliothèques requises :

        ldd libidolog.so
        ldd libidop11.so
        ldd libt_ias.so
        ldd idocachesrv

    Il me manque `libcrypto.so.1.0.0` et `libpcsclite.so.1`, cherchez sur
    [pkgs.org]. J'ai pris le package libssh de slackware et ai copié les
    fichiers dans le dossier courant.

    Vérifier avec `ldd * | grep "not found"` et utiliser `patchelf` au besoin.

  - Configurer Firefox avec un [fichier manifest] :

        mkdir -p ~/.mozilla/pkcs11-modules
        cat <<EOF >~/.mozilla/pkcs11-modules/chambersign.json
        {
          "name": "chambersign",
          "description": "Chambersign PKCS#11",
          "type": "pkcs11",
          "path": "$PWD/libidop11.so",
          "allowed_extensions": []
        }
        EOF

  - Installer la configuration :

        cat <<EOF >~/.idoss.global.conf
        SecuritySuite {
                Shell = #
        }
        TokenInterfaces2 {
                IAS = libt_ias.so
        }
        EOF

  - Démarrer le service (nécessaire à chaque fois) :

      journalctl -f &
      ./idocachesrv

  - Écrire un extension Firefox pour remplacer Libersign en utilisant pkcs11

[pkgs.org]: https://pkgs.org/
[fichier manifest]: https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_manifests#PKCS_11_manifests
