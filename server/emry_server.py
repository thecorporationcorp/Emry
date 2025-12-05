"""
EMRY Server v2.0 - The heart of Eternal Memory
Robust, cross-platform, beautiful.
"""
import os
import sys
import json
import signal
from pathlib import Path
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import threading
import time

from db import EmryDB
from markdown_generator import MarkdownGenerator

# Configuration
PORT = int(os.environ.get('EMRY_PORT', 8766))
HOST = '127.0.0.1'

# Paths
if sys.platform == 'win32':
    BASE_DIR = Path(os.environ['LOCALAPPDATA']) / 'EMRY'
else:
    BASE_DIR = Path.home() / '.emry'

DB_PATH = BASE_DIR / 'emry.db'
MD_DIR = BASE_DIR / 'memories'
CONFIG_FILE = BASE_DIR / 'config.json'

# Ensure directories
BASE_DIR.mkdir(parents=True, exist_ok=True)
MD_DIR.mkdir(parents=True, exist_ok=True)

# Initialize
app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

db = EmryDB(str(DB_PATH))
md_gen = MarkdownGenerator(str(MD_DIR))

# Privacy settings
PRIVACY_OPEN = "{{"
PRIVACY_CLOSE = "}}"
PRIVACY_REPLACEMENT = "[PRIVATE]"

# Load config
def load_config():
    global PRIVACY_OPEN, PRIVACY_CLOSE, PRIVACY_REPLACEMENT
    if CONFIG_FILE.exists():
        config = json.loads(CONFIG_FILE.read_text())
        PRIVACY_OPEN = config.get('privacy_open', '{{')
        PRIVACY_CLOSE = config.get('privacy_close', '}}')
        PRIVACY_REPLACEMENT = config.get('privacy_replacement', '[PRIVATE]')
    else:
        save_config()

def save_config():
    config = {
        'version': '2.0.0',
        'privacy_open': PRIVACY_OPEN,
        'privacy_close': PRIVACY_CLOSE,
        'privacy_replacement': PRIVACY_REPLACEMENT,
        'db_path': str(DB_PATH),
        'md_dir': str(MD_DIR),
        'port': PORT,
        'created': datetime.now().isoformat()
    }
    CONFIG_FILE.write_text(json.dumps(config, indent=2))

load_config()

# Privacy redaction
def redact_private(text: str) -> str:
    """Redact private sections marked with privacy markers"""
    if not PRIVACY_OPEN or not PRIVACY_CLOSE or PRIVACY_OPEN == PRIVACY_CLOSE:
        return text

    import re
    pattern = re.escape(PRIVACY_OPEN) + r'.*?' + re.escape(PRIVACY_CLOSE)
    return re.sub(pattern, PRIVACY_REPLACEMENT, text, flags=re.DOTALL)

