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
COMMON_CFLAGS="-O3"
#COMMON_RUNTIME_CFLAGS="-falign-functions=32"
#COMMON_RUNTIME_CFLAGS="${COMMON_CFLAGS} --target=$(${LLVM_CONFIG} --host-target) -D_DEBUG -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -fno-semantic-interposition -Werror=date-time -Werror=unguarded-availability-new -Wextra -Wno-unused-parameter -Wwrite-strings -Wmissing-field-initializers -Wimplicit-fallthrough -Wcovered-switch-default -Wno-comment -Wstring-conversion -Wmisleading-indentation -Wctad-maybe-unsupported -ffunction-sections -fdata-sections -DNDEBUG -fPIC"
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

#make clean

#CFLAGS="-DVANILLA_THIEF_SLEEP=1 ${COMMON_CFLAGS}" make -B -C runtime
#mkdir -p ${BUILD_DIR_PATH}/sleep-build/lib
#ln -rs include ${BUILD_DIR_PATH}/sleep-build/include
#CFLAGS="-DVANILLA_THIEF_SLEEP=1 ${COMMON_CFLAGS}" make -B -C handcomp_test
#mv lib/x86_64-unknown-linux-gnu ${BUILD_DIR_PATH}/sleep-build/lib/
#
#for f in ${HANDCOMP_BENCHES}; do
#    mv handcomp_test/${f} handcomp_test/sleep-${f}
#done 
#mkdir -p "${BUILD_DIR_PATH}/sleep-build"
#cd "${BUILD_DIR_PATH}/sleep-build"

#CFLAGS="-DVANILLA_THIEF_SLEEP=1 ${COMMON_CFLAGS} ${COMMON_RUNTIME_CFLAGS}" cmake ${CMAKE_ARGS} ${SCRIPTPATH}


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

    #cd handcomp_test

    #make RESOURCE_DIR="${CURR_BUILD_DIR}" RTS_LIBDIR_NAME="lib/linux"
    #for bench in ${HANDCOMP_BENCHES}; do
    #    mv ${bench} "${CURR_HANDCOMP_BUILD_DIR}/${bench}"
    #done
done
