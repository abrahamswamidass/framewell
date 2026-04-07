# Framewell — Project Context & GitHub Issues

## Project Overview
Framewell is a photo organizer app for personal use. It integrates with local and cloud photo storage, identifies duplicates, and surfaces the best photos to Alexa-connected displays via Amazon Photos.

**GitHub repo:** abrahamswamidass/framewell

---

## Board Setup

### Columns (in order)
1. Backlog
2. Ready
3. In Progress
4. Review
5. Done

### Labels to create
| Name    | Color   | Description                  |
|---------|---------|------------------------------|
| idea    | #FAEEDA | Fuzzy, not yet scoped        |
| design  | #EEEDFE | Wireframes, UX, copy         |
| dev     | #E1F5EE | Implementation               |
| qa      | #E6F1FB | Testing and review           |
| bug     | #FCEBEB | Something broken             |

### Milestones to create
| Name                  | Description                                      |
|-----------------------|--------------------------------------------------|
| v0.1 — indexing       | Core file indexing across NAS and Google Drive   |
| v0.2 — duplicates     | Duplicate detection and marking                  |
| v0.3 — tree view      | UI to visualise and act on duplicates            |
| v1.0 — alexa          | Photo recommendations and Amazon Photos sync     |

---

## Issues to Create

### Milestone: v0.1 — indexing

---

**Issue 1**
- Title: Set up SQLite database schema for photo metadata
- Label: dev
- Milestone: v0.1 — indexing
- Body:
  Create the SQLite database schema to store photo metadata.

  **Tables needed:**
  - `storage_sources` (id, name, type, path/credentials, last_scanned)
  - `photos` (id, source_id, file_path, file_name, file_size, created_at, hash_partial, hash_full, scanned_at)

  **Acceptance criteria:**
  - Schema created with migrations
  - Indexes on file_size and hash fields for performance

---

**Issue 2**
- Title: Implement Synology NAS file indexer (SMB mount)
- Label: dev
- Milestone: v0.1 — indexing
- Body:
  Connect to Synology NAS via SMB mounted drive and scan for photo files.

  **Scope:**
  - Support SMB mounted drive path as initial approach
  - Scan for .jpg, .jpeg, .png, .heic, .raw extensions
  - Extract: file path, file name, file size, created/modified time
  - Store results in SQLite photos table

  **Acceptance criteria:**
  - Can scan a NAS mount and populate DB
  - Handles permission errors gracefully
  - Logs scan summary (files found, errors)

---

**Issue 3**
- Title: Implement Google Drive file indexer
- Label: dev
- Milestone: v0.1 — indexing
- Body:
  Connect to Google Drive via API and index photo files.

  **Scope:**
  - OAuth2 authentication flow
  - List all photo files (jpg, png, heic) with metadata
  - Extract: file path, file size, created time, Drive file ID
  - Store in SQLite with source_id = Google Drive

  **Acceptance criteria:**
  - OAuth flow works locally
  - Can index a Drive folder recursively
  - Handles API rate limits with backoff

---

**Issue 4**
- Title: Implement partial + full file hashing
- Label: dev
- Milestone: v0.1 — indexing
- Body:
  Generate file hashes for duplicate detection.

  **Strategy:**
  - Partial hash: SHA256 of first + last 8KB (fast, for initial comparison)
  - Full hash: SHA256 of entire file (only when partial hashes collide on size)
  - Store both in photos table

  **Acceptance criteria:**
  - Partial hash runs on all indexed files
  - Full hash computed only on size + partial-hash matches
  - Performance benchmark logged (files/sec)

---

**Issue 5**
- Title: Periodic re-scan scheduler
- Label: dev
- Milestone: v0.1 — indexing
- Body:
  Run indexer periodically to pick up new files across all storage sources.

  **Scope:**
  - Configurable scan interval (default: daily)
  - Only process new or modified files since last scan
  - Update last_scanned timestamp per storage source

  **Acceptance criteria:**
  - Scheduler runs without manual trigger
  - Delta scan works correctly (skips unchanged files)
  - Errors don't crash the scheduler

---

### Milestone: v0.2 — duplicates

---

**Issue 6**
- Title: Exact duplicate detection algorithm
- Label: dev
- Milestone: v0.2 — duplicates
- Body:
  Identify exact duplicate photos within each storage source using hash matching.

  **Logic:**
  - Group photos by file_size first (cheap filter)
  - Within size groups, compare partial hashes
  - On partial hash match, compute and compare full hashes
  - Mark confirmed duplicates in a duplicates table

  **Schema:**
  - `duplicate_groups` (id, canonical_photo_id, detected_at)
  - `duplicate_members` (id, group_id, photo_id)

  **Acceptance criteria:**
  - No false positives (different files marked as duplicates)
  - Runs within reasonable time on 10k+ photo library

---

