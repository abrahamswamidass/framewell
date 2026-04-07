import logging
import os
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from db.database import get_connection

PHOTO_EXTENSIONS = {".jpg", ".jpeg", ".png", ".heic", ".raw"}

logging.basicConfig(format="%(levelname)s %(message)s", level=logging.INFO)
log = logging.getLogger(__name__)


@dataclass
class ScanResult:
    found: int = 0
    written: int = 0
    errors: list[str] = field(default_factory=list)


def scan(mount_path: str, source_name: str = "NAS") -> ScanResult:
    """
    Walk mount_path, index all photo files into the photos table.
    Creates or reuses a storage_sources row for this mount path.
    """
    root = Path(mount_path)
    if not root.exists():
        raise FileNotFoundError(f"Mount path not found: {mount_path}")

    result = ScanResult()
    conn = get_connection()

    try:
        source_id = _ensure_source(conn, source_name, mount_path)

        for dirpath, _dirs, filenames in os.walk(root, onerror=_onerror(result)):
            for filename in filenames:
                if Path(filename).suffix.lower() not in PHOTO_EXTENSIONS:
                    continue

                filepath = Path(dirpath) / filename

                try:
                    stat = filepath.stat()
                except PermissionError:
                    msg = f"permission denied: {filepath}"
                    result.errors.append(msg)
                    log.warning(msg)
                    continue
                except OSError as exc:
                    msg = f"os error ({exc}): {filepath}"
                    result.errors.append(msg)
                    log.warning(msg)
                    continue

                result.found += 1
                created_at = datetime.fromtimestamp(
                    min(stat.st_ctime, stat.st_mtime)
                ).isoformat()

                conn.execute(
                    """
                    INSERT INTO photos
                        (source_id, file_path, file_name, file_size, created_at)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT (source_id, file_path) DO UPDATE SET
                        file_size  = excluded.file_size,
                        created_at = excluded.created_at,
                        scanned_at = CURRENT_TIMESTAMP
                    """,
                    (source_id, str(filepath), filename, stat.st_size, created_at),
                )
                result.written += 1

        conn.commit()
        conn.execute(
            "UPDATE storage_sources SET last_scanned = CURRENT_TIMESTAMP WHERE id = ?",
            (source_id,),
        )
        conn.commit()

    finally:
        conn.close()

    _log_summary(mount_path, result)
    return result


def _ensure_source(conn, name: str, path: str) -> int:
    """Return the id of the storage_source for this path, creating it if needed."""
    row = conn.execute(
        "SELECT id FROM storage_sources WHERE type = 'nas_smb' AND path = ?",
        (path,),
    ).fetchone()
    if row:
        return row["id"]
    cur = conn.execute(
        "INSERT INTO storage_sources (name, type, path) VALUES (?, 'nas_smb', ?)",
        (name, path),
    )
    conn.commit()
    return cur.lastrowid


def _onerror(result: ScanResult):
    """os.walk error handler — logs inaccessible directories."""
    def handler(exc: OSError):
        msg = f"cannot access directory: {exc.filename}"
        result.errors.append(msg)
        log.warning(msg)
    return handler


def _log_summary(path: str, r: ScanResult) -> None:
    log.info("--- Scan complete: %s ---", path)
    log.info("  Photos found:  %d", r.found)
    log.info("  Rows written:  %d", r.written)
    log.info("  Errors:        %d", len(r.errors))
    for e in r.errors:
        log.info("    %s", e)


if __name__ == "__main__":
    import sys
    path = sys.argv[1] if len(sys.argv) > 1 else input("NAS mount path: ")
    scan(path)
