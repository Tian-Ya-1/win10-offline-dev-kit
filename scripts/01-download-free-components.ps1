[CmdletBinding()]
param(
    [string]$Destination
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = Join-Path $repoRoot "offline-bundle"
}

$installerDir = Join-Path $Destination "installers"
$vsixDir = Join-Path $Destination "vsix"
New-Item -ItemType Directory -Force -Path $installerDir, $vsixDir | Out-Null

function Download-File {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [long]$MinimumBytes = 10240
    )

    if (Test-Path $OutputPath) {
        $existingSize = (Get-Item $OutputPath).Length
        if ($existingSize -ge $MinimumBytes) {
            Write-Host "[SKIP] $Name already exists: $OutputPath"
            return
        }
        Remove-Item -Force $OutputPath
    }

    Write-Host "[GET ] $Name"
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $OutputPath -Headers @{
        "User-Agent" = "Mozilla/5.0 WindowsOfflineDevKit/1.0"
    }

    $actualSize = (Get-Item $OutputPath).Length
    if ($actualSize -lt $MinimumBytes) {
        throw "$Name download is unexpectedly small ($actualSize bytes): $OutputPath"
    }
    Write-Host "[ OK ] $Name ($actualSize bytes)"
}

$downloads = @(
    [pscustomobject]@{
        Name = "Visual Studio Code Stable x64 User Installer"
        Url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
        Path = Join-Path $installerDir "VSCodeUserSetup-x64.exe"
        MinimumBytes = 50000000
    },
    [pscustomobject]@{
        Name = "Python 3.11.9 x64"
        Url = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
        Path = Join-Path $installerDir "python-3.11.9-amd64.exe"
        MinimumBytes = 20000000
    },
    [pscustomobject]@{
        Name = "WinLibs GCC 14.3.0 MinGW-w64 UCRT Win64"
        Url = "https://github.com/brechtsanders/winlibs_mingw/releases/download/14.3.0posix-12.0.0-ucrt-r1/winlibs-x86_64-posix-seh-gcc-14.3.0-mingw-w64ucrt-12.0.0-r1.zip"
        Path = Join-Path $installerDir "winlibs-x86_64-posix-seh-gcc-14.3.0-mingw-w64ucrt-12.0.0-r1.zip"
        MinimumBytes = 240000000
    },
    [pscustomobject]@{
        Name = "VS Code C/C++"
        Url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/cpptools/latest/vspackage?targetPlatform=win32-x64"
        Path = Join-Path $vsixDir "ms-vscode.cpptools.vsix"
        MinimumBytes = 1000000
    },
    [pscustomobject]@{
        Name = "VS Code Python"
        Url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/latest/vspackage?targetPlatform=win32-x64"
        Path = Join-Path $vsixDir "ms-python.python.vsix"
        MinimumBytes = 500000
    },
    [pscustomobject]@{
        Name = "VS Code Pylance"
        Url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/vscode-pylance/latest/vspackage?targetPlatform=win32-x64"
        Path = Join-Path $vsixDir "ms-python.vscode-pylance.vsix"
        MinimumBytes = 500000
    },
    [pscustomobject]@{
        Name = "VS Code Python Debugger"
        Url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/debugpy/latest/vspackage?targetPlatform=win32-x64"
        Path = Join-Path $vsixDir "ms-python.debugpy.vsix"
        MinimumBytes = 500000
    },
    [pscustomobject]@{
        Name = "VS Code Python Environments"
        Url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/vscode-python-envs/latest/vspackage?targetPlatform=win32-x64"
        Path = Join-Path $vsixDir "ms-python.vscode-python-envs.vsix"
        MinimumBytes = 100000
    }
)

foreach ($item in $downloads) {
    Download-File -Name $item.Name -Url $item.Url -OutputPath $item.Path -MinimumBytes $item.MinimumBytes
}

$mingwPath = Join-Path $installerDir "winlibs-x86_64-posix-seh-gcc-14.3.0-mingw-w64ucrt-12.0.0-r1.zip"
$mingwExpectedSha256 = "d6e83bf3cfff02ddcb4ccb485a8a162e3852bf09976d0cb9d521f3d0d6855ea3"
$mingwActualSha256 = (Get-FileHash -Algorithm SHA256 -Path $mingwPath).Hash.ToLowerInvariant()
if ($mingwActualSha256 -ne $mingwExpectedSha256) {
    throw "MinGW SHA-256 mismatch. Expected $mingwExpectedSha256, got $mingwActualSha256"
}
Write-Host "[ OK ] MinGW publisher SHA-256 verified"

$hashFile = Join-Path $Destination "SHA256SUMS.txt"
$hashLines = Get-ChildItem -Path $installerDir, $vsixDir -File |
    Sort-Object FullName |
    ForEach-Object {
        $relativePath = $_.FullName.Substring($Destination.Length).TrimStart('\')
        $hash = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash.ToLowerInvariant()
        "$hash  $relativePath"
    }
$hashLines | Set-Content -Encoding UTF8 -Path $hashFile

$infoFile = Join-Path $Destination "download-info.txt"
@(
    "Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')"
    "Computer: $env:COMPUTERNAME"
    "Files: $($downloads.Count)"
    "MinGW publisher SHA-256: verified"
) | Set-Content -Encoding UTF8 -Path $infoFile

Write-Host ""
Write-Host "Download completed: $Destination"
Write-Host "Checksums: $hashFile"
Write-Host "Next: copy this repository and offline-bundle to the offline computer"
