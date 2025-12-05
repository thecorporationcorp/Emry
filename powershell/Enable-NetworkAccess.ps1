#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enable EMRY network access for mobile devices

.DESCRIPTION
    Configures EMRY to be accessible from your iPhone/Android:
    - Updates server to listen on all network interfaces
    - Adds Windows Firewall rule
    - Displays your PC's IP address
    - Tests connectivity

.EXAMPLE
    .\Enable-NetworkAccess.ps1
#>

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   EMRY Mobile Network Access Setup             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator and try again:" -ForegroundColor Yellow
    Write-Host "  Right-click PowerShell → Run as Administrator" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Get root directory
$RootDir = Join-Path $PSScriptRoot '..'
$ServerScript = Join-Path $RootDir 'server' 'emry_server.py'

# Step 1: Check if server file exists
Write-Host "1️⃣  Checking EMRY server file..." -ForegroundColor Yellow

if (-not (Test-Path $ServerScript)) {
    Write-Host "❌ Server file not found: $ServerScript" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found server file" -ForegroundColor Green
Write-Host ""

# Step 2: Update server to listen on all interfaces
Write-Host "2️⃣  Configuring server for network access..." -ForegroundColor Yellow

$serverContent = Get-Content $ServerScript -Raw

if ($serverContent -match "HOST = '127\.0\.0\.1'") {
    Write-Host "   Updating HOST configuration..." -ForegroundColor Gray

    $serverContent = $serverContent -replace "HOST = '127\.0\.0\.1'", "HOST = '0.0.0.0'  # Listen on all interfaces (mobile access)"

    Set-Content -Path $ServerScript -Value $serverContent -Encoding UTF8

    Write-Host "✅ Server configured for network access" -ForegroundColor Green
} elseif ($serverContent -match "HOST = '0\.0\.0\.0'") {
    Write-Host "✅ Server already configured for network access" -ForegroundColor Green
} else {
    Write-Warning "Could not find HOST configuration. Manual update may be needed."
}

Write-Host ""

# Step 3: Add Windows Firewall rule
Write-Host "3️⃣  Configuring Windows Firewall..." -ForegroundColor Yellow

$ruleName = "EMRY Server (Port 8766)"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "✅ Firewall rule already exists" -ForegroundColor Green
} else {
    try {
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound `
            -LocalPort 8766 `
            -Protocol TCP `
            -Action Allow `
            -Profile Any | Out-Null

        Write-Host "✅ Firewall rule created" -ForegroundColor Green
    } catch {
        Write-Warning "Could not create firewall rule: $_"
        Write-Host "   You may need to manually allow port 8766" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 4: Display IP addresses
Write-Host "4️⃣  Finding your PC's IP address..." -ForegroundColor Yellow
Write-Host ""

$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object IPAddress, InterfaceAlias

if ($ipAddresses) {
    Write-Host "   Your PC's IP address(es):" -ForegroundColor Cyan
    Write-Host ""

    foreach ($ip in $ipAddresses) {
        $address = $ip.IPAddress
        $interface = $ip.InterfaceAlias

        Write-Host "   📡 $address" -ForegroundColor Green
        Write-Host "      Interface: $interface" -ForegroundColor Gray
        Write-Host ""
    }

    # Pick the most likely one (WiFi or Ethernet)
    $primaryIP = ($ipAddresses | Where-Object {
        $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*"
    } | Select-Object -First 1).IPAddress

    if (-not $primaryIP) {
        $primaryIP = $ipAddresses[0].IPAddress
    }

} else {
    Write-Warning "Could not detect IP address. Make sure you're connected to a network."
    $primaryIP = "YOUR_PC_IP"
}

Write-Host ""

# Step 5: Instructions for mobile
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  SETUP COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📱 MOBILE SETUP INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Make sure your iPhone/Android is on the same WiFi network" -ForegroundColor White
Write-Host ""
Write-Host "2. On your mobile device, test the connection:" -ForegroundColor White
Write-Host "   Open Safari/Chrome and visit:" -ForegroundColor Gray
Write-Host ""
Write-Host "   http://$primaryIP`:8766/health" -ForegroundColor Yellow
Write-Host ""
Write-Host "   You should see: {`"ok`": true, `"status`": `"running`"}" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Use this URL in your mobile shortcuts/bookmarklets:" -ForegroundColor White
Write-Host ""
Write-Host "   http://$primaryIP`:8766/capture" -ForegroundColor Yellow
Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 For detailed mobile setup instructions, see:" -ForegroundColor Cyan
Write-Host "   $RootDir\docs\MOBILE-GUIDE.md" -ForegroundColor Gray
Write-Host ""

# Step 6: Test server
Write-Host "5️⃣  Testing server..." -ForegroundColor Yellow

try {
    $testUrl = "http://127.0.0.1:8766/health"
    $response = Invoke-RestMethod -Uri $testUrl -TimeoutSec 3 -ErrorAction Stop

    if ($response.ok) {
        Write-Host "✅ EMRY server is running!" -ForegroundColor Green
    } else {
        Write-Warning "Server responded but status is unexpected"
    }
} catch {
    Write-Warning "Server is not running. Start it with:"
    Write-Host "   .\powershell\Start-Emry.ps1" -ForegroundColor Cyan
}

Write-Host ""

# Copy IP to clipboard
try {
    "http://$primaryIP`:8766" | Set-Clipboard
    Write-Host "💡 Tip: Server URL copied to clipboard!" -ForegroundColor Cyan
    Write-Host ""
} catch {
    # Clipboard not available, no problem
}

Write-Host "═══════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start EMRY if not running: .\powershell\Start-Emry.ps1" -ForegroundColor Gray
Write-Host "  2. Test from mobile: http://$primaryIP`:8766/health" -ForegroundColor Gray
Write-Host "  3. Set up mobile shortcuts (see MOBILE-GUIDE.md)" -ForegroundColor Gray
Write-Host ""
Write-Host "For remote access (from anywhere), see:" -ForegroundColor Yellow
Write-Host "  → Tailscale setup in MOBILE-GUIDE.md" -ForegroundColor Gray
Write-Host ""
