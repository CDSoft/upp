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
LIB_INSTALL_PATH = $(dir $(INSTALL_PATH))/lib/upp
BUILD = .build

LIBS = $(wildcard lib/*)

all: test

.PHONY: install

install:
	install upp ${INSTALL_PATH}/
	mkdir -p ${LIB_INSTALL_PATH}/
	install lib/* ${LIB_INSTALL_PATH}/

.PHONY: test

test: test_upp test_unit_tests
	# Well done

test_upp: ${BUILD}/test.md tests/test_result.md
	diff $^

test_unit_tests: ${BUILD}/unit_tests.c tests/unit_tests_result.c
	diff $^

${BUILD}/test.md: upp tests/test.md tests/test_include.md tests/test_lib.lua Makefile $(LIBS)
	@mkdir -p ${BUILD}
	UPP_PATH=tests ./upp -p tests -p lib -e 'foo="bar"' -l test_lib.lua tests/test.md -o $@

${BUILD}/unit_tests.c: upp examples/unit_tests.lua tests/unit_tests.c Makefile
	@mkdir -p ${BUILD}
	./upp -p examples -l unit_tests.lua tests/unit_tests.c -o $@
	clang-format -i $@

.PHONY: diff

diff: diff_test diff_unit_tests

diff_test: ${BUILD}/test.md tests/test_result.md
	diff -q $^ || meld $^

diff_unit_tests: ${BUILD}/unit_tests.c tests/unit_tests_result.c
	diff -q $^ || meld $^

.PHONY: doc
