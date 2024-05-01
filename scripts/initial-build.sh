#!/bin/sh

SCRIPT_DIR=$(dirname "${0}")/..

cd ${SCRIPT_DIR}

./scripts/infrastructure/tools/build $(pwd)/src/opencilk $(pwd)/build/opencilk $(expr $(nproc) / 2)
