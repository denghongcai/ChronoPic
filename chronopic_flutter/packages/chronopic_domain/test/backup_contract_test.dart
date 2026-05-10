import 'dart:convert';

import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('parses the Electron backup fixture and reports expected counts', () {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final expected = FlutterParityFixtures.readExpectedJson();
    final counts = (expected['counts'] as Map).cast<String, Object?>();
    final preview = BackupRestorePreview.fromBackup(backup);

    expect(backup.app, 'ChronoPic');
    expect(backup.schemaVersion, expected['schemaVersion']);
    expect(preview.sourceCount, counts['sourceCount']);
    expect(preview.photoCount, counts['photoCount']);
    expect(preview.memoryCount, counts['memoryCount']);
    expect(preview.memoryPhotoCount, counts['memoryPhotoCount']);
    expect(preview.editHistoryCount, counts['editHistoryCount']);
    expect(preview.memoryCandidateCount, counts['memoryCandidateCount']);
    expect(validateChronoPicBackup(backup).valid, isTrue);
  });

  test(
    'preserves authored and generated migration-critical fields through round trip',
    () {
      final backup = ChronoPicBackup.fromJson(
        FlutterParityFixtures.readBackupJson(),
      );
      final roundTripped = ChronoPicBackup.fromJson(
        jsonDecode(jsonEncode(backup.toJson())) as Map<String, Object?>,
      );
      final expected = FlutterParityFixtures.readExpectedJson();
      final keyFields = (expected['keyFields'] as Map).cast<String, Object?>();

      expect(roundTripped.settings.locale.locale.wireName, keyFields['locale']);
      expect(
        roundTripped.settings.locale.aiOutputLocale.wireName,
        keyFields['aiOutputLocale'],
      );
      expect(
        roundTripped.photos
            .where((record) => record.photo.favorite)
            .map((record) => record.photo.id),
        keyFields['favoritePhotoIds'],
      );
      expect(
        roundTripped.memories.map((memory) => memory.id),
        keyFields['memoryIds'],
      );
      expect(
        roundTripped.memoryCandidates.map((candidate) => candidate.id),
        keyFields['memoryCandidateIds'],
      );
      expect(
        roundTripped.photos
            .where((record) => record.semantic.caption != null)
            .map((record) => record.photo.id),
        keyFields['authoredCaptionPhotoIds'],
      );
      expect(
        roundTripped.photos
            .where((record) => record.semantic.generatedCaption != null)
            .map((record) => record.photo.id),
        keyFields['generatedSemanticPhotoIds'],
      );
      expect(
        roundTripped.photos
            .where(
              (record) => record.semantic.aiStatus == AiPipelineStatus.failed,
            )
            .map((record) => record.photo.id),
        keyFields['failedAIPhotoIds'],
      );
      expect(
        roundTripped.photos
            .where(
              (record) =>
                  record.metadata.lat != null && record.metadata.lng != null,
            )
            .map((record) => record.photo.id),
        keyFields['gpsPhotoIds'],
      );
    },
  );

  test('accepts Electron fractional millisecond timestamps in backup JSON', () {
    final json = FlutterParityFixtures.readBackupJson();
    final source = ((json['librarySources'] as List<Object?>).first as Map)
        .cast<String, Object?>();
    source['createdAt'] = 1715000000000.3997;
    source['updatedAt'] = 1715000001000.3997;
    source['lastScanAt'] = 1715000002000.3997;

    final record = ((json['photos'] as List<Object?>).first as Map)
        .cast<String, Object?>();
    final photo = (record['photo'] as Map).cast<String, Object?>();
    final metadata = (record['metadata'] as Map).cast<String, Object?>();
    final semantic = (record['semantic'] as Map).cast<String, Object?>();
    final indexState = (record['indexState'] as Map).cast<String, Object?>();
    photo['createdAt'] = 1715000003000.3997;
    photo['updatedAt'] = 1715000004000.3997;
    metadata['datetime'] = 1715000005000.3997;
    semantic['aiProcessedAt'] = 1715000006000.3997;
    indexState['lastIndexedAt'] = 1715000007000.3997;
    indexState['sourceUpdatedAt'] = 1715000008000.3997;
    indexState['missingAt'] = 1715000009000.3997;

    final memory = ((json['memories'] as List<Object?>).first as Map)
        .cast<String, Object?>();
    memory['aiProcessedAt'] = 1715000010000.3997;
    memory['createdAt'] = 1715000011000.3997;
    memory['updatedAt'] = 1715000012000.3997;

    final membership = ((json['memoryPhotos'] as List<Object?>).first as Map)
        .cast<String, Object?>();
    membership['addedAt'] = 1715000013000.3997;

    final edit = ((json['editHistory'] as List<Object?>).first as Map)
        .cast<String, Object?>();
    edit['createdAt'] = 1715000014000.3997;
    edit['rolledBackAt'] = 1715000015000.3997;

    final candidate = ((json['memoryCandidates'] as List<Object?>).first as Map)
        .cast<String, Object?>();
    candidate['createdAt'] = 1715000016000.3997;
    candidate['updatedAt'] = 1715000017000.3997;

    final backup = ChronoPicBackup.fromJson(json);

    expect(backup.librarySources.single.createdAt, 1715000000000);
    expect(backup.photos.first.photo.createdAt, 1715000003000);
    expect(backup.photos.first.metadata.datetime, 1715000005000);
    expect(backup.photos.first.semantic.aiProcessedAt, 1715000006000);
    expect(backup.photos.first.indexState.missingAt, 1715000009000);
    expect(backup.memories.single.createdAt, 1715000011000);
    expect(backup.memoryPhotos.single.addedAt, 1715000013000);
    expect(backup.editHistory.first.rolledBackAt, 1715000015000);
    expect(backup.memoryCandidates.single.updatedAt, 1715000017000);
  });

  test('reports AI setup readiness without exposing secret values', () {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final readiness = getAiReadiness(backup.settings.ai);

    expect(readiness.configured, isTrue);
    expect(readiness.missingFields, isEmpty);
    expect(readiness.presentFields, [
      'apiKey',
      'baseURL',
      'model',
      'providerName',
    ]);
    expect(readiness.presentFields, isNot(contains(backup.settings.ai.apiKey)));

    final incomplete = getAiReadiness(
      const AiSettings(
        apiKey: '',
        baseURL: '',
        model: 'm',
        providerName: 'fixture',
      ),
    );
    expect(incomplete.configured, isFalse);
    expect(incomplete.missingFields, ['apiKey', 'baseURL']);
  });

  test('keeps filter defaults stable', () {
    const filter = PhotoFilter();

    expect(filter.limit, 60);
    expect(filter.offset, 0);
    expect(filter.sortBy, PhotoSortBy.datetime);
    expect(filter.sortDirection, SortDirection.desc);
  });
}
