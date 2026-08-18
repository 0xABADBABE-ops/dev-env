# WSL2 Native Dev Environment

[![Build](https://github.com/0xabadbabe-ops/dev-env/actions/workflows/build-wsl.yml/badge.svg)](https://github.com/0xabadbabe-ops/dev-env/actions/workflows/build-wsl.yml)

A ready-to-use Linux development environment for **Node.js**, running natively
inside Windows Subsystem for Linux (WSL2). Install it once and you get a
complete, reproducible toolset — no Docker, no setup wizard, no fiddling with
versions.

Works on **Debian 13** or **Ubuntu 24.04** (both use `apt`).

## What's included

| Category | Tools |
|----------|-------|
| **Runtimes** | Node.js 22 (via nvm), npm, pnpm, bun |
| **Global CLIs** | TypeScript (`tsc`), `tsx`, `turbo`, `wrangler`, Mintlify |
| **Scaffolders** | Vite, Next.js, Nuxt, shadcn/ui (run on demand) |
| **Dev utilities** | git + git-lfs, ripgrep, fd, fzf, tmux, htop, tree, jq, gh |

## Contents

- [I just want to use it](#i-just-want-to-use-it)
- [I want to build or customize it](#i-want-to-build-or-customize-it)
- [Daily use](#daily-use)
- [Point it at your project](#point-it-at-your-project)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [For maintainers: ship it to others](#for-maintainers-ship-it-to-others)

## Requirements

- Windows 10 or 11 with **WSL2** installed. If unsure, run `wsl --install` in a
  PowerShell or Command Prompt window, then reboot.

---

## I just want to use it

If a prebuilt release is available, this is the fastest path — a single
PowerShell command downloads the environment and registers it as a WSL distro.

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 `
    -Url https://github.com/0xabadbabe-ops/dev-env/releases/latest/download/dev-env.tar.gz
```

Or download `dev-env.tar.gz` from the
[Releases](https://github.com/0xabadbabe-ops/dev-env/releases) page yourself,
then double-click `install.bat`.

When it finishes, open it with:

```powershell
wsl -d DevEnv
```

You'll land in `~/projects` as the `dev` user, with the full toolset ready.

---

## I want to build or customize it

Prefer to build from this repo, or tweak what gets installed? Run the installer
script directly inside WSL2.

**Step 1 — Install WSL2 and a distro** (once, on Windows):

```powershell
wsl --install -d Debian    # or: wsl --install -d Ubuntu-24.04
```

**Step 2 — Run the installer** (inside the distro):

```bash
cd /path/to/dev-container
bash setup.sh         # installs the toolset (~2 min, safe to re-run)
bash init-configs.sh  # copies git/ssh + AI coder configs from Windows
bash doctor.sh        # verifies everything works (should print "All good ✓")
```

Open a new shell (or run `source ~/.bashrc`) and you'll see the "Dev
Environment ready" banner. You're done.

> **Tip:** `setup.sh` is idempotent — you can re-run it any time and it will
> only install what's missing, never break what's already there.

---

## Daily use

Every common task is a **recipe** you run with `just`. Forget script names —
run `just --list` to see them all:

```bash
just --list           # show all recipes and what they do
just doctor           # health-check the toolset
just start-dev        # start your project (npm run dev)
just start-selective  # start server + web (Fastify + Next.js)
just check-native     # verify native deps (sharp, better-sqlite3, esbuild)
just probe            # inspect a project's structure
```

`just` is a tiny, dependency-free command runner installed by `setup.sh`.
(`ujust` is a drop-in Rust clone that reads the same `justfile`.)

Long-running dev servers are easiest to keep alive with `tmux`.

---

## Point it at your project

The `just` recipes operate on a project you point them to with two optional
environment variables:

| Variable | Meaning | Default |
|----------|---------|---------|
| `TUI_ROOT` | Workspace root directory | `~/projects` |
| `PROJECT`  | Project folder inside it | `my-project` |

```bash
export TUI_ROOT="$HOME/projects"
export PROJECT="my-project"
git clone <your-repo> "$TUI_ROOT/$PROJECT"
```

Add those `export` lines to `~/.bashrc` to make them permanent.

> **Note:** keep your projects on the native Linux filesystem (`~/...`) for
> full speed. Pointing at a Windows folder (`/mnt/c/...`) works but is much
> slower — use it only as a last resort.

---

## Troubleshooting

**`command not found: node` / `pnpm` / `bun`**
You're in a non-interactive shell. Use a normal login shell (`wsl -d Debian`),
or run `source ~/.bashrc` first.

**`curl: (22) ... 429` during setup**
GitHub rate-limited a download. Just re-run `bash setup.sh` — the installer
uses `git clone` for nvm (which avoids this) and retries other downloads.

**`sudo: a password is required`**
Expected on a normal WSL install. Run `setup.sh` inside an interactive shell
where you can type your password, or run the system-package step as root via
`wsl -u root`.

**`doctor.sh` reports failures**
Re-run `bash setup.sh` — it fills in anything missing, then re-check with
`just doctor`.

---

## Uninstall

To remove the environment entirely, unregister the distro from Windows:

```powershell
wsl --unregister DevEnv    # or Debian, or whatever name you used
```

---

## For maintainers: ship it to others

You can publish the environment as a downloadable release using the included
GitHub Actions workflow. (Note: there's no `.wsl2` file format — WSL installs
distros from a root-filesystem tarball via `wsl --import`.)

**How the workflow works**

1. `.github/workflows/build-wsl.yml` builds the environment on an Ubuntu runner,
   then runs `docker export` to produce a WSL-importable `dev-env.tar.gz`.
2. Pushing a version tag (`v*`) attaches that tarball to a GitHub Release.
3. Users download it and run `install.ps1` / `install.bat`, which imports it
   with `wsl --import`.

**Publishing a release** (once):

```bash
git tag v1.0.0 && git push origin v1.0.0   # triggers the build + release
```

**Making a local backup image** (no GitHub needed):

```powershell
powershell -File export-image.ps1 -Distro Debian -Out dev-env.tar   # snapshot
powershell -File import-image.ps1 -Name DevEnv -Tar dev-env.tar     # restore
```

The image includes cached `node_modules`, configs, and all global tools — a
fully working environment that boots in seconds.

---

## Repository layout

| File | Purpose |
|------|---------|
| `setup.sh` | One-time installer (apt + nvm + node + pnpm + bun) |
| `init-configs.sh` | Sync git/ssh + AI coder configs from Windows |
| `doctor.sh` | Verify the whole toolset works |
| `justfile` | Task recipes (`just <recipe>`) |
| `profile.sh` / `nvm-path.sh` | Shell PATH setup |
| `_start-dev.sh` / `_start-selective.sh` | Start dev servers |
| `_check-native.sh` / `_probe-project.sh` | Project diagnostics |
| `install.ps1` / `install.bat` | One-click installer for released images |
| `export-image.ps1` / `import-image.ps1` | Snapshot/restore a distro |
| `ci/Dockerfile` + `.github/workflows/` | CI build + release automation |

