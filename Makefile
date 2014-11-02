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

sloc:
	@zsh -c "grep -vE '^ *//|^$$' SQLite\ Common/*.{swift,h,c} | wc -l"
