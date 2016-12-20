CARTHAGE := /usr/local/bin/carthage
CARTHAGE_PLATFORM := iOS
CARTHAGE_CONFIGURATION := Release
CARTHAGE_DIR := Carthage
CARTHAGE_ARGS := --no-use-binaries
CARTHAGE_TOOLCHAIN := com.apple.dt.toolchain.Swift_3_0
CARTHAGE_CMDLINE := --configuration $(CARTHAGE_CONFIGURATION) --platform $(CARTHAGE_PLATFORM) --toolchain $(CARTHAGE_TOOLCHAIN) $(CARTHAGE_ARGS)
TRAVIS_COMMIT ?= master
TRAVIS_REPO_SLUG ?= stephencelis/SQLite.swift

test: $(CARTHAGE) Cartfile
	$< bootstrap $(CARTHAGE_CMDLINE)

Cartfile:
	echo 'github "$(TRAVIS_REPO_SLUG)" "$(TRAVIS_COMMIT)"' > $@
