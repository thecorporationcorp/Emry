"""
EMRY Database - SQLite backend for reliable conversation storage
"""
import sqlite3
import json
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional
import threading

class EmryDB:
    def __init__(self, db_path: str):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._local = threading.local()
        self._init_db()

    def _get_conn(self):
        """Thread-safe connection getter"""
        if not hasattr(self._local, 'conn'):
            self._local.conn = sqlite3.connect(str(self.db_path), check_same_thread=False)
            self._local.conn.row_factory = sqlite3.Row
        return self._local.conn

    def _init_db(self):
        """Initialize database schema"""
        conn = self._get_conn()
        conn.executescript('''
            CREATE TABLE IF NOT EXISTS conversations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                platform TEXT NOT NULL,
                conversation_id TEXT,
                title TEXT,
                url TEXT,
                started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                tags TEXT,
                metadata TEXT
            );

            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                conversation_id INTEGER,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                raw_content TEXT,
                captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                source_url TEXT,
                metadata TEXT,
                FOREIGN KEY (conversation_id) REFERENCES conversations(id)
            );

            CREATE TABLE IF NOT EXISTS powershell_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT UNIQUE,
                started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ended_at TIMESTAMP,
                transcript_path TEXT,
                errors_detected INTEGER DEFAULT 0,
                metadata TEXT
            );

            CREATE TABLE IF NOT EXISTS errors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id INTEGER,
                error_text TEXT NOT NULL,
                context TEXT,
                detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                resolved BOOLEAN DEFAULT 0,
                resolution_notes TEXT,
                FOREIGN KEY (session_id) REFERENCES powershell_sessions(id)
            );

            CREATE TABLE IF NOT EXISTS search_index (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                message_id INTEGER,
                keyword TEXT NOT NULL,
                relevance REAL DEFAULT 1.0,
                FOREIGN KEY (message_id) REFERENCES messages(id)
            );

            CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
            CREATE INDEX IF NOT EXISTS idx_messages_captured ON messages(captured_at);
            CREATE INDEX IF NOT EXISTS idx_conversations_platform ON conversations(platform);
            CREATE INDEX IF NOT EXISTS idx_conversations_started ON conversations(started_at);
            CREATE INDEX IF NOT EXISTS idx_search_keyword ON search_index(keyword);
        ''')
        conn.commit()

    def add_message(self, role: str, content: str, platform: str, url: str = '',
                   conversation_id: Optional[int] = None, metadata: dict = None) -> int:
        """Add a new message to the database"""
        conn = self._get_conn()

        # Auto-detect or create conversation
        if not conversation_id:
            conversation_id = self._get_or_create_conversation(platform, url, conn)

        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO messages (conversation_id, role, content, raw_content, source_url, metadata)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (conversation_id, role, content, content, url, json.dumps(metadata or {})))

        message_id = cursor.lastrowid

        # Update conversation last_updated
        cursor.execute('''
            UPDATE conversations
            SET last_updated = CURRENT_TIMESTAMP
            WHERE id = ?
        ''', (conversation_id,))

        conn.commit()

        # Index keywords
        self._index_message(message_id, content, conn)

        return message_id

    def _get_or_create_conversation(self, platform: str, url: str, conn) -> int:
        """Get existing conversation or create new one"""
        cursor = conn.cursor()

        # Try to find recent conversation from same URL (within last hour)
        cursor.execute('''
            SELECT id FROM conversations
            WHERE platform = ? AND url = ?
            AND datetime(last_updated) > datetime('now', '-1 hour')
            ORDER BY last_updated DESC LIMIT 1
        ''', (platform, url))

        row = cursor.fetchone()
        if row:
            return row[0]

        # Create new conversation
        cursor.execute('''
            INSERT INTO conversations (platform, url, conversation_id)
            VALUES (?, ?, ?)
        ''', (platform, url, url))

        return cursor.lastrowid

    def _index_message(self, message_id: int, content: str, conn):
        """Index keywords from message for search"""
        # Simple keyword extraction (can be enhanced with NLP)
        words = content.lower().split()
        keywords = [w for w in words if len(w) > 3][:50]  # Top 50 words

        for keyword in keywords:
            try:
                conn.execute('''
                    INSERT INTO search_index (message_id, keyword)
                    VALUES (?, ?)
                ''', (message_id, keyword))
            except:
                pass  # Ignore duplicates

    def get_messages_by_date(self, date: str) -> List[Dict]:
        """Get all messages for a specific date"""
        conn = self._get_conn()
        cursor = conn.cursor()

        cursor.execute('''
            SELECT
                m.id, m.role, m.content, m.captured_at, m.source_url,
                c.platform, c.title, c.conversation_id
            FROM messages m
            JOIN conversations c ON m.conversation_id = c.id
            WHERE DATE(m.captured_at) = ?
            ORDER BY m.captured_at ASC
        ''', (date,))

        return [dict(row) for row in cursor.fetchall()]

    def get_date_range(self) -> tuple:
        """Get earliest and latest message dates"""
        conn = self._get_conn()
        cursor = conn.cursor()

        cursor.execute('SELECT DATE(MIN(captured_at)), DATE(MAX(captured_at)) FROM messages')
        row = cursor.fetchone()
        return (row[0], row[1]) if row else (None, None)

    def search(self, query: str, limit: int = 50) -> List[Dict]:
        """Search messages by keyword"""
        conn = self._get_conn()
        cursor = conn.cursor()

        query = query.lower()
        cursor.execute('''
            SELECT DISTINCT
                m.id, m.role, m.content, m.captured_at, m.source_url,
                c.platform, c.title
            FROM messages m
            JOIN conversations c ON m.conversation_id = c.id
            WHERE LOWER(m.content) LIKE ?
            ORDER BY m.captured_at DESC
            LIMIT ?
        ''', (f'%{query}%', limit))

        return [dict(row) for row in cursor.fetchall()]

    def add_powershell_session(self, session_id: str, transcript_path: str) -> int:
        """Register a PowerShell session"""
        conn = self._get_conn()
        cursor = conn.cursor()

        cursor.execute('''
            INSERT OR REPLACE INTO powershell_sessions (session_id, transcript_path)
            VALUES (?, ?)
        ''', (session_id, transcript_path))

        conn.commit()
        return cursor.lastrowid

    def add_error(self, session_id: int, error_text: str, context: str = '') -> int:
        """Record an error from PowerShell session"""
        conn = self._get_conn()
        cursor = conn.cursor()

        cursor.execute('''
            INSERT INTO errors (session_id, error_text, context)
            VALUES (?, ?, ?)
        ''', (session_id, error_text, context))

        # Update error count
        cursor.execute('''
            UPDATE powershell_sessions
            SET errors_detected = errors_detected + 1
            WHERE id = ?
        ''', (session_id,))

        conn.commit()
        return cursor.lastrowid

    def get_unresolved_errors(self) -> List[Dict]:
        """Get all unresolved errors"""
        conn = self._get_conn()
        cursor = conn.cursor()

        cursor.execute('''
            SELECT e.*, ps.session_id, ps.transcript_path
            FROM errors e
            JOIN powershell_sessions ps ON e.session_id = ps.id
            WHERE e.resolved = 0
            ORDER BY e.detected_at DESC
        ''')

        return [dict(row) for row in cursor.fetchall()]

    def get_stats(self) -> Dict:
        """Get usage statistics"""
        conn = self._get_conn()
        cursor = conn.cursor()

        stats = {}

        # Total messages
        cursor.execute('SELECT COUNT(*) FROM messages')
        stats['total_messages'] = cursor.fetchone()[0]

        # Messages by platform
        cursor.execute('''
            SELECT c.platform, COUNT(m.id) as count
            FROM messages m
            JOIN conversations c ON m.conversation_id = c.id
            GROUP BY c.platform
        ''')
        stats['by_platform'] = dict(cursor.fetchall())

        # Total conversations
        cursor.execute('SELECT COUNT(*) FROM conversations')
        stats['total_conversations'] = cursor.fetchone()[0]

        # Date range
        stats['date_range'] = self.get_date_range()

        # Unresolved errors
        cursor.execute('SELECT COUNT(*) FROM errors WHERE resolved = 0')
        stats['unresolved_errors'] = cursor.fetchone()[0]

        return stats

    def close(self):
        """Close database connection"""
        if hasattr(self._local, 'conn'):
            self._local.conn.close()
