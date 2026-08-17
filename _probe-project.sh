#!/bin/bash
source "$(dirname "$0")/nvm-path.sh"
TUI_ROOT="${TUI_ROOT:-$HOME/projects}"
PROJECT="${PROJECT:-my-project}"
cd "$TUI_ROOT/$PROJECT"
node -e '
const p = require("./package.json");
console.log("type:", p.workspaces ? "monorepo" : "single");
console.log("scripts:", JSON.stringify(p.scripts, null, 2));
console.log("workspaces:", JSON.stringify(p.workspaces || [], null, 2));
'
echo "---native-deps---"
grep -c 'sharp\|better-sqlite3\|esbuild\|bcrypt' package-lock.json 2>/dev/null || echo "0"
echo "---node_modules---"
test -d node_modules && echo "exists" || echo "missing"
