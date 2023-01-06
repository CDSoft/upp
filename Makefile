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

PREFIX ?= $(HOME)/.local/bin
BUILD = .build

UPP = $(BUILD)/upp

LIBS = $(sort $(wildcard lib/*))

# avoid being polluted by user definitions
export LUA_PATH := ./?.lua

all: compile
all: test

clean:
	rm -rf $(BUILD)

####################################################################
# Compilation
####################################################################

compile: $(UPP)

# Use LuaX from makex if available
LUAX ?= luax

$(UPP): upp.lua $(LIBS)
	@mkdir -p $(dir $@)
	$(LUAX) -o $@ upp.lua -autoload-all $(LIBS)

####################################################################
# Installation
####################################################################

.PHONY: install

install: $(PREFIX)/upp

$(PREFIX)/upp: $(UPP)
	install $^ $@

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

$(BUILD)/test.md $(BUILD)/test.d $(BUILD)/test-complement.txt $(BUILD)/other_file.md &: $(UPP) tests/test.md tests/test2.md tests/test_include.md tests/test_lib.lua Makefile
	@mkdir -p $(BUILD)
	UPP_PATH=tests $(UPP) -p tests -p lib -e 'build="$(BUILD)"' -e 'foo="bar"' -l test_lib.lua tests/test.md tests/test2.md -o $(word 1,$@) -MT fictive_target -MT $(BUILD)/non_discoverable_target.txt -MD

####################################################################
# Tests: pluggin example (unit tests generation)
####################################################################

test_unit_tests: $(BUILD)/unit_tests.c tests/unit_tests_result.c
	diff $^

diff_unit_tests: $(BUILD)/unit_tests.c tests/unit_tests_result.c
	diff -q $^ || meld $^

$(BUILD)/unit_tests.c: $(UPP) examples/unit_tests.lua tests/unit_tests.c Makefile
	@mkdir -p $(BUILD)
	$(UPP) -p examples -l unit_tests.lua tests/unit_tests.c -o $@
	clang-format -i $@

####################################################################
# Tests: req pluggin
####################################################################

test: test_req_spec test_req_code test_req_test test_req_cov
diff: diff_req_spec diff_req_code diff_req_test diff_req_cov

export REQDB = $(BUILD)/reqdb.lua

# Spec

test_req_spec: $(BUILD)/test_req_spec.md tests/test_req_spec_result.md
	diff $^

diff_req_spec: $(BUILD)/test_req_spec.md tests/test_req_spec_result.md
	diff -q $^ || meld $^

$(BUILD)/test_req_spec.md: $(UPP) tests/test_req_spec.md Makefile
	@mkdir -p $(BUILD)
	REQTARGET=$(notdir $@) $(UPP) tests/test_req_spec.md -o $@

# Code

test_req_code: $(BUILD)/test_req_code.md tests/test_req_code_result.md
	diff $^

diff_req_code: $(BUILD)/test_req_code.md tests/test_req_code_result.md
	diff -q $^ || meld $^

$(BUILD)/test_req_code.md: $(UPP) tests/test_req_code.md Makefile
	@mkdir -p $(BUILD)
	REQTARGET=$(notdir $@) $(UPP) tests/test_req_code.md -o $@

# Test

test_req_test: $(BUILD)/test_req_test.md tests/test_req_test_result.md
	diff $^

diff_req_test: $(BUILD)/test_req_test.md tests/test_req_test_result.md
	diff -q $^ || meld $^

$(BUILD)/test_req_test.md: $(UPP) tests/test_req_test.md Makefile
	@mkdir -p $(BUILD)
	REQTARGET=$(notdir $@) $(UPP) tests/test_req_test.md -o $@

# Cov

test_req_cov: $(BUILD)/test_req_cov.md tests/test_req_cov_result.md
	diff $^

diff_req_cov: $(BUILD)/test_req_cov.md tests/test_req_cov_result.md
	diff -q $^ || meld $^

$(BUILD)/test_req_cov.md: $(UPP) tests/test_req_cov.md Makefile
	@mkdir -p $(BUILD)
	REQTARGET=$(notdir $@) $(UPP) tests/test_req_cov.md -o $@

####################################################################
# Binaries (for the latests Fedora and Ubuntu versions)
####################################################################

.PHONY: release

release: $(BUILD)/release/upp_release.lua

$(BUILD)/release/upp%: release.sh upp.lua $(LIBS)
	./release.sh
