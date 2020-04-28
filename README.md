Setup on NearlyFreeSpeech.NET
-----------------------------

Set up a generic site, you need, compiled for the correct OS and architecture:

- datamgr
- filebrowser (v1.10 with Hugo integration, and no later)
- hugo (extended build)

You can put binaries in `/home/protected/bin`. you need to clone this repository
under `/home/protected/croix-de-chartreuse`. `/home/public` is the static files
root.

Set up the following daemons:

- hugo:

    - command-line: /home/protected/croix-de-chartreuse/scripts/hugo.sh
    - working directory: does not matter
    - run daemon as: me

- filebrowser:

    - command-line: /home/protected/croix-de-chartreuse/scripts/filebrowser.sh
    - working directory: does not matter
    - run daemon as: me

- datamgr:

    - command-line: /home/protected/croix-de-chartreuse/scripts/datamgr.sh
    - working directory: does not matter
    - run daemon as: me

Set up the following proxies:

- filebrowser:

    - protocol: HTTP
    - base URI: /admin/
    - document root: /admin/
    - target port: 8080

- datamgr:

    - protocol: HTTP
    - base URI: /datamgr/
    - document root: /datamgr/
    - target port: 8081

