#Requires -Version 5.1
<#
.SYNOPSIS
    Stop the EMRY server

.DESCRIPTION
    Stops the running EMRY Python server gracefully.

.EXAMPLE
    .\Stop-Emry.ps1
#>

$ErrorActionPreference = 'Stop'

$RootDir = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
    Join-Path $env:LOCALAPPDATA 'EMRY'
} else {
    Join-Path $HOME '.emry'
}

$PidFile = Join-Path $RootDir 'server.pid'

Write-Host "🛑 Stopping EMRY server..." -ForegroundColor Yellow

if (-not (Test-Path $PidFile)) {
    Write-Host "✅ Server is not running (no PID file found)" -ForegroundColor Green
    exit 0
}

$pid = Get-Content $PidFile -Raw

if ($pid) {
    $process = Get-Process -Id $pid -ErrorAction SilentlyContinue

    if ($process) {
        try {
            $process | Stop-Process -Force
            Start-Sleep -Seconds 1
            Write-Host "✅ Server stopped" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to stop process: $_"
        }
    } else {
        Write-Host "✅ Server is not running (process not found)" -ForegroundColor Green
    }
}

# Clean up PID file
Remove-Item $PidFile -Force -ErrorAction SilentlyContinue

Write-Host ""
