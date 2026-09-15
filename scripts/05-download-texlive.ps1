[CmdletBinding()]
param(
    [string]$Destination
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = Join-Path $repoRoot "offline-bundle\installers"
}
New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$isoName = "texlive2026.iso"
$isoPath = Join-Path $Destination $isoName
$checksumPath = Join-Path $Destination "$isoName.sha512"
$isoUrl = "https://mirrors.ctan.org/systems/texlive/Images/$isoName"
$checksumUrl = "https://mirrors.ctan.org/systems/texlive/Images/$isoName.sha512"
$minimumIsoBytes = 6000000000

Write-Host "[INFO] TeX Live 2026 ISO is about 6.3 GiB. Keep this window open."
Write-Host "[GET ] Official SHA-512 checksum"
Invoke-WebRequest -UseBasicParsing -Uri $checksumUrl -OutFile $checksumPath -Headers @{
    "User-Agent" = "Mozilla/5.0 WindowsOfflineDevKit/1.0"
}

$needsDownload = $true
if (Test-Path $isoPath) {
    $existingSize = (Get-Item $isoPath).Length
    if ($existingSize -ge $minimumIsoBytes) {
        Write-Host "[SKIP] TeX Live ISO already exists: $isoPath"
        $needsDownload = $false
    }
}

if ($needsDownload) {
    $curlCommand = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($null -ne $curlCommand) {
        Write-Host "[GET ] TeX Live 2026 ISO (curl resume enabled)"
        & $curlCommand.Source `
            --location `
            --fail `
            --retry 5 `
            --retry-delay 5 `
            --continue-at - `
            --output $isoPath `
            $isoUrl
        if ($LASTEXITCODE -ne 0) {
            throw "TeX Live ISO download failed with curl exit code $LASTEXITCODE"
        }
    } else {
        if (Test-Path $isoPath) {
            Remove-Item -Force $isoPath
        }
        Write-Host "[GET ] TeX Live 2026 ISO"
        Invoke-WebRequest -UseBasicParsing -Uri $isoUrl -OutFile $isoPath -Headers @{
            "User-Agent" = "Mozilla/5.0 WindowsOfflineDevKit/1.0"
        }
    }
}

$actualSize = (Get-Item $isoPath).Length
if ($actualSize -lt $minimumIsoBytes) {
    throw "TeX Live ISO is unexpectedly small ($actualSize bytes): $isoPath"
}
Write-Host "[ OK ] TeX Live ISO size: $actualSize bytes"

$checksumText = Get-Content -Raw -Path $checksumPath
$checksumMatch = [regex]::Match($checksumText, "(?i)\b[0-9a-f]{128}\b")
if (-not $checksumMatch.Success) {
    throw "Unable to read the official SHA-512 checksum: $checksumPath"
}

$expectedSha512 = $checksumMatch.Value.ToLowerInvariant()
Write-Host "[INFO] Verifying TeX Live ISO SHA-512; this can take several minutes"
$actualSha512 = (Get-FileHash -Algorithm SHA512 -Path $isoPath).Hash.ToLowerInvariant()
if ($actualSha512 -ne $expectedSha512) {
    throw "TeX Live ISO SHA-512 mismatch. Delete the ISO and download it again."
}

Write-Host "[ OK ] TeX Live official SHA-512 verified"
Write-Host "TeX Live offline image: $isoPath"
