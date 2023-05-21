XCODEBUILD = xcodebuild
BUILD_SCHEME = SQLite Mac
IOS_SIMULATOR = iPhone 14
IOS_VERSION = 16.4

# tool settings
SWIFTLINT_VERSION=0.52.2
SWIFTLINT=bin/swiftlint-$(SWIFTLINT_VERSION)
SWIFTLINT_URL=https://github.com/realm/SwiftLint/releases/download/$(SWIFTLINT_VERSION)/portable_swiftlint.zip
XCBEAUTIFY_VERSION=0.20.0
XCBEAUTIFY=bin/xcbeautify-$(XCBEAUTIFY_VERSION)
ifeq ($(shell uname), Linux)
	XCBEAUTIFY_PLATFORM=x86_64-unknown-linux-gnu.tar.xz
else
	XCBEAUTIFY_PLATFORM=universal-apple-macosx.zip
endif
XCBEAUTIFY_URL=https://github.com/tuist/xcbeautify/releases/download/$(XCBEAUTIFY_VERSION)/xcbeautify-$(XCBEAUTIFY_VERSION)-$(XCBEAUTIFY_PLATFORM)
CURL_OPTS=--fail --silent -L --retry 3

ifeq ($(BUILD_SCHEME),SQLite iOS)
	BUILD_ARGUMENTS = -scheme "$(BUILD_SCHEME)" -destination "platform=iOS Simulator,name=$(IOS_SIMULATOR),OS=$(IOS_VERSION)"
else
	BUILD_ARGUMENTS = -scheme "$(BUILD_SCHEME)"
endif

test: $(XCBEAUTIFY)
	set -o pipefail; \
	$(XCODEBUILD) $(BUILD_ARGUMENTS) test | $(XCBEAUTIFY)

build: $(XCBEAUTIFY)
	set -o pipefail; \
	$(XCODEBUILD) $(BUILD_ARGUMENTS) | $(XCBEAUTIFY)

lint: $(SWIFTLINT)
	$< --strict

lint-fix: $(SWIFTLINT)
	$< lint fix

clean:
	$(XCODEBUILD) $(BUILD_ARGUMENTS) clean

repl:
	@$(XCODEBUILD) $(BUILD_ARGUMENTS) -derivedDataPath $(TMPDIR)/SQLite.swift > /dev/null && \
		swift repl -F '$(TMPDIR)/SQLite.swift/Build/Products/Debug'

sloc:
	@zsh -c "grep -vE '^ *//|^$$' Sources/**/*.{swift,h} | wc -l"

$(SWIFTLINT):
	set -e ; \
	curl $(CURL_OPTS) $(SWIFTLINT_URL) -o swiftlint.zip; \
	unzip -o swiftlint.zip swiftlint; \
	mkdir -p bin; \
	mv swiftlint $@ && rm -f swiftlint.zip

$(XCBEAUTIFY):
	set -e; \
	FILE=$(XCBEAUTIFY_PLATFORM); \
	curl $(CURL_OPTS) $(XCBEAUTIFY_URL) -o $$FILE; \
	case "$${FILE#*.}" in \
	  "zip") \
		unzip -o $$FILE xcbeautify; \
		;; \
	  "tar.xz") \
	  	tar -xvf $$FILE xcbeautify; \
		;; \
	  *) \
		echo "unknown extension $${FILE#*.}!"; \
		exit 1; \
		;; \
	esac; \
	mkdir -p bin; \
	mv xcbeautify $@ && rm -f $$FILE;

.PHONY: test clean repl sloc
