#!/bin/bash
source "$(dirname "$0")/nvm-path.sh"
TUI_ROOT="${TUI_ROOT:-$HOME/projects}"
PROJECT="${PROJECT:-my-project}"
cd "$TUI_ROOT/$PROJECT"

# Kill any existing dev processes
pkill -f "npm run dev" 2>/dev/null
pkill -f "expo start" 2>/dev/null
pkill -f "next dev" 2>/dev/null
pkill -f "tsx watch" 2>/dev/null
sleep 1

echo "Starting server and web..."

# Start server (Fastify) in background
(cd server && nohup npm run dev > /tmp/dev-server.log 2>&1 &)
echo "server PID: $!"

# Start web (Next.js) in background
(cd apps/web && nohup npm run dev > /tmp/dev-web.log 2>&1 &)
echo "web PID: $!"

sleep 1
echo "Logs: tail -f /tmp/dev-server.log"
echo "Logs: tail -f /tmp/dev-web.log"
