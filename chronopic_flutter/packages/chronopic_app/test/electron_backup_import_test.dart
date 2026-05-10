import 'dart:convert';
import 'dart:io';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'imports sanitized real Electron backup through Flutter app service',
    () {
      final backup = ChronoPicBackup.fromJson(
        _readJson(
          '../tests/fixtures/flutter-migration/electron-backup-v1.json',
        ),
      );
      final expected = _readJson(
        '../tests/fixtures/flutter-migration/electron-backup-v1.expected.json',
      );
      final counts = (expected['counts'] as Map).cast<String, Object?>();
      final keyFields = (expected['keyFields'] as Map).cast<String, Object?>();

      expect(validateChronoPicBackup(backup).valid, isTrue);

      final service = ChronoPicAppService(ChronoPicRepository());
      final preview = service.previewBackupRestore(backup);
      expect(preview.sourceCount, counts['sourceCount']);
      expect(preview.photoCount, counts['photoCount']);
      expect(preview.memoryCount, counts['memoryCount']);
      expect(preview.memoryPhotoCount, counts['memoryPhotoCount']);
      expect(preview.editHistoryCount, counts['editHistoryCount']);
      expect(preview.memoryCandidateCount, counts['memoryCandidateCount']);

      final result = service.restoreBackup(backup);
      expect(result.restoredSourceCount, counts['sourceCount']);
      expect(result.restoredPhotoCount, counts['photoCount']);
      expect(result.restoredMemoryCount, counts['memoryCount']);
      expect(result.restoredMemoryPhotoCount, counts['memoryPhotoCount']);
      expect(result.restoredEditHistoryCount, counts['editHistoryCount']);
      expect(
        result.restoredMemoryCandidateCount,
        counts['memoryCandidateCount'],
      );

      expect(service.listLibrarySources().map((source) => source.path), [
        '/fixture/electron-backup/library',
      ]);
      expect(
        service
            .listPhotos(const PhotoFilter(favorite: true))
            .map((record) => record.photo.id),
        keyFields['favoritePhotoIds'],
      );

      final authoredPhotoId = keyFields['authoredPhotoId']! as String;
      final authoredPhoto = service.getPhoto(authoredPhotoId)!;
      expect(authoredPhoto.semantic.caption, keyFields['authoredCaption']);
      expect(authoredPhoto.semantic.labels, keyFields['authoredLabels']);
      expect(
        authoredPhoto.metadata.datetime,
        ((keyFields['photoDatetimeById'] as Map)
            .cast<String, Object?>())[authoredPhotoId],
      );

      final memoryId = keyFields['memoryId']! as String;
      final memory = service.getMemory(memoryId)!;
      expect(memory.name, keyFields['memoryName']);
      expect(memory.description, keyFields['memoryDescription']);
      expect(memory.coverPhotoId, authoredPhotoId);
      expect(
        service
            .listPhotos(PhotoFilter(memoryId: memoryId))
            .map((record) => record.photo.id),
        keyFields['memoryPhotoIds'],
      );

      final restoredBackup = service.createBackup();
      expect(
        restoredBackup.settings.locale.locale.wireName,
        keyFields['locale'],
      );
      expect(
        restoredBackup.settings.locale.aiOutputLocale.wireName,
        keyFields['aiOutputLocale'],
      );
      expect(restoredBackup.settings.map.apiKey, keyFields['mapApiKey']);

      final aiStatusById = (keyFields['photoAiStatusById'] as Map)
          .cast<String, Object?>();
      final generatedLabelsById = (keyFields['photoGeneratedLabelsById'] as Map)
          .cast<String, Object?>();
      for (final entry in aiStatusById.entries) {
        final record = service.getPhoto(entry.key)!;
        expect(record.semantic.aiStatus.name, entry.value);
        expect(record.semantic.generatedLabels, generatedLabelsById[entry.key]);
      }
    },
  );
}

JsonMap _readJson(String path) {
  return (jsonDecode(File(path).readAsStringSync()) as Map)
      .cast<String, Object?>();
}
