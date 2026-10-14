#!/usr/bin/env bash
# Builds the web game into build/web (what gets shipped).
set -euo pipefail
cd "$(dirname "$0")"
ODIN="${ODIN:-/home/yermom/ODIN/odin}"
mkdir -p build/web
"$ODIN" build src/web -collection:tggd=src -target:js_wasm32 -out:build/web/game.wasm -o:speed -vet-shadowing -vet-unused
cp "$("$ODIN" root)/core/sys/wasm/js/odin.js" build/web/
cp web/index.html build/web/
mkdir -p build/web/assets
cp assets/*.png assets/*.txt build/web/assets/
echo "built build/web"
