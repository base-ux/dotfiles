#!/bin/sh

# Set variables
PRODUCT="dotfiles"
VERSION="6"

D="$(dirname -- $0)"
D="$(cd -- "${D}" ; pwd)"

SRCDIR="${D}"
OUTDIR="${D}/out"

OUTFILE="${PRODUCT}-v${VERSION}.sh"

INITFILE="install.sh"
FILELIST="dot.bashrc dot.exrc dot.inputrc dot.profile dot.vimrc"

# Choose 'mkdeploy'
SH="$(command -v sh)"
MKDEPLOY="$(command -v mkdeploy)"
if test -z "${MKDEPLOY}" ; then
    MKDEPLOY="${D}/mkdeploy.sh"
    test -f "${MKDEPLOY}" || { echo "no mkdeploy found" ; exit 1 ; }
fi
test -x "${MKDEPLOY}" || MKDEPLOY="${SH} \"${MKDEPLOY}\""

# Run 'mkdeploy'
eval "${MKDEPLOY}" -s "${SRCDIR}" -d "${OUTDIR}" -o "${OUTFILE}" \
		   -f \"${FILELIST}\" -i "${INITFILE}" \
		   -P "${PRODUCT}" -V "${VERSION}"
