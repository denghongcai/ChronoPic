import 'package:chronopic_domain/chronopic_domain.dart';

final class BackupRestoreResult {
  const BackupRestoreResult({
    required this.preview,
    required this.restoredSourceCount,
    required this.restoredPhotoCount,
    required this.restoredMemoryCount,
    required this.restoredMemoryPhotoCount,
    required this.restoredEditHistoryCount,
    required this.restoredMemoryCandidateCount,
  });

  final BackupRestorePreview preview;
  final int restoredSourceCount;
  final int restoredPhotoCount;
  final int restoredMemoryCount;
  final int restoredMemoryPhotoCount;
  final int restoredEditHistoryCount;
  final int restoredMemoryCandidateCount;
}

final class ChronoPicRepository {
  ChronoPicRepository();

  ChronoPicBackup? _lastBackup;
  final Map<String, LibrarySource> _sources = <String, LibrarySource>{};
  final Map<String, PhotoRecord> _photos = <String, PhotoRecord>{};
  final Map<String, Memory> _memories = <String, Memory>{};
  final List<MemoryPhoto> _memoryPhotos = <MemoryPhoto>[];
  final List<EditHistory> _editHistory = <EditHistory>[];
  final Map<String, MemoryCandidate> _memoryCandidates = <String, MemoryCandidate>{};

  BackupRestorePreview previewBackupRestore(ChronoPicBackup backup) {
    return BackupRestorePreview.fromBackup(backup);
  }

  BackupRestoreResult restoreBackup(ChronoPicBackup backup) {
    final validation = validateChronoPicBackup(backup);
    if (!validation.valid) {
      throw StateError('Invalid ChronoPic backup: ${validation.errors.join(', ')}');
    }
    _lastBackup = backup;
    _sources
      ..clear()
      ..addEntries(backup.librarySources.map((source) => MapEntry(source.id, source)));
    _photos
      ..clear()
      ..addEntries(backup.photos.map((record) => MapEntry(record.photo.id, record)));
    _memories
      ..clear()
      ..addEntries(backup.memories.map((memory) => MapEntry(memory.id, memory)));
    _memoryPhotos
      ..clear()
      ..addAll(backup.memoryPhotos);
    _editHistory
      ..clear()
      ..addAll(backup.editHistory);
    _memoryCandidates
      ..clear()
      ..addEntries(backup.memoryCandidates.map((candidate) => MapEntry(candidate.id, candidate)));

    final preview = BackupRestorePreview.fromBackup(backup);
    return BackupRestoreResult(
      preview: preview,
      restoredSourceCount: preview.sourceCount,
      restoredPhotoCount: preview.photoCount,
      restoredMemoryCount: preview.memoryCount,
      restoredMemoryPhotoCount: preview.memoryPhotoCount,
      restoredEditHistoryCount: preview.editHistoryCount,
      restoredMemoryCandidateCount: preview.memoryCandidateCount,
    );
  }

  ChronoPicBackup createBackup() {
    final previous = _lastBackup;
    return ChronoPicBackup(
      app: 'ChronoPic',
      schemaVersion: 1,
      exportedAt: previous?.exportedAt ?? DateTime.now().millisecondsSinceEpoch,
      settings: previous?.settings ??
          const BackupSettings(
            ai: AiSettings(apiKey: '', baseURL: '', model: '', providerName: 'openai-compatible'),
            map: MapSettings(apiKey: '', securityJsCode: ''),
            locale: LocaleSettings(locale: LocaleSetting.enUS, aiOutputLocale: AiOutputLocale.followUi),
          ),
      librarySources: _sources.values.toList(),
      photos: _photos.values.toList(),
      memories: _memories.values.toList(),
      memoryPhotos: List<MemoryPhoto>.of(_memoryPhotos),
      editHistory: List<EditHistory>.of(_editHistory),
      memoryCandidates: _memoryCandidates.values.toList(),
    );
  }

  List<PhotoRecord> listPhotos([PhotoFilter filter = const PhotoFilter()]) {
    final records = _photos.values.where((record) {
      if (filter.favorite != null && record.photo.favorite != filter.favorite) return false;
      if (filter.memoryId != null && !_memoryPhotos.any((membership) => membership.memoryId == filter.memoryId && membership.photoId == record.photo.id)) {
        return false;
      }
      if (filter.hasGps == true && (record.metadata.lat == null || record.metadata.lng == null)) return false;
      if (filter.tag != null && !record.semantic.labels.contains(filter.tag)) return false;
      if (filter.query != null && !record.photo.path.contains(filter.query!) && !(record.semantic.caption?.contains(filter.query!) ?? false)) {
        return false;
      }
      return true;
    }).toList();

    records.sort((a, b) {
      final direction = filter.sortDirection == SortDirection.asc ? 1 : -1;
      final comparison = switch (filter.sortBy) {
        PhotoSortBy.path => a.photo.path.compareTo(b.photo.path),
        PhotoSortBy.updatedAt => a.photo.updatedAt.compareTo(b.photo.updatedAt),
        PhotoSortBy.datetime => (a.metadata.datetime ?? 0).compareTo(b.metadata.datetime ?? 0),
      };
      return comparison * direction;
    });
    final start = filter.offset.clamp(0, records.length);
    final end = (start + filter.limit).clamp(start, records.length);
    return records.sublist(start, end);
  }

