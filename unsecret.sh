#!/bin/sh

set -e

UNSECRET_VERBOSE=${UNSECRET_VERBOSE:-0}
UNSECRET_ROOTDIR=${UNSECRET_ROOTDIR:-}
UNSECRET_ENVSET=${UNSECRET_ENVSET:-}


# Print usage on stderr and exit
usage() {
    exitcode="${1:-0}"
    cat <<USAGE >&2

Description:

  $0 will read environment variables from files and start a sub-process

Usage:
  $0 [-option arg --long-option(=)arg] (--) command

  where all dash-led options/flags are as follows (long options can be followed
  by an equal sign). The command, if present is executed once environment
  variables have been set.

  Flags:
    -v | --verbose
        Be more verbose
    -h | --help
        Print this help and exit

  Options:
    -r | --root | --root(-)dir
        Root directory under which to locate all files. Default to empty.
    -e | --env(ironment)
        Variable specification, see below. Can be repeated several times.

Details:

  Environment variable specifications are composed of the name of a variable,
  followed by the colon sign, followed by the file location at which to find the
  value of the variable. When the file path is relative, it will be relative to
  the root directory, specified through --root. If the root directory is empty,
  the file will be relative to the current directory.

  The colon and file specification are optional. When they are not present, the
  script will convert the name of the environment variable to lower case,
  replace all occurrences of an underscore (_) by a dash (-) and look for a file
  with that name.

USAGE
    exit "$exitcode"
}

while [ $# -gt 0 ]; do
    case "$1" in
    -v | --verbose)
        UNSECRET_VERBOSE=1; shift 1;;

    -r | --root-dir | --root | --UNSECRET_ROOTDIR)
        UNSECRET_ROOTDIR=$2; shift 2;;
    --root-dir=* | --root=* | --UNSECRET_ROOTDIR=*)
        UNSECRET_ROOTDIR="${1#*=}"; shift 1;;
    
    -e | --env | --environment)
        UNSECRET_ENVSET=$(printf '%s\n%s' "$2" "$UNSECRET_ENVSET"); shift 2;;
    --env | --environment)
        UNSECRET_ENVSET=$(printf '%s\n%s' "${1#*=}" "$UNSECRET_ENVSET"); shift 1;;

    -h | --help)
        usage; shift 1;;

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
    if [ "$UNSECRET_VERBOSE" = "1" ]; then printf "%s\n" "$*" 1>&2; fi
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
        if [ -n "$UNSECRET_ROOTDIR" ]; then
            firstchar=$(printf %s\\n "$fpath" | cut -c1-1)
            if [ "$firstchar" != "/" ] && [ "$firstchar" != "~" ]; then
                fpath="${UNSECRET_ROOTDIR%%/}/${fpath}"
            fi
        fi
        value=$(cat "$fpath")
        verbose "Setting $varname with content of $fpath"
        export "${varname}=${value}"
    fi
done <<EOC
$UNSECRET_ENVSET
EOC

[ "$#" -gt "0" ] && exec "$@"

