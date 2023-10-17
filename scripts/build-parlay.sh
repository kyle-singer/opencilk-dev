#!/bin/bash

set -e

# Get the absolute path to this file's directory
SCRIPTPATH=$(dirname $(readlink -f "$0"))
# Get the parent directory's absolute path
SCRIPT_PARENT=$(dirname "${SCRIPTPATH}")

BUILD_TYPE=RELEASE
COMPILER=${SCRIPT_PARENT}/build/opencilk/bin/clang++
RESOURCE_PARENT=${SCRIPT_PARENT}/src/cheetah/builds

PARLAY_COMMON_FLAGS="-DCMAKE_CXX_COMPILER=${COMPILER} -DPARLAY_BENCHMARK=On -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"

cd ${SCRIPTPATH}

rm -rf ../build/parlaylib

mkdir -p ../build/parlaylib/parlaylib-no-sleep

pushd ../build/parlaylib/parlaylib-no-sleep

    cmake cmake ${PARLAY_COMMON_FLAGS} -DPARLAY_ELASTIC_PARALLELISM=Off ../../../src/parlaylib-eews
    make VERBOSE=1 -j

popd # parlaylib/parlaylib-no-sleep

mkdir -p ../build/parlaylib/parlaylib

pushd ../build/parlaylib/parlaylib

    cmake ${PARLAY_COMMON_FLAGS} ../../../src/parlaylib-eews
    make VERBOSE=1 -j

popd # parlaylib/parlaylib

mkdir -p ../build/parlaylib/parlaylib-cilk-strat

pushd ../build/parlaylib/parlaylib-cilk-strat

    cmake -E env CXXFLAGS="-DCILK_SLEEP_STRATEGY=true" cmake ${PARLAY_COMMON_FLAGS} -DPARLAY_ELASTIC_PARALLELISM=Off ../../../src/parlaylib-eews
    make VERBOSE=1 -j

popd # parlaylib/parlaylib

declare -A POSTFIX_TO_RSRC_DIR
POSTFIX_TO_RSRC_DIR[vanilla-sleep]=sleep-build
POSTFIX_TO_RSRC_DIR[central-sleep]=central-sleep-build
POSTFIX_TO_RSRC_DIR[central-stealable-sleep]=central-stealable-sleep-build
POSTFIX_TO_RSRC_DIR[distributed-stealable-sleep]=distributed-stealable-sleep-build
POSTFIX_TO_RSRC_DIR[vanilla]=no-sleep-build
POSTFIX_TO_RSRC_DIR[parlay-sleep]=parlay-sleep-build

for postfix in "${!POSTFIX_TO_RSRC_DIR[@]}"; do

    CILKFLAG="--opencilk-resource-dir=${RESOURCE_PARENT}/${POSTFIX_TO_RSRC_DIR[${postfix}]}"
    BUILD_DIR=../build/parlaylib/cilk-parlaylib-${postfix}

    mkdir -p ${BUILD_DIR}

    pushd ${BUILD_DIR}

        cmake -E env CXXFLAGS="${CILKFLAG}" LDFLAGS="${CILKFLAG}" \
            cmake ${PARLAY_COMMON_FLAGS} -DPARLAY_ELASTIC_PARALLELISM=Off -DPARLAY_OPENCILK=On ../../../src/parlaylib-eews

        VERBOSE=1 make -j

    popd

done
