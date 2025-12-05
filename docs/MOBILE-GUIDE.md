# EMRY Mobile Integration Guide

## 📱 Overview

This guide shows you how to capture AI conversations on your iPhone (and Android) and sync them to your EMRY system.

**Mobile Strategy:**
- iOS: Use Shortcuts + Share Sheet + Bookmarklets
- Android: Use Tasker + Share menu + JavaScript bookmarklets
- Both: Access your PC's EMRY server over local network or VPN

---

## 🍎 iPhone / iOS Setup

### Prerequisites

1. **EMRY server running on your PC**
2. **iPhone and PC on same WiFi network** (or use VPN/Tailscale for remote access)
3. **iOS Shortcuts app** (pre-installed on iOS 13+)

---

### Method 1: iOS Shortcuts (Recommended)

This method lets you capture ANY text to EMRY from the Share Sheet.

#### Step 1: Find Your PC's IP Address

On your PC, run:
```powershell
# PowerShell
ipconfig
# Look for "IPv4 Address" under your WiFi adapter
# Example: 192.168.1.100
```

Or run:
```powershell
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress
```

#### Step 2: Make EMRY Accessible from Network

Update your EMRY server to listen on all interfaces:

**Edit `server/emry_server.py`**, change this line:
```python
# Before:
HOST = '127.0.0.1'

# After:
HOST = '0.0.0.0'  # Listen on all network interfaces
```

**Restart EMRY:**
```powershell
.\powershell\Stop-Emry.ps1
.\powershell\Start-Emry.ps1
```

**Allow Windows Firewall:**
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "EMRY Server" -Direction Inbound -LocalPort 8766 -Protocol TCP -Action Allow
```

#### Step 3: Test from iPhone

Open Safari on your iPhone and visit:
```
http://YOUR_PC_IP:8766/health
```

You should see:
```json
{"ok": true, "status": "running", "version": "2.0.0"}
```

✅ If you see this, you're ready for the next step!

#### Step 4: Install "Capture to EMRY" Shortcut

**Option A: Import from file**

1. I'll create the shortcut file for you (see below)
2. AirDrop it to your iPhone
3. Open in Shortcuts app

**Option B: Manual creation**

1. Open **Shortcuts** app on iPhone
2. Tap **"+"** to create new shortcut
3. Add these actions:

```
Action 1: Get URLs from Shortcut Input
Action 2: Get Contents of URL
Action 3: Get Text from URL's Content
Action 4: Set variable "PageContent" to Text
Action 5: Get URL from Shortcut Input
Action 6: Set variable "PageURL" to URL
Action 7: URL action with:
   - Method: POST
   - URL: http://YOUR_PC_IP:8766/capture
   - Headers: Content-Type = application/json
   - Request Body: JSON
     {
       "role": "user",
       "content": "[PageContent variable]",
       "platform": "ios-safari",
       "url": "[PageURL variable]"
     }
Action 8: Show notification "Captured to EMRY ✓"
```

3. Name it: **"Capture to EMRY"**
4. In settings, enable:
   - ✅ Show in Share Sheet
   - ✅ Accept: Safari Web Pages, Text, URLs

#### Step 5: Using the Shortcut

**To capture a conversation:**

1. Visit ChatGPT/Claude/Gemini in Safari
2. Tap the **Share button** (square with arrow)
3. Scroll to **"Capture to EMRY"**
4. Tap it
5. ✅ Page content sent to EMRY!

---

### Method 2: Safari Bookmarklet

A bookmarklet captures the current page with one tap.

#### Step 1: Create Bookmarklet

1. In Safari, bookmark any page
2. Edit the bookmark
3. Change the URL to this JavaScript:

```javascript
javascript:(function(){
  const pc=document.body.innerText;
  const pu=window.location.href;
  const pt=document.title;
  fetch('http://YOUR_PC_IP:8766/capture',{
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({
      role:'user',
      content:pc,
      platform:'ios-safari',
      url:pu,
      metadata:{title:pt,source:'bookmarklet'}
    })
  }).then(r=>r.json()).then(d=>alert('Captured to EMRY ✅')).catch(e=>alert('Error: '+e));
})();
```

4. Name it: **"📝 EMRY Capture"**

#### Step 2: Using the Bookmarklet

1. Visit ChatGPT/Claude/Gemini
2. Tap the **address bar**
3. Start typing "EMRY"
4. Tap the **"📝 EMRY Capture"** bookmark
5. ✅ Page captured!

---

### Method 3: Siri Integration

Make EMRY voice-activated!

#### Setup:

1. Create a shortcut (Method 1)
2. Edit the shortcut
3. Go to Settings → Add to Siri
4. Record phrase: **"Capture to EMRY"** or **"Save to eternal memory"**

#### Usage:

While on ChatGPT/Claude/Gemini:
- Say: **"Hey Siri, capture to EMRY"**
- Siri captures the page automatically!

---

### Method 4: iOS Share Extension (Advanced)

For automatic capture similar to the browser extension.

**Requirements:**
- Xcode (Mac required)
- Apple Developer account (free tier works)

**Steps:**
1. Create iOS Safari Share Extension
2. Use WKWebView to extract page content
3. POST to EMRY server
4. Package as IPA and install via Xcode

*(Full guide available if you want to build this - let me know!)*

---

## 🤖 Android Setup

### Prerequisites

1. **EMRY server running on PC**
2. **Android phone and PC on same network**
3. **Tasker app** ($3.49, one-time) or **HTTP Shortcuts** (free)

---

### Method 1: HTTP Shortcuts (Free)

1. Install **HTTP Shortcuts** from Play Store
2. Create new shortcut:
   - Name: Capture to EMRY
   - Method: POST
   - URL: `http://YOUR_PC_IP:8766/capture`
   - Body:
     ```json
     {
       "role": "user",
       "content": "{clipboard}",
       "platform": "android",
       "url": ""
     }
     ```
