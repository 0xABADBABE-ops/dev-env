# =============================================================================
#  Dev Container — task recipes
#
#  Run with:   just <recipe>      (or just --list to see everything)
#  Drop-in compat: `ujust` reads this file too.
# =============================================================================

set shell := ["bash", "-uc"]

# ── Install & configure ─────────────────────────────────────────────────────

# Install the full toolset (idempotent — safe to re-run)
setup:
    bash setup.sh

# Sync AI coder configs + git/ssh from Windows
init-configs:
    bash init-configs.sh

# Verify the whole toolset (22 checks, exit non-zero on gaps)
doctor:
    bash doctor.sh

# Full provisioning: install, sync configs, verify
bootstrap: setup init-configs doctor

# ── Daily workflow ──────────────────────────────────────────────────────────

# Start ifl-broadcast (npm run dev)
start-dev:
    bash _start-dev.sh

# Start server + web (Fastify + Next.js)
start-selective:
    bash _start-selective.sh

# Verify native deps (sharp / better-sqlite3 / esbuild)
check-native:
    bash _check-native.sh

# Inspect project structure (monorepo? scripts? native deps?)
probe:
    bash _probe-project.sh

# ── Packaging (Windows-side — see note below) ───────────────────────────────

# Freeze the distro to dev-env.tar — RUN FROM WINDOWS POWERShell
export-image:
    @printf '%s\n' \
      'Run from Windows PowerShell (not inside WSL — it must stop the distro):' \
      '  powershell -File export-image.ps1 -Distro Debian -Out dev-env.tar'

# Restore a dev-env.tar as a fresh distro — RUN FROM WINDOWS POWERShell
import-image:
    @printf '%s\n' \
      'Run from Windows PowerShell:' \
      '  powershell -File import-image.ps1 -Name DevEnv -Tar dev-env.tar'

# ── Meta ────────────────────────────────────────────────────────────────────

# List all recipes
default:
    @just --list
