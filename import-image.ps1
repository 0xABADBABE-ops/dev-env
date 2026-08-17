# Import a .tar image as a fresh WSL2 distro (the "installer" for new machines).
# Run from WINDOWS PowerShell.
param(
    [string]$Name = "DevEnv",
    [string]$Tar = "dev-env.tar",
    [string]$InstallDir = "",
    [string]$DefaultUser = ""
)
$ErrorActionPreference = "Stop"

if ($InstallDir -eq "") { $InstallDir = Join-Path $env:LOCALAPPDATA "WSL\$Name" }
if (-not (Test-Path $Tar)) { throw "Image not found: $Tar" }

Write-Host "Importing '$Tar' as distro '$Name' -> $InstallDir"
wsl.exe --import $Name $InstallDir $Tar
if ($LASTEXITCODE -ne 0) { throw "wsl --import failed (exit $LASTEXITCODE)" }

if ($DefaultUser -ne "") {
    Write-Host "Setting default user to '$DefaultUser'"
    $conf = "[user]`ndefault=$DefaultUser`n"
    $conf | wsl.exe -d $Name -u root -- sh -c "cat > /etc/wsl.conf"
}

Write-Host "Done. Launch with:  wsl -d $Name"
if ($DefaultUser -eq "") {
    Write-Host "Tip: imports start as root. Set a default user (see README 'Package it as an image')."
}
