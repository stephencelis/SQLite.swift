#!/bin/bash
set -ev
if [ $RUN_TESTS == "YES" ]; then
  # Build Framework in Debug and Run Tests if specified
  make test BUILD_SCHEME="$SCHEME" BUILD_SDK="$SDK" BUILD_DESTINATION="$DESTINATION" BUILD_CONFIGURATION=Debug
  # Build Framework in Release and Run Tests if specified
  make test BUILD_SCHEME="$SCHEME" BUILD_SDK="$SDK" BUILD_DESTINATION="$DESTINATION" BUILD_CONFIGURATION=Release
else
  # Build Framework in Debug
  make build BUILD_SCHEME="$SCHEME" BUILD_SDK="$SDK" BUILD_DESTINATION="$DESTINATION" BUILD_CONFIGURATION=Debug
  # Build Framework in Release
  make build BUILD_SCHEME="$SCHEME" BUILD_SDK="$SDK" BUILD_DESTINATION="$DESTINATION" BUILD_CONFIGURATION=Release
fi
