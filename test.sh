#!/usr/bin/env bash
# Native tests of the pure game package, plus a wasm type-check of every package.
set -euo pipefail
cd "$(dirname "$0")"
ODIN="${ODIN:-/home/yermom/ODIN/odin}"
"$ODIN" test src/game -collection:tggd=src -define:ODIN_TEST_THREADS=1
"$ODIN" check src/game -collection:tggd=src -target:js_wasm32 -no-entry-point -vet-shadowing -vet-unused
"$ODIN" check src/web -collection:tggd=src -target:js_wasm32 -vet-shadowing -vet-unused
