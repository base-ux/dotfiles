## A set of dotfiles

This is a set of my personal dotfiles.

`dot.vimrc` (for Vim) is quite simple as I dont't actually like those
modern things like syntax highlighting, folding etc. :)

`dot.exrc` (for classic Vi used for example in AIX) is simple as well.
This editor just lacks tons of settings.

`dot.inputrc` contains one setting (`set enable-bracketed-paste off`) for now.

`dot.profile` is used as login profile for shells I use.
It is tested with Bourne shell (on AIX), ash, bash, dash and ksh (both ksh88 and ksh93).

`dot.bashrc` is actually used both with bash and ksh (I make symbolic link .kshrc -> .bashrc).

### Get

You can use git:

```
git clone https://github.com/base-ux/dotfiles.git
```

or simply download as zip file from Github web interface.

### Install

You can copy dot.* files to your home directory removing 'dot' prefix, e.g.:

```
cp dot.profile $HOME/.profile
```

Second option requires a couple of scripts from [spxshell toolkit].

You can use `make.sh` script included:

```
./make.sh
```

It will build `install.sh` script. Execute this script to install all this dotfiles.
Or it can be done with:

```
./make.sh install
```

Also you can generate so-called deploy script with:

```
./make.sh deploy
```

It will create shell script (in `out` directory) which can be copied to other host
and runned to do all the work. :)

[spxshell toolkit]: https://github.com/base-ux/spxshell
