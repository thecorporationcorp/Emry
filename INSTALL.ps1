#Requires -Version 5.1
<#
.SYNOPSIS
    EMRY v2.0 - One-Click Installer

.DESCRIPTION
    Installs EMRY (Eternal Memory) system:
    - Checks dependencies (Python, pip)
    - Installs Python packages
    - Creates desktop shortcuts
    - Sets up automatic startup (optional)
    - Runs initial setup

.EXAMPLE
    .\INSTALL.ps1
    .\INSTALL.ps1 -NoAutoStart
    .\INSTALL.ps1 -Force
#>

[CmdletBinding()]
param(
    [switch]$NoAutoStart,
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
if ($Verbose) { $VerbosePreference = 'Continue' }

# ============================================================================
# Configuration
# ============================================================================

$RootDir = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
    Join-Path $env:LOCALAPPDATA 'EMRY'
} else {
    Join-Path $HOME '.emry'
}

$InstallDir = $PSScriptRoot
$Desktop = [Environment]::GetFolderPath('Desktop')
$StartMenu = [Environment]::GetFolderPath('StartMenu')

# ============================================================================
# Functions
# ============================================================================

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                  ║" -ForegroundColor Cyan
    Write-Host "║       EMRY v2.0 - ETERNAL MEMORY INSTALLER       ║" -ForegroundColor Cyan
    Write-Host "║                                                  ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Your AI conversations, forever remembered." -ForegroundColor Gray
    Write-Host ""
}

function Test-Administrator {
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    return $false
}

function Test-Python {
    Write-Host "🐍 Checking Python..." -ForegroundColor Yellow

    $pythonCmd = $null

    # Try python3 first
    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = 'python3'
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = 'python'
    }

    if (-not $pythonCmd) {
        Write-Host "❌ Python not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install Python 3.7 or later from:" -ForegroundColor Yellow
        Write-Host "  https://www.python.org/downloads/" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Make sure to check 'Add Python to PATH' during installation!" -ForegroundColor Yellow
        Write-Host ""

        $response = Read-Host "Would you like to open the Python download page? (Y/N)"
        if ($response -eq 'Y' -or $response -eq 'y') {
            Start-Process "https://www.python.org/downloads/"
        }

        exit 1
    }

    $version = & $pythonCmd --version 2>&1
    Write-Host "✅ Found: $version" -ForegroundColor Green

    # Check version
    $versionMatch = $version -match 'Python (\d+)\.(\d+)'
    if ($versionMatch) {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]

        if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 7)) {
            Write-Warning "Python 3.7+ is recommended. You have $version"
        }
    }

    Write-Host ""
    return $pythonCmd
}

function Install-PythonPackages {
    param([string]$PythonCmd)

    Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
    Write-Host ""

    $requirementsFile = Join-Path $InstallDir 'server' 'requirements.txt'

    if (-not (Test-Path $requirementsFile)) {
        Write-Error "requirements.txt not found at: $requirementsFile"
    }

    try {
        & $pythonCmd -m pip install --upgrade pip -q
        & $pythonCmd -m pip install -r $requirementsFile -q

        Write-Host "✅ Python packages installed successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Some packages may have failed to install: $_"
        Write-Host "You can try installing manually later with:" -ForegroundColor Yellow
        Write-Host "  pip install -r $requirementsFile" -ForegroundColor Cyan
    }

    Write-Host ""
}

function Create-Directories {
    Write-Host "📁 Creating directories..." -ForegroundColor Yellow

    $dirs = @(
        $RootDir
        (Join-Path $RootDir 'memories')
        (Join-Path $RootDir 'transcripts')
        (Join-Path $RootDir 'logs')
    )

    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Verbose "Created: $dir"
    }

    Write-Host "✅ Directories created" -ForegroundColor Green
    Write-Host ""
}

