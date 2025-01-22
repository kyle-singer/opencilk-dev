#!/bin/bash

READLINK=readlink

# Get the absolute path to this file
SCRIPT=$($READLINK -f "$0")

# Get the absolute path to the directory this file is in
SCRIPT_PATH=$(realpath $(dirname "${SCRIPT}"))

PROJ_ROOT=$(dirname "${SCRIPT_PATH}")
CHEETAH_ROOT=${PROJ_ROOT}/src/cheetah

set -x
set -e


LLVM_PATH="${PROJ_ROOT}/build/opencilk/bin"
C_COMPILER="${LLVM_PATH}/clang"
CXX_COMPILER="${LLVM_PATH}/clang++"
LLVM_CONFIG="${LLVM_PATH}/llvm-config"

BUILD_DIR_PATH="${PROJ_ROOT}/build/cheetah"
HANDCOMP_BUILD_DIR_PATH="${PROJ_ROOT}/build/handcomp_test"

HANDCOMP_BENCHES="fib mm_dac nqueens cilksort"
COMMON_CFLAGS="-Wall -O3"
COMMON_RUNTIME_CFLAGS="${COMMON_CFLAGS} -D_DEBUG -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -fno-semantic-interposition -Werror=date-time -Werror=unguarded-availability-new -Wextra -Wno-unused-parameter -Wwrite-strings -Wmissing-field-initializers -Wimplicit-fallthrough -Wcovered-switch-default -Wno-comment -Wstring-conversion -Wmisleading-indentation -Wctad-maybe-unsupported -ffunction-sections -fdata-sections -DNDEBUG -fPIC"

CMAKE_ARGS="-DCMAKE_C_COMPILER=${C_COMPILER} -DCMAKE_CXX_COMPILER=${CXX_COMPILER} -DLLVM_CONFIG_PATH=${LLVM_CONFIG} -DCMAKE_EXPORT_COMPILE_COMMANDS=On"

declare -A PREFIX_TO_RSRC_DIR
PREFIX_TO_RSRC_DIR[vanilla-sleep]=sleep-build
PREFIX_TO_RSRC_DIR[vanilla]=no-sleep-build

declare -A PREFIX_TO_FLAGS
PREFIX_TO_FLAGS[vanilla-sleep]="-DENABLE_THIEF_SLEEP=1 ${COMMON_RUNTIME_CFLAGS}"
PREFIX_TO_FLAGS[vanilla]="-DENABLE_THIEF_SLEEP=0 ${COMMON_RUNTIME_CFLAGS}"

rm -rf ${BUILD_DIR_PATH}
mkdir ${BUILD_DIR_PATH}

for prefix in "${!PREFIX_TO_RSRC_DIR[@]}"; do
    cd "${CHEETAH_ROOT}"

    CURR_BUILD_DIR="${BUILD_DIR_PATH}/${PREFIX_TO_RSRC_DIR[${prefix}]}"
    mkdir -p "${CURR_BUILD_DIR}"
    CURR_HANDCOMP_BUILD_DIR="${HANDCOMP_BUILD_DIR_PATH}/${PREFIX_TO_RSRC_DIR[${prefix}]}"
    mkdir -p "${CURR_HANDCOMP_BUILD_DIR}"

    cd "${CURR_BUILD_DIR}"

        CFLAGS="${PREFIX_TO_FLAGS[${prefix}]}" cmake ${CMAKE_ARGS} ${CHEETAH_ROOT}
        cmake --build . -- VERBOSE=1 -j

    cd "${CHEETAH_ROOT}"

    cd handcomp_test

    make -B RESOURCE_DIR="${CURR_BUILD_DIR}"
    for bench in ${HANDCOMP_BENCHES}; do
        mv ${bench} "${CURR_HANDCOMP_BUILD_DIR}/${bench}"
    done
done
