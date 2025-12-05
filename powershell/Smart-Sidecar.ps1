#Requires -Version 5.1
<#
.SYNOPSIS
    EMRY Smart Sidecar - Advanced memory analytics and search

.DESCRIPTION
    Monitors your EMRY memories and provides:
    - Real-time conversation threading
    - Semantic search and indexing
    - Usage statistics and insights
    - Conversation summaries

.EXAMPLE
    .\Smart-Sidecar.ps1
    .\Smart-Sidecar.ps1 -Search "error handling"
    .\Smart-Sidecar.ps1 -Stats
#>

param(
    [int]$Port = 8766,
    [string]$Search = '',
    [switch]$Stats,
    [switch]$Monitor
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# Configuration
# ============================================================================

$ServerUrl = "http://127.0.0.1:$Port"

# ============================================================================
# Functions
# ============================================================================

function Test-ServerConnection {
    try {
        $response = Invoke-RestMethod -Uri "$ServerUrl/health" -Method GET -TimeoutSec 2
        return $response.ok -eq $true
    } catch {
        return $false
    }
}

function Get-Stats {
    try {
        $response = Invoke-RestMethod -Uri "$ServerUrl/stats" -Method GET -TimeoutSec 5
        return $response.stats
    } catch {
        Write-Error "Could not fetch stats: $_"
        return $null
    }
}

function Search-Memories {
    param([string]$Query)

    try {
        $uri = "$ServerUrl/search?q=$([Uri]::EscapeDataString($Query))&limit=50"
        $response = Invoke-RestMethod -Uri $uri -Method GET -TimeoutSec 10

        return $response.results
    } catch {
        Write-Error "Search failed: $_"
        return @()
    }
}

function Show-Stats {
    $stats = Get-Stats

    if (-not $stats) {
        Write-Warning "Could not retrieve statistics"
        return
    }

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           EMRY Memory Statistics               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Total Messages:      " -NoNewline -ForegroundColor Gray
    Write-Host $stats.total_messages -ForegroundColor Green

    Write-Host "  Total Conversations: " -NoNewline -ForegroundColor Gray
    Write-Host $stats.total_conversations -ForegroundColor Green

    if ($stats.date_range) {
        Write-Host "  Date Range:          " -NoNewline -ForegroundColor Gray
        Write-Host "$($stats.date_range[0]) to $($stats.date_range[1])" -ForegroundColor Yellow
    }

    Write-Host "  Unresolved Errors:   " -NoNewline -ForegroundColor Gray
    if ($stats.unresolved_errors -gt 0) {
        Write-Host $stats.unresolved_errors -ForegroundColor Red
    } else {
        Write-Host "0 ✅" -ForegroundColor Green
    }

    Write-Host ""

    if ($stats.by_platform -and $stats.by_platform.PSObject.Properties.Count -gt 0) {
        Write-Host "  Messages by Platform:" -ForegroundColor Cyan
        Write-Host ""

        foreach ($platform in $stats.by_platform.PSObject.Properties) {
            $name = $platform.Name
            $count = $platform.Value

            $emoji = switch ($name) {
                'chatgpt' { '💬' }
                'claude' { '🤖' }
                'gemini' { '✨' }
                'perplexity' { '🔍' }
                default { '📝' }
            }

            Write-Host "    $emoji $($name.ToUpper()): " -NoNewline -ForegroundColor Gray
            Write-Host $count -ForegroundColor Yellow
        }

        Write-Host ""
    }
}

function Show-SearchResults {
    param([string]$Query, $Results)

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              Search Results                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Query: " -NoNewline -ForegroundColor Gray
    Write-Host "`"$Query`"" -ForegroundColor Yellow
    Write-Host "  Results: " -NoNewline -ForegroundColor Gray
    Write-Host $Results.Count -ForegroundColor Green
    Write-Host ""

    if ($Results.Count -eq 0) {
        Write-Host "  No results found." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    foreach ($result in $Results) {
        $timestamp = if ($result.captured_at) {
            (Get-Date $result.captured_at -Format 'yyyy-MM-dd HH:mm')
        } else {
            'Unknown time'
        }

        $platform = if ($result.platform) {
            $result.platform.ToUpper()
        } else {
            'UNKNOWN'
        }

        $roleEmoji = if ($result.role -eq 'user') { '👤' } else { '🤖' }

        Write-Host "  $roleEmoji " -NoNewline -ForegroundColor Cyan
        Write-Host "[$platform] " -NoNewline -ForegroundColor Magenta
        Write-Host "$timestamp" -ForegroundColor Gray
        Write-Host ""

        # Show content preview (first 200 chars)
        $preview = $result.content
        if ($preview.Length -gt 200) {
            $preview = $preview.Substring(0, 200) + '...'
        }

        $preview = $preview -replace '\n', ' '

        # Highlight search term (simple)
        $highlighted = $preview -replace "(?i)($Query)", "`e[93m`$1`e[0m"

        Write-Host "  $highlighted" -ForegroundColor White
        Write-Host ""

        if ($result.source_url) {
            Write-Host "  🔗 " -NoNewline -ForegroundColor DarkGray
            Write-Host $result.source_url -ForegroundColor DarkGray
            Write-Host ""
        }

        Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Start-Monitor {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          EMRY Real-Time Monitor                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Monitoring your EMRY memories in real-time..." -ForegroundColor Yellow
    Write-Host "  Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""

    $lastStats = $null

    while ($true) {
        try {
            $stats = Get-Stats

            if ($stats) {
                # Check if new messages
                if ($lastStats -and $stats.total_messages -gt $lastStats.total_messages) {
                    $newMessages = $stats.total_messages - $lastStats.total_messages

                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor Gray
                    Write-Host "+$newMessages new message(s) captured! " -NoNewline -ForegroundColor Green
                    Write-Host "(Total: $($stats.total_messages))" -ForegroundColor Cyan
                }

                $lastStats = $stats
            }

            Start-Sleep -Seconds 3
        } catch {
            Write-Warning "Monitor error: $_"
            Start-Sleep -Seconds 5
        }
    }
}

# ============================================================================
# Main
# ============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           EMRY Smart Sidecar v2.0              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check server connection
Write-Host "🔌 Connecting to EMRY server..." -ForegroundColor Yellow

if (-not (Test-ServerConnection)) {
    Write-Host "❌ Cannot connect to EMRY server on port $Port" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the server first:" -ForegroundColor Yellow
    Write-Host "  .\Start-Emry.ps1" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "✅ Connected!" -ForegroundColor Green

# Execute requested operation
if ($Search) {
    Write-Host "🔍 Searching memories..." -ForegroundColor Yellow

    $results = Search-Memories -Query $Search

    Show-SearchResults -Query $Search -Results $results

} elseif ($Stats) {
    Show-Stats

} elseif ($Monitor) {
    Start-Monitor

} else {
    # Default: show stats
    Show-Stats

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                 Commands                       ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Search:  " -NoNewline -ForegroundColor Gray
    Write-Host ".\Smart-Sidecar.ps1 -Search 'your query'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Stats:   " -NoNewline -ForegroundColor Gray
    Write-Host ".\Smart-Sidecar.ps1 -Stats" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Monitor: " -NoNewline -ForegroundColor Gray
    Write-Host ".\Smart-Sidecar.ps1 -Monitor" -ForegroundColor Cyan
    Write-Host ""
}
