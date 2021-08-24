BUILD_TOOL = xcodebuild
BUILD_SCHEME = SQLite Mac
IOS_SIMULATOR = iPhone 12
IOS_VERSION = 14.4
ifeq ($(BUILD_SCHEME),SQLite iOS)
	BUILD_ARGUMENTS = -scheme "$(BUILD_SCHEME)" -destination "platform=iOS Simulator,name=$(IOS_SIMULATOR),OS=$(IOS_VERSION)"
else
	BUILD_ARGUMENTS = -scheme "$(BUILD_SCHEME)"
endif

XCPRETTY := $(shell command -v xcpretty)
TEST_ACTIONS := clean build build-for-testing test-without-building

default: test

build:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS)

lint:
	swiftlint --strict

test:
ifdef XCPRETTY
	@set -o pipefail && $(BUILD_TOOL) $(BUILD_ARGUMENTS) $(TEST_ACTIONS) | $(XCPRETTY) -c
else
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) $(TEST_ACTIONS)
endif

clean:
	$(BUILD_TOOL) $(BUILD_ARGUMENTS) clean

repl:
	@$(BUILD_TOOL) $(BUILD_ARGUMENTS) -derivedDataPath $(TMPDIR)/SQLite.swift > /dev/null && \
		swift -F '$(TMPDIR)/SQLite.swift/Build/Products/Debug'

sloc:
	@zsh -c "grep -vE '^ *//|^$$' Sources/**/*.{swift,h,m} | wc -l"

.PHONY: test clean repl sloc
