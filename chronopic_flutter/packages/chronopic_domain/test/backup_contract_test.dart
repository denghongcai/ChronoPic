import 'dart:convert';

import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('parses the Electron backup fixture and reports expected counts', () {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
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

  test('preserves authored and generated migration-critical fields through round trip', () {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
    final roundTripped = ChronoPicBackup.fromJson(jsonDecode(jsonEncode(backup.toJson())) as Map<String, Object?>);
    final expected = FlutterParityFixtures.readExpectedJson();
    final keyFields = (expected['keyFields'] as Map).cast<String, Object?>();

    expect(roundTripped.settings.locale.locale.wireName, keyFields['locale']);
    expect(roundTripped.settings.locale.aiOutputLocale.wireName, keyFields['aiOutputLocale']);
    expect(roundTripped.photos.where((record) => record.photo.favorite).map((record) => record.photo.id), keyFields['favoritePhotoIds']);
    expect(roundTripped.memories.map((memory) => memory.id), keyFields['memoryIds']);
    expect(roundTripped.memoryCandidates.map((candidate) => candidate.id), keyFields['memoryCandidateIds']);
    expect(
      roundTripped.photos.where((record) => record.semantic.caption != null).map((record) => record.photo.id),
      keyFields['authoredCaptionPhotoIds'],
    );
    expect(
      roundTripped.photos.where((record) => record.semantic.generatedCaption != null).map((record) => record.photo.id),
      keyFields['generatedSemanticPhotoIds'],
    );
    expect(
      roundTripped.photos.where((record) => record.semantic.aiStatus == AiPipelineStatus.failed).map((record) => record.photo.id),
      keyFields['failedAIPhotoIds'],
    );
    expect(
      roundTripped.photos.where((record) => record.metadata.lat != null && record.metadata.lng != null).map((record) => record.photo.id),
      keyFields['gpsPhotoIds'],
    );
  });

  test('reports AI setup readiness without exposing secret values', () {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
    final readiness = getAiReadiness(backup.settings.ai);

    expect(readiness.configured, isTrue);
    expect(readiness.missingFields, isEmpty);
    expect(readiness.presentFields, ['apiKey', 'baseURL', 'model', 'providerName']);
    expect(readiness.presentFields, isNot(contains(backup.settings.ai.apiKey)));

    final incomplete = getAiReadiness(const AiSettings(apiKey: '', baseURL: '', model: 'm', providerName: 'fixture'));
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
