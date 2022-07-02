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

LAPP_VERSION=0.8.1

RELEASE=.build/release
INDEX=$RELEASE/upp_release.lua
INDEX_NEW=$RELEASE/upp_release.lua.new

set -ex

###############################################################################
# Native Linux binaries
###############################################################################

build_linux()
{
    local LINUX_ARCHIVE=upp-linux-x86_64.tar.gz

    echo "{'Linux', '$LINUX_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$LINUX_ARCHIVE ] && return

    lapp upp.lua lib/*.lua -o $RELEASE/upp
    tar czf $RELEASE/$LINUX_ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp
    rm $RELEASE/upp
}

build_win()
{
    local WINDOWS_ARCHIVE=upp-win-x86_64.zip

    echo "{'Windows', '$WINDOWS_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$WINDOWS_ARCHIVE ] && return

    lapp upp.lua lib/*.lua -o $RELEASE/upp.exe
    zip --junk-paths $RELEASE/$WINDOWS_ARCHIVE README.md $RELEASE/upp.exe
    rm $RELEASE/upp.exe
}

###############################################################################
# Generic portable bytecode
###############################################################################

build_generic()
{
    local BYTECODE_ARCHIVE=upp-generic.tar.gz

    echo "{'Generic bytecode', '$BYTECODE_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$BYTECODE_ARCHIVE ] && return

    lapp upp.lua lib/*.lua -o $RELEASE/upp.lc
    tar czf $RELEASE/$BYTECODE_ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp.lc
    rm $RELEASE/upp.lc
}

###############################################################################
# Build binaries for mainstream Linux distributions
###############################################################################

mkdir -p $RELEASE

echo "return {" > $INDEX_NEW

build_linux
build_win
build_generic

echo "}" >> $INDEX_NEW

if ! [ -f $INDEX ] || diff -q $INDEX_NEW $INDEX
then
    mv $INDEX_NEW $INDEX
else
    rm $INDEX_NEW
fi
