# WSL2 Native Dev Environment

[![Build](https://github.com/0xabadbabe-ops/dev-env/actions/workflows/build-wsl.yml/badge.svg)](https://github.com/0xabadbabe-ops/dev-env/actions/workflows/build-wsl.yml)

A complete, reproducible Node.js development environment running **natively in
WSL2** — no Docker, no volume sync, native file I/O. Target distro:
**Debian 13 (trixie)** — also works on Ubuntu 24.04 (both apt-based).

```
justfile            task recipes — run `just <recipe>` (see "Recipes" below)
setup.sh            one-time, idempotent installer (apt + nvm + node + pnpm + bun)
init-configs.sh     sync AI coder configs + git/ssh from Windows
profile.sh          login shell profile (PATH + banner)
nvm-path.sh         PATH bootstrap for helper scripts
doctor.sh           self-check: verifies the whole toolset is working
_start-dev.sh       start the target project (npm run dev)
_start-selective.sh start server + web (Fastify + Next.js)
_check-native.sh    verify sharp / better-sqlite3 / esbuild
export-image.ps1    (Windows) freeze the distro to a portable .tar image
import-image.ps1    (Windows) restore a .tar image as a fresh distro
```

## Fresh install

```bash
# On Windows (one time): install WSL2 + a distro
wsl --install -d Debian        # Debian 13 (trixie); or: wsl --install -d Ubuntu-24.04

# Inside WSL2 (your normal user):
cd /path/to/dev-container
bash setup.sh         # ~2 min — safe to re-run
bash init-configs.sh  # pull configs from Windows
bash doctor.sh        # verify everything works
```

Open a new shell (or `source ~/.bashrc`) — you'll land in `~/projects` with the
"Dev Environment ready" banner.

## Recipes (just / ujust)

Every task is exposed as a **recipe** in `justfile`, so you can drive the whole
environment from one place instead of remembering individual script names.

```bash
just --list          # show all recipes + descriptions
just bootstrap       # one-shot: setup + init-configs + doctor
just doctor          # verify the toolset
just start-dev       # run the target project
just start-selective # run server + web
just check-native    # native deps
just probe           # project structure
```

`just` is a single static binary (installed from Debian repos via `setup.sh`);
`ujust` is a drop-in Rust clone that reads the same `justfile`.

## What's installed

**Runtimes**
- Node.js 22 via nvm (set `NODE_VERSION=24` for the active LTS)
- npm (bundled with Node)
- pnpm (installed via npm — `corepack` is deprecated)
- bun (latest standalone binary)

**Global CLI tools** — long-lived runtimes only
- TypeScript (`tsc`), `tsx`, `turbo`, `wrangler`, Mintlify (`mintlify`)

**Scaffolders — on demand, never stale**
```bash
pnpm create vite@latest          # Vite
pnpm create next-app@latest      # Next.js
pnpm dlx nuxi@latest init        # Nuxt
pnpm dlx shadcn@latest init      # shadcn/ui
```

**System packages** — build toolchain (`build-essential`, `pkg-config`,
`python3-dev/venv`), `git` + `git-lfs`, `ripgrep`, `fd-find`, `fzf`, `tmux`,
`htop`, `tree`, `jq`, `gh`, `netcat`, and friends.

## Git & SSH

`init-configs.sh` copies `~/.gitconfig` and `~/.ssh` from Windows on first run
(never overwriting), and wires `credential.helper` to Git for Windows'
Credential Manager so HTTPS push/pull "just works".

## Project location

Helpers target a project you point them at via two optional env vars
(`TUI_ROOT` = workspace root, `PROJECT` = directory inside it):

```bash
export TUI_ROOT="$HOME/projects"   # workspace root (default: ~/projects)
export PROJECT="my-project"        # project dir inside it (default: my-project)
git clone <your-repo> "$TUI_ROOT/$PROJECT"
```

Then `just start-dev` / `just start-selective` / `just probe` operate on
`$TUI_ROOT/$PROJECT`. To use a Windows-side checkout (slower, last resort), set
`TUI_ROOT=/mnt/c/Users/<you>/...`. Make the exports permanent in `~/.bashrc`.

## Daily workflow

```bash
bash /path/to/dev-container/_start-selective.sh   # server + web
bash /path/to/dev-container/_check-native.sh      # native deps
bash /path/to/dev-container/_probe-project.sh     # project structure
```

Prefer `tmux` for keeping dev servers alive across disconnects.

## Package it as an image (new machines)

Once the distro is configured, freeze it into a portable installer:

```powershell
# Windows PowerShell — export
powershell -File export-image.ps1 -Distro Debian -Out dev-env.tar

# Windows PowerShell — import on a fresh machine
powershell -File import-image.ps1 -Name DevEnv -Tar dev-env.tar -DefaultUser <your-user>
```

The `.tar` includes cached `node_modules`, AI coder configs, and all global tools
— a fully working environment that boots in seconds.

## Distribute as a release (GitHub Actions)

Publish the whole environment as a downloadable, one-click-installable image.
There is no `.wsl2` file format — WSL installs distros from a **rootfs tarball**
(`.tar.gz`) via `wsl --import`, so the "package" is that tarball plus an
installer script.

**How it works**

1. `.github/workflows/build-wsl.yml` builds the environment on an Ubuntu runner
   (Linux already, so no Windows needed), using `ci/Dockerfile` → `docker export`
   to produce a WSL-importable `dev-env.tar.gz`.
2. On a version tag (`v*`) it attaches that tarball to a GitHub Release.
3. Users download and run `install.ps1` (or double-click `install.bat`), which
   imports the tarball with `wsl --import` — that's the "executable".

**On the repo owner's machine (once)**

```bash
git init && git add -A && git commit -m "WSL2 dev environment"
gh repo create <owner>/dev-env --public --source=. --push
gh release create v1.0.0 --generate-notes   # triggers the Action to attach the artifact
```

**On the end-user's machine**

```powershell
# one-liner from a GitHub Release:
powershell -ExecutionPolicy Bypass -File install.ps1 `
    -Url https://github.com/<owner>/dev-env/releases/latest/download/dev-env.tar.gz

# or from a locally downloaded tarball:
install.bat -Tar .\dev-env.tar.gz
```

Installing registers a distro named `DevEnv` (default user `dev`, lands in
`~/projects`). Launch with `wsl -d DevEnv`.

## Re-sync configs from Windows

```bash
bash init-configs.sh   # re-copies AI coder configs (git/ssh only on first run)
```

To reset a config, delete it and re-sync:

```bash
rm -rf ~/.qwen && bash init-configs.sh
```
