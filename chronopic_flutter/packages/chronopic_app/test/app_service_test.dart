import 'dart:convert';
import 'dart:io';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('exports and imports portable photo metadata sidecars', () async {
    final fixture = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final directory = Directory.systemTemp.createTempSync(
      'chronopic-photo-sidecars-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final sourceDirectory = Directory('${directory.path}/source')..createSync();
    final targetDirectory = Directory('${directory.path}/target')..createSync();
    final sidecarDirectory = Directory('${directory.path}/sidecars')
      ..createSync();

    final source = ChronoPicAppService(ChronoPicRepository())
      ..restoreBackup(fixture);
    _relocateFixturePhotos(source, sourceDirectory);
    source.updatePhotoCaption('photo-city', 'Sidecar caption');
    source.updatePhotoTags('photo-city', ['sidecar', 'travel']);
    source.updatePhotoDatetime('photo-city', 1712345678000);
    source.updatePhotoFavorite('photo-city', true);
    source.repository.updatePhotoMetadataFields(
      'photo-city',
      lat: 37.5,
      lng: -122.25,
      camera: 'Sidecar Camera',
      confidence: 0.9,
      originalDatetimeText: '2024:04:05 06:07:08',
    );

    final export = await source.exportPhotoSidecars(sidecarDirectory.path);
    expect(export.processed, 2);
    expect(export.errors, isEmpty);
    final exportedSidecar = sidecarDirectory
        .listSync()
        .whereType<File>()
        .firstWhere((file) => file.path.endsWith('.chronopic.json'));
    final exportedJson =
        jsonDecode(exportedSidecar.readAsStringSync()) as Map<String, Object?>;
    expect(exportedJson, isNot(contains('generatedCaption')));
    expect(exportedJson, isNot(contains('apiKey')));

    final targetDataFile = File('${directory.path}/target-catalog.json');
    final target = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: targetDataFile.path,
    )..restoreBackup(fixture);
    _relocateFixturePhotos(target, targetDirectory);
    final lakeFile = File('${targetDirectory.path}/photo-lake.jpg');
    lakeFile.writeAsBytesSync(List<int>.filled(lakeFile.lengthSync(), 0x41));
    final lakeBytesBeforeImport = lakeFile.readAsBytesSync();
    final generatedCaptionBefore = target
        .getPhoto('photo-city')!
        .semantic
        .generatedCaption;
    final malformed = File('${sidecarDirectory.path}/bad.chronopic.json')
      ..writeAsStringSync('{invalid json');

    final imported = await target.importPhotoSidecars(sidecarDirectory.path);
    expect(imported.processed, 1);
    expect(imported.errors, hasLength(2));
    expect(imported.errors.join('\n'), contains(malformed.path));
    expect(imported.errors.join('\n'), contains('No library photo matches'));

    final city = target.getPhoto('photo-city')!;
    expect(city.semantic.caption, 'Sidecar caption');
    expect(city.semantic.labels, ['sidecar', 'travel']);
    expect(city.semantic.generatedCaption, generatedCaptionBefore);
    expect(city.photo.favorite, isTrue);
    expect(city.metadata.datetime, 1712345678000);
    expect(city.metadata.lat, 37.5);
    expect(city.metadata.lng, -122.25);
    expect(city.metadata.camera, 'Sidecar Camera');
    expect(city.metadata.confidence, 0.9);
    expect(city.metadata.originalDatetimeText, '2024:04:05 06:07:08');
    expect(
      target.getPhoto('photo-lake')!.semantic.caption,
      'Manual lake caption',
    );
    expect(lakeFile.readAsBytesSync(), lakeBytesBeforeImport);

    final restarted = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: targetDataFile.path,
    );
    expect(
      restarted.getPhoto('photo-city')?.semantic.caption,
      'Sidecar caption',
    );
    expect(restarted.getPhoto('photo-city')?.photo.favorite, isTrue);
  });

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

void _relocateFixturePhotos(
  ChronoPicAppService service,
  Directory destination,
) {
  for (final record in service.listPhotos(const PhotoFilter(limit: 1000000))) {
    final bytes = utf8.encode('media bytes for ${record.photo.id}');
    final file = File('${destination.path}/${record.photo.id}.jpg')
      ..writeAsBytesSync(bytes);
    service.repository.upsertPhotoRecord(
      PhotoRecord(
        photo: Photo(
          id: record.photo.id,
          path: file.path,
          hash: file.path,
          size: bytes.length,
          mime: record.photo.mime,
          thumbnailPath: record.photo.thumbnailPath,
          favorite: record.photo.favorite,
          createdAt: record.photo.createdAt,
          updatedAt: record.photo.updatedAt,
        ),
        metadata: record.metadata,
        semantic: record.semantic,
        indexState: record.indexState,
      ),
    );
  }
}
