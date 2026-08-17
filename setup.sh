#!/usr/bin/env bash
# =============================================================================
#  WSL2 Native Dev Environment — one-time, idempotent setup
#  Target distro: Debian 13 (trixie) or Ubuntu 24.04 — both apt-based
#
#  Run as your normal (non-root) user inside WSL2:
#      bash setup.sh
#
#  Safe to re-run: every step is guarded and skips already-installed tools.
# =============================================================================
set -euo pipefail

# --- Config (override via env) -------------------------------------------
NODE_VERSION="${NODE_VERSION:-22}"          # 22 = maintenance LTS, 24 = active LTS
NVM_VERSION="v0.40.3"
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
# curl wrapper with retries — GitHub occasionally returns HTTP 429
fetch() { curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors "$@"; }

# --- Root guard -----------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    echo "Refusing to run as root — tools must live in your user home."
    echo "Create a normal user first, then re-run:"
    echo "  sudo adduser dev && sudo usermod -aG sudo dev"
    echo "  # set default in /etc/wsl.conf:  [user]  default=dev"
    exit 1
fi

# --- 1. System packages ---------------------------------------------------
log "[1/6] System packages (sudo required)"
sudo apt-get update
# Core packages — present in Debian 13 (trixie) and Ubuntu 24.04 default repos
sudo apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl file git git-lfs gnupg gzip jq just less \
    make openssh-client pkg-config python3 python3-dev python3-pip python3-venv \
    ripgrep rsync sudo tmux tree unzip vim-tiny wget xz-utils zstd
# Optional extras — non-fatal if one isn't available (see README)
sudo apt-get install -y --no-install-recommends fd-find fzf gh htop netcat-openbsd \
    || warn "Some optional tools skipped (fd-find/fzf/gh/htop/netcat). See README."
# git-lfs needs a one-time per-user init
git lfs install >/dev/null 2>&1 || true

# --- 2. nvm + Node --------------------------------------------------------
log "[2/6] nvm + Node.js ${NODE_VERSION}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    # git clone avoids raw.githubusercontent.com, which GitHub rate-limits (HTTP 429)
    rm -rf "$NVM_DIR"   # clear any partial state from a previous failed run
    echo "Cloning nvm ${NVM_VERSION} via git (avoids the HTTP 429 rate limit)..."
    git clone --quiet --depth 1 --branch "${NVM_VERSION}" \
        https://github.com/nvm-sh/nvm.git "$NVM_DIR"
else
    echo "nvm already installed."
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
if command -v node >/dev/null 2>&1 && [ "$(node -v)" = "v${NODE_VERSION}" ]; then
    echo "Node ${NODE_VERSION} already installed."
else
    nvm install "$NODE_VERSION"
fi
nvm alias default "$NODE_VERSION" >/dev/null 2>&1 || true
nvm use "$NODE_VERSION" >/dev/null 2>&1 || true

# --- 3. pnpm (via npm — corepack is deprecated) ---------------------------
log "[3/6] pnpm"
if have pnpm; then
    echo "pnpm $(pnpm -v) already installed."
else
    npm install -g pnpm@latest
fi
mkdir -p "$PNPM_HOME"

# --- 4. bun ---------------------------------------------------------------
log "[4/6] bun"
if have bun; then
    echo "bun $(bun --version) already installed."
else
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64)  BUN_ARCH="x64" ;;
        aarch64) BUN_ARCH="aarch64" ;;
        *)       BUN_ARCH="$ARCH" ;;
    esac
    fetch "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${BUN_ARCH}.zip" -o /tmp/bun.zip
    unzip -o /tmp/bun.zip -d /tmp/bun-extract
    mkdir -p "$BUN_INSTALL"
    mv "/tmp/bun-extract/bun-linux-${BUN_ARCH}/bun" "$BUN_INSTALL/bun"
    chmod +x "$BUN_INSTALL/bun"
    ln -sf "$BUN_INSTALL/bun" "$BUN_INSTALL/bunx"
    rm -rf /tmp/bun*
fi

# --- 5. Global tools ------------------------------------------------------
log "[5/6] Global CLI tools"
# Scaffolder CLIs (vite/next/nuxt/shadcn) are run on demand via `pnpm create` /
# `pnpm dlx` so they never go stale — only long-lived runtimes are global here.
npm install -g \
    typescript \
    tsx \
    turbo@latest \
    wrangler@latest \
    @mintlify/cli@latest

# --- 6. Shell profile -----------------------------------------------------
log "[6/6] Shell profile"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.profile.d"
cp "$SCRIPT_DIR/profile.sh" "$HOME/.profile.d/99-dev.sh"
chmod +x "$HOME/.profile.d/99-dev.sh"
grep -q '99-dev.sh' "$HOME/.bashrc" 2>/dev/null || \
    echo '[ -f "$HOME/.profile.d/99-dev.sh" ] && . "$HOME/.profile.d/99-dev.sh"' >> "$HOME/.bashrc"
# Also source it from ~/.profile so login + non-interactive shells get the
# toolchain (nvm/Node/pnpm/bun on PATH), not just interactive ones.
grep -q '99-dev.sh' "$HOME/.profile" 2>/dev/null || \
    echo '[ -f "$HOME/.profile.d/99-dev.sh" ] && . "$HOME/.profile.d/99-dev.sh"' >> "$HOME/.profile"

mkdir -p "$HOME/projects"

# --- Done -----------------------------------------------------------------
log "Done"
cat <<EOF

Environment ready. Open a new shell (or: source ~/.bashrc).

  node  $(node -v 2>/dev/null || echo missing)
  npm   $(npm -v 2>/dev/null || echo missing)
  pnpm  $(pnpm -v 2>/dev/null || echo missing)
  bun   $(bun --version 2>/dev/null || echo missing)

Next:
  bash init-configs.sh   # sync AI coder configs + git/ssh from Windows
  bash doctor.sh         # verify the whole toolset
EOF
