# Non-interactive PATH bootstrap — sourced by helper scripts (no banner, no cd).
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL:$PATH"
