#!/usr/bin/env bash
# Self-check: verify the whole dev toolset is installed and working.
# Usage: bash doctor.sh
set -uo pipefail

PASS=0
FAIL=0
check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf '  \033[1;32m[ ok ]\033[0m %s\n' "$name"
        PASS=$((PASS + 1))
    else
        printf '  \033[1;31m[FAIL]\033[0m %s\n' "$name"
        FAIL=$((FAIL + 1))
    fi
}

# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/nvm-path.sh" 2>/dev/null || true

echo "Runtimes:"
check "node"       node -v
check "npm"        npm -v
check "pnpm"       pnpm -v
check "bun"        bun --version
check "git"        git --version
check "git-lfs"    git lfs version

echo "System tools:"
check "rg"         rg --version
check "fdfind"     fdfind --version
check "fzf"        fzf --version
check "tmux"       tmux -V
check "htop"       htop --version
check "tree"       tree --version
check "jq"         jq --version
check "make"       make --version
check "gcc"        gcc --version
check "python3"    python3 --version
check "gh"         gh --version
check "just"       just --version

echo "Global CLI tools:"
check "tsc"        tsc --version
check "tsx"        tsx --version
check "turbo"      turbo --version
check "wrangler"   wrangler --version
check "mintlify"   mintlify --version

echo
printf 'Result: %d passed, %d failed.\n' "$PASS" "$FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "All good ✓"
else
    echo "Run 'bash setup.sh' to fill the gaps."
fi
exit "$FAIL"
