BUILD_TOOL = xcodebuild
BUILD_PLATFORM ?= Mac
BUILD_ARGUMENTS = -scheme 'SQLite $(BUILD_PLATFORM)'

XCPRETTY := $(shell command -v xcpretty)

default: test

build:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS)

test:
ifdef XCPRETTY
	@set -o pipefail && $(BUILD_TOOL) $(BUILD_ARGUMENTS) test | $(XCPRETTY) -c
else
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) test
endif

clean:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) clean

repl:
	@$(BUILD_TOOL) $(BUILD_ARGUMENTS) -derivedDataPath $(TMPDIR)/SQLite.swift > /dev/null 2>&1 && \
		swift -F '$(TMPDIR)/SQLite.swift/Build/Products/Debug'

sloc:
	@zsh -c "grep -vE '^ *//|^$$' SQLite\ Common/*.{swift,h,c} | wc -l"