  PhotoRecord? getPhoto(String photoId) => _photos[photoId];

  PhotoRecord updatePhotoCaption(String photoId, String? caption) {
    final record = _requirePhoto(photoId);
    final updated = _replaceRecord(
      record,
      semantic: Semantic(
        photoId: record.semantic.photoId,
        labels: record.semantic.labels,
        caption: caption,
        generatedLabels: record.semantic.generatedLabels,
        generatedCaption: record.semantic.generatedCaption,
        summary: record.semantic.summary,
        embeddingRef: record.semantic.embeddingRef,
        aiStatus: record.semantic.aiStatus,
        aiProvider: record.semantic.aiProvider,
        aiModel: record.semantic.aiModel,
        aiProcessedAt: record.semantic.aiProcessedAt,
        aiError: record.semantic.aiError,
      ),
    );
    _photos[photoId] = updated;
    return updated;
  }

  PhotoRecord updatePhotoTags(String photoId, List<String> labels) {
    final record = _requirePhoto(photoId);
    final updated = _replaceRecord(
      record,
      semantic: Semantic(
        photoId: record.semantic.photoId,
        labels: List<String>.of(labels),
        caption: record.semantic.caption,
        generatedLabels: record.semantic.generatedLabels,
        generatedCaption: record.semantic.generatedCaption,
        summary: record.semantic.summary,
        embeddingRef: record.semantic.embeddingRef,
        aiStatus: record.semantic.aiStatus,
        aiProvider: record.semantic.aiProvider,
        aiModel: record.semantic.aiModel,
        aiProcessedAt: record.semantic.aiProcessedAt,
        aiError: record.semantic.aiError,
      ),
    );
    _photos[photoId] = updated;
    return updated;
  }

  PhotoRecord updatePhotoFavorite(String photoId, bool favorite) {
    final record = _requirePhoto(photoId);
    final updated = _replaceRecord(
      record,
      photo: Photo(
        id: record.photo.id,
        path: record.photo.path,
        hash: record.photo.hash,
        size: record.photo.size,
        mime: record.photo.mime,
        thumbnailPath: record.photo.thumbnailPath,
        favorite: favorite,
        createdAt: record.photo.createdAt,
        updatedAt: record.photo.updatedAt,
      ),
    );
    _photos[photoId] = updated;
    return updated;
  }

  Memory createMemory(String id, String name, {String? description}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final memory = Memory(
      id: id,
      name: name,
      description: description,
      coverPhotoId: null,
      coverThumbnailPath: null,
      photoCount: 0,
      generatedName: null,
      generatedDescription: null,
      generatedLabels: const <String>[],
      aiStatus: AiPipelineStatus.disabled,
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
      source: MemorySource.manual,
      createdAt: now,
      updatedAt: now,
    );
    _memories[id] = memory;
    return memory;
  }

  void addPhotoToMemory(String memoryId, String photoId) {
    _requirePhoto(photoId);
    if (!_memories.containsKey(memoryId)) throw StateError('Unknown memory $memoryId');
    if (_memoryPhotos.any((membership) => membership.memoryId == memoryId && membership.photoId == photoId)) return;
    _memoryPhotos.add(MemoryPhoto(memoryId: memoryId, photoId: photoId, addedAt: DateTime.now().millisecondsSinceEpoch));
  }

  List<PhotoRecord> listPhotosByMemory(String memoryId) {
    final ids = _memoryPhotos.where((membership) => membership.memoryId == memoryId).map((membership) => membership.photoId).toSet();
    return _photos.values.where((record) => ids.contains(record.photo.id)).toList();
  }

  List<MemoryCandidate> listMemoryCandidates([MemoryCandidateStatus status = MemoryCandidateStatus.pending]) {
    return _memoryCandidates.values.where((candidate) => candidate.status == status).toList();
  }

  PhotoRecord _requirePhoto(String photoId) {
    final record = _photos[photoId];
    if (record == null) throw StateError('Unknown photo $photoId');
    return record;
  }

  PhotoRecord _replaceRecord(PhotoRecord record, {Photo? photo, Semantic? semantic}) {
    return PhotoRecord(
      photo: photo ?? record.photo,
      metadata: record.metadata,
      semantic: semantic ?? record.semantic,
      indexState: record.indexState,
    );
  }
}
