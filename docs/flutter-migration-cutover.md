# Flutter Migration Cutover

## Decision

Flutter is the release line for Phase 7.
Electron is no longer released as a new app artifact.
Keep the Electron app only as a reference implementation and as the source for
exporting backup JSON until users have verified their Flutter restore.

Direct import from the old Electron SQLite database is not required for Phase 7
because the versioned JSON backup path is covered by a sanitized backup fixture
generated from the real Electron E2E export flow and restored through Flutter
app/domain code.

## User Migration Flow

1. Open the current Electron ChronoPic app.
2. Export a local JSON backup from the backup settings surface.
3. Install the Flutter release.
4. Restore the JSON backup in Flutter.
5. Verify the restore preview counts before applying the restore.
6. After restore, verify photo count, favorite state, captions, tags, edited
   datetimes, memories, memory membership, locale, map settings, and generated
   AI status fields.
7. Keep original photo files in their existing folders.
   ChronoPic backups store metadata and references to originals; they do not
   copy the original photo library.
8. Keep the Electron app installed until the restored Flutter library has been
   checked by the user.

## Verified Compatibility

Phase 7 adds a migration fixture pair:

- `tests/fixtures/flutter-migration/electron-backup-v1.json`
- `tests/fixtures/flutter-migration/electron-backup-v1.expected.json`

The fixture is generated from the latest real Electron backup E2E output with:

```bash
pnpm run e2e:backup
node scripts/write-flutter-migration-fixtures.mjs
```

The generator removes local temp/home paths,
replaces Electron E2E secret placeholders,
normalizes IDs and fixture paths,
and preserves the Electron JSON shape.
It also keeps fractional millisecond timestamp values where Electron can emit
them from JavaScript numbers so Flutter parsing remains compatible with real
exports.

Flutter restore compatibility is verified with:

```bash
cd chronopic_flutter
dart test packages/chronopic_app/test/electron_backup_import_test.dart
```

The test verifies preview counts,
replace-style restore,
favorites,
captions,
tags,
edited datetimes,
memory metadata,
memory membership,
locale settings,
map settings,
and AI status/generated-label fields.

2026-05-10 Phase 7 verification passed:

- `pnpm run e2e:backup`
- `node scripts/write-flutter-migration-fixtures.mjs`
- `cd chronopic_flutter && dart test packages/chronopic_app/test/electron_backup_import_test.dart`

## Fallback

If a user's Flutter restore preview does not match their expected Electron
library counts,
do not remove Electron.
Re-export the JSON backup from Electron and retry the Flutter restore.

If JSON backup import fails on a real user backup,
capture the sanitized failing shape and add it as the next versioned migration
fixture before considering direct old SQLite import.
Direct SQLite import should remain a fallback only for backup-export failure,
not the primary Phase 7 cutover path.
