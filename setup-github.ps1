# Framewell GitHub setup — labels, milestones, and 15 issues
# Run in PowerShell: .\setup-github.ps1

$repo = "abrahamswamidass/framewell"

Write-Host "Setting default repo..."
gh repo set-default $repo

# ── Labels ────────────────────────────────────────────────────────────────────
Write-Host "`nCreating labels..."
gh label create "idea"   --color "FAEEDA" --description "Fuzzy, not yet scoped"   --repo $repo --force
gh label create "design" --color "EEEDFE" --description "Wireframes, UX, copy"    --repo $repo --force
gh label create "dev"    --color "E1F5EE" --description "Implementation"           --repo $repo --force
gh label create "qa"     --color "E6F1FB" --description "Testing and review"       --repo $repo --force
gh label create "bug"    --color "FCEBEB" --description "Something broken"         --repo $repo --force

# ── Milestones ────────────────────────────────────────────────────────────────
Write-Host "`nCreating milestones..."
gh api POST /repos/$repo/milestones -f title="v0.1 — indexing"   -f description="Core file indexing across NAS and Google Drive"
gh api POST /repos/$repo/milestones -f title="v0.2 — duplicates" -f description="Duplicate detection and marking"
gh api POST /repos/$repo/milestones -f title="v0.3 — tree view"  -f description="UI to visualise and act on duplicates"
gh api POST /repos/$repo/milestones -f title="v1.0 — alexa"      -f description="Photo recommendations and Amazon Photos sync"

# ── Issues ────────────────────────────────────────────────────────────────────
Write-Host "`nCreating issues..."

gh issue create --repo $repo `
  --title "Set up SQLite database schema for photo metadata" `
  --label "dev" --milestone "v0.1 — indexing" `
  --body "Create the SQLite database schema to store photo metadata.

**Tables needed:**
- \`storage_sources\` (id, name, type, path/credentials, last_scanned)
- \`photos\` (id, source_id, file_path, file_name, file_size, created_at, hash_partial, hash_full, scanned_at)

**Acceptance criteria:**
- Schema created with migrations
- Indexes on file_size and hash fields for performance"

gh issue create --repo $repo `
  --title "Implement Synology NAS file indexer (SMB mount)" `
  --label "dev" --milestone "v0.1 — indexing" `
  --body "Connect to Synology NAS via SMB mounted drive and scan for photo files.

**Scope:**
- Support SMB mounted drive path as initial approach
- Scan for .jpg, .jpeg, .png, .heic, .raw extensions
- Extract: file path, file name, file size, created/modified time
- Store results in SQLite photos table

**Acceptance criteria:**
- Can scan a NAS mount and populate DB
- Handles permission errors gracefully
- Logs scan summary (files found, errors)"

gh issue create --repo $repo `
  --title "Implement Google Drive file indexer" `
  --label "dev" --milestone "v0.1 — indexing" `
  --body "Connect to Google Drive via API and index photo files.

**Scope:**
- OAuth2 authentication flow
- List all photo files (jpg, png, heic) with metadata
- Extract: file path, file size, created time, Drive file ID
- Store in SQLite with source_id = Google Drive

**Acceptance criteria:**
- OAuth flow works locally
- Can index a Drive folder recursively
- Handles API rate limits with backoff"

gh issue create --repo $repo `
  --title "Implement partial + full file hashing" `
  --label "dev" --milestone "v0.1 — indexing" `
  --body "Generate file hashes for duplicate detection.

**Strategy:**
- Partial hash: SHA256 of first + last 8KB (fast, for initial comparison)
- Full hash: SHA256 of entire file (only when partial hashes collide on size)
- Store both in photos table

**Acceptance criteria:**
- Partial hash runs on all indexed files
- Full hash computed only on size + partial-hash matches
- Performance benchmark logged (files/sec)"

gh issue create --repo $repo `
  --title "Periodic re-scan scheduler" `
  --label "dev" --milestone "v0.1 — indexing" `
  --body "Run indexer periodically to pick up new files across all storage sources.

**Scope:**
- Configurable scan interval (default: daily)
- Only process new or modified files since last scan
- Update last_scanned timestamp per storage source

**Acceptance criteria:**
- Scheduler runs without manual trigger
- Delta scan works correctly (skips unchanged files)
- Errors don't crash the scheduler"

gh issue create --repo $repo `
  --title "Exact duplicate detection algorithm" `
  --label "dev" --milestone "v0.2 — duplicates" `
  --body "Identify exact duplicate photos within each storage source using hash matching.

**Logic:**
- Group photos by file_size first (cheap filter)
- Within size groups, compare partial hashes
- On partial hash match, compute and compare full hashes
- Mark confirmed duplicates in a duplicates table

