#!/bin/sh

P="$(dirname -- $0)"
MKDEPLOY="$P/mkdeploy.sh"

SRCDIR="$P" \
OUTDIR="$P" \
INITFILE="install.sh" \
FILELIST="
bashrc
exrc
inputrc
profile
vimrc
" \
command -p sh "${MKDEPLOY}"
