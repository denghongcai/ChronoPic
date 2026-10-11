import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('restores and exports the Flutter parity backup fixture', () {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final expected = FlutterParityFixtures.readExpectedJson();
    final counts = (expected['counts'] as Map).cast<String, Object?>();
    final repository = ChronoPicRepository();

    final preview = repository.previewBackupRestore(backup);
    expect(preview.photoCount, counts['photoCount']);

    final result = repository.restoreBackup(backup);
    expect(result.restoredPhotoCount, counts['photoCount']);
    expect(result.restoredMemoryCount, counts['memoryCount']);
    expect(result.restoredMemoryPhotoCount, counts['memoryPhotoCount']);

    final exported = repository.createBackup();
    expect(exported.photos.length, counts['photoCount']);
    expect(exported.memories.length, counts['memoryCount']);
    expect(exported.memoryCandidates.length, counts['memoryCandidateCount']);
    expect(validateChronoPicBackup(exported).valid, isTrue);
  });

  test(
    'supports critical photo, memory, and candidate repository operations',
    () {
      final backup = ChronoPicBackup.fromJson(
        FlutterParityFixtures.readBackupJson(),
      );
      final repository = ChronoPicRepository()..restoreBackup(backup);

      expect(repository.countPhotos(), 2);
      expect(repository.countPhotos(const PhotoFilter(limit: 1)), 2);
      expect(repository.countPhotos(const PhotoFilter(favorite: true)), 1);
      expect(
        repository
            .listPhotos(const PhotoFilter(favorite: true))
            .map((record) => record.photo.id),
        ['photo-lake'],
      );
      expect(
        repository
            .listPhotos(const PhotoFilter(hasGps: true))
            .map((record) => record.photo.id),
        ['photo-lake'],
      );
      expect(
        repository
            .listPhotos(const PhotoFilter(hasGps: false))
            .map((record) => record.photo.id),
        ['photo-city'],
      );
      expect(
        repository
            .listPhotos(const PhotoFilter(tag: 'city'))
            .map((record) => record.photo.id),
        ['photo-city'],
      );
      expect(
        repository
            .listPhotos(const PhotoFilter(aiStatus: AiPipelineStatus.completed))
            .map((record) => record.photo.id),
        ['photo-lake'],
      );
      expect(
        repository
            .listPhotos(const PhotoFilter(fromDatetime: 1715001800000))
            .map((record) => record.photo.id),
        ['photo-city'],
      );
      expect(
        repository
            .listPhotos(
              const PhotoFilter(
                sortBy: PhotoSortBy.path,
                sortDirection: SortDirection.asc,
              ),
            )
            .map((record) => record.photo.id),
        ['photo-city', 'photo-lake'],
      );
      expect(
        repository
            .listPhotosByMemory('memory-weekend')
            .map((record) => record.photo.id),
        ['photo-lake'],
      );
      expect(
        repository.listMemoryCandidates().map((candidate) => candidate.id),
        ['candidate-city-lake'],
      );
      expect(repository.retryFailedAiQueue(), 1);
      expect(
        repository
            .listPhotos(const PhotoFilter(aiStatus: AiPipelineStatus.pending))
            .map((record) => record.photo.id),
        ['photo-city'],
      );
      expect(
        repository
            .updateAiSettings(
              const AiSettings(
                apiKey: 'updated-key',
                baseURL: 'https://updated.example/v1',
                model: 'updated-model',
                providerName: 'updated-provider',
              ),
            )
            .ai
            .model,
        'updated-model',
      );

      expect(
        repository
            .updatePhotoCaption('photo-city', 'Manual city caption')
            .semantic
            .caption,
        'Manual city caption',
      );
      expect(
        repository
            .updatePhotoTags('photo-city', ['city', 'manual'])
            .semantic
            .labels,
        ['city', 'manual'],
      );
      expect(
        repository.updatePhotoFavorite('photo-city', true).photo.favorite,
        isTrue,
      );

      repository.createMemory(
        'memory-extra',
        'Extra Memory',
        description: 'Created by repository test',
      );
      repository.addPhotoToMemory('memory-extra', 'photo-city');
      expect(repository.getMemory('memory-extra')?.coverPhotoId, 'photo-city');
      expect(
        repository
            .listPhotosByMemory('memory-extra')
            .map((record) => record.photo.id),
        ['photo-city'],
      );
      expect(
        repository
            .updateMemory(
              'memory-extra',
              name: 'Renamed Memory',
              description: 'Updated description',
            )
            .description,
        'Updated description',
      );
      repository.addPhotoToMemory('memory-extra', 'photo-lake');
      expect(
        repository.setMemoryCover('memory-extra', 'photo-lake').coverPhotoId,
        'photo-lake',
      );
      repository.removePhotoFromMemory('memory-extra', 'photo-lake');
      expect(repository.getMemory('memory-extra')?.coverPhotoId, 'photo-city');
      expect(
        repository
            .listPhotosByMemory('memory-extra')
            .map((record) => record.photo.id),
        ['photo-city'],
      );
      final accepted = repository.acceptMemoryCandidate('candidate-city-lake');
      expect(accepted.name, 'Fixture Trip');
      expect(
        repository
            .listMemoryCandidates(MemoryCandidateStatus.accepted)
            .single
            .acceptedMemoryId,
        accepted.id,
      );
      expect(
        repository
            .listPhotosByMemory(accepted.id)
            .map((record) => record.photo.id),
        containsAll(<String>['photo-city', 'photo-lake']),
      );
    },
  );

  group('semantic enrichment updates', () {
    ChronoPicBackup fixtureBackup() =>
        ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());

    test('photo processing transition clears error and preserves fields', () {
      final repository = ChronoPicRepository()..restoreBackup(fixtureBackup());

      final updated = repository.updatePhotoSemanticEnrichment(
        'photo-city',
        aiStatus: AiPipelineStatus.processing,
        aiError: null,
      );

      expect(updated.semantic.aiStatus, AiPipelineStatus.processing);
      expect(updated.semantic.aiError, isNull);
      expect(updated.semantic.labels, ['city']);
      expect(updated.semantic.caption, isNull);
      expect(updated.semantic.generatedLabels, ['street', 'architecture']);
      expect(updated.semantic.generatedCaption, 'Generated city caption');
      expect(
        updated.semantic.summary,
        'A generated summary for the city fixture.',
      );
      expect(updated.semantic.aiProvider, 'fixture-provider');
      expect(updated.semantic.aiModel, 'fixture-vision-model');
      expect(updated.semantic.aiProcessedAt, isNull);
      expect(updated.indexState.aiProcessed, isFalse);
    });

    test(
      'photo completed transition writes generated fields and keeps manual fields',
      () {
        final repository = ChronoPicRepository()
          ..restoreBackup(fixtureBackup());

        final updated = repository.updatePhotoSemanticEnrichment(
          'photo-city',
          aiStatus: AiPipelineStatus.completed,
          aiError: null,
          generatedLabels: ['fresh', 'fresh'],
          generatedCaption: 'Fresh generated caption',
          summary: 'Fresh generated summary',
          aiProvider: 'next-provider',
          aiModel: 'next-model',
          aiProcessedAt: 1715009000000,
        );

        expect(updated.semantic.aiStatus, AiPipelineStatus.completed);
        expect(updated.semantic.aiError, isNull);
        expect(updated.semantic.generatedLabels, ['fresh', 'fresh']);
        expect(updated.semantic.generatedCaption, 'Fresh generated caption');
        expect(updated.semantic.summary, 'Fresh generated summary');
        expect(updated.semantic.aiProvider, 'next-provider');
        expect(updated.semantic.aiModel, 'next-model');
        expect(updated.semantic.aiProcessedAt, 1715009000000);
        expect(updated.semantic.labels, ['city']);
        expect(updated.semantic.caption, isNull);
        expect(updated.photo.path, '/fixture/chronopic/library/backup-city.png');
        expect(updated.indexState.aiProcessed, isTrue);
      },
    );

    test('photo failed transition keeps previous generated fields', () {
      final repository = ChronoPicRepository()..restoreBackup(fixtureBackup());

      final updated = repository.updatePhotoSemanticEnrichment(
        'photo-lake',
        aiStatus: AiPipelineStatus.failed,
        aiError: 'boom',
        aiProcessedAt: 1715009001000,
      );

      expect(updated.semantic.aiStatus, AiPipelineStatus.failed);
      expect(updated.semantic.aiError, 'boom');
      expect(updated.semantic.aiProcessedAt, 1715009001000);
      expect(updated.semantic.generatedLabels, ['water', 'travel']);
      expect(updated.semantic.generatedCaption, 'Generated lake caption');
      expect(
        updated.semantic.summary,
        'A generated summary for the lake fixture.',
      );
      expect(updated.semantic.aiProvider, 'fixture-provider');
      expect(updated.semantic.aiModel, 'fixture-vision-model');
      expect(updated.semantic.labels, ['backup', 'lake']);
      expect(updated.semantic.caption, 'Manual lake caption');
      expect(updated.indexState.aiProcessed, isFalse);
    });

    test('photo enrichment on unknown id throws', () {
      final repository = ChronoPicRepository()..restoreBackup(fixtureBackup());

      expect(
        () => repository.updatePhotoSemanticEnrichment(
          'photo-missing',
          aiStatus: AiPipelineStatus.processing,
        ),
        throwsStateError,
      );
    });

    test('memory processing transition clears error and preserves fields', () {
      final repository = ChronoPicRepository()..restoreBackup(fixtureBackup());

      final updated = repository.updateMemorySemanticEnrichment(
        'memory-weekend',
        aiStatus: AiPipelineStatus.processing,
        aiError: null,
      );

      expect(updated.aiStatus, AiPipelineStatus.processing);
      expect(updated.aiError, isNull);
      expect(updated.name, 'Fixture Weekend');
      expect(
        updated.description,
        'A portable memory used for Flutter parity tests.',
      );
      expect(updated.generatedName, 'Generated Weekend');
      expect(updated.generatedDescription, 'Generated memory description.');
      expect(updated.generatedLabels, ['weekend', 'travel']);
      expect(updated.aiProvider, 'fixture-provider');
      expect(updated.aiModel, 'fixture-vision-model');
      expect(updated.aiProcessedAt, 1715000060000);
    });

    test(
      'memory completed transition writes generated fields and keeps authored fields',
      () {
        final repository = ChronoPicRepository()
          ..restoreBackup(fixtureBackup());
        final before = DateTime.now().millisecondsSinceEpoch;

        final updated = repository.updateMemorySemanticEnrichment(
          'memory-weekend',
          aiStatus: AiPipelineStatus.completed,
          aiError: null,
          generatedName: 'Fresh Memory Name',
          generatedDescription: 'Fresh memory description.',
          generatedLabels: ['fresh', 'memory'],
          aiProvider: 'next-provider',
          aiModel: 'next-model',
          aiProcessedAt: 1715009002000,
        );

        expect(updated.aiStatus, AiPipelineStatus.completed);
        expect(updated.aiError, isNull);
        expect(updated.generatedName, 'Fresh Memory Name');
        expect(updated.generatedDescription, 'Fresh memory description.');
        expect(updated.generatedLabels, ['fresh', 'memory']);
        expect(updated.aiProvider, 'next-provider');
        expect(updated.aiModel, 'next-model');
        expect(updated.aiProcessedAt, 1715009002000);
        expect(updated.name, 'Fixture Weekend');
        expect(
          updated.description,
          'A portable memory used for Flutter parity tests.',
        );
        expect(updated.coverPhotoId, 'photo-lake');
        expect(updated.photoCount, 1);
        expect(updated.updatedAt, greaterThanOrEqualTo(before));
      },
    );

    test('memory failed transition keeps previous generated fields', () {
      final repository = ChronoPicRepository()..restoreBackup(fixtureBackup());

      final updated = repository.updateMemorySemanticEnrichment(
        'memory-weekend',
        aiStatus: AiPipelineStatus.failed,
        aiError: 'memory boom',
        aiProcessedAt: 1715009003000,
      );

      expect(updated.aiStatus, AiPipelineStatus.failed);
      expect(updated.aiError, 'memory boom');
      expect(updated.aiProcessedAt, 1715009003000);
      expect(updated.generatedName, 'Generated Weekend');
      expect(updated.generatedDescription, 'Generated memory description.');
      expect(updated.generatedLabels, ['weekend', 'travel']);
      expect(updated.name, 'Fixture Weekend');
      expect(
        updated.description,
        'A portable memory used for Flutter parity tests.',
      );
    });

    test('memory enrichment on unknown id throws', () {
      final repository = ChronoPicRepository()..restoreBackup(fixtureBackup());

      expect(
        () => repository.updateMemorySemanticEnrichment(
          'memory-missing',
          aiStatus: AiPipelineStatus.processing,
        ),
        throwsStateError,
      );
    });

    test('enrichment state survives export and reload', () {
      final repository = ChronoPicRepository()..restoreBackup(fixtureBackup());

      repository.updatePhotoSemanticEnrichment(
        'photo-city',
        aiStatus: AiPipelineStatus.completed,
        aiError: null,
        generatedLabels: ['persisted'],
        generatedCaption: 'Persisted caption',
        summary: 'Persisted summary',
        aiProvider: 'persisted-provider',
        aiModel: 'persisted-model',
        aiProcessedAt: 1715009004000,
      );
      repository.updateMemorySemanticEnrichment(
        'memory-weekend',
        aiStatus: AiPipelineStatus.failed,
        aiError: 'persisted failure',
        aiProcessedAt: 1715009005000,
      );

      final reloaded = ChronoPicRepository()
        ..restoreBackup(repository.createBackup());

      final photo = reloaded.getPhoto('photo-city');
      expect(photo, isNotNull);
      expect(photo!.semantic.aiStatus, AiPipelineStatus.completed);
      expect(photo.semantic.aiError, isNull);
      expect(photo.semantic.generatedLabels, ['persisted']);
      expect(photo.semantic.generatedCaption, 'Persisted caption');
      expect(photo.semantic.summary, 'Persisted summary');
      expect(photo.semantic.aiProvider, 'persisted-provider');
      expect(photo.semantic.aiModel, 'persisted-model');
      expect(photo.semantic.aiProcessedAt, 1715009004000);
      expect(photo.semantic.labels, ['city']);
      expect(photo.indexState.aiProcessed, isTrue);

      final memory = reloaded.getMemory('memory-weekend');
      expect(memory, isNotNull);
      expect(memory!.aiStatus, AiPipelineStatus.failed);
      expect(memory.aiError, 'persisted failure');
      expect(memory.aiProcessedAt, 1715009005000);
      expect(memory.generatedName, 'Generated Weekend');
      expect(memory.name, 'Fixture Weekend');
    });
  });
}
