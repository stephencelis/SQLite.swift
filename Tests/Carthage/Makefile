CARTHAGE := $(shell which carthage)
CARTHAGE_PLATFORM := iOS
CARTHAGE_CONFIGURATION := Release
CARTHAGE_DIR := Carthage
CARTHAGE_ARGS := --no-use-binaries --use-xcframeworks
# CARTHAGE_TOOLCHAIN := com.apple.dt.toolchain.Swift_3_0
CARTHAGE_TOOLCHAIN := com.apple.dt.toolchain.XcodeDefault
CARTHAGE_CMDLINE := --configuration $(CARTHAGE_CONFIGURATION) --platform $(CARTHAGE_PLATFORM) --toolchain $(CARTHAGE_TOOLCHAIN) $(CARTHAGE_ARGS)

test: $(CARTHAGE) Cartfile
	$< bootstrap $(CARTHAGE_CMDLINE)

Cartfile:
	echo 'git "$(GITHUB_WORKSPACE)" "HEAD"' > $@

clean:
	@rm -f Cartfile Cartfile.resolved
