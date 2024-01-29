#!/bin/sh

D="$(dirname -- $0)"

# Choose 'mkdeploy'
SH="$(command -v sh)"
MKDEPLOY="$(command -v mkdeploy)"
test -n "${MKDEPLOY}" || MKDEPLOY="${D}/mkdeploy.sh"
test -x "${MKDEPLOY}" || MKDEPLOY="${SH} \"${MKDEPLOY}\""

# Set variables
PRODUCT="dotfiles"
VERSION="2"

SRCDIR="${D}"
OUTDIR="${D}"

OUTFILE="${OUTDIR}/${PRODUCT}-v${VERSION}.sh"

INITFILE="install.sh"
FILELIST="bashrc exrc inputrc profile vimrc"

# Run 'mkdeploy' passing parameters via variables
eval '\
SRCDIR="${SRCDIR}" \
OUTDIR="${OUTDIR}" \
OUTFILE="${OUTFILE}" \
PRODUCT="${PRODUCT}" \
VERSION="${VERSION}" \
INITFILE="${INITFILE}" \
FILELIST="${FILELIST}"' \
"${MKDEPLOY}"
