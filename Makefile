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

INSTALL_PATH = $(HOME)/.local/bin
BUILD = .build

all: test

.PHONY: install

install:
	install upp ${INSTALL_PATH}/

.PHONY: test

test: ${BUILD}/test.md tests/test_result.md
	diff ${BUILD}/test.md tests/test_result.md
	# Well done

${BUILD}/test.md: upp tests/test.md tests/test_include.md tests/test_lib.lua Makefile
	@mkdir -p ${BUILD}
	UPP_PATH=tests ./upp -p tests -e 'foo="bar"' -l test_lib.lua tests/test.md -o ${BUILD}/test.md

.PHONY: diff

diff: ${BUILD}/test.md tests/test_result.md
	meld $^

.PHONY: doc
