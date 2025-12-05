<parameter name="content">#Requires -Version 5.1
<#
.SYNOPSIS
    EMRY v2.0 - Start the Eternal Memory system

.DESCRIPTION
    Starts the EMRY Python server and opens a browser with the extension loaded.
    This is your one-click launcher for EMRY.

.EXAMPLE
    .\Start-Emry.ps1
    .\Start-Emry.ps1 -Port 8766
    .\Start-Emry.ps1 -NoBrowser
#>

param(
    [int]$Port = 8766,
    [switch]$NoBrowser,
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

$ServerDir = Join-Path $PSScriptRoot '..' 'server'
$ExtensionDir = Join-Path $PSScriptRoot '..' 'extension'
$PythonScript = Join-Path $ServerDir 'emry_server.py'
$PidFile = Join-Path $RootDir 'server.pid'

# ============================================================================
# Functions
# ============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       EMRY v2.0 - Eternal Memory System       ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Python {
    try {
        $pythonCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) {
            'python3'
        } elseif (Get-Command python -ErrorAction SilentlyContinue) {
            'python'
        } else {
            $null
        }

        if (-not $pythonCmd) {
            throw "Python not found"
        }

        $version = & $pythonCmd --version 2>&1
        Write-Verbose "Found Python: $version"

        return $pythonCmd
    } catch {
        Write-Host "❌ Python not found!" -ForegroundColor Red
        Write-Host "   Please install Python 3.7+ from https://www.python.org/" -ForegroundColor Yellow
        exit 1
    }
}

function Install-Dependencies {
    param([string]$PythonCmd)

    Write-Host "📦 Checking Python dependencies..." -ForegroundColor Yellow

    $RequirementsFile = Join-Path $ServerDir 'requirements.txt'

    try {
        & $PythonCmd -m pip install -q -r $RequirementsFile
        Write-Host "✅ Dependencies installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install dependencies: $_"
        Write-Host "Continuing anyway..." -ForegroundColor Yellow
    }
}

function Test-ServerRunning {
    if (Test-Path $PidFile) {
        $pid = Get-Content $PidFile -Raw
        if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
            return $true
        }
    }
    return $false
}

function Start-Server {
    param([string]$PythonCmd)

    Write-Host "🚀 Starting EMRY server on port $Port..." -ForegroundColor Cyan

    # Set environment variable for port
    $env:EMRY_PORT = $Port

    # Start Python server in background
    $process = Start-Process -FilePath $PythonCmd -ArgumentList $PythonScript `
        -WindowStyle Hidden -PassThru -WorkingDirectory $ServerDir

    # Save PID
    $process.Id | Set-Content $PidFile -Force

    # Wait for server to start
    Start-Sleep -Seconds 2

    # Check if started successfully
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ Server started successfully on port $Port" -ForegroundColor Green
                return $true
            }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }

    Write-Warning "Server may not have started correctly. Check logs."
    return $false
}

function Open-Browser {
    if ($NoBrowser) {
        return
    }

    Write-Host "🌐 Opening browser with EMRY extension..." -ForegroundColor Cyan

    $chromeArgs = @(
        '--new-window'
        "--user-data-dir=`"$RootDir\ChromeSession`""
        "--load-extension=`"$ExtensionDir`""
        'https://chat.openai.com/'
    )

    $launched = $false

    # Try Chrome
    if (-not $launched) {
        try {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                Start-Process 'chrome.exe' -ArgumentList $chromeArgs -ErrorAction Stop
            } else {
                Start-Process 'google-chrome' -ArgumentList $chromeArgs -ErrorAction Stop
            }
            $launched = $true
            Write-Host "✅ Chrome opened" -ForegroundColor Green
        } catch {
            Write-Verbose "Chrome not available: $_"
        }
    }

    # Try Edge
    if (-not $launched -and ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
        try {
            Start-Process 'msedge.exe' -ArgumentList $chromeArgs -ErrorAction Stop
            $launched = $true
            Write-Host "✅ Edge opened" -ForegroundColor Green
        } catch {
            Write-Verbose "Edge not available: $_"
        }
    }

    if (-not $launched) {
        Write-Warning "Could not auto-open browser. Please:"
        Write-Host "  1. Open Chrome/Edge" -ForegroundColor Yellow
        Write-Host "  2. Go to chrome://extensions/" -ForegroundColor Yellow
        Write-Host "  3. Enable Developer Mode" -ForegroundColor Yellow
        Write-Host "  4. Click 'Load unpacked' and select: $ExtensionDir" -ForegroundColor Yellow
    }
}

# ============================================================================
# Main
# ============================================================================

Write-Banner

# Check if already running
if (Test-ServerRunning) {
    Write-Host "✅ EMRY server is already running on port $Port" -ForegroundColor Green
    Write-Host ""
    Write-Host "To stop: .\Stop-Emry.ps1" -ForegroundColor Gray
    Write-Host "To restart: .\Stop-Emry.ps1 ; .\Start-Emry.ps1" -ForegroundColor Gray
    exit 0
}

# Check Python
$pythonCmd = Test-Python

# Install dependencies
Install-Dependencies -PythonCmd $pythonCmd

# Create root directory
New-Item -ItemType Directory -Force -Path $RootDir | Out-Null

# Start server
$started = Start-Server -PythonCmd $pythonCmd

if ($started) {
    # Open browser
    Open-Browser

    Write-Host ""
    Write-Host "════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  EMRY is running! 🎉" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Server:   http://127.0.0.1:$Port" -ForegroundColor Cyan
    Write-Host "  Memories: $RootDir\memories" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Visit ChatGPT, Claude, or Gemini to start capturing!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To stop: .\Stop-Emry.ps1" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "❌ Failed to start server. Please check the logs." -ForegroundColor Red
    exit 1
}