function Create-Shortcuts {
    Write-Host "🔗 Creating shortcuts..." -ForegroundColor Yellow

    $startScript = Join-Path $InstallDir 'powershell' 'Start-Emry.ps1'
    $stopScript = Join-Path $InstallDir 'powershell' 'Stop-Emry.ps1'
    $sidecarScript = Join-Path $InstallDir 'powershell' 'Smart-Sidecar.ps1'

    # Desktop shortcuts
    $shortcuts = @(
        @{
            Name = 'EMRY - Start'
            Target = 'powershell.exe'
            Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$startScript`""
            Icon = 'powershell.exe,0'
        }
        @{
            Name = 'EMRY - Stop'
            Target = 'powershell.exe'
            Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$stopScript`""
            Icon = 'powershell.exe,0'
        }
        @{
            Name = 'EMRY - Smart Sidecar'
            Target = 'powershell.exe'
            Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$sidecarScript`""
            Icon = 'powershell.exe,0'
        }
    )

    $shell = New-Object -ComObject WScript.Shell

    foreach ($shortcut in $shortcuts) {
        try {
            $shortcutPath = Join-Path $Desktop "$($shortcut.Name).lnk"

            $sc = $shell.CreateShortcut($shortcutPath)
            $sc.TargetPath = $shortcut.Target
            $sc.Arguments = $shortcut.Arguments
            $sc.IconLocation = $shortcut.Icon
            $sc.WorkingDirectory = $InstallDir
            $sc.Save()

            Write-Verbose "Created shortcut: $($shortcut.Name)"
        } catch {
            Write-Warning "Could not create shortcut $($shortcut.Name): $_"
        }
    }

    Write-Host "✅ Desktop shortcuts created" -ForegroundColor Green
    Write-Host ""
}

function Setup-AutoStart {
    if ($NoAutoStart) {
        Write-Host "⏭️  Skipping auto-start setup" -ForegroundColor Gray
        Write-Host ""
        return
    }

    Write-Host "🚀 Setting up auto-start..." -ForegroundColor Yellow

    $response = Read-Host "Would you like EMRY to start automatically with Windows? (Y/N)"

    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "⏭️  Skipped auto-start" -ForegroundColor Gray
        Write-Host ""
        return
    }

    $startScript = Join-Path $InstallDir 'powershell' 'Start-Emry.ps1'
    $startupFolder = [Environment]::GetFolderPath('Startup')
    $shortcutPath = Join-Path $startupFolder 'EMRY.lnk'

    try {
        $shell = New-Object -ComObject WScript.Shell
        $sc = $shell.CreateShortcut($shortcutPath)
        $sc.TargetPath = 'powershell.exe'
        $sc.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$startScript`" -NoBrowser"
        $sc.WorkingDirectory = $InstallDir
        $sc.Save()

        Write-Host "✅ Auto-start enabled" -ForegroundColor Green
    } catch {
        Write-Warning "Could not setup auto-start: $_"
    }

    Write-Host ""
}

function Show-NextSteps {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          INSTALLATION COMPLETE! 🎉               ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  EMRY is ready to capture your AI conversations!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  1. Start EMRY:" -ForegroundColor White
    Write-Host "     • Double-click 'EMRY - Start' on your desktop" -ForegroundColor Gray
    Write-Host "     • Or run: .\powershell\Start-Emry.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Load the browser extension:" -ForegroundColor White
    Write-Host "     • Open Chrome/Edge" -ForegroundColor Gray
    Write-Host "     • Go to: chrome://extensions/" -ForegroundColor Gray
    Write-Host "     • Enable 'Developer mode'" -ForegroundColor Gray
    Write-Host "     • Click 'Load unpacked'" -ForegroundColor Gray
    Write-Host "     • Select folder: $InstallDir\extension" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Visit ChatGPT, Claude, or Gemini!" -ForegroundColor White
    Write-Host "     • Your conversations will be automatically captured" -ForegroundColor Gray
    Write-Host "     • Memories saved to: $RootDir\memories" -ForegroundColor Gray
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host "  DESKTOP SHORTCUTS:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  • EMRY - Start          → Start the server" -ForegroundColor Cyan
    Write-Host "  • EMRY - Stop           → Stop the server" -ForegroundColor Cyan
    Write-Host "  • EMRY - Smart Sidecar  → Search & analytics" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host "  MORE INFO:" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  • README: $InstallDir\README.md" -ForegroundColor Gray
    Write-Host "  • Documentation: $InstallDir\docs\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Need help? Check the README or documentation!" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# Main Installation
# ============================================================================

Write-Banner

Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "  INSTALLATION STARTING" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# Check if already installed
if ((Test-Path $RootDir) -and -not $Force) {
    Write-Host "⚠️  EMRY appears to be already installed at:" -ForegroundColor Yellow
    Write-Host "  $RootDir" -ForegroundColor Cyan
    Write-Host ""
    $response = Read-Host "Reinstall? This will preserve your existing memories. (Y/N)"

    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host ""
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }

    Write-Host ""
}

# Check Python
$pythonCmd = Test-Python

# Install packages
Install-PythonPackages -PythonCmd $pythonCmd

# Create directories
Create-Directories

# Create shortcuts
Create-Shortcuts

# Setup auto-start
Setup-AutoStart

# Show next steps
Show-NextSteps

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
