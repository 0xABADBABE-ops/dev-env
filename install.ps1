<#
.SYNOPSIS
  One-click installer for the WSL2 Dev Environment.
  Downloads the rootfs tarball (from a GitHub Release or a local file) and
  imports it as a WSL distro via `wsl --import`.

.EXAMPLE
  # From a local tarball (e.g. the CI artifact):
  powershell -ExecutionPolicy Bypass -File install.ps1 -Tar .\dev-env.tar.gz

.EXAMPLE
  # From a GitHub Release asset:
  powershell -ExecutionPolicy Bypass -File install.ps1 `
      -Url https://github.com/OWNER/REPO/releases/latest/download/dev-env.tar.gz
#>
[CmdletBinding()]
param(
    [string]$Name       = "DevEnv",
    [string]$Url        = "",   # direct download URL (optional)
    [string]$Tar        = "",   # local tarball (optional; takes precedence over -Url)
    [string]$InstallDir = "$env:LOCALAPPDATA\WSL\DevEnv"
)

$ErrorActionPreference = "Stop"

# --- Preflight: WSL must be installed ---------------------------------------
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "WSL is not installed. Run:  wsl --install"
}

# --- Resolve the rootfs tarball ---------------------------------------------
$tmp = $null
if ($Tar -ne "" -and (Test-Path -LiteralPath $Tar)) {
    $archive = (Resolve-Path -LiteralPath $Tar).Path
    Write-Host "Using local tarball: $archive"
}
elseif ($Url -ne "") {
    $tmp = Join-Path $env:TEMP "dev-env.tar.gz"
    Write-Host "Downloading $Url ..."
    Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing
    $archive = $tmp
}
else {
    throw "Provide either -Tar <file> or -Url <url>."
}

# --- Refuse to clobber an existing distro -----------------------------------
$existing = wsl.exe --list --quiet 2>$null
if ($existing -split "`r?`n" | Where-Object { $_ -eq $Name }) {
    throw "A distro named '$Name' already exists. Remove it first:  wsl --unregister $Name"
}

# --- Import -----------------------------------------------------------------
Write-Host "Importing '$archive' as WSL distro '$Name' -> $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
wsl.exe --import $Name $InstallDir $archive
if ($LASTEXITCODE -ne 0) {
    throw "wsl --import failed (exit $LASTEXITCODE)"
}

if ($tmp) { Remove-Item $tmp -Force }

Write-Host ""
Write-Host "Done. Launch it with:   wsl -d $Name"
Write-Host "Default user 'dev' is baked in - you'll land in ~/projects."
