[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $repoRoot "verification-report.txt"
$report = New-Object System.Collections.Generic.List[string]

function Add-ReportLine {
    param([string]$Text)
    $report.Add($Text)
    Write-Host $Text
}

function Check-Command {
    param(
        [string]$DisplayName,
        [string]$CommandName,
        [string[]]$VersionArguments
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Add-ReportLine "[FAIL] $DisplayName not found in PATH"
        return $false
    }

    Add-ReportLine "[ OK ] $DisplayName: $($command.Source)"
    try {
        $versionText = & $command.Source @VersionArguments 2>&1 | Select-Object -First 1
        Add-ReportLine "       $versionText"
    } catch {
        Add-ReportLine "[WARN] Unable to read $DisplayName version: $($_.Exception.Message)"
    }
    return $true
}

$os = Get-CimInstance Win32_OperatingSystem
Add-ReportLine "Offline development environment verification"
Add-ReportLine "Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')"
Add-ReportLine "OS: $($os.Caption) $($os.Version), build $($os.BuildNumber)"
Add-ReportLine "64-bit OS: $([Environment]::Is64BitOperatingSystem)"
Add-ReportLine ""

$gccOk = Check-Command -DisplayName "GCC" -CommandName "gcc" -VersionArguments @("--version")
$gppOk = Check-Command -DisplayName "G++" -CommandName "g++" -VersionArguments @("--version")
$gdbOk = Check-Command -DisplayName "GDB" -CommandName "gdb" -VersionArguments @("--version")
$pythonOk = Check-Command -DisplayName "Python" -CommandName "python" -VersionArguments @("--version")
$codeOk = Check-Command -DisplayName "VS Code" -CommandName "code" -VersionArguments @("--version")
$pdfLatexOk = Check-Command -DisplayName "pdfLaTeX" -CommandName "pdflatex" -VersionArguments @("--version")
$xeLatexOk = Check-Command -DisplayName "XeLaTeX" -CommandName "xelatex" -VersionArguments @("--version")
$latexmkOk = Check-Command -DisplayName "latexmk" -CommandName "latexmk" -VersionArguments @("-v")

if ($gppOk) {
    $testRoot = Join-Path $env:TEMP "win10-offline-dev-kit-test"
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
    $sourcePath = Join-Path $testRoot "hello.cpp"
    $programPath = Join-Path $testRoot "hello.exe"
    @"
#include <iostream>
int main() {
    std::cout << "C++ environment OK" << std::endl;
    return 0;
}
"@ | Set-Content -Encoding ASCII -Path $sourcePath

    & g++ -std=c++17 -g $sourcePath -o $programPath 2>&1 | ForEach-Object { Add-ReportLine "       $_" }
    if (($LASTEXITCODE -eq 0) -and (Test-Path $programPath)) {
        $programOutput = & $programPath
        Add-ReportLine "[ OK ] C++ compile and run test: $programOutput"
    } else {
        Add-ReportLine "[FAIL] C++ compile test failed"
    }
}

if ($pythonOk) {
    $pythonTest = & python -c "import sys; print(sys.executable); print('Python environment OK')" 2>&1
    $pythonTest | ForEach-Object { Add-ReportLine "       $_" }
}

if ($codeOk) {
    Add-ReportLine ""
    Add-ReportLine "VS Code extensions:"
    & code --list-extensions 2>&1 | ForEach-Object { Add-ReportLine "       $_" }
}

$report | Set-Content -Encoding UTF8 -Path $reportPath
Write-Host ""
Write-Host "Verification report: $reportPath"
