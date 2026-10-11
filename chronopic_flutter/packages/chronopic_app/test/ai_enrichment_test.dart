import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

/// Recording fake so tests can inspect exactly what the app service sends to
/// the AI client without any network access.
final class _RecordingAiClient implements ChronoPicAiClient {
  _RecordingAiClient({this.failingPhotoIds = const <String>{}});

  final Set<String> failingPhotoIds;

  final List<String> photoIds = <String>[];
  final List<PhotoAiContext> photoContexts = <PhotoAiContext>[];
  final List<MemoryAIContext> memoryContexts = <MemoryAIContext>[];
  final List<List<PhotoRecord>> memoryPhotos = <List<PhotoRecord>>[];

  @override
  bool get isEnabled => true;

  @override
  Future<PhotoAiResult> analyzePhoto({
    required String photoId,
    required List<int> bytes,
    required String mime,
    DateTime? datetime,
    double? lat,
    double? lng,
    String? path,
    PhotoAiContext context = const PhotoAiContext(),
  }) async {
    photoIds.add(photoId);
    photoContexts.add(context);
    if (failingPhotoIds.contains(photoId)) {
      return PhotoAiResult(
        status: AiPipelineStatus.failed,
        error: 'recording failure for $photoId',
      );
    }
    return PhotoAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: <String>['recorded', photoId],
      generatedCaption: 'Recorded caption for $photoId',
      summary: 'Recorded summary for $photoId.',
      provider: 'recording-provider',
      model: 'recording-model',
    );
  }

  @override
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  }) async {
    memoryContexts.add(context);
    memoryPhotos.add(photos);
    return MemoryAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: const <String>['recorded', 'memory'],
      generatedName: 'Recorded name for ${memory.id}',
      generatedDescription: 'Recorded description for ${memory.id}.',
      provider: 'recording-provider',
      model: 'recording-model',
    );
  }
}

PhotoRecord _seedRecord(
  String id, {
  required AiPipelineStatus aiStatus,
  int? datetime,
  int updatedAt = 1000,
}) {
  return PhotoRecord(
    photo: Photo(
      id: id,
      path: '/fixture/$id-source.png',
      hash: null,
      size: 32,
      mime: 'image/png',
      thumbnailPath: null,
      favorite: false,
      createdAt: 900,
      updatedAt: updatedAt,
    ),
    metadata: Metadata(
      photoId: id,
      datetime: datetime,
      lat: null,
      lng: null,
      camera: null,
      confidence: 1,
      originalDatetimeText: null,
    ),
    semantic: Semantic(
      photoId: id,
      labels: <String>['manual'],
      caption: 'Manual $id caption',
      generatedLabels: const <String>[],
      generatedCaption: null,
      summary: null,
      embeddingRef: null,
      aiStatus: aiStatus,
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
    ),
    indexState: IndexState(
      photoId: id,
      indexed: true,
      aiProcessed: false,
      error: null,
      lastIndexedAt: null,
      duplicateOf: null,
      sourceUpdatedAt: null,
      missingAt: null,
    ),
  );
}

ChronoPicAppService _fixtureService() {
  final service = ChronoPicAppService(ChronoPicRepository());
  service.restoreBackup(
    ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson()),
  );
  return service;
}

