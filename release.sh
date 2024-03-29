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

RELEASE=.build/release
INDEX=$RELEASE/upp_release.lua
INDEX_NEW=$RELEASE/upp_release.lua.new

set -e

###############################################################################
# Native Linux/MacOS/Windows binaries
###############################################################################

build()
{
    local ARCH=$1
    local OS=$2
    local LIBC=$3

    local ARCHIVE
    case $OS in
        (windows)   ARCHIVE=upp-$ARCH-$OS-$LIBC.zip ;;
        (*)         ARCHIVE=upp-$ARCH-$OS-$LIBC.tar.xz ;;
    esac

    echo "{'$OS', '$ARCH', '$LIBC', '$ARCHIVE'}," >> $INDEX_NEW

    case $OS-$LIBC in
        (windows-*)
            luax -o $RELEASE/upp.exe -t $ARCH-$OS-$LIBC upp.lua lib/*.lua
            zip -9 --junk-paths $RELEASE/$ARCHIVE README.md $RELEASE/upp.exe
            rm $RELEASE/upp.exe
            ;;
        (linux-gnu)
            luax -o $RELEASE/upp -t $ARCH-$OS-$LIBC upp.lua lib/*.lua
            SHARED_LIB=$(lddtree $RELEASE/upp 2>/dev/null | awk '$1~/libluaxruntime/ { print $3 }')
            XZ_OPT=-9 tar cJf $RELEASE/$ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp $SHARED_LIB
            rm $RELEASE/upp
            ;;
        (*)
            luax -o $RELEASE/upp -t $ARCH-$OS-$LIBC upp.lua lib/*.lua
            XZ_OPT=-9 tar cJf $RELEASE/$ARCHIVE --transform="s#.*/##" README.md $RELEASE/upp
            rm $RELEASE/upp
            ;;
    esac
}

###############################################################################
# Build binaries
###############################################################################

mkdir -p $RELEASE

echo "return {" > $INDEX_NEW

build x86_64  linux gnu
build i386    linux gnu
build aarch64 linux gnu

build x86_64  linux musl
build i386    linux musl
build aarch64 linux musl

build x86_64  macos gnu
build aarch64 macos gnu

build x86_64  windows gnu
build i386    windows gnu

echo "}" >> $INDEX_NEW

if ! [ -f $INDEX ] || ! diff -q $INDEX_NEW $INDEX
then
    mv $INDEX_NEW $INDEX
else
    rm $INDEX_NEW
fi

exa --color=always -lh $RELEASE
bat --force-colorization --paging=never $INDEX