3. Add to home screen
4. Copy text → Tap shortcut → Captured!

### Method 2: Tasker (Advanced)

1. Install **Tasker** ($3.49)
2. Create Task:
   ```
   Task: Capture to EMRY
   1. HTTP Request
      - Method: POST
      - URL: http://YOUR_PC_IP:8766/capture
      - Body: {"role":"user","content":"%CLIP","platform":"android","url":""}
      - Headers: Content-Type: application/json
   2. Flash: Captured to EMRY ✓
   ```
3. Add quick settings tile or widget

### Method 3: Chrome Bookmarklet

Same as iOS bookmarklet - create a bookmark with the JavaScript code above.

---

## 🌐 Remote Access (Access EMRY from Anywhere)

### Option 1: Tailscale (Recommended)

**Tailscale creates a secure VPN so you can access your PC from anywhere.**

#### Setup on PC:

1. Install Tailscale: https://tailscale.com/download
2. Sign in and connect
3. Note your Tailscale IP (e.g., `100.64.0.1`)

#### Setup on iPhone:

1. Install Tailscale from App Store
2. Sign in with same account
3. Connect
4. Use Tailscale IP in shortcuts: `http://100.64.0.1:8766`

**Benefits:**
- Secure (encrypted)
- Works anywhere (home, office, coffee shop)
- No port forwarding needed
- Free for personal use

### Option 2: ngrok (Quick & Easy)

**ngrok exposes your local server to the internet.**

#### Setup:

1. Download ngrok: https://ngrok.com/download
2. Run on PC:
   ```powershell
   ngrok http 8766
   ```
3. Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`)
4. Use this URL in your mobile shortcuts

**⚠️ Security Note:** Anyone with the URL can access your EMRY. Use ngrok's authentication or Tailscale instead.

### Option 3: Home Router Port Forwarding (Not Recommended)

Exposes your PC to the internet - use Tailscale instead for security.

---

## 📱 Mobile Workflows

### Workflow 1: Quick Text Capture

1. Copy interesting text from any app
2. Tap EMRY widget/shortcut
3. ✅ Captured!

### Workflow 2: Full Page Capture

1. Visit AI chat in Safari/Chrome
2. Tap Share → Capture to EMRY
3. ✅ Entire conversation captured!

### Workflow 3: Voice Capture (iOS)

1. "Hey Siri, capture to EMRY"
2. ✅ Current page captured!

### Workflow 4: Automatic Capture (Future)

*Possible with native app development:*
- Background web scraper
- Periodic sync with EMRY
- Notification when new messages detected

---

## 🔄 Sync Strategy

### Option A: Real-Time Sync

- Mobile → EMRY server → Database → MD files
- Instant synchronization
- Requires network connection

### Option B: Queue-Based Sync

Create a local queue on mobile:
1. Captures saved to local storage when offline
2. Sync when connected to EMRY
3. Prevents data loss

*(Advanced - requires custom app)*

### Option C: Cloud Intermediary

1. Mobile → Dropbox/Google Drive
2. PC watcher imports from cloud
3. Works without direct connection

---

## 🛠️ Advanced: Native Mobile App

Want a dedicated EMRY mobile app? Here's the approach:

### iOS App (Swift)

**Features:**
- Safari extension for automatic capture
- Share sheet integration
- Offline queue
- Local SQLite cache
- Sync with PC

**Tech Stack:**
- SwiftUI for UI
- WKWebView for web scraping
- URLSession for API calls
- Core Data for local storage

### Android App (Kotlin)

**Features:**
- Chrome custom tabs integration
- Share intent receiver
- Background service
- Local Room database
- Sync service

**Tech Stack:**
- Jetpack Compose for UI
- OkHttp for networking
- Room for local database
- WorkManager for sync

### Cross-Platform (Flutter / React Native)

Build once, deploy to both platforms.

**Let me know if you want me to start building a mobile app!**

---

## 📊 Mobile Capture Formats

### Automatic Platform Detection

EMRY automatically detects mobile captures:

```json
{
  "platform": "ios-safari",
  "metadata": {
    "source": "iPhone",
    "device": "iPhone 15 Pro",
    "os": "iOS 17.2"
  }
}
```

Shows in markdown as:
```markdown
**📱 USER (iOS)** *(02:15:30 PM)*
```

---

## 🎯 Best Practices

### 1. Use Descriptive Titles

Before capturing, set a good conversation title in ChatGPT.

### 2. Capture Full Conversations

Wait until conversation is complete before capturing.

### 3. Tag Mobile Captures

Add metadata for easy search:
```json
{
  "metadata": {
    "tags": ["mobile", "on-the-go", "quick-note"]
  }
}
```

### 4. Verify Captures

Check EMRY's memories folder after mobile captures to confirm sync.

### 5. Use Privacy Markers

Even on mobile: `{{private text}}`

---

## 🔧 Troubleshooting

### "Cannot connect to server"

**Causes:**
- PC is sleeping/off
- Firewall blocking
- Wrong IP address
- Not on same network

**Solutions:**
```powershell
# Check EMRY is running
curl http://localhost:8766/health

