#!/bin/bash
set -ev
if [ -n "$BUILD_SCHEME" ]; then
    if [ -n "$IOS_SIMULATOR" ]; then
        make test BUILD_SCHEME="$BUILD_SCHEME" IOS_SIMULATOR="$IOS_SIMULATOR"
    else
        make test BUILD_SCHEME="$BUILD_SCHEME"
    fi
elif [ -n "$VALIDATOR_SUBSPEC" ]; then
    cd CocoaPodsTests && make test
fi
