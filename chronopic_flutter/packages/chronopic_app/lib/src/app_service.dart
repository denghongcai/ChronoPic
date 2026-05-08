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
    ChronoPicAiClient aiClient = const DisabledAiClient(),
  }) async {
    repository.upsertLibrarySource(path);
    final indexer = ChronoPicIndexerService(
      repository: repository,
      mediaSource: DesktopDirectoryMediaSource(Directory(path)),
      aiClient: aiClient,
      thumbnailDirectory: _thumbnailDirectoryFor(path),
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

  PhotoRecord? getPhoto(String photoId) => repository.getPhoto(photoId);

  AiReadiness getAiSetupReadiness() =>
      getAiReadiness(createBackup().settings.ai);

  BackupSettings updateAiSettings(AiSettings aiSettings) {
    final settings = repository.updateAiSettings(aiSettings);
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
