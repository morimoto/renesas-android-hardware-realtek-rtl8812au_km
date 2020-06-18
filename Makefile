#
# This Makefile contain kbuild build system parts, related to configuration
# (menuconfig, *_defconfig, etc.). Flags and options hadling and build targets
# located in build.mk. build.mk should be synced with Makefile from aircrack-ng
# repository after driver version update (new files, flags, defines, etc.).
# There is no need to change this file after driver sources update.
#

# We want bash as shell
SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	 else if [ -x /bin/bash ]; then echo /bin/bash; \
	 else echo sh; fi; fi)

# Set O variable if not already done on the command line;
# or avoid confusing packages that can use the O=<dir> syntax for out-of-tree
# build by preventing it from being forwarded to sub-make calls.
ifneq ("$(origin O)", "command line")
O := $(CURDIR)/output
endif

override O := $(patsubst %/,%,$(patsubst %.,%,$(O)))
# Make sure $(O) actually exists before calling realpath on it; this is to
# avoid empty CANONICAL_O in case on non-existing entry.
CANONICAL_O := $(shell mkdir -p $(O) >/dev/null 2>&1)$(realpath $(O))

CANONICAL_CURDIR = $(realpath $(CURDIR))
WORKDIR ?= $(CANONICAL_CURDIR)
REQ_UMASK = 0022

# Make sure O= is passed (with its absolute canonical path) everywhere the
# toplevel makefile is called back.
EXTRAMAKEARGS := O=$(CANONICAL_O)

ifneq ($(shell umask):$(CURDIR):$(O),$(REQ_UMASK):$(CANONICAL_CURDIR):$(CANONICAL_O))

.PHONY: _all $(MAKECMDGOALS)

$(MAKECMDGOALS): _all
	@:

_all:
	@umask $(REQ_UMASK) && \
		$(MAKE) -C $(CANONICAL_CURDIR) --no-print-directory \
			$(MAKECMDGOALS) $(EXTRAMAKEARGS)

else # umask / $(CURDIR) / $(O)

# This is our default rule, so must come first
all: modules

.PHONY: all

# Save running make version since it's clobbered by the make package
RUNNING_MAKE_VERSION := $(MAKE_VERSION)

# Check for minimal make version (note: this check will break at make 10.x)
MIN_MAKE_VERSION = 3.81
ifneq ($(firstword $(sort $(RUNNING_MAKE_VERSION) $(MIN_MAKE_VERSION))),$(MIN_MAKE_VERSION))
$(error You have make '$(RUNNING_MAKE_VERSION)' installed. GNU make >= $(MIN_MAKE_VERSION) is required)
endif

# absolute path
TOPDIR := $(CURDIR)
CONFIG_CONFIG_IN = Kconfig
CONFIG = support/kconfig
DATE := $(shell date +%Y%m%d)

# List of targets and target patterns for which .config doesn't need to be read in
noconfig_targets := menuconfig nconfig gconfig xconfig config oldconfig randconfig \
	defconfig %_defconfig allyesconfig allnoconfig alldefconfig syncconfig \
	print-version olddefconfig distclean

# Some global targets do not trigger a build, but are used to collect
# metadata, or do various checks. When such targets are triggered,
# some packages should not do their configuration sanity
# checks. Provide them a BR_BUILDING variable set to 'y' when we're
# actually building and they should do their sanity checks.
#
# We're building in two situations: when MAKECMDGOALS is empty
# (default target is to build), or when MAKECMDGOALS contains
# something else than one of the nobuild_targets.
nobuild_targets := clean distclean help \
	list-defconfigs \
	savedefconfig

# Include some helper macros and variables
-include support/misc/utils.mk

# Set variables related to in-tree or out-of-tree build.
# Here, both $(O) and $(CURDIR) are absolute canonical paths.
ifeq ($(O),$(CURDIR)/output)
CONFIG_DIR := $(CURDIR)
else
CONFIG_DIR := $(O)
endif

BASE_DIR := $(CANONICAL_O)
$(if $(BASE_DIR),, $(error output directory "$(O)" does not exist))

BUILD_DIR := $(BASE_DIR)/build
BR2_CONFIG = $(CONFIG_DIR)/.config

# Pull in the user's configuration file
ifeq ($(filter $(noconfig_targets),$(MAKECMDGOALS)),)
-include $(BR2_CONFIG)
endif

# To put more focus on warnings, be less verbose as default
# Use 'make V=1' to see the full commands
ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  Q =
ifndef VERBOSE
  VERBOSE = 1
