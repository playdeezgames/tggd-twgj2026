#!/usr/bin/env bash
# Tests and builds the game, then zips it. Publishes to itch.io ONLY with --push, and only
# when the user has said to ship: it makes the game public.
set -euo pipefail
cd "$(dirname "$0")"
./test.sh
./build.sh
rm -f build/turn-left-at-the-cow-html5.zip
(cd build/web && zip -qr ../turn-left-at-the-cow-html5.zip .)
echo "zipped build/turn-left-at-the-cow-html5.zip"
if [[ "${1:-}" == "--push" ]]; then
  butler push build/web thegrumpygamedev/turn-left-at-the-cow:html
else
  echo "not pushed (pass --push to publish)"
fi
