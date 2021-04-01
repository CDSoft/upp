#!/bin/bash

make $*
while true
do
    printf "\\e[44m### %-$(($(tput cols) - 4))s\\e[0m\\r" "waiting for changes..."
    if inotifywait -q -r --exclude "\.git|\.sw." -e modify . > /dev/null
    then
        printf "\\e[44m### %-$(($(tput cols) - 4))s\\e[0m\\n" "make"
        sleep 1
        make $*
    fi
done
