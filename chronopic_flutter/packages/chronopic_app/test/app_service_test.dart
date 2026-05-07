import 'dart:io';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test(
    'orchestrates backup restore and photo actions through repository boundary',
    () {
      final backup = ChronoPicBackup.fromJson(
        FlutterParityFixtures.readBackupJson(),
      );
      final service = ChronoPicAppService(ChronoPicRepository());

      expect(service.previewBackupRestore(backup).photoCount, 2);
      expect(service.restoreBackup(backup).restoredPhotoCount, 2);
      expect(
        service.listPhotos(const PhotoFilter(favorite: true)).single.photo.id,
        'photo-lake',
      );
      expect(
        service
            .updatePhotoCaption('photo-city', 'Caption from app')
            .semantic
            .caption,
        'Caption from app',
      );
      expect(service.rollbackLatestEdit('photo-city').semantic.caption, isNull);
      final originalCityLabels = service
          .getPhoto('photo-city')!
          .semantic
          .labels;
      expect(
        service
            .updatePhotoTags('photo-city', <String>['desk', 'edited'])
            .semantic
            .labels,
        <String>['desk', 'edited'],
      );
      expect(
        service.rollbackLatestEdit('photo-city').semantic.labels,
        originalCityLabels,
      );
      final originalCityDatetime = service
          .getPhoto('photo-city')!
          .metadata
          .datetime;
      expect(
        service
            .updatePhotoDatetime('photo-city', 1710000000000)
            .metadata
            .datetime,
        1710000000000,
      );
      expect(
        service.rollbackLatestEdit('photo-city').metadata.datetime,
        originalCityDatetime,
      );
      expect(
        service.updatePhotoFavorite('photo-city', true).photo.favorite,
        isTrue,
      );
      expect(service.rollbackLatestEdit('photo-city').photo.favorite, isFalse);
      final memory = service.createMemory('App Memory');
      service.addPhotoToMemory(memory.id, 'photo-city');
      expect(
        service
            .updateMemory(
              memory.id,
              name: 'Renamed App Memory',
              description: 'App memory description',
            )
            .description,
        'App memory description',
      );
      expect(
        service.setMemoryCover(memory.id, 'photo-city').coverPhotoId,
        'photo-city',
      );
      expect(
        service
            .listMemories()
            .singleWhere((item) => item.id == memory.id)
            .photoCount,
        1,
      );
      expect(
        service.listPhotos(PhotoFilter(memoryId: memory.id)).single.photo.id,
        'photo-city',
      );
      service.removePhotoFromMemory(memory.id, 'photo-city');
      expect(service.listPhotos(PhotoFilter(memoryId: memory.id)), isEmpty);
      service.addPhotoToMemory(memory.id, 'photo-city');
      expect(service.getAiSetupReadiness().configured, isTrue);
      expect(service.getAiStatusCounts()[AiPipelineStatus.completed], 1);
      expect(service.getAiStatusCounts()[AiPipelineStatus.failed], 1);
      expect(service.listMemoryCandidates().single.id, 'candidate-city-lake');
      expect(
        service
            .updateAiSettings(
              const AiSettings(
                apiKey: 'service-key',
                baseURL: 'https://service.example/v1',
                model: 'service-model',
                providerName: 'service-provider',
              ),
            )
            .ai
            .providerName,
        'service-provider',
      );
      expect(service.retryFailedAiQueue(), 1);
      expect(service.getAiStatusCounts()[AiPipelineStatus.pending], 1);
      final acceptedCandidate = service.acceptMemoryCandidate(
        'candidate-city-lake',
      );
      expect(acceptedCandidate.name, 'Fixture Trip');
      expect(service.listMemoryCandidates(), isEmpty);
      expect(service.createBackup().photos.length, 2);

      final directory = Directory.systemTemp.createTempSync(
        'chronopic-backup-file-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final backupFile = File('${directory.path}/backup.json');
      service.exportBackupToFile(backupFile.path);
      expect(backupFile.existsSync(), isTrue);
      expect(service.previewBackupFile(backupFile.path).photoCount, 2);

      service.updatePhotoCaption('photo-city', 'Temporary caption');
      expect(service.restoreBackupFile(backupFile.path).restoredPhotoCount, 2);
      expect(service.getPhoto('photo-city')?.semantic.caption, isNull);

      final malformedBackup = File('${directory.path}/malformed.json');
      malformedBackup.writeAsStringSync('{not valid json');
      expect(
        () => service.previewBackupFile(malformedBackup.path),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('persists desktop library state across service restarts', () {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final directory = Directory.systemTemp.createTempSync(
      'chronopic-persistent-service-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final dataFile = File('${directory.path}/chronopic-state.json');

    final firstService = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: dataFile.path,
    );
    firstService.restoreBackup(backup);
    firstService.addLibrarySource('/media/photos');
    firstService.updatePhotoCaption('photo-city', 'Restart caption');
    firstService.updatePhotoTags('photo-city', <String>['restart', 'linux']);
    firstService.updatePhotoDatetime('photo-city', 1712345678000);
    firstService.updatePhotoFavorite('photo-city', true);
    final memory = firstService.createMemory('Restart Memory');
    firstService.addPhotoToMemory(memory.id, 'photo-city');

    expect(dataFile.existsSync(), isTrue);

    final restartedService = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: dataFile.path,
    );
    expect(
      restartedService.listLibrarySources().map((source) => source.path),
      contains('/media/photos'),
    );
    final restoredCity = restartedService.getPhoto('photo-city')!;
    expect(restoredCity.semantic.caption, 'Restart caption');
    expect(restoredCity.semantic.labels, <String>['restart', 'linux']);
    expect(restoredCity.metadata.datetime, 1712345678000);
    expect(restoredCity.photo.favorite, isTrue);
    expect(
      restartedService.listMemories().map((item) => item.name),
      contains('Restart Memory'),
    );
    expect(
      restartedService
          .listPhotos(PhotoFilter(memoryId: memory.id))
          .single
          .photo
          .id,
      'photo-city',
    );
  });
}