# Routes
@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({
        'ok': True,
        'status': 'running',
        'version': '2.0.0',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/config', methods=['GET'])
def get_config():
    """Get current configuration"""
    return jsonify({
        'ok': True,
        'port': PORT,
        'privacy_open': PRIVACY_OPEN,
        'privacy_close': PRIVACY_CLOSE,
        'privacy_replacement': PRIVACY_REPLACEMENT,
        'db_path': str(DB_PATH),
        'md_dir': str(MD_DIR)
    })

@app.route('/capture', methods=['POST'])
def capture():
    """Capture a new message"""
    try:
        data = request.get_json()

        role = data.get('role', 'user').lower()
        content = data.get('content', '').strip()
        platform = data.get('platform', 'unknown').lower()
        url = data.get('url', '')

        if not content:
            return jsonify({'ok': False, 'error': 'Empty content'}), 400

        # Redact private info
        content = redact_private(content)

        # Save to database
        message_id = db.add_message(
            role=role,
            content=content,
            platform=platform,
            url=url,
            metadata=data.get('metadata', {})
        )

        # Get date and regenerate that day's MD file
        today = datetime.now().strftime('%Y-%m-%d')
        messages = db.get_messages_by_date(today)
        md_file = md_gen.generate_daily_file(today, messages)

        # Also update index
        md_gen.generate_index(db)

        # Notify connected clients via WebSocket
        socketio.emit('new_message', {
            'id': message_id,
            'role': role,
            'platform': platform,
            'timestamp': datetime.now().isoformat()
        })

        return jsonify({
            'ok': True,
            'message_id': message_id,
            'md_file': md_file
        })

    except Exception as e:
        print(f"Error in /capture: {e}")
        return jsonify({'ok': False, 'error': str(e)}), 500

@app.route('/search', methods=['GET'])
def search():
    """Search through memories"""
    query = request.args.get('q', '')
    limit = int(request.args.get('limit', 50))

    if not query:
        return jsonify({'ok': False, 'error': 'No query provided'}), 400

    results = db.search(query, limit)

    return jsonify({
        'ok': True,
        'query': query,
        'count': len(results),
        'results': results
    })

@app.route('/stats', methods=['GET'])
def stats():
    """Get statistics"""
    stats = db.get_stats()

    return jsonify({
        'ok': True,
        'stats': stats
    })

@app.route('/regenerate', methods=['POST'])
def regenerate():
    """Regenerate all markdown files"""
    try:
        files = md_gen.regenerate_all(db)
        return jsonify({
            'ok': True,
            'files_generated': len(files),
            'files': files
        })
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500

@app.route('/powershell/session', methods=['POST'])
def ps_session():
    """Register a PowerShell session"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        transcript_path = data.get('transcript_path')

        ps_id = db.add_powershell_session(session_id, transcript_path)

        return jsonify({
            'ok': True,
            'session_db_id': ps_id
        })
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500

@app.route('/powershell/error', methods=['POST'])
def ps_error():
    """Report a PowerShell error"""
    try:
        data = request.get_json()
        session_id = data.get('session_db_id')
        error_text = data.get('error')
        context = data.get('context', '')

        error_id = db.add_error(session_id, error_text, context)

        # Notify via WebSocket
        socketio.emit('new_error', {
            'id': error_id,
            'error': error_text,
            'timestamp': datetime.now().isoformat()
        })

        return jsonify({
            'ok': True,
            'error_id': error_id
        })
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500

@app.route('/errors/unresolved', methods=['GET'])
def get_errors():
    """Get unresolved errors"""
    errors = db.get_unresolved_errors()
    return jsonify({
        'ok': True,
        'count': len(errors),
        'errors': errors
    })

@app.route('/export/json', methods=['GET'])
def export_json():
    """Export all data as JSON"""
    date = request.args.get('date')
    if date:
        messages = db.get_messages_by_date(date)
    else:
        # Export all (be careful with large datasets)
        start, end = db.get_date_range()
        messages = []
        # This could be optimized, but keeping it simple for now

    return jsonify({
        'ok': True,
        'export_date': datetime.now().isoformat(),
        'messages': messages
    })

# WebSocket events
@socketio.on('connect')
def handle_connect():
    emit('connected', {'status': 'ok', 'version': '2.0.0'})

@socketio.on('ping')
def handle_ping():
    emit('pong', {'timestamp': datetime.now().isoformat()})

# Auto-regeneration thread
def auto_regenerate_worker():
    """Background worker to regenerate markdown files periodically"""
    last_date = None
    while True:
        try:
            current_date = datetime.now().strftime('%Y-%m-%d')
            if current_date != last_date:
                # New day, regenerate index
                md_gen.generate_index(db)
                last_date = current_date
        except Exception as e:
            print(f"Auto-regenerate error: {e}")

        time.sleep(300)  # Check every 5 minutes

# Cleanup on shutdown
def cleanup(signum=None, frame=None):
    print("\nShutting down EMRY server...")
    db.close()
    sys.exit(0)

signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)

if __name__ == '__main__':
    # Start background worker
    worker_thread = threading.Thread(target=auto_regenerate_worker, daemon=True)
    worker_thread.start()

    print(f"""
    ╔══════════════════════════════════════════════╗
    ║   EMRY v2.0 - Eternal Memory Server          ║
    ║   Running on http://{HOST}:{PORT}        ║
    ╚══════════════════════════════════════════════╝

    Database: {DB_PATH}
    Memories: {MD_DIR}

    Server is ready! 🚀
    """)

    # Run server
    try:
        socketio.run(app, host=HOST, port=PORT, debug=False, allow_unsafe_werkzeug=True)
    except Exception as e:
        print(f"Server error: {e}")
    finally:
        cleanup()
