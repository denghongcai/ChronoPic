# ChronoPic

[![Release](https://img.shields.io/github/v/release/denghongcai/ChronoPic?label=release)](https://github.com/denghongcai/ChronoPic/releases/latest)

ChronoPic is an AI-powered, local-first desktop photo workspace. It indexes the folders you choose, generates thumbnails, keeps an editable catalog in a local SQLite database, and helps you browse, search, organize, enrich, and back up your photo library.

ChronoPic uses AI to turn a local photo library into searchable semantics, story-ready Memories, and reviewable organization suggestions. Its core workflow does not require cloud storage: your original photos stay in your own folders, while the app stores indexes, thumbnails, settings, edit history, and organization data locally.

## Download

Latest verified release: `v0.1.4`

Download ChronoPic from the GitHub Releases page:

https://github.com/denghongcai/ChronoPic/releases/latest

Current Flutter release artifacts:

- Android APK: `chronopic-flutter-android-release.apk`
- Android App Bundle: `chronopic-flutter-android-release.aab`
- Linux desktop: `chronopic-flutter-linux-x64-0.1.4.tar.gz`

Each artifact has a matching `.sha256` checksum file.
Electron desktop archives are historical artifacts only;
new releases use the Flutter line.

## Current Limitations

- Releases are portable, unpacked desktop bundles rather than installers.
- Android uses local or CI-provided release signing material.
- The current Android package id is still `com.example.chronopic`,
  so Phase 7 APK/AAB builds are technical verification artifacts until the
  final production id is chosen.
- macOS/iOS release builds require macOS/Xcode and are not produced from this
  Linux environment.
- Windows builds are not part of the Flutter Phase 7 release line yet.
- Auto-update is not implemented yet.
- Backups do not copy original photo files; they export ChronoPic's local catalog projection and settings.

## What You Can Do

- Add local photo folders as library sources
- Scan folders and build a local index
- Extract photo time, location, camera, and related metadata
- Generate local thumbnails
- Browse photos in waterfall, map, and timeline views
- Search paths, captions, tags, AI-generated fields, and Memory content
- Open detail and immersive gallery views
- Edit captions, tags, and datetimes
- Roll back the latest edit
- Mark photos as favorites
- Create and manage Memories
- Set Memory covers, descriptions, and story sections
- Add photos to Memories or remove them
- Use AI-powered enrichment to generate captions, summaries, tags, Memory suggestions, and candidate Memories
- Review AI queue and Memory candidates from Notifications
- Switch between English and Simplified Chinese UI
- Set AI output language separately from UI language
- Configure Gaode/AMap for optional map browsing
- Export local JSON backups
- Preview restore conflicts
- Restore backups into the local database

## Where Data Is Stored

ChronoPic is local-first:

- Original photos stay in the folders you selected.
- The app stores its database, thumbnails, settings, and debug log locally.
- Backup files are local JSON files.
- AI calls happen only after you configure AI provider settings.

You can set `CHRONOPIC_USER_DATA_DIR` to use an isolated data directory for testing or temporary runs.

## Optional Features

### AI

AI is disabled until provider settings are configured:

- API Key
- Base URL
- Model
- Provider name
- AI output language

AI-powered enrichment can generate captions, summaries, tags, Memory suggestions, and candidate Memories. Generated content is stored separately from user-authored captions, tags, and descriptions so suggestions do not overwrite your edits.

### Maps

Map browsing uses Gaode/AMap Web JS API settings. If no map key is configured, normal browsing, search, Memories, and backup still work.

## Backup And Restore

Library Settings includes local backup actions:

- Export Backup
- Preview Restore
- Restore Backup

Backups include:

- Library sources
- Photo index and metadata
- User captions, tags, datetime corrections, and favorites
- Edit history
- Memories and photo membership
- AI-generated fields and candidate Memories
- AI, map, and language settings

Backups do not include original photo files. After restore, photo paths still point to their original local file locations.

## For Developers

Developer setup, testing, packaging, release, architecture, and repository workflow documentation lives in:

- [DEVELOPMENT.md](DEVELOPMENT.md)
- [PLAN.md](PLAN.md)
- [AGENTS.md](AGENTS.md)
- [docs/agent-verification-script.md](docs/agent-verification-script.md)
