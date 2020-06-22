#!/bin/bash

while getopts "dxn" OPT
do
    case $OPT in
        d) debug=yes;;
        x) set -x;;
        n) dryrun="yes";;
    esac
done
shift $((OPTIND - 1))

locales=`week -l | perl -nE '/--(.._..)/ and say $1'`

run() {
    if [ "$dryrun" != "" ]
    then
	echo $*
    else
	$*
    fi
}

capture() {
    run sleep 0.1
    run screencapture -R5,61,592,210 $1.png
}

for locale in $locales
do
    run clear
    run week --$locale 2020/07/24
    run echo
    capture $l
done
