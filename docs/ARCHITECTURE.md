# EMRY v2.0 Architecture

## Overview

EMRY is a three-tier system designed for reliability, extensibility, and ease of use.

## System Components

### 1. Browser Layer (Extension)

**Location:** `/extension/`

The browser extension runs in Chrome/Edge and captures AI conversations in real-time.

#### Components:

- **manifest.json**: Manifest V3 configuration
- **background.js**: Service worker managing extension lifecycle
- **content/universal.js**: Shared utilities for all platforms
- **content/chatgpt.js**: ChatGPT-specific capture logic
- **content/claude.js**: Claude-specific capture logic
- **content/gemini.js**: Gemini-specific capture logic
- **content/perplexity.js**: Perplexity-specific capture logic
- **popup/**: Extension popup UI

#### How It Works:

1. Content scripts inject into AI platform pages
2. MutationObserver watches for new messages
3. Messages are extracted and normalized
4. Universal helper sends to EMRY server via HTTP POST
5. Background worker monitors server connection
6. Badge shows connection status (green/red)

#### Extension Strategy:

```javascript
// Platform-specific detection
if (element has chatgpt-specific-attribute) {
    // Use primary selector
} else if (fallback-pattern-matches) {
    // Use fallback selector
} else {
    // Use generic detection
}
```

Multiple detection strategies ensure resilience to UI changes.

### 2. Server Layer (Python)

**Location:** `/server/`

The Python Flask server is the heart of EMRY, handling all data storage and processing.

#### Components:

**emry_server.py**
- Flask REST API
- WebSocket support (SocketIO)
- Request routing
- Server lifecycle management

**db.py**
- SQLite database operations
- CRUD operations for messages, conversations, errors
- Thread-safe connection management
- Keyword indexing
- Search functionality

**markdown_generator.py**
- Generates pristine markdown files from database
- Daily file organization
- Conversation threading
- Beautiful formatting
- Index generation

#### Database Schema:

```sql
conversations
├── id (PK)
├── platform
├── conversation_id
├── title
├── url
├── started_at
├── last_updated
├── tags
└── metadata

messages
├── id (PK)
├── conversation_id (FK)
├── role
├── content
├── raw_content
├── captured_at
├── source_url
└── metadata

powershell_sessions
├── id (PK)
├── session_id
├── started_at
├── ended_at
├── transcript_path
├── errors_detected
└── metadata

errors
├── id (PK)
├── session_id (FK)
├── error_text
├── context
├── detected_at
├── resolved
└── resolution_notes

search_index
├── id (PK)
├── message_id (FK)
├── keyword
└── relevance
```

#### API Endpoints:

```
GET  /health              - Health check
GET  /config              - Get configuration
POST /capture             - Capture message
GET  /search              - Search messages
GET  /stats               - Get statistics
POST /regenerate          - Regenerate MD files
POST /powershell/session  - Register PS session
POST /powershell/error    - Report error
GET  /errors/unresolved   - Get unresolved errors
GET  /export/json         - Export as JSON
```

### 3. PowerShell Layer

**Location:** `/powershell/`

PowerShell scripts provide Windows integration and advanced features.

#### Scripts:

**Start-Emry.ps1**
- Checks Python installation
- Installs dependencies
- Starts server
- Opens browser with extension
- Creates shortcuts

**Stop-Emry.ps1**
- Gracefully stops server
- Cleans up PID files

**Capture-Session.ps1**
- Starts PowerShell transcript
- Monitors for errors
- Reports errors to EMRY
- Provides error context

**Auto-Debug.ps1**
- Fetches unresolved errors
- Formats for AI submission
- Copies to clipboard
- Opens browser

**Smart-Sidecar.ps1**
- Search functionality
- Statistics display
- Real-time monitoring
- Analytics

## Data Flow

### Message Capture Flow

```
1. User types message on ChatGPT
2. User/Assistant message appears in DOM
3. Content script MutationObserver detects change
4. Content script extracts message content
5. Content script normalizes message (role, platform, etc.)
6. Universal helper checks for duplicates
7. Universal helper discovers server port
8. Universal helper POSTs to /capture endpoint
9. Server validates and sanitizes input
10. Server redacts private information
11. Server saves to SQLite database
12. Server regenerates today's markdown file
13. Server updates index
14. Server emits WebSocket event
15. Extension badge animates success
16. Background worker updates statistics
```

### Markdown Generation Flow

```
1. New message arrives at server
2. Server saves to database
3. Server gets date (YYYY-MM-DD)
4. Server queries all messages for that date
5. Markdown generator groups by conversation
6. Generator formats each conversation
7. Generator writes pristine markdown file
8. Generator updates INDEX.md
9. Files are ready to read
```

### Error Capture Flow

```
1. PowerShell session started with Capture-Session.ps1
2. User runs commands
3. Error occurs
4. PowerShell trap captures error
5. Error formatted with context
6. Error POSTed to /powershell/error
7. Server saves to errors table
8. Server emits WebSocket event
9. Auto-Debug.ps1 can retrieve and format
10. User pastes to AI for help
```

## Design Decisions

### Why SQLite?

- **Reliability**: ACID transactions, no corruption
- **Performance**: Fast for read-heavy workloads
- **Portability**: Single file, no setup
- **Familiarity**: SQL is well-known
- **Backup**: Just copy the .db file

### Why Generate MD from DB?

Original EMRY wrote directly to MD files, which caused:
- Race conditions
- Corruption
- Lost data
- Formatting issues

Solution: Database is source of truth, MD files are generated views.

Benefits:
- Never corrupt
- Always consistent
- Easy to regenerate
- Can export to other formats

### Why Python for Server?

- **Cross-platform**: Works on Windows, Mac, Linux
- **Mature ecosystem**: Flask, SQLite, etc.
- **Easy to maintain**: Readable, well-documented
- **Performance**: Fast enough for local use
- **Extensibility**: Easy to add features

### Why Multiple Detection Strategies?

AI platforms constantly change their UIs. Multiple strategies ensure:
- Primary: Fastest, most reliable
- Fallback: Works when primary breaks
- Generic: Works as last resort

Example for ChatGPT:
```javascript
// Primary: Official attribute
element.getAttribute('data-message-author-role')

// Fallback: DOM structure
article.querySelector('[data-message-author-role="user"]')

// Generic: Class names
element.className.includes('user-message')
```

## Performance Considerations

### Extension Performance

- Debounced MutationObserver (500ms)
- Queue-based message processing
- Deduplication via hashing
- Minimal DOM queries
- Efficient selectors

### Server Performance

- Thread-safe database connections
- Index on commonly queried fields
- Batch operations where possible
- Efficient markdown generation
- WebSocket for real-time updates

### Database Indexing

```sql
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_captured ON messages(captured_at);
CREATE INDEX idx_conversations_platform ON conversations(platform);
CREATE INDEX idx_search_keyword ON search_index(keyword);
```

## Security

### Local-First

- No cloud dependencies
- No external API calls
- All data stays on your machine

### Privacy Redaction

- Configurable markers: `{{` and `}}`
- Applied before database storage
- Regular expression based
- Customizable replacement

### Extension Permissions

Minimal permissions requested:
- `storage`: Save settings
- `activeTab`: Capture from current tab
- `host_permissions`: Only for AI platforms

## Extensibility

### Adding New Platforms

1. Create `/extension/content/newplatform.js`
2. Implement capture logic
3. Add to `manifest.json` content_scripts
4. Test and iterate

### Adding API Endpoints

1. Add route in `emry_server.py`
2. Implement database operations in `db.py`
3. Update documentation
4. Test

### Custom Markdown Formatting

Override methods in `markdown_generator.py`:
- `_render_conversation()`
- `_clean_content()`
- `_format_time()`

## Deployment

### Local Development

```bash
# Server
cd server
python emry_server.py

# Extension
Load unpacked from /extension
```

### Production (User Install)

```powershell
.\INSTALL.ps1
# Creates shortcuts
# Sets up auto-start
# Installs dependencies
```

### Updates

```bash
git pull
pip install -r server/requirements.txt
# Reload extension in chrome://extensions/
```

## Future Enhancements

### Planned

- Semantic search with embeddings
- Conversation summarization
- Mobile app
- Web dashboard
- Plugins system
- Cloud sync (optional)

### Technical Debt

- Add comprehensive unit tests
- CI/CD pipeline
- Automated releases
- Performance profiling
- Memory leak testing

## Troubleshooting

### Common Issues

**Extension not capturing:**
- Check badge color (should be green)
- Check browser console for errors
- Verify server is running
- Check selector matches

**Server won't start:**
- Check Python version
- Check port availability
- Check dependencies installed
- Check logs

**Markdown files wrong:**
- Regenerate from database
- Check database integrity
- Verify date format

## Contributing

See main README.md for contribution guidelines.

Key areas for contribution:
- New platform support
- Improved detection algorithms
- Performance optimizations
- Documentation
- Testing
- Bug fixes

---

*This architecture is designed for longevity, maintainability, and user delight.*
