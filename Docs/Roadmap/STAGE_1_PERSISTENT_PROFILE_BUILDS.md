# Stage 1 — Persistent Profile, Builds, and Saves

Status: APPROVED  
Release target: CORE  
Branch: `stage1/persistent-profile-builds`

## Objective

Create the permanent progression foundation for AbyssFall without coupling gameplay systems directly to storage.

## Locked product rule

AbyssFall does not require players to create a new character to access future chapter or seasonal content. Existing profiles and builds continue forward.

## Ownership model

### PlayerProfile owns

- profile identity and save version
- account-wide unlocks
- currencies
- shared inventory references
- statistics
- story/world progress
- content chapter progress
- build IDs
- selected build ID

### BuildData owns

- build identity and display name
- class ID
- level and experience
- equipped gear references
- skills and hotbar
- weapon sets
- class-tree state
- shared-core state
- build-specific quest/progression state
- timestamps and statistics

### ContentChapterProgress owns

- chapter ID and version
- unlock state
- quest progress
- boss progress
- activity progress
- reward progress
- completion flags

Build data never belongs to a season or chapter.

## Architecture rule

Gameplay code must not read or write files directly.

`Gameplay State -> Save Data Models -> SaveManager -> File Storage`

## Stage 1A scope

Included:

- typed save-data models
- profile creation/load/save
- multiple build records
- build create/rename/select/delete operations
- versioned JSON
- backups and safe recovery hooks
- migration entry point
- chapter-progress foundation

Excluded:

- cloud or cross-platform saves
- co-op
- hardcore
- build sharing/import/export
- final inventory UI
- final class trees or Shared Core implementation
- encryption

## Proposed storage layout

```text
user://abyssfall/
  profile.json
  builds/
    build_<uuid>.json
  backups/
    profile_backup.json
    build_<uuid>_backup.json
```

## Acceptance criteria

1. A new profile can be created and restored after restart.
2. Multiple builds remain independent.
3. Renaming/deleting one build does not damage another.
4. Missing or malformed files fail safely.
5. Backup recovery has a defined entry point.
6. Old save versions enter a migration path.
7. Chapter data can be added without resetting builds.
8. Gameplay scripts do not write directly to disk.
9. Resource-specific class data remains isolated.
10. The implementation is reviewed before promotion to VERIFIED.