# Check firewall
New-NetFirewallRule -DisplayName "EMRY" -Direction Inbound -LocalPort 8766 -Protocol TCP -Action Allow

# Find correct IP
ipconfig

# Keep PC awake
powercfg /change standby-timeout-ac 0
```

### "Capture succeeds but not in EMRY"

**Check:**
1. Database: `%LOCALAPPDATA%\EMRY\emry.db`
2. Regenerate markdown: `curl -X POST http://localhost:8766/regenerate`
3. Check server logs

### "Slow on mobile data"

Use Tailscale for optimized mobile data usage.

---

## 🚀 Quick Start Guide

### For iPhone (5 minutes):

1. Get PC IP: `ipconfig` → `192.168.1.100`
2. Edit `emry_server.py`: `HOST = '0.0.0.0'`
3. Allow firewall: `New-NetFirewallRule -DisplayName "EMRY" -Direction Inbound -LocalPort 8766 -Protocol TCP -Action Allow`
4. Test: Safari → `http://192.168.1.100:8766/health`
5. Create shortcut (see Method 1)
6. ✅ Start capturing!

### For Remote Access (10 minutes):

1. Install Tailscale on PC and iPhone
2. Connect both devices
3. Note Tailscale IP: `100.x.x.x`
4. Update shortcuts with Tailscale IP
5. ✅ Capture from anywhere!

---

## 📱 Mobile Shortcuts Collection

I can create ready-to-use shortcuts for:

- ✅ **Capture Current Page** - Grabs entire page
- ✅ **Capture Selection** - Just highlighted text
- ✅ **Capture with Note** - Add custom notes
- ✅ **Voice Capture** - Dictate notes to EMRY
- ✅ **Quick Clip** - Clipboard to EMRY
- ✅ **Screenshot to EMRY** - OCR images (future)

**Want me to generate these .shortcut files for you?**

---

## 🎉 What's Next?

### Immediate (You can do now):
- Set up iOS Shortcuts
- Configure network access
- Start mobile capturing

### Near Future (Coming soon):
- Native iOS app
- Native Android app
- Offline queue
- Push notifications for captures

### Long Term (Roadmap):
- Voice-to-text integration
- Screenshot OCR
- Automatic mobile browser capture
- Apple Watch integration
- Android Wear integration

---

## 💡 Pro Tips

### 1. **Home Screen Widget** (iOS)
Add EMRY shortcut to home screen for one-tap access.

### 2. **Back Tap** (iOS)
Settings → Accessibility → Touch → Back Tap → Double Tap → Capture to EMRY

### 3. **Quick Settings** (Android)
Add EMRY Tasker task to quick settings tile.

### 4. **Voice Commands**
"Hey Siri/Google, capture to EMRY" becomes muscle memory!

### 5. **Offline Queue**
When building native app, queue captures for later sync.

---

## 🤝 Community Shortcuts

Share your mobile workflows!

- Submit shortcuts to: [GitHub Discussions]
- Download community shortcuts
- Share tips and tricks

---

**Your eternal memory is now pocket-sized!** 🧠📱✨

Questions? Want me to build the native app? Let me know!
