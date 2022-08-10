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

clean:
	rm -rf $(BUILD)

####################################################################
# Installation
####################################################################

.PHONY: install install_sources

install_sources:
	install -T upp.lua $(INSTALL_PATH)/upp
	mkdir -p $(LIB_INSTALL_PATH)/
	install lib/* $(LIB_INSTALL_PATH)/

install:
	luax -o $(INSTALL_PATH)/upp upp.lua $(patsubst %,-autoload %,$(LIBS))

####################################################################
# Tests
####################################################################

.PHONY: test

test: test_upp test_upp_deps test_upp_non_discoverable_target
test: test_upp_multiple_outputs_1 test_upp_multiple_outputs_2
test: test_unit_tests
test:
	# Well done

.PHONY: diff

diff: diff_test diff_test_deps diff_test_upp_non_discoverable_target
diff: diff_test_multiple_outputs_1 diff_test_multiple_outputs_2
diff: diff_unit_tests

####################################################################
# Tests: generic upp tests + multiple output files
####################################################################

test_upp: $(BUILD)/test.md tests/test_result.md
	diff $^

test_upp_deps: $(BUILD)/test.d tests/test_result.d
	diff $^

test_upp_non_discoverable_target: $(BUILD)/non_discoverable_target.txt tests/non_discoverable_target_result.txt
	diff $^

test_upp_multiple_outputs_1: $(BUILD)/test-complement.txt tests/test_result-complmement.txt
	diff $^

test_upp_multiple_outputs_2: $(BUILD)/other_file.md tests/test_result_other_file.md
	diff $^

diff_test_deps: $(BUILD)/test.d tests/test_result.d
	diff -q $^ || meld $^

diff_test: $(BUILD)/test.md tests/test_result.md
	diff -q $^ || meld $^

diff_test_upp_non_discoverable_target: $(BUILD)/non_discoverable_target.txt tests/non_discoverable_target_result.txt
	diff -q $^ || meld $^

diff_test_multiple_outputs_1: $(BUILD)/test-complement.txt tests/test_result-complmement.txt
	diff -q $^ || meld $^

diff_test_multiple_outputs_2: $(BUILD)/other_file.md tests/test_result_other_file.md
	diff -q $^ || meld $^

$(BUILD)/test.md $(BUILD)/test.d $(BUILD)/test-complement.txt $(BUILD)/other_file.md &: upp.lua tests/test.md tests/test2.md tests/test_include.md tests/test_lib.lua Makefile $(LIBS)
	@mkdir -p $(BUILD)
	UPP_PATH=tests ./upp.lua -p tests -p lib -e 'build="$(BUILD)"' -e 'foo="bar"' -l test_lib.lua tests/test.md tests/test2.md -o $(word 1,$@) -MT fictive_target -MT $(BUILD)/non_discoverable_target.txt -MD

####################################################################
# Tests: pluggin example (unit tests generation)
####################################################################

test_unit_tests: $(BUILD)/unit_tests.c tests/unit_tests_result.c
	diff $^

diff_unit_tests: $(BUILD)/unit_tests.c tests/unit_tests_result.c
	diff -q $^ || meld $^

$(BUILD)/unit_tests.c: upp.lua examples/unit_tests.lua tests/unit_tests.c Makefile
	@mkdir -p $(BUILD)
	./upp.lua -p examples -l unit_tests.lua tests/unit_tests.c -o $@
	clang-format -i $@

####################################################################
# Binaries (for the latests Fedora and Ubuntu versions)
####################################################################

.PHONY: release

release: $(BUILD)/release/upp_release.lua

$(BUILD)/release/upp%: release.sh upp.lua $(LIBS)
	./release.sh
