# Changelog

All notable changes to EMRY will be documented in this file.

## [2.0.0] - 2025-12-05

### 🎉 Major Rewrite - Complete Resurrection

This is a complete rewrite and modernization of the original EMRY system. The original stopped working after browser updates, but v2.0 brings it back better than ever!

### ✨ Added

- **Cross-Platform Backend**: Moved from PowerShell HTTP server to robust Python Flask server
- **SQLite Database**: Reliable storage with SQLite, generating markdown files on-demand
- **Multi-Platform Support**: ChatGPT, Claude, Gemini, and Perplexity support out of the box
- **Smart Sidecar**: Advanced search, analytics, and monitoring system
- **Auto-Debug System**: Automatically detects PowerShell errors and formats them for AI submission
- **PowerShell Integration**: Capture transcripts and errors from PowerShell sessions
- **Browser Extension (MV3)**: Modern Manifest V3 extension with adaptive content scripts
- **Beautiful Markdown**: Pristine, guaranteed-formatted daily markdown files
- **Real-time Updates**: WebSocket support for live capture notifications
- **Privacy Redaction**: Mark sensitive info with `{{private}}` syntax
- **Full-Text Search**: Search across all captured conversations
- **Statistics Dashboard**: Track your AI usage patterns
- **One-Click Installer**: Easy installation with INSTALL.ps1
- **Desktop Shortcuts**: Quick access to all EMRY features
- **Conversation Threading**: Smart detection of conversation boundaries
- **Deduplication**: Never capture the same message twice
- **API Endpoints**: REST API for programmatic access

### 🔄 Changed

- Backend: PowerShell → Python (cross-platform, more reliable)
- Storage: Direct MD writes → SQLite + generated MD files
- Extension: Manifest V2 → Manifest V3 (Chrome's latest standard)
- Platform Detection: Single-site → Universal multi-platform detector
- Error Handling: Manual checks → Automatic error tracking and reporting
- UI: None → Beautiful popup with status and statistics

### 🐛 Fixed

- **MD File Corruption**: Files are now generated from database, never corrupted
- **Missing Messages**: Multiple detection strategies ensure no messages are lost
- **Browser Compatibility**: Works with latest Chrome, Edge, and Chromium browsers
- **UI Changes**: Adaptive selectors handle ChatGPT/Claude UI changes
- **Port Conflicts**: Auto-discovers available ports in range
- **Race Conditions**: Queue-based message processing prevents duplicates
- **Timestamp Issues**: All times now in ISO 8601 format with proper timezone handling

### 📚 Documentation

- Comprehensive README with architecture diagrams
- Installation guide
- Usage examples
- Troubleshooting section
- API documentation
- FAQ section

### 🚀 Performance

- Faster capture with async operations
- Efficient database indexing
- Minimal browser overhead
- Smart caching and deduplication

### 🔒 Security

- All data stays local
- No cloud dependencies
- Privacy-first design
- Configurable redaction

---

## [1.0.0] - Original Version (Deprecated)

### The Original EMRY

The original EMRY was a groundbreaking PowerShell-based system that captured ChatGPT conversations. It worked beautifully for its time but eventually broke due to:

- ChatGPT UI changes
- Chrome extension updates (MV2 → MV3 transition)
- MD file race conditions
- Port binding issues

**Key Features of Original:**
- PowerShell HTTP server
- Direct markdown file writes
- ChatGPT-only support
- Basic privacy redaction
- Desktop shortcut launcher

**What We Learned:**
- Need for reliable backend (Python > PowerShell HTTP server)
- Database as source of truth (not direct file writes)
- Multi-platform support essential
- Better error handling required
- Need for easier maintenance and updates

---

## Future Roadmap

### v2.1.0 (Planned)
- [ ] Mobile app support (iOS/Android)
- [ ] Cloud sync option (optional)
- [ ] Conversation tagging system
- [ ] Export to PDF/DOCX
- [ ] Web dashboard
- [ ] Conversation summaries with AI
- [ ] Voice memo integration

### v2.2.0 (Planned)
- [ ] Semantic search with embeddings
- [ ] Conversation analytics
- [ ] Theme customization
- [ ] Plugins system
- [ ] Multi-user support
- [ ] Encrypted backups

### Community Requests
- [ ] Claude Desktop app support
- [ ] Perplexity app integration
- [ ] Browser history integration
- [ ] Automatic conversation titling
- [ ] Related conversation suggestions

---

Have a feature request? [Open an issue!](https://github.com/yourusername/emry/issues)
