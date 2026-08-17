#!/usr/bin/env bash
# Sync configs from the Windows host into native WSL2 home.
#   - AI coder configs:  ~/.qwen  ~/.codex  ~/.opencode  ~/.droid
#   - git identity:      ~/.gitconfig   (first run only)
#   - SSH keys:          ~/.ssh         (first run only)
#   - Git Credential Manager wiring (if Git for Windows is installed)
# Safe to re-run: existing native files are never overwritten.
set -euo pipefail

WIN_USERPROFILE="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')"
WIN_HOME="$(printf '%s' "$WIN_USERPROFILE" | sed 's|\\|/|g; s|^[Cc]:|/mnt/c|')"
echo "Windows profile: ${WIN_USERPROFILE}  ->  ${WIN_HOME}"

sync_dir() {
    local name="$1" src="$2" dst="$3"
    if [ ! -d "$src" ]; then
        echo "  [skip] $name (not found on Windows)"
        return
    fi
    mkdir -p "$dst"
    rsync -a "$src"/ "$dst"/ 2>/dev/null || cp -a "$src"/. "$dst"/
    echo "  [ ok ] $name -> $dst"
}

echo "AI coder configs:"
sync_dir "Qwen Code" "$WIN_HOME/.qwen"     "$HOME/.qwen"
sync_dir "Codex"      "$WIN_HOME/.codex"    "$HOME/.codex"
sync_dir "OpenCode"   "$WIN_HOME/.opencode" "$HOME/.opencode"
sync_dir "Droid"      "$WIN_HOME/.droid"    "$HOME/.droid"

echo "Git + SSH:"
if [ -f "$HOME/.gitconfig" ]; then
    echo "  [skip] ~/.gitconfig already exists"
elif [ -f "$WIN_HOME/.gitconfig" ]; then
    cp "$WIN_HOME/.gitconfig" "$HOME/.gitconfig"
    echo "  [ ok ] ~/.gitconfig copied from Windows"
else
    echo "  [skip] no .gitconfig found — run: git config --global user.name/user.email"
fi

if [ -d "$HOME/.ssh" ]; then
    echo "  [skip] ~/.ssh already exists"
elif [ -d "$WIN_HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    cp -a "$WIN_HOME/.ssh"/. "$HOME/.ssh"/
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
    echo "  [ ok ] ~/.ssh copied from Windows"
else
    echo "  [skip] no ~/.ssh found on Windows"
fi

# Point git at the Windows Git Credential Manager (for HTTPS push/pull).
GCM_WIN="/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"
if [ -f "$GCM_WIN" ] && ! git config --global --get credential.helper >/dev/null 2>&1; then
    git config --global credential.helper "\"$GCM_WIN\""
    echo "  [ ok ] git credential helper -> Git for Windows GCM"
fi

echo
echo "Done. Review with: git config --global --list"
