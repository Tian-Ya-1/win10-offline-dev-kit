[CmdletBinding()]
param(
    [string]$ArchivePath,
    [string]$ToolsRoot = (Join-Path $env:USERPROFILE "Tools")
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
    $ArchivePath = Join-Path $repoRoot "offline-bundle\installers\winlibs-x86_64-posix-seh-gcc-14.3.0-mingw-w64ucrt-12.0.0-r1.zip"
}

if (-not (Test-Path $ArchivePath)) {
    throw "MinGW archive not found: $ArchivePath"
}

$expectedSha256 = "d6e83bf3cfff02ddcb4ccb485a8a162e3852bf09976d0cb9d521f3d0d6855ea3"
$actualSha256 = (Get-FileHash -Algorithm SHA256 -Path $ArchivePath).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
    throw "MinGW SHA-256 mismatch. Do not install this archive."
}

$mingwRoot = Join-Path $ToolsRoot "mingw64"
$mingwBin = Join-Path $mingwRoot "bin"

if (Test-Path $mingwRoot) {
    Write-Host "MinGW already exists: $mingwRoot"
} else {
    New-Item -ItemType Directory -Force -Path $ToolsRoot | Out-Null
    Write-Host "Extracting MinGW to $ToolsRoot ..."
    Expand-Archive -Path $ArchivePath -DestinationPath $ToolsRoot
}

$requiredFiles = @("gcc.exe", "g++.exe", "gdb.exe")
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $mingwBin $file
    if (-not (Test-Path $fullPath)) {
        throw "Required tool missing: $fullPath"
    }
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @($userPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($pathEntries -notcontains $mingwBin) {
    $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
        $mingwBin
    } else {
        "$userPath;$mingwBin"
    }
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "Added to user PATH: $mingwBin"
}

if (($env:Path -split ";") -notcontains $mingwBin) {
    $env:Path = "$mingwBin;$env:Path"
}

Write-Host ""
& (Join-Path $mingwBin "gcc.exe") --version | Select-Object -First 1
& (Join-Path $mingwBin "g++.exe") --version | Select-Object -First 1
& (Join-Path $mingwBin "gdb.exe") --version | Select-Object -First 1
Write-Host ""
Write-Host "MinGW installation completed. Restart VS Code before compiling."
