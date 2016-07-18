#!/bin/bash
set -ev
if [ -n "$BUILD_SCHEME" ]; then
    make test BUILD_SCHEME="$BUILD_SCHEME"
elif [ -n "$VALIDATOR_SUBSPEC" ]; then
    cd CocoaPodsTests && make test
fi
