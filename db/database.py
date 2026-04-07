import os
import sqlite3
from pathlib import Path

DB_PATH = os.getenv("FRAMEWELL_DB", "framewell.db")
MIGRATIONS_DIR = Path(__file__).parent / "migrations"


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def run_migrations() -> None:
    conn = get_connection()
    try:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS _migrations (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                filename   TEXT      UNIQUE NOT NULL,
                applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()

        applied = {
            row["filename"]
            for row in conn.execute("SELECT filename FROM _migrations")
        }

        for path in sorted(MIGRATIONS_DIR.glob("*.sql")):
            if path.name in applied:
                continue
            conn.executescript(path.read_text())
            conn.execute("INSERT INTO _migrations (filename) VALUES (?)", (path.name,))
            conn.commit()
            print(f"  applied: {path.name}")

    finally:
        conn.close()


if __name__ == "__main__":
    print(f"Running migrations on {DB_PATH}...")
    run_migrations()
    print("Done.")
