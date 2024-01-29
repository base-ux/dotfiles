#!/bin/sh

D="$(dirname -- $0)"

# Choose 'mkdeploy'
MKDEPLOY="$(command -v mkdeploy)"
test -n "${MKDEPLOY}" || MKDEPLOY="${D}/mkdeploy.sh"
test -x "${MKDEPLOY}" || MKDEPLOY="command -p sh \"${MKDEPLOY}\""

# Set variables
PRODUCT="dotfiles"
VERSION="2"

SRCDIR="${D}"
OUTDIR="${D}"

OUTFILE="${OUTDIR}/${PRODUCT}-v${VERSION}.sh"

INITFILE="install.sh"
FILELIST="
bashrc
exrc
inputrc
profile
vimrc
"

# Run 'mkdeploy' passing parameters via variables
SRCDIR="${SRCDIR}" \
OUTDIR="${OUTDIR}" \
OUTFILE="${OUTFILE}" \
PRODUCT="${PRODUCT}" \
VERSION="${VERSION}" \
INITFILE="${INITFILE}" \
FILELIST="${FILELIST}" \
eval "${MKDEPLOY}"
