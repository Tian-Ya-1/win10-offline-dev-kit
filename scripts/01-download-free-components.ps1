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

function Get-VsixPackage {
    param(
        [Parameter(Mandatory = $true)][string]$ExtensionId,
        [string]$TargetPlatform = "win32-x64"
    )

    $queryBody = @{
        filters = @(
            @{
                criteria = @(
                    @{ filterType = 7; value = $ExtensionId },
                    @{ filterType = 12; value = "4096" }
                )
                pageNumber = 1
                pageSize = 1
                sortBy = 0
                sortOrder = 0
            }
        )
        assetTypes = @("Microsoft.VisualStudio.Services.VSIXPackage")
        flags = 439
    } | ConvertTo-Json -Depth 8 -Compress

    $listing = Invoke-RestMethod `
        -Method Post `
        -Uri "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery?api-version=3.0-preview.1" `
        -ContentType "application/json" `
        -Body $queryBody `
        -Headers @{ "User-Agent" = "Mozilla/5.0 WindowsOfflineDevKit/1.0" }

    $extension = $listing.results.extensions | Select-Object -First 1
    if ($null -eq $extension) {
        throw "VS Code extension was not found: $ExtensionId"
    }

    $version = $extension.versions |
        Where-Object {
            $_.targetPlatform -eq $TargetPlatform -or
            [string]::IsNullOrWhiteSpace($_.targetPlatform)
        } |
        Select-Object -First 1

    if ($null -eq $version) {
        throw "No $TargetPlatform or universal VSIX was found for: $ExtensionId"
    }

    $packageFile = $version.files |
        Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.VSIXPackage" } |
        Select-Object -First 1

    if ($null -eq $packageFile -or [string]::IsNullOrWhiteSpace($packageFile.source)) {
        throw "VSIX download URL was not found for: $ExtensionId $($version.version)"
    }

    return [pscustomobject]@{
        Url = $packageFile.source
        Version = $version.version
        Platform = $(if ([string]::IsNullOrWhiteSpace($version.targetPlatform)) { "universal" } else { $version.targetPlatform })
    }
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
    }
)

$vsixDownloads = @(
    [pscustomobject]@{
        Name = "VS Code C/C++"
        ExtensionId = "ms-vscode.cpptools"
        Path = Join-Path $vsixDir "ms-vscode.cpptools.vsix"
        MinimumBytes = 1000000
    },
    [pscustomobject]@{
        Name = "VS Code Python"
        ExtensionId = "ms-python.python"
        Path = Join-Path $vsixDir "ms-python.python.vsix"
        MinimumBytes = 500000
    },
    [pscustomobject]@{
        Name = "VS Code Pylance"
        ExtensionId = "ms-python.vscode-pylance"
        Path = Join-Path $vsixDir "ms-python.vscode-pylance.vsix"
        MinimumBytes = 500000
    },
    [pscustomobject]@{
        Name = "VS Code Python Debugger"
        ExtensionId = "ms-python.debugpy"
        Path = Join-Path $vsixDir "ms-python.debugpy.vsix"
        MinimumBytes = 500000
    },
    [pscustomobject]@{
        Name = "VS Code Python Environments"
        ExtensionId = "ms-python.vscode-python-envs"
        Path = Join-Path $vsixDir "ms-python.vscode-python-envs.vsix"
        MinimumBytes = 100000
    },
    [pscustomobject]@{
        Name = "VS Code Code Runner"
        ExtensionId = "formulahendry.code-runner"
        Path = Join-Path $vsixDir "formulahendry.code-runner.vsix"
        MinimumBytes = 100000
    },
    [pscustomobject]@{
        Name = "VS Code Markdown All in One"
        ExtensionId = "yzhang.markdown-all-in-one"
        Path = Join-Path $vsixDir "yzhang.markdown-all-in-one.vsix"
        MinimumBytes = 100000
    },
    [pscustomobject]@{
        Name = "VS Code LaTeX Workshop"
        ExtensionId = "James-Yu.latex-workshop"
        Path = Join-Path $vsixDir "James-Yu.latex-workshop.vsix"
        MinimumBytes = 500000
    },
    [pscustomobject]@{
        Name = "VS Code Jupyter Keymap"
        ExtensionId = "ms-toolsai.jupyter-keymap"
        Path = Join-Path $vsixDir "ms-toolsai.jupyter-keymap.vsix"
        MinimumBytes = 20000
    },
    [pscustomobject]@{
        Name = "VS Code Jupyter Notebook Renderers"
        ExtensionId = "ms-toolsai.jupyter-renderers"
        Path = Join-Path $vsixDir "ms-toolsai.jupyter-renderers.vsix"
        MinimumBytes = 100000
    },
    [pscustomobject]@{
        Name = "VS Code Jupyter Cell Tags"
        ExtensionId = "ms-toolsai.vscode-jupyter-cell-tags"
        Path = Join-Path $vsixDir "ms-toolsai.vscode-jupyter-cell-tags.vsix"
        MinimumBytes = 20000
    },
    [pscustomobject]@{
        Name = "VS Code Jupyter Slide Show"
        ExtensionId = "ms-toolsai.vscode-jupyter-slideshow"
        Path = Join-Path $vsixDir "ms-toolsai.vscode-jupyter-slideshow.vsix"
        MinimumBytes = 20000
    },
    [pscustomobject]@{
        Name = "VS Code Jupyter"
        ExtensionId = "ms-toolsai.jupyter"
        Path = Join-Path $vsixDir "ms-toolsai.jupyter.vsix"
        MinimumBytes = 1000000
    }
)

foreach ($item in $downloads) {
    Download-File -Name $item.Name -Url $item.Url -OutputPath $item.Path -MinimumBytes $item.MinimumBytes
}

foreach ($item in $vsixDownloads) {
    if (Test-Path $item.Path) {
        $existingSize = (Get-Item $item.Path).Length
        if ($existingSize -ge $item.MinimumBytes) {
            Write-Host "[SKIP] $($item.Name) already exists: $($item.Path)"
            continue
        }
        Remove-Item -Force $item.Path
    }

    Write-Host "[INFO] Resolving $($item.ExtensionId) from VS Code Marketplace"
    $package = Get-VsixPackage -ExtensionId $item.ExtensionId
    Write-Host "[INFO] Selected $($package.Version) ($($package.Platform))"
    Download-File -Name $item.Name -Url $package.Url -OutputPath $item.Path -MinimumBytes $item.MinimumBytes
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
    "Files: $($downloads.Count + $vsixDownloads.Count)"
    "MinGW publisher SHA-256: verified"
) | Set-Content -Encoding UTF8 -Path $infoFile

Write-Host ""
Write-Host "Download completed: $Destination"
Write-Host "Checksums: $hashFile"
Write-Host "Next: copy this repository and offline-bundle to the offline computer"
