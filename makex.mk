# This file is part of makex.
#
# makex is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# makex is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with makex.  If not, see <https://www.gnu.org/licenses/>.
#
# For further information about makex you can visit
# http://cdelord.fr/makex

# Warning: this is a reduced version of makex.mk to install only UPP test
# dependencies.

###########################################################################
# Configuration
###########################################################################

#{{{
# makex defines some make variable that can be used to execute makex tools:
#
# LUAX
#     path to the LuaX interpretor (see https://github.com/CDSoft/luax)
#
# It also adds some targets:
#
# makex-clean
#     remove all makex tools
#
# help
#     runs the `welcome` target (user defined)
#     and lists the targets with their documentation

# The project configuration variables can be defined before including
# makex.mk.
#
# Makex update:
# wget http://cdelord.fr/makex/makex.mk

# MAKEX_INSTALL_PATH defines the path where tools are installed
MAKEX_INSTALL_PATH ?= /var/tmp/makex

# MAKEX_CACHE is the path where makex tools sources are stored and built
MAKEX_CACHE ?= /var/tmp/makex/cache

# MAKEX_HELP_TARGET_MAX_LEN is the maximal size of target names
# used to format the help message
MAKEX_HELP_TARGET_MAX_LEN ?= 20

# LUAX_VERSION is a tag or branch name in the LuaX repository
LUAX_VERSION ?= master

#}}}

###########################################################################
# Help
###########################################################################

.PHONY: help welcome

BLACK     := $(shell tput -Txterm setaf 0)
RED       := $(shell tput -Txterm setaf 1)
GREEN     := $(shell tput -Txterm setaf 2)
YELLOW    := $(shell tput -Txterm setaf 3)
BLUE      := $(shell tput -Txterm setaf 4)
PURPLE    := $(shell tput -Txterm setaf 5)
CYAN      := $(shell tput -Txterm setaf 6)
WHITE     := $(shell tput -Txterm setaf 7)
BG_BLACK  := $(shell tput -Txterm setab 0)
BG_RED    := $(shell tput -Txterm setab 1)
BG_GREEN  := $(shell tput -Txterm setab 2)
BG_YELLOW := $(shell tput -Txterm setab 3)
BG_BLUE   := $(shell tput -Txterm setab 4)
BG_PURPLE := $(shell tput -Txterm setab 5)
BG_CYAN   := $(shell tput -Txterm setab 6)
BG_WHITE  := $(shell tput -Txterm setab 7)
NORMAL    := $(shell tput -Txterm sgr0)

CMD_COLOR    := ${YELLOW}
TARGET_COLOR := ${GREEN}
TEXT_COLOR   := ${CYAN}
MAKEX_COLOR  := ${BLACK}${BG_CYAN}

## show this help massage
help: welcome
	@echo ''
	@echo 'Usage:'
	@echo '  ${CMD_COLOR}make${NORMAL} ${TARGET_COLOR}<target>${NORMAL}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
	    helpMessage = match(lastLine, /^## (.*)/); \
	    if (helpMessage) { \
	        helpCommand = substr($$1, 0, index($$1, ":")-1); \
	        helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
	        printf "  ${TARGET_COLOR}%-$(MAKEX_HELP_TARGET_MAX_LEN)s${NORMAL} ${TEXT_COLOR}%s${NORMAL}\n", helpCommand, helpMessage; \
	    } \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

.SECONDARY:

###########################################################################
# Cleaning makex directories
###########################################################################

makex-clean:
	@echo "$(MAKEX_COLOR)[MAKEX]$(NORMAL) $(TEXT_COLOR)clean$(NORMAL)"
	rm -rf $(MAKEX_INSTALL_PATH) $(MAKEX_CACHE)

###########################################################################
# makex directories
###########################################################################

$(MAKEX_CACHE) $(MAKEX_INSTALL_PATH):
	@mkdir -p $@

###########################################################################
# Host detection
###########################################################################

MAKEX_ARCH := $(shell uname -m)
MAKEX_OS := $(shell uname -s)

###########################################################################
# LuaX
###########################################################################

LUAX_URL = https://github.com/CDSoft/luax
LUAX = $(MAKEX_INSTALL_PATH)/luax/$(LUAX_VERSION)/luax

export PATH := $(dir $(LUAX)):$(PATH)

$(dir $(LUAX)):
	@mkdir -p $@

$(LUAX): | $(MAKEX_CACHE) $(dir $(LUAX))
	@echo "$(MAKEX_COLOR)[MAKEX]$(NORMAL) $(TEXT_COLOR)install LuaX$(NORMAL)"
	@test -f $(@) \
	|| \
	(   (   test -d $(MAKEX_CACHE)/luax \
	        && ( cd $(MAKEX_CACHE)/luax && git pull ) \
	        || git clone $(LUAX_URL) $(MAKEX_CACHE)/luax \
	    ) \
	    && cd $(MAKEX_CACHE)/luax \
	    && git checkout $(LUAX_VERSION) \
	    && make install-all PREFIX=$(realpath $(dir $@)) \
	)

makex-install: makex-install-luax
makex-install-luax: $(LUAX)
