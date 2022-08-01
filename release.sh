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

RELEASE=.build/release
INDEX=$RELEASE/upp_release.lua
INDEX_NEW=$RELEASE/upp_release.lua.new

set -ex

###############################################################################
# Native Linux/MacOS/Windows binaries
###############################################################################

build_linux_intel()
{
    local LINUX_ARCHIVE=upp-linux-x86_64.tar.gz

    echo "{'Linux x86_64', '$LINUX_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$LINUX_ARCHIVE ] && return

    luax -o $RELEASE/upp -t luax-x86_64-linux-musl upp.lua lib/*.lua
    tar czf $RELEASE/$LINUX_ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp
    rm $RELEASE/upp
}

build_linux_arm()
{
    local LINUX_ARCHIVE=upp-linux-aarch64.tar.gz

    echo "{'Linux aarch64', '$LINUX_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$LINUX_ARCHIVE ] && return

    luax -o $RELEASE/upp -t luax-aarch64-linux-musl upp.lua lib/*.lua
    tar czf $RELEASE/$LINUX_ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp
    rm $RELEASE/upp
}

build_macos_intel()
{
    local LINUX_ARCHIVE=upp-macos-x86_64.tar.gz

    echo "{'MacOS x86_64', '$LINUX_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$LINUX_ARCHIVE ] && return

    luax -o $RELEASE/upp -t luax-x86_64-macos-gnu upp.lua lib/*.lua
    tar czf $RELEASE/$LINUX_ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp
    rm $RELEASE/upp
}

build_macos_arm()
{
    local LINUX_ARCHIVE=upp-macos-aarch64.tar.gz

    echo "{'MacOS aarch64', '$LINUX_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$LINUX_ARCHIVE ] && return

    luax -o $RELEASE/upp -t luax-aarch64-macos-gnu upp.lua lib/*.lua
    tar czf $RELEASE/$LINUX_ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp
    rm $RELEASE/upp
}

build_win()
{
    local WINDOWS_ARCHIVE=upp-win-x86_64.zip

    echo "{'Windows', '$WINDOWS_ARCHIVE'}," >> $INDEX_NEW

    [ -f $RELEASE/$WINDOWS_ARCHIVE ] && return

    luax -o $RELEASE/upp.exe -t luax-x86_64-windows-gnu.exe upp.lua lib/*.lua
    zip --junk-paths $RELEASE/$WINDOWS_ARCHIVE README.md $RELEASE/upp.exe
    rm $RELEASE/upp.exe
}

###############################################################################
# Build binaries
###############################################################################

mkdir -p $RELEASE

echo "return {" > $INDEX_NEW

build_linux_intel
build_linux_arm
build_macos_intel
build_macos_arm
build_win

echo "}" >> $INDEX_NEW

if ! [ -f $INDEX ] || diff -q $INDEX_NEW $INDEX
then
    mv $INDEX_NEW $INDEX
else
    rm $INDEX_NEW
fi
