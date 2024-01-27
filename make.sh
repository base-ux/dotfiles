#!/bin/sh

D="$(dirname -- $0)"

# Choose 'mkdeploy'
MKDEPLOY="$(command -v mkdeploy)"
test -n "${MKDEPLOY}" || MKDEPLOY="${D}/mkdeploy.sh"
test -x "${MKDEPLOY}" || MKDEPLOY="command -p sh \"${MKDEPLOY}\""

# Set variables
PRODUCT="dotfiles"
VERSION=""

SRCDIR="${D}"
OUTDIR="${D}"

OUTFILE="${OUTDIR}/${PRODUCT}.sh"
VERFILE="${SRCDIR}/version"

INITFILE="install.sh"
FILELIST="
bashrc
exrc
inputrc
profile
vimrc
"

# Check version
if test -f "${VERFILE}" ; then
    # Get current version
    VERSION="$(cat "${VERFILE}")"
    if test -n "${VERSION}" ; then
	_list=""
	for _f in ${INITFILE} ${FILELIST} ; do
	    test -n "${_list}" && _list="${_list} ${SRCDIR}/${_f}" || _list="${SRCDIR}/${_f}"
	done
	# Find newer files
	if test -n "$(find ${_list} -newer "${VERFILE}" 2>/dev/null)" ; then
	    # Bump version
	    VERSION=$(( ${VERSION} + 1 ))
	    echo "${VERSION}" > "${VERFILE}"
	fi
	unset _list _f
    else
	# Initial version
	VERSION="1"
	echo "${VERSION}" > "${VERFILE}"
    fi
    OUTFILE="${OUTDIR}/${PRODUCT}-v${VERSION}.sh"
fi

# Run 'mkdeploy' passing parameters via variables
SRCDIR="${SRCDIR}" \
OUTDIR="${OUTDIR}" \
OUTFILE="${OUTFILE}" \
PRODUCT="${PRODUCT}" \
VERSION="${VERSION}" \
INITFILE="${INITFILE}" \
FILELIST="${FILELIST}" \
eval "${MKDEPLOY}"