void main() {
  group('photo semantic enrichment', () {
    test('success writes generated fields and preserves manual fields', () async {
      final service = _fixtureService();

      final updated = await service.enrichPhotoSemantic(
        'photo-city',
        aiClient: const FixtureSuccessAiClient(),
      );

      expect(updated.semantic.aiStatus, AiPipelineStatus.completed);
      expect(updated.semantic.aiError, isNull);
      expect(updated.semantic.generatedLabels, <String>['fixture', 'image']);
      expect(updated.semantic.generatedCaption, 'Generated caption for photo-city');
      expect(updated.semantic.summary, 'Generated summary for photo-city.');
      expect(updated.semantic.aiProvider, 'fixture-provider');
      expect(updated.semantic.aiModel, 'fixture-model');
      expect(updated.semantic.aiProcessedAt, isNotNull);
      // Manual (user-authored) fields are never touched.
      expect(updated.semantic.labels, <String>['city']);
      expect(updated.semantic.caption, isNull);
    });

    test('failed result writes failed status and preserves fields', () async {
      final service = _fixtureService();

      final updated = await service.enrichPhotoSemantic(
        'photo-lake',
        aiClient: const FixtureFailureAiClient(),
      );

      expect(updated.semantic.aiStatus, AiPipelineStatus.failed);
      expect(updated.semantic.aiError, 'fixture failure for photo-lake');
      expect(updated.semantic.aiProcessedAt, isNotNull);
      // Manual fields and previous generated fields survive a failed run.
      expect(updated.semantic.labels, <String>['backup', 'lake']);
      expect(updated.semantic.caption, 'Manual lake caption');
      expect(updated.semantic.generatedLabels, <String>['water', 'travel']);
      expect(updated.semantic.generatedCaption, 'Generated lake caption');
      expect(updated.semantic.summary, 'A generated summary for the lake fixture.');
    });

    test('unknown photo throws before any state transition', () {
      final service = _fixtureService();

      expect(
        () => service.enrichPhotoSemantic(
          'photo-missing',
          aiClient: const FixtureSuccessAiClient(),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Photo not found: photo-missing',
          ),
        ),
      );
    });

    test('processing transition clears previous error', () async {
      final service = _fixtureService();
      // photo-city is failed in the fixture, so it carries an aiError.
      expect(service.getPhoto('photo-city')!.semantic.aiError, isNotNull);

      await service.enrichPhotoSemantic(
        'photo-city',
        aiClient: const FixtureSuccessAiClient(),
      );

      expect(service.getPhoto('photo-city')!.semantic.aiError, isNull);
    });
  });

  group('enrichment guard', () {
    test('throws when no AI client is configured', () async {
      final repository = ChronoPicRepository();
      final service = ChronoPicAppService(repository);
      repository.upsertPhotoRecord(
        _seedRecord('photo-plain', aiStatus: AiPipelineStatus.pending),
      );
      final memory = service.createMemory('Plain Memory');
      repository.addPhotoToMemory(memory.id, 'photo-plain');

      expect(
        () => service.enrichPhotoSemantic('photo-plain'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'AI enrichment is not configured',
          ),
        ),
      );
      expect(
        () => service.enrichMemorySemantic(memory.id),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'AI enrichment is not configured',
          ),
        ),
      );
      expect(
        () => service.enrichPendingSemantics(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'AI enrichment is not configured',
          ),
        ),
      );
    });

    test('default client is built from persisted AI settings', () {
      final service = ChronoPicAppService(ChronoPicRepository());
      service.restoreBackup(
        ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson()),
      );

      // The fixture settings configure a full AI credential set, so the
      // settings-built default client is enabled and the guard passes — the
      // failure surface becomes "photo not found", not "not configured".
      expect(
        () => service.enrichPhotoSemantic('photo-missing'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Photo not found: photo-missing',
          ),
        ),
      );
    });
  });

  group('memory semantic enrichment', () {
    test('zero photos fails with the exact analysis error', () async {
      final service = _fixtureService();
      final emptyMemory = service.createMemory('Empty Memory');

      final updated = await service.enrichMemorySemantic(
        emptyMemory.id,
        aiClient: const FixtureSuccessAiClient(),
      );

      expect(updated.aiStatus, AiPipelineStatus.failed);
      expect(updated.aiError, 'Memory has no photos to analyze');
      expect(updated.aiProcessedAt, isNotNull);
      expect(updated.generatedName, isNull);
    });

    test('success writes generated fields and keeps authored fields', () async {
      final service = _fixtureService();

      final updated = await service.enrichMemorySemantic(
        'memory-weekend',
        aiClient: const FixtureSuccessAiClient(),
      );

      expect(updated.aiStatus, AiPipelineStatus.completed);
      expect(updated.aiError, isNull);
      expect(updated.generatedName, 'Generated title for memory-weekend');
      expect(
        updated.generatedDescription,
        'Generated description for memory-weekend.',
      );
      expect(updated.generatedLabels, <String>['fixture', 'memory']);
      expect(updated.aiProvider, 'fixture-provider');
      expect(updated.aiModel, 'fixture-model');
      expect(updated.aiProcessedAt, isNotNull);
      // Authored memory metadata is never overwritten by generated values.
      expect(updated.name, 'Fixture Weekend');
      expect(
        updated.description,
        'A portable memory used for Flutter parity tests.',
      );
    });

    test('memory drafts are forwarded to the client', () async {
      final service = _fixtureService();
      final client = _RecordingAiClient();

      await service.enrichMemorySemantic(
        'memory-weekend',
        aiClient: client,
        context: const MemoryAIContext(
          name: 'Draft title',
          description: 'Draft body',
        ),
      );

      expect(client.memoryContexts, hasLength(1));
      expect(client.memoryContexts.single.name, 'Draft title');
      expect(client.memoryContexts.single.description, 'Draft body');
      // The memory's photos are handed to the client as records.
      expect(
        client.memoryPhotos.single.map((record) => record.photo.id),
        <String>['photo-lake'],
      );
    });

    test('unknown memory throws', () {
      final service = _fixtureService();

      expect(
        () => service.enrichMemorySemantic(
          'memory-missing',
          aiClient: const FixtureSuccessAiClient(),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Memory not found: memory-missing',
          ),
        ),
      );
    });
  });

  group('enrichPendingSemantics', () {
    test('processes pending, failed, and disabled photos only', () async {
      final repository = ChronoPicRepository();
      final service = ChronoPicAppService(repository);
      repository.upsertPhotoRecord(
        _seedRecord('photo-pending', aiStatus: AiPipelineStatus.pending, updatedAt: 1001),
      );
      repository.upsertPhotoRecord(
        _seedRecord('photo-failed', aiStatus: AiPipelineStatus.failed, updatedAt: 1002),
      );
      repository.upsertPhotoRecord(
        _seedRecord('photo-disabled', aiStatus: AiPipelineStatus.disabled, updatedAt: 1003),
      );
      repository.upsertPhotoRecord(
        _seedRecord('photo-done', aiStatus: AiPipelineStatus.completed, updatedAt: 1004),
      );
      final client = _RecordingAiClient(failingPhotoIds: <String>{'photo-failed'});

      final summary = await service.enrichPendingSemantics(aiClient: client);

      expect(summary.processed, 3);
      expect(summary.completed, 2);
      expect(summary.failed, 1);
      expect(client.photoIds, <String>['photo-pending', 'photo-failed', 'photo-disabled']);

      expect(
        service.getPhoto('photo-pending')!.semantic.aiStatus,
        AiPipelineStatus.completed,
      );
      expect(
        service.getPhoto('photo-failed')!.semantic.aiStatus,
        AiPipelineStatus.failed,
      );
      expect(
        service.getPhoto('photo-disabled')!.semantic.aiStatus,
        AiPipelineStatus.completed,
      );
      // Completed photos are not re-enriched.
      final done = service.getPhoto('photo-done')!;
      expect(done.semantic.aiStatus, AiPipelineStatus.completed);
      expect(done.semantic.generatedCaption, isNull);
      expect(done.semantic.aiProcessedAt, isNull);
    });

    test('limit caps the processed batch', () async {
      final repository = ChronoPicRepository();
      final service = ChronoPicAppService(repository);
      for (var i = 0; i < 5; i++) {
        repository.upsertPhotoRecord(
          _seedRecord('photo-q$i', aiStatus: AiPipelineStatus.pending, updatedAt: 1000 + i),
        );
      }
      final client = _RecordingAiClient();

      final summary = await service.enrichPendingSemantics(limit: 2, aiClient: client);

      expect(summary.processed, 2);
      expect(summary.completed, 2);
      expect(client.photoIds, hasLength(2));
    });
  });

  group('output locale resolution', () {
    test('follow-ui resolves through the UI locale setting', () async {
      final service = _fixtureService();
      final client = _RecordingAiClient();
      service.updateLocaleSettings(
        const LocaleSettings(
          locale: LocaleSetting.zhCN,
          aiOutputLocale: AiOutputLocale.followUi,
        ),
      );

      await service.enrichPhotoSemantic('photo-city', aiClient: client);

      expect(client.photoContexts.single.outputLocale, 'zh-CN');
    });

    test('explicit aiOutputLocale overrides the UI locale', () async {
      final service = _fixtureService();
      final client = _RecordingAiClient();
      service.updateLocaleSettings(
        const LocaleSettings(
          locale: LocaleSetting.enUS,
          aiOutputLocale: AiOutputLocale.zhCN,
        ),
      );

      await service.enrichPhotoSemantic('photo-city', aiClient: client);

      expect(client.photoContexts.single.outputLocale, 'zh-CN');
    });

    test('explicit context overrides persisted settings', () async {
      final service = _fixtureService();
      final client = _RecordingAiClient();
      service.updateLocaleSettings(
        const LocaleSettings(
          locale: LocaleSetting.zhCN,
          aiOutputLocale: AiOutputLocale.zhCN,
        ),
      );

      await service.enrichPhotoSemantic(
        'photo-city',
        aiClient: client,
        context: const PhotoAiContext(outputLocale: 'en-US'),
      );
      await service.enrichMemorySemantic(
        'memory-weekend',
        aiClient: client,
        context: const MemoryAIContext(outputLocale: 'en-US'),
      );

      expect(client.photoContexts.single.outputLocale, 'en-US');
      expect(client.memoryContexts.single.outputLocale, 'en-US');
    });

    test('default English is used before locale settings exist', () async {
      final repository = ChronoPicRepository();
      final service = ChronoPicAppService(repository);
      repository.upsertPhotoRecord(
        _seedRecord('photo-plain', aiStatus: AiPipelineStatus.pending),
      );
      final client = _RecordingAiClient();

      await service.enrichPhotoSemantic('photo-plain', aiClient: client);

      expect(client.photoContexts.single.outputLocale, 'en-US');
    });
  });
}
