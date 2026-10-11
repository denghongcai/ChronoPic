import 'dart:convert';
import 'dart:io';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';

import 'indexer_service.dart';

final class ChronoPicAppService {
  ChronoPicAppService(this.repository, {this.persistencePath}) {
    _loadPersistedBackup();
  }

  /// Upper bound on how many photos a single memory synthesis call may sample,
  /// matching the Electron reference (`enrichMemorySemantic` limit: 24).
  static const int _memoryAnalysisPhotoLimit = 24;

  factory ChronoPicAppService.persistent({
    ChronoPicRepository? repository,
    String? dataFilePath,
  }) {
    return ChronoPicAppService(
      repository ?? ChronoPicRepository(),
      persistencePath: dataFilePath ?? defaultPersistencePath(),
    );
  }

  final ChronoPicRepository repository;
  final String? persistencePath;

  static String defaultPersistencePath() {
    final dataHome =
        Platform.environment['XDG_DATA_HOME'] ??
        '${Platform.environment['HOME'] ?? Directory.systemTemp.path}/.local/share';
    return '$dataHome/chronopic_flutter/chronopic-backup.json';
  }

  BackupRestorePreview previewBackupRestore(ChronoPicBackup backup) =>
      repository.previewBackupRestore(backup);

  BackupRestoreResult restoreBackup(ChronoPicBackup backup) {
    final result = repository.restoreBackup(backup);
    _persistIfConfigured();
    return result;
  }

  ChronoPicBackup createBackup() => repository.createBackup();

