# EMRY v2.0 - Eternal Memory

<div align="center">

🧠 **Never forget an AI conversation again.** 🧠

*Your eternal memory for ChatGPT, Claude, Gemini, and more.*

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/yourusername/emry)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.7+-yellow.svg)](https://www.python.org)

</div>

---

## 📖 Table of Contents

- [What is EMRY?](#what-is-emry)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Architecture](#architecture)
- [Advanced Features](#advanced-features)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## 🤔 What is EMRY?

**EMRY** (Eternal Memory) is a powerful system that **automatically captures, organizes, and preserves** all your AI conversations across multiple platforms. Never lose an important insight, code snippet, or brilliant idea again.

### Why EMRY?

- 🔄 **Auto-Capture**: Seamlessly records conversations from ChatGPT, Claude, Gemini, and more
- 📝 **Pristine Formatting**: Generates beautifully formatted, daily markdown files
- 🔍 **Smart Search**: Find any conversation instantly with full-text search
- 🤖 **Auto-Debug**: Automatically detects PowerShell errors and prepares AI-ready bug reports
- 📊 **Analytics**: Track your AI usage patterns and conversation statistics
- 🔒 **Privacy-First**: Everything stays local on your machine
- 💾 **SQLite Backend**: Reliable database with markdown file generation

---

## ✨ Features

### Core Features

- ✅ **Multi-Platform Support**
  - ChatGPT (chat.openai.com, chatgpt.com)
  - Claude (claude.ai)
  - Google Gemini (gemini.google.com)
  - Perplexity (perplexity.ai)
  - Extensible to any AI platform

- ✅ **Beautiful Markdown Files**
  - Auto-organized by date
  - Proper conversation threading
  - Syntax highlighting for code blocks
  - Clean, readable formatting
  - Guaranteed pristine output (no corruption!)

- ✅ **Smart Sidecar**
  - Full-text search across all memories
  - Usage statistics and analytics
  - Real-time monitoring
  - Conversation summaries

- ✅ **PowerShell Integration**
  - Auto-capture PowerShell sessions
  - Error detection and logging
  - Auto-generate bug reports for AI
  - One-click error submission

- ✅ **Privacy Features**
  - Redact sensitive information with `{{ private text }}`
  - Everything runs locally
  - No cloud dependencies
  - Full control over your data

### Advanced Features

- 🎯 Conversation deduplication
- 🔄 Real-time markdown regeneration
- 📊 Platform-specific statistics
- 🔍 Keyword indexing
- 📱 Mobile-ready (future enhancement)
- 🌐 WebSocket support for real-time updates

---

## 🚀 Installation

### Prerequisites

- **Windows 10/11** (or Linux/macOS with minor modifications)
- **Python 3.7+** ([Download here](https://www.python.org/downloads/))
- **Chrome or Edge** browser

### One-Click Install

1. **Clone or download** this repository

2. **Run the installer:**
   ```powershell
   .\INSTALL.ps1
   ```

3. **Follow the prompts**
   - The installer will check Python
   - Install dependencies automatically
   - Create desktop shortcuts
   - Optionally set up auto-start

That's it! 🎉

### Manual Installation

If you prefer manual installation:

```powershell
# Install Python dependencies
cd server
pip install -r requirements.txt

# Create directories
mkdir $env:LOCALAPPDATA\EMRY\memories
mkdir $env:LOCALAPPDATA\EMRY\transcripts

# Done!
```

---

## 🎯 Quick Start

### 1. Start EMRY

**Option A:** Double-click the **"EMRY - Start"** desktop shortcut

**Option B:** Run from PowerShell:
```powershell
.\powershell\Start-Emry.ps1
```

You should see:
```
╔════════════════════════════════════════════════╗
║   EMRY v2.0 - Eternal Memory Server            ║
║   Running on http://127.0.0.1:8766             ║
╚════════════════════════════════════════════════╝

Server is ready! 🚀
```

### 2. Install Browser Extension

1. Open Chrome or Edge
2. Navigate to `chrome://extensions/`
3. Enable **"Developer mode"** (toggle in top right)
4. Click **"Load unpacked"**
5. Select the `extension` folder from your EMRY installation

### 3. Start Capturing!

1. Visit [ChatGPT](https://chat.openai.com), [Claude](https://claude.ai), or [Gemini](https://gemini.google.com)
2. Have a conversation
3. Watch as EMRY automatically captures everything! ✨

### 4. View Your Memories

Your conversations are saved as markdown files:

**Location:** `%LOCALAPPDATA%\EMRY\memories\`

**Files:**
- `2025-12-05.md` - Today's conversations
- `2025-12-04.md` - Yesterday's conversations
- `INDEX.md` - Master index with statistics

---

## 📚 Usage

### Starting & Stopping

```powershell
# Start EMRY
.\powershell\Start-Emry.ps1

# Stop EMRY
.\powershell\Stop-Emry.ps1

# Start without opening browser
.\powershell\Start-Emry.ps1 -NoBrowser

# Use custom port
.\powershell\Start-Emry.ps1 -Port 9000
```

### Smart Sidecar

Access advanced features:

```powershell
# View statistics
.\powershell\Smart-Sidecar.ps1 -Stats

# Search your memories
.\powershell\Smart-Sidecar.ps1 -Search "error handling"

# Real-time monitoring
.\powershell\Smart-Sidecar.ps1 -Monitor
```

### PowerShell Integration

Capture your PowerShell sessions:

```powershell
# Start a captured session
.\powershell\Capture-Session.ps1

# With auto-debug enabled
.\powershell\Capture-Session.ps1 -AutoDebug
```

### Auto-Debug System

When PowerShell errors occur:

```powershell
# View unresolved errors
.\powershell\Auto-Debug.ps1

# Copy error report to clipboard
.\powershell\Auto-Debug.ps1 -CopyToClipboard

# Auto-open ChatGPT with report ready to paste
.\powershell\Auto-Debug.ps1 -OpenInBrowser
```

---

## 🏗️ Architecture

```
EMRY v2.0 Architecture
┌─────────────────────────────────────────────────────┐
│                   Browser Layer                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ ChatGPT  │  │  Claude  │  │  Gemini  │  ...    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       │             │              │                │
│  ┌────┴─────────────┴──────────────┴────┐          │
│  │      EMRY Browser Extension           │          │
│  │  (content scripts + background)       │          │
│  └────────────────┬──────────────────────┘          │
└───────────────────┼─────────────────────────────────┘
                    │ HTTP POST
┌───────────────────┼─────────────────────────────────┐
│                   ▼                                  │
│  ┌──────────────────────────────────────┐           │
│  │      EMRY Python Server               │           │
│  │  (Flask + SocketIO + SQLite)          │           │
│  └──────────────┬──────┬────────┬────────┘           │
│                 │      │        │                    │
│     ┌───────────┘      │        └────────────┐       │
│     ▼                  ▼                     ▼       │
│  ┌─────────┐    ┌──────────┐       ┌────────────┐   │
│  │ SQLite  │    │ Markdown │       │  Sidecar   │   │
│  │   DB    │    │Generator │       │  Indexer   │   │
│  └─────────┘    └──────────┘       └────────────┘   │
│                                                      │
│  Server Components:                                  │
│  • db.py - Database operations                       │
│  • markdown_generator.py - MD file creation          │
│  • emry_server.py - API endpoints                    │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│             PowerShell Layer                         │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │  Capture     │  │  Auto-Debug  │                 │
│  │  Session     │  │  System      │                 │
│  └──────┬───────┘  └──────┬───────┘                 │
│         │                 │                          │
│         └─────────┬───────┘                          │
│                   │ HTTP POST                        │
│                   ▼                                  │
│         [EMRY Server /powershell/*]                  │
└──────────────────────────────────────────────────────┘

Storage:
• SQLite Database: %LOCALAPPDATA%\EMRY\emry.db
• Markdown Files:  %LOCALAPPDATA%\EMRY\memories\*.md
• Transcripts:     %LOCALAPPDATA%\EMRY\transcripts\*.log
```

### Key Components

1. **Browser Extension (MV3)**
   - Content scripts for each platform
   - Universal helper library
   - Background service worker
   - Real-time status badge

2. **Python Server**
   - Flask REST API
   - SQLite database
   - Markdown generator
   - WebSocket support

3. **PowerShell Scripts**
   - Start/Stop management
   - Session capture
   - Auto-debug system
   - Smart Sidecar analytics

---

## 🔧 Advanced Features

### Privacy Redaction

Mark sensitive information to be automatically redacted:

```
My API key is {{sk-1234567890abcdef}} and my password is {{mySecretPass}}
```

EMRY will save:
```
My API key is [PRIVATE] and my password is [PRIVATE]
```

### Custom Port

```powershell
$env:EMRY_PORT = 9000
.\powershell\Start-Emry.ps1
```

### API Endpoints

EMRY exposes a REST API:

```
GET  /health              - Server health check
GET  /config              - Current configuration
POST /capture             - Capture a new message
GET  /search?q=query      - Search memories
GET  /stats               - Usage statistics
POST /regenerate          - Regenerate all markdown files
POST /powershell/session  - Register PS session
POST /powershell/error    - Report an error
GET  /errors/unresolved   - Get unresolved errors
```

### Programmatic Access

```python
import requests

# Capture a message
response = requests.post('http://127.0.0.1:8766/capture', json={
    'role': 'user',
    'content': 'Hello EMRY!',
    'platform': 'custom',
    'url': 'https://example.com'
})

# Search
results = requests.get('http://127.0.0.1:8766/search?q=error').json()
```

---

## 🐛 Troubleshooting

### Server Won't Start

**Problem:** "Cannot connect to EMRY server"

**Solutions:**
1. Check if Python is installed: `python --version`
2. Check if port 8766 is available: `netstat -ano | findstr 8766`
3. Try a different port: `.\powershell\Start-Emry.ps1 -Port 9000`
4. Check the logs in `%LOCALAPPDATA%\EMRY\logs\`

### Extension Not Capturing

**Problem:** Conversations aren't being captured

**Solutions:**
1. Check extension badge - should be green ●
2. Check browser console for errors (F12)
3. Refresh the page
4. Verify server is running: `http://127.0.0.1:8766/health`
5. Check that extension has required permissions

### Markdown Files Corrupted

**Problem:** This shouldn't happen in v2.0!

**Solutions:**
1. Run: `curl -X POST http://127.0.0.1:8766/regenerate`
2. All files will be regenerated from the SQLite database
3. The database is the source of truth

### Python Dependencies Failed

**Problem:** `pip install` errors

**Solutions:**
1. Upgrade pip: `python -m pip install --upgrade pip`
2. Install one by one:
   ```
   pip install flask
   pip install flask-cors
   pip install flask-socketio
   ```
3. Use virtual environment:
   ```
   python -m venv venv
   .\venv\Scripts\activate
   pip install -r requirements.txt
   ```

---

## ❓ FAQ

### Q: Is my data sent to the cloud?

**A:** No! Everything runs locally on your machine. Your conversations never leave your computer.

### Q: What happens if I uninstall a browser?

**A:** Your memories are stored independently. You can switch browsers anytime.

### Q: Can I use this on Mac/Linux?

**A:** Yes! The Python server works cross-platform. You'll need to modify the PowerShell scripts to use bash/zsh.

### Q: How much disk space does this use?

**A:** Very little. Text is highly compressible. Expect ~1MB per month of heavy usage.

### Q: Can I export my data?

**A:** Yes! Your data is already in standard markdown and SQLite formats. Use the `/export/json` API endpoint for JSON export.

### Q: Does this work with other AI platforms?

**A:** Yes! The extension is designed to be extensible. Check `extension/content/` to add new platforms.

### Q: Will this slow down my browser?

**A:** No. The extension uses minimal resources and works in the background.

### Q: Can I sync across devices?

**A:** Not built-in yet, but you can sync the `%LOCALAPPDATA%\EMRY` folder using Dropbox, Google Drive, or OneDrive.

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report Bugs:** Open an issue with details
2. **Suggest Features:** Describe your idea in an issue
3. **Submit Pull Requests:** Fork, code, test, PR!
4. **Improve Documentation:** PRs for docs are always appreciated
5. **Add Platform Support:** Create new content scripts for other AI platforms

### Development Setup

```powershell
# Clone repository
git clone https://github.com/yourusername/emry.git
cd emry

# Install dev dependencies
pip install -r server/requirements.txt

# Run server in debug mode
cd server
python emry_server.py

# Load extension in Chrome
# Navigate to chrome://extensions/
# Enable Developer Mode
# Load unpacked from /extension directory
```

---

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Original EMRY concept and development
- Flask and Python community
- Chrome Extension developers
- Everyone who provides feedback and suggestions

---

## 📞 Support

- **Documentation:** See `docs/` folder
- **Issues:** [GitHub Issues](https://github.com/yourusername/emry/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/emry/discussions)

---

<div align="center">

**EMRY v2.0 - Your Eternal Memory** 🧠

*Made with ❤️ for the AI community*

</div>
