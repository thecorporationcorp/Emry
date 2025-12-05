#Requires -Version 5.1
<#
.SYNOPSIS
    EMRY PowerShell Session Capture

.DESCRIPTION
    Starts a PowerShell transcript and monitors for errors.
    Automatically sends errors to EMRY for tracking.

.EXAMPLE
    .\Capture-Session.ps1
#>

param(
    [int]$Port = 8766,
    [switch]$AutoDebug
)

$ErrorActionPreference = 'Continue'

# ============================================================================
# Configuration
# ============================================================================

$RootDir = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
    Join-Path $env:LOCALAPPDATA 'EMRY'
} else {
    Join-Path $HOME '.emry'
}

$SessionId = [Guid]::NewGuid().ToString('N')
$TranscriptDir = Join-Path $RootDir 'transcripts'
$TranscriptFile = Join-Path $TranscriptDir "session_$SessionId.log"

# ============================================================================
# Functions
# ============================================================================

function Register-Session {
    try {
        $serverUrl = "http://127.0.0.1:$Port"

        $body = @{
            session_id = $SessionId
            transcript_path = $TranscriptFile
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$serverUrl/powershell/session" `
            -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 5

        if ($response.ok) {
            $script:SessionDbId = $response.session_db_id
            return $true
        }
    } catch {
        Write-Warning "Could not register session with EMRY server: $_"
    }
    return $false
}

function Send-Error {
    param(
        [string]$ErrorText,
        [string]$Context = ''
    )

    if (-not $script:SessionDbId) {
        return
    }

    try {
        $serverUrl = "http://127.0.0.1:$Port"

        $body = @{
            session_db_id = $script:SessionDbId
            error = $ErrorText
            context = $Context
        } | ConvertTo-Json

        Invoke-RestMethod -Uri "$serverUrl/powershell/error" `
            -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 5 | Out-Null

        Write-Host "📝 Error logged to EMRY" -ForegroundColor Yellow
    } catch {
        # Silently fail
    }
}

function Format-ErrorReport {
    param($ErrorRecord)

    $report = @"
╔════════════════════════════════════════════════╗
║            PowerShell Error Detected           ║
╚════════════════════════════════════════════════╝

Error: $($ErrorRecord.Exception.Message)

Location: $($ErrorRecord.InvocationInfo.ScriptName):$($ErrorRecord.InvocationInfo.ScriptLineNumber)

Command: $($ErrorRecord.InvocationInfo.Line)

Category: $($ErrorRecord.CategoryInfo.Category)

Stack Trace:
$($ErrorRecord.ScriptStackTrace)

Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Session: $SessionId
"@

    return $report
}

# ============================================================================
# Main
# ============================================================================

# Create transcript directory
New-Item -ItemType Directory -Force -Path $TranscriptDir | Out-Null

# Start transcript
try {
    Start-Transcript -Path $TranscriptFile -Force
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     EMRY PowerShell Session Capture Active    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Session ID: $SessionId" -ForegroundColor Gray
    Write-Host "  Transcript: $TranscriptFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  All commands and outputs are being captured." -ForegroundColor Yellow
    Write-Host "  Errors will be automatically logged to EMRY." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To end session: exit" -ForegroundColor Gray
    Write-Host ""

    # Register session with EMRY
    if (Register-Session) {
        Write-Host "✅ Connected to EMRY server" -ForegroundColor Green
        Write-Host ""
    }
} catch {
    Write-Warning "Could not start transcript: $_"
}

# Error trap
$script:SessionDbId = $null
trap {
    $errorRecord = $_

    Write-Host ""
    Write-Host "══════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ERROR DETECTED" -ForegroundColor Red
    Write-Host "══════════════════════════════════════════════" -ForegroundColor Red

    # Format and display error
    $report = Format-ErrorReport -ErrorRecord $errorRecord

    Write-Host $report -ForegroundColor Yellow

    # Send to EMRY
    $context = @"
Command: $($errorRecord.InvocationInfo.Line)
Location: $($errorRecord.InvocationInfo.ScriptName):$($errorRecord.InvocationInfo.ScriptLineNumber)
"@

    Send-Error -ErrorText $errorRecord.Exception.Message -Context $context

    if ($AutoDebug) {
        Write-Host ""
        Write-Host "🤖 Auto-Debug Mode: Error report prepared" -ForegroundColor Cyan
        Write-Host "   Send this to ChatGPT/Claude for analysis!" -ForegroundColor Cyan
    }

    Write-Host ""

    continue
}

# Keep session alive
Write-Host "Session is ready. Run your commands below." -ForegroundColor Green
Write-Host ""
