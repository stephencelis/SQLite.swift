BUILD_TOOL = xcodebuild
BUILD_PLATFORM ?= Mac
BUILD_ARGUMENTS = -scheme 'SQLite $(BUILD_PLATFORM)'

default: test

build:
	@$(BUILD_TOOL) $(BUILD_ARGUMENTS)

test:
	@$(BUILD_TOOL) $(BUILD_ARGUMENTS) test

clean:
	@$(BUILD_TOOL) $(BUILD_ARGUMENTS) clean

sloc:
	@zsh -c "grep -vE '^ *//|^$$' SQLite\ Common/*.{swift,h,c} | wc -l"
