#!/bin/bash
# Login shell profile for the WSL2 dev environment (installed by setup.sh).
# Sourced from both ~/.bashrc (interactive) and ~/.profile (login).
# PATH setup runs always; banner + cd only in interactive shells.

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL:$PATH"

# Ubuntu packages `fd` as `fdfind`
command -v fdfind >/dev/null 2>&1 && alias fd=fdfind

# Interactive-only niceties (banner + auto-cd)
case $- in
    *i*) ;;
      *) return 0 ;;
esac

cd ~/projects 2>/dev/null || true

echo
echo "  Dev Environment ready"
echo "    node  $(node -v 2>/dev/null || echo missing)"
echo "    pnpm  $(pnpm -v 2>/dev/null || echo missing)"
echo "    bun   $(bun --version 2>/dev/null || echo missing)"
echo "    work  ~/projects"
echo
