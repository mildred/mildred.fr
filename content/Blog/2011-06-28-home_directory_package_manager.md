---
title:      Home directory package manager
created_at: 2011-06-28 12:17:55 +02:00
excerpt:
kind:       article
publish:    true
tags:
  - misc
  - comp
  - configuration
  - en
---

I always wanted to manage the files in my home directory. Generally, it's a
complete mess and I wanted to get things right and understand the files I had.

At first, I just created a simple shell script that maintained symbolic links of
the dotfiles and dordirs of my homedirs to `.local/config`, sort of early XDG
configuration directory. I also changed my .bashrc and later .zshrc to point to
files in `.local/etc/profile.d`. The shell script was reading a database in
`.local/config/database.sh` that contained the link information in the form.

The script did the following for each file declared:

  - if the file existed in the homedir but not in the database directory, it was
    simply moved and a link was created in its place.
  - if the file existed at both places, tell there is a conflict.
  - if the file existed in the database directory but not in the homedir, create
    the link

The database looks like:

    link ".bashrc" "bashrc"
    link ".zshrc"  "zshrc"

    # First file in home directory
    # Second file in .local/config

My script just defined a function `link` and sourced the database. But links
were not easy to construct in shell. So later, I decided to rewrite it in Tcl,
simply because the syntax is compatible (I love the Tcl syntax for that) and
because of the wonderful [file][file] command.

Later, I improved the script that was then called `fixdir` to list which files
were not managed, and display them. So I could either delete those files
(because I don't care about them) or integrate them in the database. The script
gained a `clean` command to automatically remove files declared as noisy.

Now, I have a slightly different problem. I have now different computers which
do not have all the same configuration. At first, I synchronized everything and
just used the hostname in the database to get different links depending on the
machine. But now, with my computer at work, I will not synchronize all the
personal configurations. i have to get to a modular approach.

And this script did not help me in tracking what programs I installed in
`~/.local/{bin,share,lib}`. For this, I wanted something like [stow][stow]. I
tried using stow, but it failed with a conflict. Then I tried using
[homedir][homedir]. I just didn't like it because it created an ugly `~/bin`
instead of `~/.local/bin`.

Then I realized my `fixdir` script looks much like `homedir` already, and I
patched it up to make it better. And there it is.

[The current version of fixdir is on github.][fixdir]

Let me copy the README file:

What is it?
-----------

This is my homedir package manager. Written first in shell then translated in
tcl. Originally, this was just to maintain a set of symbolic links from my home
directory to a directory where all important comfig files were stored. Then I
decided to make it a package manager.

How to install it?
------------------

    git clone git://github.com/mildred/fixdir.git fixdir
    fixdir_dir="$(pwd)/fixdir"
    cd
    "$fixdir_dir/fixdir" install "$fixdir_dir/hpkg.tcl"

`fixdir` is installed in `~/.local/bin`. Make sure it is in your `$PATH`.

How does it work
----------------

`fixdir` works better when you are in your target directory (homedir)

Invoke one action with a database file. The database file is a tcl script that
contain all files and directories that should be linked.

What else can it do?
--------------------

`fixdir unknown` list all files not manages by fixdir in the current directory

`fixdir clean` remove files declared as noisy

Bugs
----

* fixdir list doesn't work when pwd != target directory


[file]: http://www.tcl.tk/man/tcl8.5/TclCmd/file.htm
[stow]: http://www.gnu.org/software/stow/
[homedir]: https://github.com/docwhat/homedir
[fixdir]: https://github.com/mildred/fixdir

