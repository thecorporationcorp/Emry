"""
EMRY File Size Manager - Handles large markdown files intelligently
"""
import os
from pathlib import Path
from datetime import datetime
from typing import List, Dict

class FileSizeManager:
    """Manages markdown file sizes and automatic archival"""

    # File size limits
    MAX_FILE_SIZE_MB = 10  # Split files larger than 10MB
    ARCHIVE_AFTER_DAYS = 90  # Archive files older than 90 days

    def __init__(self, md_dir: str):
        self.md_dir = Path(md_dir)
        self.archive_dir = self.md_dir / '_archive'
        self.archive_dir.mkdir(exist_ok=True)

    def check_file_size(self, filepath: Path) -> bool:
        """Check if file exceeds size limit"""
        if not filepath.exists():
            return False

        size_mb = filepath.stat().st_size / (1024 * 1024)
        return size_mb > self.MAX_FILE_SIZE_MB

    def split_large_file(self, date: str, messages: List[Dict]) -> List[str]:
        """Split large daily files into parts"""
        if not messages:
            return []

        files_created = []
        current_batch = []
        current_size = 0
        part_number = 1

        # Estimate size per message (rough)
        avg_msg_size = 500  # bytes
        max_messages_per_file = (self.MAX_FILE_SIZE_MB * 1024 * 1024) // avg_msg_size

        for i, msg in enumerate(messages):
            current_batch.append(msg)
            current_size += len(msg.get('content', ''))

            # Split if batch is large enough
            if len(current_batch) >= max_messages_per_file:
                filename = f"{date}_part{part_number}.md"
                filepath = self.md_dir / filename

                # Generate markdown for this batch
                # (Would call markdown_generator here)

                files_created.append(str(filepath))
                current_batch = []
                current_size = 0
                part_number += 1

        # Handle remaining messages
        if current_batch:
            if part_number == 1:
                filename = f"{date}.md"
            else:
                filename = f"{date}_part{part_number}.md"

            filepath = self.md_dir / filename
            files_created.append(str(filepath))

        return files_created

    def archive_old_files(self) -> List[str]:
        """Archive old markdown files to keep main directory clean"""
        archived = []
        cutoff_date = datetime.now().timestamp() - (self.ARCHIVE_AFTER_DAYS * 24 * 60 * 60)

        for md_file in self.md_dir.glob('????-??-??.md'):
            if md_file.stat().st_mtime < cutoff_date:
                # Move to archive
                archive_path = self.archive_dir / md_file.name
                md_file.rename(archive_path)
                archived.append(str(md_file))

        return archived

    def compress_archive(self):
        """Compress archived files to save space"""
        import zipfile
        from datetime import datetime

        # Create yearly archive zips
        years = {}
        for md_file in self.archive_dir.glob('????-??-??.md'):
            year = md_file.stem[:4]
            if year not in years:
                years[year] = []
            years[year].append(md_file)

        for year, files in years.items():
            zip_path = self.archive_dir / f'EMRY_{year}.zip'

            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for file in files:
                    zipf.write(file, file.name)
                    file.unlink()  # Delete original after zipping

    def get_storage_stats(self) -> Dict:
        """Get storage statistics"""
        total_size = 0
        file_count = 0

        # Current files
        for md_file in self.md_dir.glob('*.md'):
            total_size += md_file.stat().st_size
            file_count += 1

        # Archive size
        archive_size = 0
        archive_count = 0
        for item in self.archive_dir.rglob('*'):
            if item.is_file():
                archive_size += item.stat().st_size
                archive_count += 1

        return {
            'current_files': file_count,
            'current_size_mb': total_size / (1024 * 1024),
            'archive_files': archive_count,
            'archive_size_mb': archive_size / (1024 * 1024),
            'total_size_mb': (total_size + archive_size) / (1024 * 1024)
        }
