#!/bin/bash

# This file is part of UPP.
#
# UPP is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# UPP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with UPP.  If not, see <https://www.gnu.org/licenses/>.
#
# For further information about UPP you can visit
# http://cdelord.fr/upp

# Use docker to build upp for Debian, Ubuntu, Fedora and Windows

LAPP_VERSION=0.6.4

RELEASE=.build/release
INDEX=$RELEASE/upp_release.lua
INDEX_NEW=$RELEASE/upp_release.lua.new

set -ex

###############################################################################
# Native Linux binaries built with docker
###############################################################################

build()
{
    local OS="$1"
    local OS_VERSION="$2"
    local LINUX_BINARY=upp-$OS-$OS_VERSION-x86_64

    echo "{'$OS', '$OS_VERSION', '$LINUX_BINARY'}," >> $INDEX_NEW

    [ -f $RELEASE/$LINUX_BINARY ] && return

    local TAG=$(external/dockgen/dockgen.lua $OS $OS_VERSION lapp $LAPP_VERSION)
    docker run                                          \
        --privileged                                    \
        --volume $PWD:/mnt/app                          \
        -t -i "$TAG"                                    \
        lapp upp.lua lib/*.lua -o $RELEASE/$LINUX_BINARY
}

build_win()
{
    local OS="$1"
    local OS_VERSION="$2"
    local WINDOWS_BINARY=upp-win-x86_64.exe

    echo "{'Windows', '', '$WINDOWS_BINARY'}," >> $INDEX_NEW

    [ -f $RELEASE/$WINDOWS_BINARY ] && return

    local TAG=$(external/dockgen/dockgen.lua $OS $OS_VERSION lapp $LAPP_VERSION)
    docker run                                          \
        --privileged                                    \
        --volume $PWD:/mnt/app                          \
        -t -i "$TAG"                                    \
        lapp upp.lua lib/*.lua -o $RELEASE/$WINDOWS_BINARY
}

###############################################################################
# Generic portable bytecode
###############################################################################

build_generic()
{
    local BYTECODE=upp-generic.lc

    echo "{'Generic', 'luax', '$BYTECODE'}," >> $INDEX_NEW

    [ -f $RELEASE/$BYTECODE ] && return

    lapp upp.lua lib/*.lua -o $RELEASE/$BYTECODE
}

###############################################################################
# Build binaries for mainstream Linux distributions
###############################################################################

mkdir -p $RELEASE

echo "return {" > $INDEX_NEW

build debian 9
build debian 10
build debian 11

build ubuntu 20.04      # LTS
build ubuntu 21.04
build ubuntu 21.10
build ubuntu 22.04      # LTS

build fedora 34
build fedora 35
build fedora 36

build archlinux latest

build_win fedora 36

build_generic

echo "}" >> $INDEX_NEW

if ! [ -f $INDEX ] || diff -q $INDEX_NEW $INDEX
then
    mv $INDEX_NEW $INDEX
else
    rm $INDEX_NEW
fi
