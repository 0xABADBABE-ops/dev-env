#!/bin/bash
source "$(dirname "$0")/nvm-path.sh"
TUI_ROOT="${TUI_ROOT:-$HOME/projects}"
PROJECT="${PROJECT:-my-project}"
cd "$TUI_ROOT/$PROJECT"
node -e 'const sharp=require("sharp"); console.log("sharp:", sharp.versions)'
node -e 'require("better-sqlite3"); console.log("better-sqlite3: ok")'
node -e 'const esbuild=require("esbuild"); console.log("esbuild:", esbuild.version)'