**Issue 7**
- Title: Define canonical photo selection rules
- Label: idea
- Milestone: v0.2 — duplicates
- Body:
  When duplicates are found, one file should be marked as the "canonical" (preferred) version.

  **Rules to decide (in priority order):**
  1. Highest resolution
  2. Oldest created date
  3. Source preference (NAS > Google Drive)

  **Acceptance criteria:**
  - Canonical selection is deterministic
  - Rules are configurable

---

**Issue 8**
- Title: Store and expose duplicate metadata
- Label: dev
- Milestone: v0.2 — duplicates
- Body:
  Persist duplicate detection results and make them queryable.

  **Scope:**
  - Write duplicate groups and members to SQLite
  - Expose a query interface: get all groups, get members of a group, get canonical photo
  - Include counts: total duplicates, total wasted storage

  **Acceptance criteria:**
  - Data persists across app restarts
  - Query returns correct canonical and duplicate members

---

### Milestone: v0.3 — tree view

---

**Issue 9**
- Title: Design duplicate tree view UI
- Label: design
- Milestone: v0.3 — tree view
- Body:
  Design the UI for browsing and acting on duplicate photo groups.

  **Requirements:**
  - Tree structure: duplicate group at root, members as children
  - Show file path, size, source, created date per item
  - Highlight canonical photo
  - Actions: mark for deletion, open file location, dismiss group

  **Deliverable:**
  - Wireframe or mockup approved before dev starts

---

**Issue 10**
- Title: Build local web UI (server + frontend)
- Label: dev
- Milestone: v0.3 — tree view
- Body:
  Build a local web app to serve the duplicate tree view.

  **Scope:**
  - Lightweight local server (e.g. FastAPI or Express)
  - Frontend showing duplicate groups as expandable tree
  - Actions: flag for deletion, dismiss group
  - No cloud hosting needed — runs on LAN

  **Acceptance criteria:**
  - Accessible from browser at localhost
  - Tree loads and is interactive
  - Actions persist to SQLite

---

**Issue 11**
- Title: Implement safe file deletion flow
- Label: dev
- Milestone: v0.3 — tree view
- Body:
  Allow users to delete duplicate files from the UI safely.

  **Rules:**
  - Never delete the canonical file
  - Confirm before delete (show file path + size to reclaim)
  - Move to OS trash/recycle bin rather than permanent delete
  - Log all deletions to an audit table

  **Acceptance criteria:**
  - Canonical file is protected from deletion
  - Deleted files go to recycle bin, not permanent delete
  - Audit log queryable

---

### Milestone: v1.0 — alexa

---

**Issue 12**
- Title: Research Amazon Photos upload API
- Label: idea
- Milestone: v1.0 — alexa
- Body:
  Investigate the Amazon Photos API (unofficial/community) for uploading photos programmatically.

  **Questions to answer:**
  - Is there a stable community library? (check github for amazon-photos-api)
  - What auth method is needed?
  - Are there rate limits or upload size restrictions?
  - Does upload to Amazon Photos make photos available on Alexa devices automatically?

  **Deliverable:**
  - Short findings doc added to repo /docs folder

---

**Issue 13**
- Title: Define "interesting photo" scoring algorithm
- Label: idea
- Milestone: v1.0 — alexa
- Body:
  Determine how to score photos for Alexa recommendation.

  **Options to evaluate (easiest to hardest):**
  1. EXIF-based scoring: GPS present, high resolution, recent date
  2. Perceptual hash variance: images with more detail score higher
  3. Local ML model: CLIP or MobileNet aesthetic scorer
  4. Amazon Rekognition: faces, scenes, quality (costs money)

  **Deliverable:**
  - Decision on approach with rationale
  - Scoring schema added to SQLite

---

**Issue 14**
- Title: Implement photo scoring and recommendation engine
- Label: dev
- Milestone: v1.0 — alexa
- Body:
  Score all indexed photos and select top candidates for Amazon Photos upload.

  **Scope:**
  - Run scoring algorithm on non-duplicate canonical photos
  - Store score in photos table
  - Select top N photos per period (configurable, default: 20/week)
  - Exclude already-uploaded photos

  **Acceptance criteria:**
  - Scoring runs as part of periodic scheduler
  - Top N selection is deterministic and logged

---

**Issue 15**
- Title: Implement Amazon Photos sync
- Label: dev
- Milestone: v1.0 — alexa
- Body:
  Upload recommended photos to Amazon Photos periodically.

  **Scope:**
  - Authenticate with Amazon Photos API
  - Upload selected photos on schedule
  - Track uploaded photos in SQLite (uploaded_at, amazon_photo_id)
  - Handle failures with retry logic

  **Acceptance criteria:**
  - Photos appear in Amazon Photos after upload
  - No duplicate uploads
  - Failures logged and retried on next run

---

## Instructions for Claude Code

1. Authenticate with: `gh auth login`
2. Set the working repo: `gh repo set-default abrahamswamidass/framewell`
3. Create labels as listed above
4. Create milestones as listed above
5. Create all 15 issues with correct labels, milestones, and body text
6. Add all issues to the GitHub Project board in the Backlog column