  File exportBackupToFile(String path) {
    final file = File(path);
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(createBackup().toJson()),
    );
    return file;
  }

  ChronoPicBackup readBackupFile(String path) {
    final json = jsonDecode(File(path).readAsStringSync()) as Map;
    return ChronoPicBackup.fromJson(json.cast<String, Object?>());
  }

  BackupRestorePreview previewBackupFile(String path) =>
      previewBackupRestore(readBackupFile(path));

  BackupRestoreResult restoreBackupFile(String path) =>
      restoreBackup(readBackupFile(path));

  List<LibrarySource> listLibrarySources() => repository.listLibrarySources();

  LibrarySource addLibrarySource(String path) {
    final source = repository.upsertLibrarySource(path);
    _persistIfConfigured();
    return source;
  }

  Future<IndexerStats> scanDesktopDirectory(
    String path, {
    ChronoPicAiClient? aiClient,
  }) async {
    return scanMediaSource(
      path,
      DesktopDirectoryMediaSource(Directory(path)),
      aiClient: aiClient,
    );
  }

  Future<IndexerStats> scanMediaSource(
    String path,
    MediaSourceAdapter mediaSource, {
    ChronoPicAiClient? aiClient,
    Future<bool> Function()? shouldPause,
    void Function(ScanProgress progress)? onProgress,
  }) async {
    repository.upsertLibrarySource(path);
    final indexer = ChronoPicIndexerService(
      repository: repository,
      mediaSource: mediaSource,
      aiClient: aiClient ?? createAiClient(createBackup().settings.ai),
      thumbnailDirectory: _thumbnailDirectoryFor(path),
      shouldPause: shouldPause,
      onProgress: onProgress,
    );
    final stats = await indexer.scanLibrary();
    repository.upsertLibrarySource(
      path,
      lastScanAt: DateTime.now().millisecondsSinceEpoch,
    );
    _persistIfConfigured();
    return stats;
  }

  List<PhotoRecord> listPhotos([PhotoFilter filter = const PhotoFilter()]) =>
      repository.listPhotos(filter);

  int countPhotos([PhotoFilter filter = const PhotoFilter()]) =>
      repository.countPhotos(filter);

  PhotoRecord? getPhoto(String photoId) => repository.getPhoto(photoId);

  AiReadiness getAiSetupReadiness() =>
      getAiReadiness(createBackup().settings.ai);

  BackupSettings updateAiSettings(AiSettings aiSettings) {
    final settings = repository.updateAiSettings(aiSettings);
    _persistIfConfigured();
    return settings;
  }

  BackupSettings updateMapSettings(MapSettings mapSettings) {
    final settings = repository.updateMapSettings(mapSettings);
    _persistIfConfigured();
    return settings;
  }

  BackupSettings updateLocaleSettings(LocaleSettings localeSettings) {
    final settings = repository.updateLocaleSettings(localeSettings);
    _persistIfConfigured();
    return settings;
  }

  Map<AiPipelineStatus, int> getAiStatusCounts() {
    final counts = <AiPipelineStatus, int>{
      for (final status in AiPipelineStatus.values) status: 0,
    };
    for (final record in listPhotos(const PhotoFilter(limit: 1000000))) {
      counts[record.semantic.aiStatus] = counts[record.semantic.aiStatus]! + 1;
    }
    return counts;
  }

  List<MemoryCandidate> listMemoryCandidates([
    MemoryCandidateStatus status = MemoryCandidateStatus.pending,
  ]) => repository.listMemoryCandidates(status);

  Memory acceptMemoryCandidate(String candidateId) {
    final memory = repository.acceptMemoryCandidate(candidateId);
    _persistIfConfigured();
    return memory;
  }

  MemoryCandidate rejectMemoryCandidate(String candidateId) {
    final candidate = repository.rejectMemoryCandidate(candidateId);
    _persistIfConfigured();
    return candidate;
  }

  int retryFailedAiQueue() {
    final count = repository.retryFailedAiQueue();
    _persistIfConfigured();
    return count;
  }

  PhotoRecord updatePhotoCaption(String photoId, String? caption) {
    final record = repository.updatePhotoCaption(photoId, caption);
    _persistIfConfigured();
    return record;
  }

  PhotoRecord updatePhotoTags(String photoId, List<String> labels) {
    final record = repository.updatePhotoTags(photoId, labels);
    _persistIfConfigured();
    return record;
  }

  PhotoRecord updatePhotoDatetime(String photoId, int? datetime) {
    final record = repository.updatePhotoDatetime(photoId, datetime);
    _persistIfConfigured();
    return record;
  }

  PhotoRecord updatePhotoFavorite(String photoId, bool favorite) {
    final record = repository.updatePhotoFavorite(photoId, favorite);
    _persistIfConfigured();
    return record;
  }

  PhotoRecord rollbackLatestEdit(String photoId) {
    final record = repository.rollbackLatestEdit(photoId);
    _persistIfConfigured();
    return record;
  }

  // ─── AI enrichment orchestration ────────────────────────────────────────────

  /// Runs photo semantic enrichment through the repository state machine:
  /// `processing` → `completed` / `failed`, preserving manual fields.
  ///
  /// The AI client defaults to one built from persisted settings; tests may
  /// inject a fixture client through [aiClient]. Non-JSON model output arrives
  /// as a `failed` result from the client; transport exceptions are caught and
  /// mapped to the `failed` transition (Electron reference parity).
  Future<PhotoRecord> enrichPhotoSemantic(
    String photoId, {
    PhotoAiContext? context,
    ChronoPicAiClient? aiClient,
  }) async {
    final client = aiClient ?? _defaultAiClient();
    if (!client.isEnabled) {
      throw StateError('AI enrichment is not configured');
    }

    final photo = repository.getPhoto(photoId);
    if (photo == null) {
      throw StateError('Photo not found: $photoId');
    }

    repository.updatePhotoSemanticEnrichment(
      photoId,
      aiStatus: AiPipelineStatus.processing,
      aiError: null,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final input = await _resolvePhotoInput(photo);
      final analysis = await client.analyzePhoto(
        photoId: photoId,
        bytes: input?.bytes ?? const <int>[],
        mime: input?.mime ?? photo.photo.mime,
        datetime: photo.metadata.datetime == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(photo.metadata.datetime!),
        lat: photo.metadata.lat,
        lng: photo.metadata.lng,
        path: photo.photo.path,
        context: PhotoAiContext(
          outputLocale: context?.outputLocale ?? _defaultOutputLocale(),
        ),
      );

      if (analysis.status == AiPipelineStatus.failed) {
        final updated = repository.updatePhotoSemanticEnrichment(
          photoId,
          aiStatus: AiPipelineStatus.failed,
          aiError: analysis.error ?? 'Unknown AI enrichment error',
          aiProcessedAt: now,
        );
        _persistIfConfigured();
        return updated;
      }

      final updated = repository.updatePhotoSemanticEnrichment(
        photoId,
        aiStatus: AiPipelineStatus.completed,
        aiError: null,
        generatedLabels: analysis.generatedLabels,
        generatedCaption: analysis.generatedCaption,
        summary: analysis.summary,
        aiProvider: analysis.provider,
        aiModel: analysis.model,
        aiProcessedAt: now,
      );
      _persistIfConfigured();
      return updated;
    } catch (error) {
      final updated = repository.updatePhotoSemanticEnrichment(
        photoId,
        aiStatus: AiPipelineStatus.failed,
        aiError: error.toString(),
        aiProcessedAt: now,
      );
      _persistIfConfigured();
      return updated;
    }
  }

  /// Processes a bounded batch of photos whose AI state is `pending`, `failed`,
  /// or `disabled` (the disabled bucket keeps late-configured libraries
  /// enrichable without a re-index), one photo at a time.
  Future<({int processed, int completed, int failed})>
  enrichPendingSemantics({int limit = 12, PhotoAiContext? context, ChronoPicAiClient? aiClient}) async {
    final client = aiClient ?? _defaultAiClient();
    if (!client.isEnabled) {
      throw StateError('AI enrichment is not configured');
    }

    final queue = <PhotoRecord>[
      for (final status in <AiPipelineStatus>[
        AiPipelineStatus.disabled,
        AiPipelineStatus.pending,
        AiPipelineStatus.failed,
      ])
        ...repository.listPhotos(PhotoFilter(
          aiStatus: status,
          sortBy: PhotoSortBy.updatedAt,
          sortDirection: SortDirection.asc,
        )),
    ]..sort((a, b) => a.photo.updatedAt.compareTo(b.photo.updatedAt));
    final batch = queue.take(limit).toList();

    var completed = 0;
    var failed = 0;
    for (final photo in batch) {
      final updated = await enrichPhotoSemantic(
        photo.photo.id,
        context: context,
        aiClient: client,
      );
      if (updated.semantic.aiStatus == AiPipelineStatus.completed) {
        completed += 1;
      } else {
        failed += 1;
      }
    }

    return (
      processed: batch.length,
      completed: completed,
      failed: failed,
    );
  }

  /// Runs memory-level AI synthesis over a sampled subset of the memory's
  /// photos (newest first), preserving authored memory metadata.
  Future<Memory> enrichMemorySemantic(
    String memoryId, {
    MemoryAIContext? context,
    ChronoPicAiClient? aiClient,
  }) async {
    final client = aiClient ?? _defaultAiClient();
    if (!client.isEnabled) {
      throw StateError('AI enrichment is not configured');
    }

    final memory = repository.getMemory(memoryId);
    if (memory == null) {
      throw StateError('Memory not found: $memoryId');
    }

    final photos = repository.listPhotosByMemory(memoryId).toList()
      ..sort(
        (a, b) => (b.metadata.datetime ?? 0).compareTo(a.metadata.datetime ?? 0),
      );
    final sample = photos.take(_memoryAnalysisPhotoLimit).toList();

    if (sample.isEmpty) {
      final updated = repository.updateMemorySemanticEnrichment(
        memoryId,
        aiStatus: AiPipelineStatus.failed,
        aiError: 'Memory has no photos to analyze',
        aiProcessedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _persistIfConfigured();
      return updated;
    }

    repository.updateMemorySemanticEnrichment(
      memoryId,
      aiStatus: AiPipelineStatus.processing,
      aiError: null,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final analysis = await client.analyzeMemory(
        memory: memory,
        photos: sample,
        context: MemoryAIContext(
          name: context?.name,
          description: context?.description,
          outputLocale: context?.outputLocale ?? _defaultOutputLocale(),
        ),
      );

      if (analysis.status == AiPipelineStatus.failed) {
        final updated = repository.updateMemorySemanticEnrichment(
          memoryId,
          aiStatus: AiPipelineStatus.failed,
          aiError: analysis.error ?? 'Unknown AI enrichment error',
          aiProcessedAt: now,
        );
        _persistIfConfigured();
        return updated;
      }

      final updated = repository.updateMemorySemanticEnrichment(
        memoryId,
        aiStatus: AiPipelineStatus.completed,
        aiError: null,
        generatedName: analysis.generatedName,
        generatedDescription: analysis.generatedDescription,
        generatedLabels: analysis.generatedLabels,
        aiProvider: analysis.provider,
        aiModel: analysis.model,
        aiProcessedAt: now,
      );
      _persistIfConfigured();
      return updated;
    } catch (error) {
      final updated = repository.updateMemorySemanticEnrichment(
        memoryId,
        aiStatus: AiPipelineStatus.failed,
        aiError: error.toString(),
        aiProcessedAt: now,
      );
      _persistIfConfigured();
      return updated;
    }
  }

  ChronoPicAiClient _defaultAiClient() =>
      createAiClient(createBackup().settings.ai);

  /// Resolves the default AI output locale from persisted locale settings,
  /// mirroring the Electron `resolveAIOutputLocale` behavior: an explicit AI
  /// output locale wins; `follow-ui` falls back to the UI locale.
  String _defaultOutputLocale() {
    final locale = createBackup().settings.locale;
    return switch (locale.aiOutputLocale) {
      AiOutputLocale.zhCN => 'zh-CN',
      AiOutputLocale.enUS => 'en-US',
      AiOutputLocale.followUi =>
        locale.locale == LocaleSetting.zhCN ? 'zh-CN' : 'en-US',
    };
  }

  /// Electron `resolvePhotoInput` parity: prefer an absolute thumbnail (it is
  /// always a jpeg), else the original file for image mimes, else no image
  /// input at all. Unreadable files fall back to the text-only prompt instead
  /// of failing the enrichment run.
  Future<_PhotoFileInput?> _resolvePhotoInput(PhotoRecord record) async {
    final photo = record.photo;
    final String preferredPath;
    final String preferredMime;
    if (photo.thumbnailPath != null && File(photo.thumbnailPath!).isAbsolute) {
      preferredPath = photo.thumbnailPath!;
      preferredMime = 'image/jpeg';
    } else if (photo.mime.startsWith('image/')) {
      preferredPath = photo.path;
      preferredMime = photo.mime;
    } else {
      return null;
    }
    try {
      final bytes = await File(preferredPath).readAsBytes();
      return _PhotoFileInput(bytes: bytes, mime: preferredMime);
    } catch (_) {
      return null;
    }
  }

  List<Memory> listMemories() => repository.listMemories();

  Memory? getMemory(String memoryId) => repository.getMemory(memoryId);

  Memory createMemory(String name, {String? description}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final memory = repository.createMemory(
      'memory-$now',
      name,
      description: description,
    );
    _persistIfConfigured();
    return memory;
  }

  void addPhotoToMemory(String memoryId, String photoId) {
    repository.addPhotoToMemory(memoryId, photoId);
    _persistIfConfigured();
  }

  Memory updateMemory(
    String memoryId, {
    required String name,
    String? description,
  }) {
    final memory = repository.updateMemory(
      memoryId,
      name: name,
      description: description,
    );
    _persistIfConfigured();
    return memory;
  }

  Memory setMemoryCover(String memoryId, String photoId) {
    final memory = repository.setMemoryCover(memoryId, photoId);
    _persistIfConfigured();
    return memory;
  }

  void removePhotoFromMemory(String memoryId, String photoId) {
    repository.removePhotoFromMemory(memoryId, photoId);
    _persistIfConfigured();
  }

  void _loadPersistedBackup() {
    final path = persistencePath;
    if (path == null) return;
    final file = File(path);
    if (!file.existsSync()) return;
    final json = jsonDecode(file.readAsStringSync()) as Map;
    repository.restoreBackup(
      ChronoPicBackup.fromJson(json.cast<String, Object?>()),
    );
  }

  void _persistIfConfigured() {
    final path = persistencePath;
    if (path == null) return;
    exportBackupToFile(path);
  }

  Directory _thumbnailDirectoryFor(String libraryPath) {
    final base =
        Platform.environment['XDG_CACHE_HOME'] ??
        '${Platform.environment['HOME'] ?? Directory.systemTemp.path}/.cache';
    final encoded = base64Url
        .encode(utf8.encode(Directory(libraryPath).absolute.path))
        .replaceAll('=', '');
    return Directory('$base/chronopic_flutter/thumbnails/$encoded');
  }
}

/// Resolved file input handed to the AI client for photo analysis, mirroring
/// the Electron `FileInput` shape (`data` + `mediaType`).
final class _PhotoFileInput {
  const _PhotoFileInput({required this.bytes, required this.mime});

  final List<int> bytes;
  final String mime;
}
