import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';

final class IndexerStats {
  const IndexerStats({
    required this.discovered,
    required this.processed,
    required this.imported,
    required this.duplicates,
    required this.errors,
    required this.skipped,
    required this.missing,
  });

  final int discovered;
  final int processed;
  final int imported;
  final int duplicates;
  final int errors;
  final int skipped;
  final int missing;
}

final class ChronoPicIndexerService {
  ChronoPicIndexerService({
    required this.repository,
    required this.mediaSource,
    required this.aiClient,
  });

  final ChronoPicRepository repository;
  final MediaSourceAdapter mediaSource;
  final ChronoPicAiClient aiClient;
  final Set<String> _knownAssetIds = <String>{};
  final Map<String, int> _knownUpdatedAt = <String, int>{};

  Future<IndexerStats> scanLibrary() async {
    final assets = await mediaSource.listAssets();
    var imported = 0;
    var skipped = 0;
    var errors = 0;
    final seen = <String>{};

    for (final asset in assets) {
      seen.add(asset.id);
      final unchanged = _knownAssetIds.contains(asset.id) && _knownUpdatedAt[asset.id] == asset.metadata.updatedAt;
      if (unchanged) {
        skipped += 1;
        continue;
      }
      try {
        final read = await mediaSource.readAsset(asset.id);
        final ai = await aiClient.analyzePhoto(photoId: asset.id, bytes: read.bytes, mime: asset.metadata.mime ?? mimeFromPath(asset.path));
        repository.restoreBackup(_singleAssetBackup(asset, ai));
        _knownAssetIds.add(asset.id);
        _knownUpdatedAt[asset.id] = asset.metadata.updatedAt;
        imported += 1;
      } on Object {
        errors += 1;
      }
    }

    final missing = await mediaSource.listMissingAssetIds(_knownAssetIds.difference(seen));
    return IndexerStats(
      discovered: assets.length,
      processed: assets.length - skipped,
      imported: imported,
      duplicates: 0,
      errors: errors,
      skipped: skipped,
      missing: missing.length,
    );
  }

  ChronoPicBackup _singleAssetBackup(MediaAsset asset, PhotoAiResult ai) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = PhotoRecord(
      photo: Photo(
        id: asset.id,
        path: asset.path,
        hash: asset.id,
        size: asset.metadata.size,
        mime: asset.metadata.mime ?? mimeFromPath(asset.path),
        thumbnailPath: null,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      metadata: Metadata(
        photoId: asset.id,
        datetime: asset.metadata.datetime,
        lat: asset.metadata.lat,
        lng: asset.metadata.lng,
        camera: asset.metadata.camera,
        confidence: 0.5,
        originalDatetimeText: null,
      ),
      semantic: Semantic(
        photoId: asset.id,
        labels: const <String>[],
        caption: null,
        generatedLabels: ai.generatedLabels,
        generatedCaption: ai.generatedCaption,
        summary: ai.summary,
        embeddingRef: null,
        aiStatus: ai.status,
        aiProvider: ai.provider,
        aiModel: ai.model,
        aiProcessedAt: ai.status == AiPipelineStatus.completed ? now : null,
        aiError: ai.error,
      ),
      indexState: IndexState(
        photoId: asset.id,
        indexed: true,
        aiProcessed: ai.status == AiPipelineStatus.completed,
        error: null,
        lastIndexedAt: now,
        duplicateOf: null,
        sourceUpdatedAt: asset.metadata.updatedAt,
        missingAt: null,
      ),
    );
    return ChronoPicBackup(
      app: 'ChronoPic',
      schemaVersion: 1,
      exportedAt: now,
      settings: const BackupSettings(
        ai: AiSettings(apiKey: '', baseURL: '', model: '', providerName: 'openai-compatible'),
        map: MapSettings(apiKey: '', securityJsCode: ''),
        locale: LocaleSettings(locale: LocaleSetting.enUS, aiOutputLocale: AiOutputLocale.followUi),
      ),
      librarySources: const <LibrarySource>[],
      photos: <PhotoRecord>[record],
      memories: const <Memory>[],
      memoryPhotos: const <MemoryPhoto>[],
      editHistory: const <EditHistory>[],
      memoryCandidates: const <MemoryCandidate>[],
    );
  }
}

