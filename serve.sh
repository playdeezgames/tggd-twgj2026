#!/usr/bin/env bash
# Serves build/web on http://localhost:8000 (wasm needs http, not file://).
exec python3 -m http.server 8000 -d "$(dirname "$0")/build/web"
