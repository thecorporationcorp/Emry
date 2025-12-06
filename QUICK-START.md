# 🚀 EMRY v2.0 - Quick Start Installation Guide

## Welcome to EMRY - Your Eternal Memory!

This guide will get you up and running in **under 10 minutes**.

---

## 📋 Prerequisites

Before you start, make sure you have:

- ✅ **Windows 10/11** (or Mac/Linux with minor tweaks)
- ✅ **Python 3.7+** - [Download here](https://www.python.org/downloads/) if you don't have it
- ✅ **Chrome or Edge** browser
- ✅ **Administrator access** (for firewall rules if using mobile)

---

## 🎯 Installation Methods

Choose the method that works best for you:

### Method 1: One-Click Install (Recommended) ⚡

**This is the easiest way!**

1. **Download this repository**
   - If you have git: `git clone [repository-url]`
   - Or download as ZIP and extract

2. **Run the installer**
   ```powershell
   # Right-click PowerShell → Run as Administrator
   cd path\to\Emry
   .\INSTALL.ps1
   ```

3. **Follow the prompts**
   - Installer checks Python
   - Installs dependencies
   - Creates shortcuts
   - Sets up everything automatically

4. **Done!** 🎉

---

### Method 2: Manual Install (If you prefer control)

#### Step 1: Install Python Dependencies

```powershell
cd path\to\Emry\server
pip install -r requirements.txt
```

#### Step 2: Create Directories

The installer does this automatically, but if you want to do it manually:

```powershell
mkdir $env:LOCALAPPDATA\EMRY\memories
mkdir $env:LOCALAPPDATA\EMRY\transcripts
mkdir $env:LOCALAPPDATA\EMRY\logs
```

#### Step 3: You're Ready!

---

## 🚀 Starting EMRY

### Option 1: Desktop Shortcut

After installation, double-click:
- **"EMRY - Start"** on your desktop

### Option 2: PowerShell

```powershell
cd path\to\Emry
.\powershell\Start-Emry.ps1
```

You should see:
```
╔══════════════════════════════════════════════╗
║   EMRY v2.0 - Eternal Memory Server          ║
║   Running on http://127.0.0.1:8766           ║
╚══════════════════════════════════════════════╝

[CloudSync] Google Drive detected: C:\Users\...\Google Drive\My Drive
[CloudSync] ✓ Synced 0 files to Google Drive
[CloudSync] ✓ Auto-sync started

Database: C:\Users\...\AppData\Local\EMRY\emry.db
Memories: C:\Users\...\AppData\Local\EMRY\memories

Server is ready! 🚀
```

---

## 🌐 Installing the Browser Extension

**CRITICAL: This is required for automatic capture!**

### Step 1: Open Chrome/Edge

Navigate to: `chrome://extensions/`

### Step 2: Enable Developer Mode

Toggle the **"Developer mode"** switch in the top right corner

### Step 3: Load Extension

1. Click **"Load unpacked"**
2. Navigate to: `path\to\Emry\extension`
3. Select the `extension` folder
4. Click **"Select Folder"**

### Step 4: Verify

You should see:
- **EMRY - Eternal Memory** extension installed
- Badge shows **green ●** (connected) or **red ●** (server not running)

### Step 5: Pin Extension (Optional)

Click the puzzle piece icon → Pin EMRY for easy access

---

## ✅ Testing Everything Works

### Test 1: Server Health Check

Open browser and visit:
```
http://127.0.0.1:8766/health
```

Should show:
```json
{"ok": true, "status": "running", "version": "2.0.0", "timestamp": "..."}
```

✅ **Server is working!**

### Test 2: Capture a Conversation

1. Go to [ChatGPT](https://chat.openai.com)
2. Ask ChatGPT a question
3. Wait for response
4. Check extension badge - should flash **✓**

### Test 3: View Your Memories

Open: `%LOCALAPPDATA%\EMRY\memories\`

You should see:
- `2025-12-06.md` (today's file)
- `INDEX.md` (master index)

Open today's file - your conversation is there! 🎉

---

## 🎯 Next Steps (Optional But Recommended)

### 1. Set Up ChatGPT Custom Instructions (5 minutes)

**Makes ChatGPT EMRY-aware!**

1. Open: `docs/CHATGPT-INSTRUCTIONS.md`
2. Copy the custom instructions
3. Go to [ChatGPT](https://chat.openai.com) → Settings → Personalization
4. Paste into both sections
5. Save

Now ChatGPT will naturally reference your EMRY memories! 🧠

### 2. Enable Mobile Access (10 minutes)

**Capture from your iPhone!**

```powershell
# Run as Administrator
.\powershell\Enable-NetworkAccess.ps1
```

Follow the guide: `docs/MOBILE-GUIDE.md`

### 3. Set Up Auto-Start (Optional)

The installer asks about this. If you skipped it:

1. Press `Win + R`
2. Type: `shell:startup`
3. Create shortcut to: `powershell\Start-Emry.ps1`

EMRY will start automatically with Windows! 🚀

---

## 🔧 Troubleshooting

### Problem: "Python not found"

**Solution:**
1. Install Python from: https://www.python.org/downloads/
2. ✅ **IMPORTANT:** Check "Add Python to PATH" during installation
3. Restart PowerShell
4. Run installer again

### Problem: "Module not found" errors

**Solution:**
```powershell
cd path\to\Emry\server
pip install --upgrade pip
pip install -r requirements.txt
```

### Problem: Extension shows red badge

**Solution:**
1. Make sure EMRY server is running
2. Restart the server: `.\powershell\Stop-Emry.ps1` then `.\powershell\Start-Emry.ps1`
3. Refresh the browser
4. Check: http://127.0.0.1:8766/health

### Problem: "Permission denied" when installing

**Solution:**
Run PowerShell as Administrator:
1. Right-click PowerShell
2. Select "Run as Administrator"
3. Run installer again

### Problem: Firewall blocking

**Solution:**
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "EMRY Server" -Direction Inbound -LocalPort 8766 -Protocol TCP -Action Allow
```

---

## 📚 Important File Locations

### Your Memories
```
%LOCALAPPDATA%\EMRY\memories\
├── 2025-12-06.md        (Today's conversations)
├── 2025-12-05.md        (Yesterday's)
├── INDEX.md             (Master index)
└── _archive\            (Old files)
```

### Google Drive Sync (Automatic)
```
Google Drive\My Drive\EMRY-Memories\
└── (Same files, auto-synced)
```

### Database (Source of Truth)
```
%LOCALAPPDATA%\EMRY\emry.db
```

### PowerShell Transcripts
```
%LOCALAPPDATA%\EMRY\transcripts\
```

---

## 🎮 Quick Commands Reference

```powershell
# Start EMRY
.\powershell\Start-Emry.ps1

# Stop EMRY
.\powershell\Stop-Emry.ps1

# Search memories
.\powershell\Smart-Sidecar.ps1 -Search "your query"

# View statistics
.\powershell\Smart-Sidecar.ps1 -Stats

# Monitor real-time
.\powershell\Smart-Sidecar.ps1 -Monitor

# Enable mobile access
.\powershell\Enable-NetworkAccess.ps1

# Auto-debug errors
.\powershell\Auto-Debug.ps1

# Capture PowerShell session
.\powershell\Capture-Session.ps1
```

---

## 📖 Documentation

### Essential Reading:
- **README.md** - Complete user guide
- **CHATGPT-INSTRUCTIONS.md** - Make ChatGPT EMRY-aware
- **ADVANTAGES.md** - What EMRY means for you
- **MOBILE-GUIDE.md** - iPhone/Android setup

### Technical:
- **ARCHITECTURE.md** - System design
- **CHANGELOG.md** - Version history

---

## 🆘 Getting Help

### Check the Docs
Most questions are answered in:
- `README.md` - Main documentation
- `docs/ARCHITECTURE.md` - Technical details
- Troubleshooting section above

### Common Issues
- Server not starting → Check Python installation
- Extension not capturing → Verify extension is loaded
- Files not syncing → Check Google Drive is installed
- Mobile not connecting → Run Enable-NetworkAccess.ps1

---

## ✨ First Time Checklist

After installation, make sure:

- [ ] EMRY server starts without errors
- [ ] Extension shows green badge
- [ ] ChatGPT conversation gets captured
- [ ] Markdown file appears in memories folder
- [ ] Google Drive sync is working (if installed)
- [ ] ChatGPT custom instructions added
- [ ] Tested search functionality

**If all checked - you're ready to go!** 🎉

---

## 🚀 What Now?

1. **Use AI normally** - ChatGPT, Claude, Gemini, etc.
2. **EMRY captures everything** - Automatically
3. **Search when needed** - `Smart-Sidecar.ps1 -Search "topic"`
4. **Enjoy eternal memory!** 🧠

---

## 💡 Pro Tips

### Tip 1: Create Keyboard Shortcuts

Add to your PowerShell profile:
```powershell
function emry { .\path\to\Emry\powershell\Start-Emry.ps1 }
function emry-search { param($q) .\path\to\Emry\powershell\Smart-Sidecar.ps1 -Search $q }
```

Now just type: `emry-search "Python"`

### Tip 2: Use Privacy Markers

When sharing sensitive info:
```
My API key is {{sk-1234567890abcdef}}
```

EMRY saves: `My API key is [PRIVATE]`

### Tip 3: Review Daily Files

End of each day:
1. Open today's markdown file
2. Review conversations
3. Add tags or notes
4. Learn from your interactions

### Tip 4: Leverage ChatGPT Integration

Ask ChatGPT:
- "Generate search keywords for this conversation"
- "Summarize our discussion for my EMRY notes"
- "What topics have we covered this week?"

---

## 🎊 Welcome to EMRY!

**You now have eternal memory for all AI conversations!**

- Never lose another conversation
- Build on previous knowledge
- Search across all platforms
- Access from anywhere
- Completely automatic

**Your AI journey is now preserved forever.** 🚀

---

## 📞 Support

- **Documentation:** Check `docs/` folder
- **Troubleshooting:** See section above
- **Updates:** Check CHANGELOG.md

---

**Enjoy your eternal memory!** 🧠✨

*Questions? Everything is documented in the README and docs folder.*
