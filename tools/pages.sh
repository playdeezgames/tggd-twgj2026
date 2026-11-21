#!/usr/bin/env bash
# Builds the web build and copies it to docs/ for GitHub Pages (served from the default branch, /docs):
# https://playdeezgames.github.io/tggd-twgj2026/
# docs/ is generated and wiped on each run. Never commits or pushes.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf build/web; ./build.sh
rm -rf docs
mkdir docs
cp -r build/web/. docs/
touch docs/.nojekyll
echo "docs/ ready: $(du -sh docs | cut -f1)"
