#!/bin/sh

set -e

VERBOSE=0
ROOTDIR=
ENVSET=


# Print usage on stderr and exit
usage() {
    exitcode="$1"
    cat <<USAGE >&2

Description:

  $0 will read environment variables from files and start
  a sub-process

USAGE
    exit "$exitcode"
}

while [ $# -gt 0 ]; do
    case "$1" in
    -v | --verbose)
        VERBOSE=1; shift 1;;

    -r | --root-dir | --root | --rootdir)
        ROOTDIR=$2; shift 2;;
    --root-dir=* | --root=* | --rootdir=*)
        ROOTDIR="${1#*=}"; shift 1;;
    
    -e | --env | --environment)
        ENVSET=$(printf '%s\n%s' "$2" "$ENVSET"); shift 2;;
    --env | --environment)
        ENVSET=$(printf '%s\n%s' "${1#*=}" "$ENVSET"); shift 1;;

    --)
        shift
        break
        ;;

    -*)
        usage 1
        exit
        ;;

    *)
        break
        ;;
    esac
done

warn() {
    printf "%s\n" "$*" 1>&2
}

verbose() {
    if [ "$VERBOSE" = "1" ]; then printf "%s\n" "$*" 1>&2; fi
}

while read -r cmd; do
    if [ -n "$(printf %s\\n "$cmd" | sed -E 's/^[[:space:]]*$//g')" ]; then
        varname=$(printf %s\\n "$cmd"|awk -F ":" '{print $1}')
        # Path to file is directly specified or comes from name of variable.
        fpath=$(printf %s\\n "$cmd"|awk -F ":" '{print $2}')
        if [ -z "$fpath" ]; then
            fpath=$(printf %s\\n "$varname" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
        fi
        # Relative path from root dir when root dir is not empty.
        if [ -n "$ROOTDIR" ]; then
            firstchar=$(printf %s\\n "$fpath" | cut -c1-1)
            if [ "$firstchar" != "/" ] && [ "$firstchar" != "~" ]; then
                fpath="${ROOTDIR%%/}/${fpath}"
            fi
        fi
        value=$(cat "$fpath")
        verbose "Setting $varname with content of $fpath"
        export "${varname}=${value}"
    fi
done <<EOC
$ENVSET
EOC

if [ "$#" != "0" ]; then
    exec "$@"
fi