**Schema:**
- \`duplicate_groups\` (id, canonical_photo_id, detected_at)
- \`duplicate_members\` (id, group_id, photo_id)

**Acceptance criteria:**
- No false positives (different files marked as duplicates)
- Runs within reasonable time on 10k+ photo library"

gh issue create --repo $repo `
  --title "Define canonical photo selection rules" `
  --label "idea" --milestone "v0.2 — duplicates" `
  --body "When duplicates are found, one file should be marked as the canonical (preferred) version.

**Rules to decide (in priority order):**
1. Highest resolution
2. Oldest created date
3. Source preference (NAS > Google Drive)

**Acceptance criteria:**
- Canonical selection is deterministic
- Rules are configurable"

gh issue create --repo $repo `
  --title "Store and expose duplicate metadata" `
  --label "dev" --milestone "v0.2 — duplicates" `
  --body "Persist duplicate detection results and make them queryable.

**Scope:**
- Write duplicate groups and members to SQLite
- Expose a query interface: get all groups, get members of a group, get canonical photo
- Include counts: total duplicates, total wasted storage

**Acceptance criteria:**
- Data persists across app restarts
- Query returns correct canonical and duplicate members"

gh issue create --repo $repo `
  --title "Design duplicate tree view UI" `
  --label "design" --milestone "v0.3 — tree view" `
  --body "Design the UI for browsing and acting on duplicate photo groups.

**Requirements:**
- Tree structure: duplicate group at root, members as children
- Show file path, size, source, created date per item
- Highlight canonical photo
- Actions: mark for deletion, open file location, dismiss group

**Deliverable:**
- Wireframe or mockup approved before dev starts"

gh issue create --repo $repo `
  --title "Build local web UI (server + frontend)" `
  --label "dev" --milestone "v0.3 — tree view" `
  --body "Build a local web app to serve the duplicate tree view.

**Scope:**
- Lightweight local server (e.g. FastAPI or Express)
- Frontend showing duplicate groups as expandable tree
- Actions: flag for deletion, dismiss group
- No cloud hosting needed — runs on LAN

**Acceptance criteria:**
- Accessible from browser at localhost
- Tree loads and is interactive
- Actions persist to SQLite"

gh issue create --repo $repo `
  --title "Implement safe file deletion flow" `
  --label "dev" --milestone "v0.3 — tree view" `
  --body "Allow users to delete duplicate files from the UI safely.

**Rules:**
- Never delete the canonical file
- Confirm before delete (show file path + size to reclaim)
- Move to OS trash/recycle bin rather than permanent delete
- Log all deletions to an audit table

**Acceptance criteria:**
- Canonical file is protected from deletion
- Deleted files go to recycle bin, not permanent delete
- Audit log queryable"

gh issue create --repo $repo `
  --title "Research Amazon Photos upload API" `
  --label "idea" --milestone "v1.0 — alexa" `
  --body "Investigate the Amazon Photos API (unofficial/community) for uploading photos programmatically.

**Questions to answer:**
- Is there a stable community library? (check github for amazon-photos-api)
- What auth method is needed?
- Are there rate limits or upload size restrictions?
- Does upload to Amazon Photos make photos available on Alexa devices automatically?

**Deliverable:**
- Short findings doc added to repo /docs folder"

gh issue create --repo $repo `
  --title "Define 'interesting photo' scoring algorithm" `
  --label "idea" --milestone "v1.0 — alexa" `
  --body "Determine how to score photos for Alexa recommendation.

**Options to evaluate (easiest to hardest):**
1. EXIF-based scoring: GPS present, high resolution, recent date
2. Perceptual hash variance: images with more detail score higher
3. Local ML model: CLIP or MobileNet aesthetic scorer
4. Amazon Rekognition: faces, scenes, quality (costs money)

**Deliverable:**
- Decision on approach with rationale
- Scoring schema added to SQLite"

gh issue create --repo $repo `
  --title "Implement photo scoring and recommendation engine" `
  --label "dev" --milestone "v1.0 — alexa" `
  --body "Score all indexed photos and select top candidates for Amazon Photos upload.

**Scope:**
- Run scoring algorithm on non-duplicate canonical photos
- Store score in photos table
- Select top N photos per period (configurable, default: 20/week)
- Exclude already-uploaded photos

**Acceptance criteria:**
- Scoring runs as part of periodic scheduler
- Top N selection is deterministic and logged"

gh issue create --repo $repo `
  --title "Implement Amazon Photos sync" `
  --label "dev" --milestone "v1.0 — alexa" `
  --body "Upload recommended photos to Amazon Photos periodically.

**Scope:**
- Authenticate with Amazon Photos API
- Upload selected photos on schedule
- Track uploaded photos in SQLite (uploaded_at, amazon_photo_id)
- Handle failures with retry logic

**Acceptance criteria:**
- Photos appear in Amazon Photos after upload
- No duplicate uploads
- Failures logged and retried on next run"

Write-Host "`nDone! All labels, milestones, and 15 issues created."
Write-Host "Check: https://github.com/$repo/issues"
