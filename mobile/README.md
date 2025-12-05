# EMRY Mobile Integration

This folder contains resources for using EMRY on your iPhone and Android devices.

## 📱 Quick Start

### For iPhone:

1. **Enable network access on your PC:**
   ```powershell
   # Run as Administrator
   .\powershell\Enable-NetworkAccess.ps1
   ```

2. **Get your PC's IP address** (the script will show it, e.g., `192.168.1.100`)

3. **Test from iPhone Safari:**
   ```
   http://YOUR_PC_IP:8766/health
   ```
   Should show: `{"ok": true, "status": "running"}`

4. **Set up iOS Shortcuts:**
   - See `ios-shortcuts-guide.md` for step-by-step instructions
   - Import pre-made shortcuts from `ios-shortcuts/` folder
   - Add to Share Sheet for easy access

5. **Start capturing!**
   - Visit ChatGPT/Claude/Gemini in Safari
   - Tap Share → "Capture to EMRY"
   - ✅ Conversation saved!

### For Android:

1. Enable network access (same as iPhone step 1)
2. Install "HTTP Shortcuts" app from Play Store (free)
3. See `android-setup.md` for configuration
4. Copy text → Tap shortcut → Captured!

### For Remote Access (From Anywhere):

**Use Tailscale (Recommended):**

1. Install Tailscale on PC: https://tailscale.com/download
2. Install Tailscale on iPhone/Android
3. Sign in with same account on both
4. Get your Tailscale IP (e.g., `100.64.0.1`)
5. Use Tailscale IP in your shortcuts
6. ✅ Access EMRY from anywhere securely!

## 📂 Folder Contents

```
mobile/
├── README.md                    # This file
├── ios-shortcuts-guide.md       # Detailed iOS setup
├── android-setup.md             # Detailed Android setup
├── ios-shortcuts/               # Pre-made iOS shortcuts
│   ├── Capture-Page.shortcut    # Capture full page
│   ├── Capture-Selection.shortcut # Capture selected text
│   └── Quick-Clip.shortcut      # Capture clipboard
├── android-shortcuts/           # HTTP Shortcuts configs
│   └── emry-capture.json        # Import into HTTP Shortcuts app
└── bookmarklets/                # JavaScript bookmarklets
    ├── chatgpt-capture.js       # ChatGPT bookmarklet
    └── universal-capture.js     # Works on any page
```

## 🎯 Use Cases

### Scenario 1: On-the-Go Capture
You're at a coffee shop using your iPhone:
1. Ask ChatGPT a question
2. Get a brilliant response
3. Tap Share → Capture to EMRY
4. Later, search your EMRY memories on PC

### Scenario 2: Voice Capture
You're driving and get an idea:
1. "Hey Siri, capture to EMRY"
2. Dictate your thought
3. EMRY saves it to your memories

### Scenario 3: Cross-Device Continuation
Start on iPhone, finish on PC:
1. Begin conversation on iPhone, capture to EMRY
2. Get home, open EMRY memories on PC
3. Continue the conversation with full context

### Scenario 4: Travel Mode
You're traveling with just your phone:
1. Connect via Tailscale VPN
2. Access your home EMRY server
3. Capture conversations on the road
4. Everything syncs to your home PC

## 🔧 Configuration

### Change Server URL

If you move or change networks, update your shortcuts:

**iOS:**
1. Open Shortcuts app
2. Edit "Capture to EMRY" shortcut
3. Find the "Get Contents of URL" action
4. Update URL to new IP

**Android:**
1. Open HTTP Shortcuts app
2. Edit EMRY shortcut
3. Change URL field

### Custom Port

Using a different port? (e.g., 9000)

Set environment variable:
```powershell
$env:EMRY_PORT = 9000
.\powershell\Start-Emry.ps1
```

Update mobile shortcuts to use new port:
```
http://YOUR_PC_IP:9000/capture
```

## 🌐 Network Options

### Option 1: Local Network (Same WiFi)
- ✅ Fast
- ✅ Free
- ✅ Private
- ❌ Only works on same network

### Option 2: Tailscale VPN
- ✅ Works anywhere
- ✅ Secure (encrypted)
- ✅ Easy setup
- ✅ Free for personal use
- ✅ No port forwarding

### Option 3: Dynamic DNS + Port Forwarding
- ✅ Works anywhere
- ❌ Complex setup
- ❌ Security risks
- ❌ Not recommended

