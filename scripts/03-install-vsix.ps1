[CmdletBinding()]
param(
    [string]$VsixDirectory
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($VsixDirectory)) {
    $VsixDirectory = Join-Path $repoRoot "offline-bundle\vsix"
}

if (-not (Test-Path $VsixDirectory)) {
    throw "VSIX directory not found: $VsixDirectory"
}

$codeCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"),
    (Join-Path $env:ProgramFiles "Microsoft VS Code\bin\code.cmd")
)

$codeCommand = Get-Command code -ErrorAction SilentlyContinue
if ($null -ne $codeCommand) {
    $codePath = $codeCommand.Source
} else {
    $codePath = $codeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($codePath)) {
    throw "VS Code command was not found. Install VS Code first, then rerun this script."
}

$installOrder = @(
    "ms-vscode.cpptools.vsix",
    "ms-python.python.vsix",
    "ms-python.debugpy.vsix",
    "ms-python.vscode-python-envs.vsix",
    "ms-python.vscode-pylance.vsix",
    "formulahendry.code-runner.vsix",
    "yzhang.markdown-all-in-one.vsix",
    "James-Yu.latex-workshop.vsix"
)

foreach ($fileName in $installOrder) {
    $vsixPath = Join-Path $VsixDirectory $fileName
    if (-not (Test-Path $vsixPath)) {
        Write-Warning "Missing plugin package: $fileName"
        continue
    }

    Write-Host "Installing: $fileName"
    & $codePath --install-extension $vsixPath
    if ($LASTEXITCODE -ne 0) {
        throw "VSIX installation failed: $fileName"
    }
}

Write-Host ""
Write-Host "Installed VS Code extensions:"
& $codePath --list-extensions
Write-Host ""
Write-Host "VSIX installation completed. Restart VS Code."