endif
export VERBOSE
else
  Q = @
endif

# kconfig uses CONFIG_SHELL
CONFIG_SHELL := $(SHELL)

export SHELL CONFIG_SHELL Q KBUILD_VERBOSE

ifndef HOSTCC
HOSTCC := gcc
HOSTCC := $(shell which $(HOSTCC) || type -p $(HOSTCC) || echo gcc)
endif
HOSTCC_NOCCACHE := $(HOSTCC)

ifndef HOSTCXX
HOSTCXX := g++
HOSTCXX := $(shell which $(HOSTCXX) || type -p $(HOSTCXX) || echo g++)
endif
HOSTCXX_NOCCACHE := $(HOSTCXX)

HOSTCPP := $(shell which $(HOSTCPP) || type -p $(HOSTCPP) || echo cpp)
SED := $(shell which sed || type -p sed) -i -e

export HOSTCC HOSTCXX
export HOSTCC_NOCCACHE HOSTCXX_NOCCACHE

# When adding a new host gcc version in Config.in,
# update the HOSTCC_MAX_VERSION variable:
HOSTCC_MAX_VERSION := 8

HOSTCC_VERSION := $(shell V=$$($(HOSTCC_NOCCACHE) --version | \
	sed -n -r 's/^.* ([0-9]*)\.([0-9]*)\.([0-9]*)[ ]*.*/\1 \2/p'); \
	[ "$${V%% *}" -le $(HOSTCC_MAX_VERSION) ] || V=$(HOSTCC_MAX_VERSION); \
	printf "%s" "$${V}")

# For gcc >= 5.x, we only need the major version.
ifneq ($(firstword $(HOSTCC_VERSION)),4)
HOSTCC_VERSION := $(firstword $(HOSTCC_VERSION))
endif

ifeq ($(BR2_HAVE_DOT_CONFIG),y)

# silent mode requested?
QUIET := $(if $(findstring s,$(filter-out --%,$(MAKEFLAGS))),-q)

# Scripts in support/ or post-build scripts may need to reference
# these locations, so export them so it is easier to use
export BR2_CONFIG

endif # ifeq ($(BR2_HAVE_DOT_CONFIG),y)
HOSTCFLAGS = $(CFLAGS_FOR_BUILD)
export HOSTCFLAGS

$(BUILD_DIR)/driver-config/%onf:
	$(Q)mkdir -p $(@D)/lxdialog
	$(Q) PKG_CONFIG_PATH="$(HOST_PKG_CONFIG_PATH)" $(MAKE) CC="$(HOSTCC_NOCCACHE)" HOSTCC="$(HOSTCC_NOCCACHE)" \
	    obj=$(@D) -C $(CONFIG) -f Makefile.br $(@F)

DEFCONFIG = $(call qstrip,$(BR2_DEFCONFIG))

# We don't want to fully expand BR2_DEFCONFIG here, so Kconfig will
# recognize that if it's still at its default $(CONFIG_DIR)/defconfig
COMMON_CONFIG_ENV = \
	BR2_DEFCONFIG='$(call qstrip,$(value BR2_DEFCONFIG))' \
	KCONFIG_AUTOCONFIG=$(BUILD_DIR)/driver-config/auto.conf \
	KCONFIG_AUTOHEADER=$(BUILD_DIR)/driver-config/autoconf.h \
	KCONFIG_TRISTATE=$(BUILD_DIR)/driver-config/tristate.config \
	BR2_CONFIG=$(BR2_CONFIG) \
	HOST_GCC_VERSION="$(HOSTCC_VERSION)" \
	BUILD_DIR=$(BUILD_DIR) \
	SKIP_LEGACY=

menuconfig: $(BUILD_DIR)/driver-config/mconf
	@$(COMMON_CONFIG_ENV) $< $(CONFIG_CONFIG_IN)

config: $(BUILD_DIR)/driver-config/conf
	@$(COMMON_CONFIG_ENV) $< $(CONFIG_CONFIG_IN)

randconfig allyesconfig alldefconfig allnoconfig: $(BUILD_DIR)/driver-config/conf
	@$(COMMON_CONFIG_ENV) SKIP_LEGACY=y $< --$@ $(CONFIG_CONFIG_IN)
	@$(COMMON_CONFIG_ENV) $< --olddefconfig $(CONFIG_CONFIG_IN) >/dev/null

oldconfig syncconfig olddefconfig: $(BUILD_DIR)/driver-config/conf
	@$(COMMON_CONFIG_ENV) $< --$@ $(CONFIG_CONFIG_IN)

