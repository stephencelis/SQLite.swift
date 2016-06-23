#!/bin/bash
set -ev
if [ -n "$BUILD_SCHEME" ]; then
    make test
elif [ -n "$VALIDATOR_SUBSPEC" ]; then
    cd CocoaPodsTests && make test
fi 