# Export the configured WSL2 distro to a portable .tar image (the "installer").
# Run from WINDOWS PowerShell. The distro must be fully configured (setup.sh done).
param(
    [string]$Distro = "Ubuntu-24.04",
    [string]$Out = "dev-env.tar"
)
$ErrorActionPreference = "Stop"

wsl.exe --list --verbose

Write-Host "Exporting '$Distro' -> $Out ..."
wsl.exe --export $Distro $Out
if ($LASTEXITCODE -ne 0) { throw "wsl --export failed (exit $LASTEXITCODE)" }

$size = [math]::Round((Get-Item $Out).Length / 1MB, 1)
Write-Host "Done: $Out ($size MB)"
Write-Host "Import elsewhere:  powershell -File import-image.ps1 -Tar $Out"