defconfig: $(BUILD_DIR)/driver-config/conf
	@$(COMMON_CONFIG_ENV) $< --defconfig$(if $(DEFCONFIG),=$(DEFCONFIG)) $(CONFIG_CONFIG_IN)

define percent_defconfig
# Override the BR2_DEFCONFIG from COMMON_CONFIG_ENV with the new defconfig
%_defconfig: $(BUILD_DIR)/driver-config/conf $(1)/configs/%_defconfig
	@$$(COMMON_CONFIG_ENV) BR2_DEFCONFIG=$(1)/configs/$$@ \
		$$< --defconfig=$(1)/configs/$$@ $$(CONFIG_CONFIG_IN)
endef
$(eval $(foreach d,$(call reverse,$(TOPDIR) $(BR2_EXTERNAL_DIRS)),$(call percent_defconfig,$(d))$(sep)))

savedefconfig: $(BUILD_DIR)/driver-config/conf
	@$(COMMON_CONFIG_ENV) $< \
		--savedefconfig=$(if $(DEFCONFIG),$(DEFCONFIG),$(CONFIG_DIR)/defconfig) \
		$(CONFIG_CONFIG_IN)
	@$(SED) '/BR2_DEFCONFIG=/d' $(if $(DEFCONFIG),$(DEFCONFIG),$(CONFIG_DIR)/defconfig)

.PHONY: defconfig savedefconfig

.PHONY: clean
clean: modclean
	@ echo "Cleaning configuration artifacts..."
	$(Q) rm -rf $(BUILD_DIR)

.PHONY: distclean
distclean: clean
ifeq ($(O),$(CURDIR)/output)
	$(Q) rm -rf $(O)
endif
	$(Q) rm -rf $(TOPDIR)/dl $(BR2_CONFIG) $(CONFIG_DIR)/.config.old $(CONFIG_DIR)/..config.tmp \
		$(CONFIG_DIR)/.auto.deps $(BR2_EXTERNAL_FILE)

.PHONY: help
help:
	@echo 'Cleaning:'
	@echo '  clean                  - delete all files created by build'
	@echo '  distclean              - delete all non-source files (including .config)'
	@echo
	@echo 'Configuration:'
	@echo '  menuconfig             - interactive curses-based configurator'
	@echo '  oldconfig              - resolve any unresolved symbols in .config'
	@echo '  syncconfig             - Same as oldconfig, but quietly, additionally update deps'
	@echo '  olddefconfig           - Same as syncconfig but sets new symbols to their default value'
	@echo '  randconfig             - New config with random answer to all options'
	@echo '  defconfig              - New config with default answer to all options;'
	@echo '                             BR2_DEFCONFIG, if set on the command line, is used as input'
	@echo '  savedefconfig          - Save current config to BR2_DEFCONFIG (minimal config)'
	@echo '  allyesconfig           - New config where all options are accepted with yes'
	@echo '  allnoconfig            - New config where all options are answered with no'
	@echo '  alldefconfig           - New config where all options are set to default'

# List the defconfig files
# $(1): base directory
# $(2): br2-external name, empty for bundled
define list-defconfigs
	@first=true; \
	for defconfig in $(1)/configs/*_defconfig; do \
		[ -f "$${defconfig}" ] || continue; \
		if $${first}; then \
			if [ "$(2)" ]; then \
				printf 'External configs in "$(call qstrip,$(2))":\n'; \
			else \
				printf "Built-in configs:\n"; \
			fi; \
			first=false; \
		fi; \
		defconfig="$${defconfig##*/}"; \
		printf "  %-35s - Build for %s\n" "$${defconfig}" "$${defconfig%_defconfig}"; \
	done; \
	$${first} || printf "\n"
endef

# We iterate over BR2_EXTERNAL_NAMES rather than BR2_EXTERNAL_DIRS,
# because we want to display the name of the br2-external tree.
.PHONY: list-defconfigs
list-defconfigs:
	$(call list-defconfigs,$(TOPDIR))
	$(foreach name,$(BR2_EXTERNAL_NAMES),\
		$(call list-defconfigs,$(BR2_EXTERNAL_$(name)_PATH),\
			$(BR2_EXTERNAL_$(name)_DESC))$(sep))

.PHONY: $(noconfig_targets)

# This Makefile contain all build logic required for driver, should be synced with aircrack-ng Makefile
include $(WORKDIR)/build.mk

endif #umask / $(CURDIR) / $(O)
