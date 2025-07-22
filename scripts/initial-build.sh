#!/bin/sh

SCRIPT_DIR=$(dirname "${0}")/..

cd ${SCRIPT_DIR}

CCACHE=$(which ccache)

CMAKE_C_COMPILER_LAUNCHER=${CCACHE} CMAKE_CXX_COMPILER_LAUNCHER=${CCACHE} OPENCILK_RELEASE=RelWithDebInfo ./scripts/infrastructure/tools/build $(pwd)/src/opencilk $(pwd)/build/opencilk $(nproc)