**Recommendation: Use Tailscale for remote access!**

## 📊 Mobile Capture Statistics

EMRY tracks where captures come from:

```markdown
### Conversation 5: ChatGPT (Mobile)
**Started:** 03:45:22 PM
**Platform:** iOS Safari
**Device:** iPhone 15 Pro

**📱 USER** *(03:45:22 PM)*
[Your question from mobile...]
```

Search for mobile captures:
```powershell
.\powershell\Smart-Sidecar.ps1 -Search "platform:ios"
```

## 🐛 Troubleshooting

### "Cannot connect to server"

**Check 1:** Is EMRY running?
```powershell
.\powershell\Start-Emry.ps1
```

**Check 2:** Is firewall allowing connections?
```powershell
# Run as Administrator
.\powershell\Enable-NetworkAccess.ps1
```

**Check 3:** Are you on the same network?
- PC and phone must be on same WiFi
- Or use Tailscale VPN

**Check 4:** Is IP address correct?
```powershell
ipconfig
# Look for IPv4 Address under WiFi adapter
```

### "Connection timeout"

**Possible causes:**
- PC is sleeping → Adjust power settings
- Firewall blocking → Run Enable-NetworkAccess.ps1
- Wrong port → Check EMRY is using 8766
- Network isolation → Some public WiFi blocks device-to-device

### "Captured but not showing in EMRY"

**Solutions:**
```powershell
# Regenerate markdown files
curl -X POST http://localhost:8766/regenerate

# Check today's file
Get-Content $env:LOCALAPPDATA\EMRY\memories\$(Get-Date -Format 'yyyy-MM-dd').md

# View recent captures in database
.\powershell\Smart-Sidecar.ps1 -Stats
```

## 💡 Pro Tips

### 1. **Home Screen Widget (iOS)**
Add EMRY shortcut to home screen:
- Long press shortcut → Share → Add to Home Screen
- Now one-tap capture!

### 2. **Back Tap (iOS 14+)**
Trigger EMRY with back tap:
- Settings → Accessibility → Touch → Back Tap
- Double Tap → Capture to EMRY
- Triple Tap → Quick Clip

### 3. **Share Sheet Reordering (iOS)**
Move EMRY to top of Share Sheet:
- Tap Share button
- Scroll to "Edit Actions"
- Drag "Capture to EMRY" to top

### 4. **Offline Queue (Future)**
When native app is built:
- Captures saved locally when offline
- Auto-sync when connected
- Never lose a capture!

### 5. **Voice Shortcuts (iOS)**
"Hey Siri, capture to EMRY" becomes automatic:
- Works from lock screen
- Hands-free operation
- Perfect for driving

## 🔮 Future Mobile Features

### Coming Soon:
- ✅ Native iOS app
- ✅ Native Android app
- ✅ Offline queue
- ✅ Push notifications
- ✅ Widget shortcuts
- ✅ Apple Watch integration
- ✅ Android Wear integration

### In Development:
- Screenshot OCR capture
- Voice-to-text notes
- Apple Pencil annotations
- Handoff integration (start on iPhone, finish on Mac)

### Community Requested:
- Automatic browser capture (like desktop extension)
- Background sync
- Mobile dashboard
- Conversation tagging on mobile

## 📚 Additional Resources

- **Full Mobile Guide:** `../docs/MOBILE-GUIDE.md`
- **ChatGPT Instructions:** `../docs/CHATGPT-INSTRUCTIONS.md`
- **Architecture:** `../docs/ARCHITECTURE.md`
- **Main README:** `../README.md`

## 🤝 Help & Support

**Having issues?**
1. Check troubleshooting section above
2. Review MOBILE-GUIDE.md for detailed setup
3. Check GitHub Issues
4. Join discussions

**Want to contribute?**
- Share your mobile shortcuts
- Submit iOS/Android improvements
- Help build native apps
- Improve documentation

---

## 🚀 Quick Command Reference

```powershell
# Enable mobile access (run as admin)
.\powershell\Enable-NetworkAccess.ps1

# Start EMRY
.\powershell\Start-Emry.ps1

# Check server status
curl http://localhost:8766/health

# Find your IP
ipconfig

# Test from mobile
# Visit: http://YOUR_PC_IP:8766/health

# View mobile captures
.\powershell\Smart-Sidecar.ps1 -Search "platform:ios"
```

---

**Your eternal memory, now in your pocket!** 🧠📱✨
