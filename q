#!/usr/bin/bash
# manipulate queues
# Usage: q COMMAND ARGS
#
# Commands:
#   push FILE STRING    push STRING onto the top of FILE
#   peek FILE           peek at the bottom of FILE
#   pop  FILE           output the bottom of FILE and remove it

cmd=$1
file=$2

die() {
    echo "$1" >&2
    exit 1
}

if [ $# -lt 2 ]; then
    die "usage: q COMMAND ARGS"
fi

if [ ! -f "$file" ]; then
    if [ $cmd = push ]; then
        # push onto new file
        what=$3
        if [ -z "$what" ]; then
            die "usage: q push FILE STRING"
        fi
        echo "$what" > "$file"
        exit 0
    else
        die "error: no such file: $file"
    fi
fi

case $cmd in
    push)
        what=$3
        if [ -z "$what" ]; then
            die "usage: q push FILE STRING"
        fi

        cat <(echo "$what") $file > $file.tmp
        mv $file.tmp $file
        ;;
    peek)
        tail -n1 $file
        ;;
    pop)
        tail -n1 $file
        head -n-1 $file > $file.tmp
        mv $file.tmp $file
        ;;
    ?)
        echo "error: unknown command: $cmd" >&2
        exit 1
        ;;
esac
