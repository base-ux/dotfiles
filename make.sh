#!/bin/sh

# Set variables
PRODUCT="dotfiles"
VERSION="9"

PROG="$(basename -- "$0")"

D="$(dirname -- "$0")"
D="$(cd -- "${D}" ; pwd)"

SRCDIR="${D}"
OUTDIR="${D}/out"

OUTFILE="${PRODUCT}-v${VERSION}.sh"

SH="$(command -pv sh)"
SPXGEN="$(command -v spxgen)"
MKDEPLOY="$(command -v mkdeploy)"

INSTALL_SHT="${SRCDIR}/install.sht"
INSTALL="${SRCDIR}/install.sh"

FILELIST="dot.bashrc dot.exrc dot.inputrc dot.profile dot.vimrc"

# Generate 'install.sh' script
build ()
{
    if test -z "${SPXGEN}" ; then
	printf "%s: command 'spxgen' not found\n" "${PROG}"
	return 1
    fi
    if test -f "${INSTALL_SHT}" ; then
	${SPXGEN} -o "${INSTALL}" "${INSTALL_SHT}" || return 1
    else
	printf "%s: file '%s' not found\n" "${PROG}" "${INSTALL_SHT}"
	return 1
    fi
}

# Create deploy script
deploy ()
{
    # Build scripts first
    build || return 1
    if test -z "${MKDEPLOY}" ; then
	printf "%s: command 'mkdeploy' not found\n" "${PROG}"
	return 1
    fi
    ${MKDEPLOY} \
	-s "${SRCDIR}" \
	-o "${OUTDIR}/${PRODUCT}-v${VERSION}.sh" \
	-P "${PRODUCT}" -V "${VERSION}" \
	-i "${INSTALL}" \
	-f "${FILELIST}" \
    || return 1
}

# Call install script
install ()
{
    # Build scripts first
    build || return 1
    ${SH} "${INSTALL}" || return 1
}

# Show usage information
usage ()
{
    cat << EOF
Usage: ${PROG} target
    'target' is one of the following ('all' if missed):
    all		build all
    build	build installation script
    deploy	create deploy script
    install	call installation script
EOF
}

# Main subroutine
main ()
{
    # Check command line arguments
    test $# -le 1 || { usage ; return 1 ; }
    test $# -gt 0 && _target="$1" || _target="all"
    # Create output directory
    test -d "${OUTDIR}" || mkdir -p "${OUTDIR}" || return 1
    case "${_target}" in
	( "all" ) build ;;
	( "build" ) build ;;
	( "deploy" ) deploy ;;
	( "install" ) install ;;
	( * ) usage ; return 1 ;;
    esac
}

# Call main subroutine
main "$@"
