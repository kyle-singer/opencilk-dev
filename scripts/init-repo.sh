#!/bin/bash

cd "$(dirname "$0")"/..

#git submodule update --init --recursive

pushd src/opencilk

ln -frs ../cheetah cheetah
ln -frs ../cilktools cilktools

popd
