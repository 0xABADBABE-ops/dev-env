#!/bin/bash
source "$(dirname "$0")/nvm-path.sh"
TUI_ROOT="${TUI_ROOT:-$HOME/projects}"
PROJECT="${PROJECT:-my-project}"
cd "$TUI_ROOT/$PROJECT"
nohup npm run dev > /tmp/dev-output.log 2>&1 &
echo "PID: $!"
