# Flutter Photo Metadata Sidecars

Status: implemented, locally verified, and published in `v0.1.14`.

## Goal

Make user-authored photo metadata portable independently of a full ChronoPic
backup, while keeping original media untouched.

## Scope

- Export one `*.chronopic.json` file per catalog photo into a user-selected
  folder.
- Import sidecars recursively from a user-selected folder.
- Use a versioned `chronopic-photo-metadata` JSON format and match media using
  SHA-256 and byte size.
- Store only a SHA-256 path fingerprint (never an absolute source path) to
  resolve byte-identical photos when their original paths are unchanged.
- Carry captions, tags, favorites, datetime, GPS, camera, confidence, and
  original datetime text.
- Treat sidecars as snapshots: replace those catalog fields on a verified
  match, including clearing nullable values represented as `null`.
- Preserve generated AI fields and report invalid, unmatched, duplicate, and
  ambiguous sidecars without applying them.
- Do not modify original media or write EXIF.

Full backups remain the supported format for Memories, settings, AI-generated
content, library sources, and edit history.

## Verification

Automated coverage validates schema and field bounds, portable matching after a
path move, SHA-256 rejection when media bytes differ, partial import reporting,
authored-field persistence across restart, and generated-field preservation.
The completion evidence and product verification record are in
[the active Flutter step log](agent-step-log-flutter-2026-10-12.md).
