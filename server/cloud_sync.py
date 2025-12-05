"""
EMRY Cloud Sync - Automatic, transparent Google Drive synchronization
User never needs to think about it - it just works.
"""
import os
import shutil
from pathlib import Path
from typing import Optional, List
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class CloudSyncManager:
    """Automatically syncs EMRY memories to Google Drive (completely transparent)"""

    def __init__(self, local_dir: str):
        self.local_dir = Path(local_dir)

        # Auto-detect Google Drive location
        self.google_drive = self._find_google_drive()

        if self.google_drive:
            self.sync_dir = self.google_drive / 'EMRY-Memories'
            self.sync_dir.mkdir(exist_ok=True)
            print(f"[CloudSync] Google Drive detected: {self.google_drive}")
            print(f"[CloudSync] Syncing to: {self.sync_dir}")
        else:
            self.sync_dir = None
            print("[CloudSync] Google Drive not detected - running in local-only mode")

    def _find_google_drive(self) -> Optional[Path]:
        """Auto-detect Google Drive location"""
        possible_locations = [
            # Windows Google Drive (File Stream)
            Path(os.environ.get('USERPROFILE', '')) / 'Google Drive' / 'My Drive',

            # Windows Google Drive (Desktop app)
            Path(os.environ['USERPROFILE']) / 'GoogleDrive',

            # Check all drives for Google Drive label
            *[Path(f"{drive}:") / 'My Drive' for drive in 'DEFGHIJ'],

            # Mac
            Path.home() / 'Google Drive',

            # Linux
            Path.home() / 'GoogleDrive',
        ]

        for location in possible_locations:
            if location.exists() and location.is_dir():
                return location

        # Check mounted drives on Windows
        try:
            import subprocess
            result = subprocess.run(['wmic', 'volume', 'get', 'Label,Name'],
                                  capture_output=True, text=True, timeout=5)

            for line in result.stdout.split('\n'):
                if 'Google Drive' in line:
                    parts = line.split()
                    if len(parts) >= 2:
                        drive = parts[-1].strip()
                        if drive and Path(drive).exists():
                            return Path(drive) / 'My Drive'
        except:
            pass

        return None

    def sync_file(self, local_file: Path):
        """Sync a single file to Google Drive"""
        if not self.sync_dir:
            return

        try:
            # Maintain directory structure
            relative_path = local_file.relative_to(self.local_dir)
            target_path = self.sync_dir / relative_path

            # Create parent directories
            target_path.parent.mkdir(parents=True, exist_ok=True)

            # Copy file
            shutil.copy2(local_file, target_path)
            print(f"[CloudSync] ✓ Synced: {local_file.name}")
        except Exception as e:
            print(f"[CloudSync] ⚠ Sync failed for {local_file.name}: {e}")

    def sync_all(self):
        """Sync all markdown files to Google Drive"""
        if not self.sync_dir:
            print("[CloudSync] Google Drive not available")
            return

        synced_count = 0

        for md_file in self.local_dir.rglob('*.md'):
            self.sync_file(md_file)
            synced_count += 1

        print(f"[CloudSync] ✓ Synced {synced_count} files to Google Drive")

    def start_auto_sync(self):
        """Start automatic background sync (watches for file changes)"""
        if not self.sync_dir:
            print("[CloudSync] Auto-sync disabled (Google Drive not found)")
            return None

        class SyncHandler(FileSystemEventHandler):
            def __init__(self, manager):
                self.manager = manager

            def on_modified(self, event):
                if event.is_directory:
                    return
                if event.src_path.endswith('.md'):
                    self.manager.sync_file(Path(event.src_path))

            def on_created(self, event):
                if event.is_directory:
                    return
                if event.src_path.endswith('.md'):
                    self.manager.sync_file(Path(event.src_path))

        observer = Observer()
        observer.schedule(SyncHandler(self), str(self.local_dir), recursive=True)
        observer.start()

        print("[CloudSync] ✓ Auto-sync started - all changes sync automatically")

        return observer

    def get_sync_status(self) -> dict:
        """Get current sync status"""
        if not self.sync_dir:
            return {
                'enabled': False,
                'reason': 'Google Drive not detected'
            }

        # Count files
        local_files = list(self.local_dir.rglob('*.md'))
        synced_files = list(self.sync_dir.rglob('*.md'))

        return {
            'enabled': True,
            'google_drive_path': str(self.google_drive),
            'sync_path': str(self.sync_dir),
            'local_files': len(local_files),
            'synced_files': len(synced_files),
            'in_sync': len(local_files) == len(synced_files)
        }


class DropboxSyncManager(CloudSyncManager):
    """Sync to Dropbox instead of Google Drive"""

    def _find_google_drive(self) -> Optional[Path]:
        """Find Dropbox location"""
        possible_locations = [
            Path.home() / 'Dropbox',
            Path(os.environ.get('USERPROFILE', '')) / 'Dropbox',
        ]

        for location in possible_locations:
            if location.exists():
                return location

        return None


class OneDriveSyncManager(CloudSyncManager):
    """Sync to OneDrive"""

    def _find_google_drive(self) -> Optional[Path]:
        """Find OneDrive location"""
        possible_locations = [
            Path(os.environ.get('OneDrive', '')),
            Path(os.environ.get('OneDriveConsumer', '')),
            Path(os.environ.get('OneDriveCommercial', '')),
            Path.home() / 'OneDrive',
        ]

        for location in possible_locations:
            if location and Path(location).exists():
                return Path(location)

        return None
