#!/bin/bash

# arcane wizadry
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

[ -d build ] || mkdir build
cd build

cmake "$SCRIPT_DIR/../deps/qpakman" -DCMAKE_BUILD_TYPE=Release
cmake --build . -- -j8
