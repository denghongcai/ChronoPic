import 'package:chronopic_domain/chronopic_domain.dart';

const Object _unchanged = Object();

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
  BackupSettings? _settings;
  final Map<String, LibrarySource> _sources = <String, LibrarySource>{};
  final Map<String, PhotoRecord> _photos = <String, PhotoRecord>{};
  final Map<String, Memory> _memories = <String, Memory>{};
  final List<MemoryPhoto> _memoryPhotos = <MemoryPhoto>[];
  final List<EditHistory> _editHistory = <EditHistory>[];
  final Map<String, MemoryCandidate> _memoryCandidates =
      <String, MemoryCandidate>{};

  BackupRestorePreview previewBackupRestore(ChronoPicBackup backup) {
    return BackupRestorePreview.fromBackup(backup);
  }

  BackupRestoreResult restoreBackup(ChronoPicBackup backup) {
    final validation = validateChronoPicBackup(backup);
    if (!validation.valid) {
      throw StateError(
        'Invalid ChronoPic backup: ${validation.errors.join(', ')}',
      );
    }
    _lastBackup = backup;
    _settings = backup.settings;
    _sources
      ..clear()
      ..addEntries(
        backup.librarySources.map((source) => MapEntry(source.id, source)),
      );
    _photos
      ..clear()
      ..addEntries(
        backup.photos.map((record) => MapEntry(record.photo.id, record)),
      );
    _memories
      ..clear()
      ..addEntries(
        backup.memories.map((memory) => MapEntry(memory.id, memory)),
      );
    _memoryPhotos
      ..clear()
      ..addAll(backup.memoryPhotos);
    _editHistory
      ..clear()
      ..addAll(backup.editHistory);
    _memoryCandidates
      ..clear()
      ..addEntries(
        backup.memoryCandidates.map(
          (candidate) => MapEntry(candidate.id, candidate),
        ),
      );

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

  List<LibrarySource> listLibrarySources() =>
      _sources.values.toList()..sort((a, b) => a.path.compareTo(b.path));

  LibrarySource upsertLibrarySource(String path, {int? lastScanAt}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = path;
    final previous = _sources[id];
    final source = LibrarySource(
      id: id,
      path: path,
      isActive: true,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      lastScanAt: lastScanAt ?? previous?.lastScanAt,
    );
    _sources[id] = source;
    return source;
  }

  PhotoRecord upsertPhotoRecord(PhotoRecord record) {
    final previous = _photos[record.photo.id];
    final merged = previous == null
        ? record
        : _mergeIndexedRecord(previous, record);
    _photos[record.photo.id] = merged;
    return merged;
  }

  ChronoPicBackup createBackup() {
    final previous = _lastBackup;
    return ChronoPicBackup(
      app: 'ChronoPic',
      schemaVersion: 1,
      exportedAt: previous?.exportedAt ?? DateTime.now().millisecondsSinceEpoch,
      settings:
          _settings ??
          previous?.settings ??
          const BackupSettings(
            ai: AiSettings(
              apiKey: '',
              baseURL: '',
              model: '',
              providerName: 'openai-compatible',
            ),
            map: MapSettings(apiKey: '', securityJsCode: ''),
            locale: LocaleSettings(
              locale: LocaleSetting.enUS,
              aiOutputLocale: AiOutputLocale.followUi,
            ),
          ),
      librarySources: _sources.values.toList(),
      photos: _photos.values.toList(),
      memories: _memories.values.toList(),
      memoryPhotos: List<MemoryPhoto>.of(_memoryPhotos),
      editHistory: List<EditHistory>.of(_editHistory),
      memoryCandidates: _memoryCandidates.values.toList(),
    );
  }

  BackupSettings updateAiSettings(AiSettings aiSettings) {
    final current = createBackup().settings;
    _settings = BackupSettings(
      ai: aiSettings,
      map: current.map,
      locale: current.locale,
    );
    return _settings!;
  }

  BackupSettings updateMapSettings(MapSettings mapSettings) {
    final current = createBackup().settings;
    _settings = BackupSettings(
      ai: current.ai,
      map: mapSettings,
      locale: current.locale,
    );
    return _settings!;
  }

  BackupSettings updateLocaleSettings(LocaleSettings localeSettings) {
    final current = createBackup().settings;
    _settings = BackupSettings(
      ai: current.ai,
      map: current.map,
      locale: localeSettings,
    );
    return _settings!;
  }

  List<PhotoRecord> listPhotos([PhotoFilter filter = const PhotoFilter()]) {
    final records = _photos.values.where((record) {
      if (filter.favorite != null && record.photo.favorite != filter.favorite) {
        return false;
      }
      if (filter.memoryId != null &&
          !_memoryPhotos.any(
            (membership) =>
                membership.memoryId == filter.memoryId &&
                membership.photoId == record.photo.id,
          )) {
        return false;
      }
      if (filter.mimePrefix != null &&
          !record.photo.mime.startsWith(filter.mimePrefix!)) {
        return false;
      }
      if (filter.aiStatus != null &&
          record.semantic.aiStatus != filter.aiStatus) {
        return false;
      }
      if (filter.indexed != null &&
          record.indexState.indexed != filter.indexed) {
        return false;
      }
      if (filter.hasError != null &&
          (record.indexState.error != null ||
                  record.semantic.aiError != null) !=
              filter.hasError) {
        return false;
      }
      if (filter.hasGps == true &&
          (record.metadata.lat == null || record.metadata.lng == null)) {
        return false;
      }
      if (filter.hasGps == false &&
          record.metadata.lat != null &&
          record.metadata.lng != null) {
        return false;
      }
      if (filter.tag != null && !record.semantic.labels.contains(filter.tag)) {
        return false;
      }
      if (filter.fromDatetime != null &&
          (record.metadata.datetime == null ||
              record.metadata.datetime! < filter.fromDatetime!)) {
        return false;
      }
      if (filter.toDatetime != null &&
          (record.metadata.datetime == null ||
              record.metadata.datetime! > filter.toDatetime!)) {
        return false;
      }
      if (filter.query != null &&
          !record.photo.path.contains(filter.query!) &&
          !(record.semantic.caption?.contains(filter.query!) ?? false)) {
        return false;
      }
      return true;
    }).toList();

    records.sort((a, b) {
      final direction = filter.sortDirection == SortDirection.asc ? 1 : -1;
      final comparison = switch (filter.sortBy) {
        PhotoSortBy.path => a.photo.path.compareTo(b.photo.path),
        PhotoSortBy.updatedAt => a.photo.updatedAt.compareTo(b.photo.updatedAt),
        PhotoSortBy.datetime => (a.metadata.datetime ?? 0).compareTo(
          b.metadata.datetime ?? 0,
        ),
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
    final previousCaption = record.semantic.caption;
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
    _recordEdit(
      photoId: photoId,
      fieldName: 'caption',
      previousValue: previousCaption,
      nextValue: caption,
    );
    return updated;
  }

  PhotoRecord updatePhotoTags(String photoId, List<String> labels) {
    final record = _requirePhoto(photoId);
    final previousLabels = record.semantic.labels.join(',');
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
    _recordEdit(
      photoId: photoId,
      fieldName: 'tags',
      previousValue: previousLabels,
      nextValue: labels.join(','),
    );
    return updated;
  }

  PhotoRecord updatePhotoDatetime(String photoId, int? datetime) {
    final record = _requirePhoto(photoId);
    final previousDatetime = record.metadata.datetime?.toString();
    final updated = PhotoRecord(
      photo: record.photo,
      metadata: Metadata(
        photoId: record.metadata.photoId,
        datetime: datetime,
        lat: record.metadata.lat,
        lng: record.metadata.lng,
        camera: record.metadata.camera,
        confidence: record.metadata.confidence,
        originalDatetimeText: record.metadata.originalDatetimeText,
      ),
      semantic: record.semantic,
      indexState: record.indexState,
    );
    _photos[photoId] = updated;
    _recordEdit(
      photoId: photoId,
      fieldName: 'datetime',
      previousValue: previousDatetime,
      nextValue: datetime?.toString(),
    );
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
    _recordEdit(
      photoId: photoId,
      fieldName: 'favorite',
      previousValue: record.photo.favorite.toString(),
      nextValue: favorite.toString(),
    );
    return updated;
  }

  PhotoRecord rollbackLatestEdit(String photoId) {
    final editIndex = _editHistory.lastIndexWhere(
      (edit) => edit.photoId == photoId && edit.rolledBackAt == null,
    );
    if (editIndex < 0) return _requirePhoto(photoId);
    final edit = _editHistory[editIndex];
    final record = _requirePhoto(photoId);
    final rolledBack = switch (edit.fieldName) {
      'caption' => _replaceRecord(
        record,
        semantic: Semantic(
          photoId: record.semantic.photoId,
          labels: record.semantic.labels,
          caption: edit.previousValue,
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
      ),
      'tags' => _replaceRecord(
        record,
        semantic: Semantic(
          photoId: record.semantic.photoId,
          labels: _splitTags(edit.previousValue),
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
      ),
      'favorite' => _replaceRecord(
        record,
        photo: Photo(
          id: record.photo.id,
          path: record.photo.path,
          hash: record.photo.hash,
          size: record.photo.size,
          mime: record.photo.mime,
          thumbnailPath: record.photo.thumbnailPath,
          favorite: edit.previousValue == 'true',
          createdAt: record.photo.createdAt,
          updatedAt: record.photo.updatedAt,
        ),
      ),
      'datetime' => PhotoRecord(
        photo: record.photo,
        metadata: Metadata(
          photoId: record.metadata.photoId,
          datetime: _parseInt(edit.previousValue),
          lat: record.metadata.lat,
          lng: record.metadata.lng,
          camera: record.metadata.camera,
          confidence: record.metadata.confidence,
          originalDatetimeText: record.metadata.originalDatetimeText,
        ),
        semantic: record.semantic,
        indexState: record.indexState,
      ),
      _ => record,
    };
    _photos[photoId] = rolledBack;
    _editHistory[editIndex] = EditHistory(
      id: edit.id,
      photoId: edit.photoId,
      fieldName: edit.fieldName,
      previousValue: edit.previousValue,
      nextValue: edit.nextValue,
      createdAt: edit.createdAt,
      rolledBackAt: DateTime.now().millisecondsSinceEpoch,
    );
    return rolledBack;
  }

  List<EditHistory> listEditHistory(String photoId) {
    return _editHistory.where((edit) => edit.photoId == photoId).toList();
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

  List<Memory> listMemories() =>
      _memories.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Memory? getMemory(String memoryId) => _memories[memoryId];

  Memory updateMemory(
    String memoryId, {
    required String name,
    String? description,
  }) {
    final memory = _requireMemory(memoryId);
    final updated = _copyMemory(
      memory,
      name: name,
      description: description,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _memories[memoryId] = updated;
    return updated;
  }

  void addPhotoToMemory(String memoryId, String photoId) {
    _requirePhoto(photoId);
    _requireMemory(memoryId);
    if (_memoryPhotos.any(
      (membership) =>
          membership.memoryId == memoryId && membership.photoId == photoId,
    )) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    _memoryPhotos.add(
      MemoryPhoto(memoryId: memoryId, photoId: photoId, addedAt: now),
    );
    final memory = _memories[memoryId]!;
    final count = _memoryPhotos
        .where((membership) => membership.memoryId == memoryId)
        .length;
    final photo = _photos[photoId]!.photo;
    _memories[memoryId] = Memory(
      id: memory.id,
      name: memory.name,
      description: memory.description,
      coverPhotoId: memory.coverPhotoId ?? photoId,
      coverThumbnailPath: memory.coverThumbnailPath ?? photo.thumbnailPath,
      photoCount: count,
      generatedName: memory.generatedName,
      generatedDescription: memory.generatedDescription,
      generatedLabels: memory.generatedLabels,
      aiStatus: memory.aiStatus,
      aiProvider: memory.aiProvider,
      aiModel: memory.aiModel,
      aiProcessedAt: memory.aiProcessedAt,
      aiError: memory.aiError,
      source: memory.source,
      createdAt: memory.createdAt,
      updatedAt: now,
    );
  }

  void removePhotoFromMemory(String memoryId, String photoId) {
    final memory = _requireMemory(memoryId);
    _memoryPhotos.removeWhere(
      (membership) =>
          membership.memoryId == memoryId && membership.photoId == photoId,
    );
    final remaining = _memoryPhotos
        .where((membership) => membership.memoryId == memoryId)
        .toList();
    final nextCoverPhotoId = memory.coverPhotoId == photoId
        ? (remaining.isEmpty ? null : remaining.first.photoId)
        : null;
    final nextCover = nextCoverPhotoId == null
        ? (memory.coverPhotoId == photoId
              ? null
              : _photos[memory.coverPhotoId]?.photo)
        : _photos[nextCoverPhotoId]?.photo;
    _memories[memoryId] = _copyMemory(
      memory,
      coverPhotoId: nextCover?.id,
      coverThumbnailPath: nextCover?.thumbnailPath,
      photoCount: remaining.length,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Memory setMemoryCover(String memoryId, String photoId) {
    final memory = _requireMemory(memoryId);
    final photo = _requirePhoto(photoId).photo;
    if (!_memoryPhotos.any(
      (membership) =>
          membership.memoryId == memoryId && membership.photoId == photoId,
    )) {
      throw StateError('Photo $photoId is not in memory $memoryId');
    }
    final updated = _copyMemory(
      memory,
      coverPhotoId: photoId,
      coverThumbnailPath: photo.thumbnailPath,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _memories[memoryId] = updated;
    return updated;
  }

  List<PhotoRecord> listPhotosByMemory(String memoryId) {
    final ids = _memoryPhotos
        .where((membership) => membership.memoryId == memoryId)
        .map((membership) => membership.photoId)
        .toSet();
    return _photos.values
        .where((record) => ids.contains(record.photo.id))
        .toList();
  }

  List<MemoryCandidate> listMemoryCandidates([
    MemoryCandidateStatus status = MemoryCandidateStatus.pending,
  ]) {
    return _memoryCandidates.values
        .where((candidate) => candidate.status == status)
        .toList();
  }

  Memory acceptMemoryCandidate(String candidateId) {
    final candidate = _requireMemoryCandidate(candidateId);
    if (candidate.status == MemoryCandidateStatus.accepted &&
        candidate.acceptedMemoryId != null) {
      return _requireMemory(candidate.acceptedMemoryId!);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final memoryId = candidate.acceptedMemoryId ?? 'memory-${candidate.id}';
    final memory = createMemory(
      memoryId,
      candidate.title,
      description: candidate.description,
    );
    for (final photoId in candidate.photoIds) {
      if (_photos.containsKey(photoId)) addPhotoToMemory(memoryId, photoId);
    }
    if (candidate.coverPhotoId != null &&
        _photos.containsKey(candidate.coverPhotoId)) {
      setMemoryCover(memoryId, candidate.coverPhotoId!);
    }
    _memoryCandidates[candidateId] = _copyMemoryCandidate(
      candidate,
      status: MemoryCandidateStatus.accepted,
      acceptedMemoryId: memoryId,
      updatedAt: now,
    );
    return _memories[memoryId] ?? memory;
  }

  MemoryCandidate rejectMemoryCandidate(String candidateId) {
    final candidate = _requireMemoryCandidate(candidateId);
    final updated = _copyMemoryCandidate(
      candidate,
      status: MemoryCandidateStatus.rejected,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _memoryCandidates[candidateId] = updated;
    return updated;
  }

  int retryFailedAiQueue() {
    var retried = 0;
    for (final entry in _photos.entries.toList()) {
      final record = entry.value;
      if (record.semantic.aiStatus != AiPipelineStatus.failed) continue;
      retried += 1;
      _photos[entry.key] = _replaceRecord(
        record,
        semantic: Semantic(
          photoId: record.semantic.photoId,
          labels: record.semantic.labels,
          caption: record.semantic.caption,
          generatedLabels: record.semantic.generatedLabels,
          generatedCaption: record.semantic.generatedCaption,
          summary: record.semantic.summary,
          embeddingRef: record.semantic.embeddingRef,
          aiStatus: AiPipelineStatus.pending,
          aiProvider: record.semantic.aiProvider,
          aiModel: record.semantic.aiModel,
          aiProcessedAt: record.semantic.aiProcessedAt,
          aiError: null,
        ),
      );
    }
    return retried;
  }

  void markMissingAssets(Iterable<String> assetIds) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final id in assetIds) {
      final record = _photos[id];
      if (record == null) continue;
      _photos[id] = PhotoRecord(
        photo: record.photo,
        metadata: record.metadata,
        semantic: record.semantic,
        indexState: IndexState(
          photoId: record.indexState.photoId,
          indexed: record.indexState.indexed,
          aiProcessed: record.indexState.aiProcessed,
          error: record.indexState.error,
          lastIndexedAt: record.indexState.lastIndexedAt,
          duplicateOf: record.indexState.duplicateOf,
          sourceUpdatedAt: record.indexState.sourceUpdatedAt,
          missingAt: now,
        ),
      );
    }
  }

  PhotoRecord _requirePhoto(String photoId) {
    final record = _photos[photoId];
    if (record == null) throw StateError('Unknown photo $photoId');
    return record;
  }

  Memory _requireMemory(String memoryId) {
    final memory = _memories[memoryId];
    if (memory == null) throw StateError('Unknown memory $memoryId');
    return memory;
  }

  MemoryCandidate _requireMemoryCandidate(String candidateId) {
    final candidate = _memoryCandidates[candidateId];
    if (candidate == null) {
      throw StateError('Unknown memory candidate $candidateId');
    }
    return candidate;
  }

  Memory _copyMemory(
    Memory memory, {
    String? name,
    Object? description = _unchanged,
    Object? coverPhotoId = _unchanged,
    Object? coverThumbnailPath = _unchanged,
    int? photoCount,
    int? updatedAt,
  }) {
    return Memory(
      id: memory.id,
      name: name ?? memory.name,
      description: description == _unchanged
          ? memory.description
          : description as String?,
      coverPhotoId: coverPhotoId == _unchanged
          ? memory.coverPhotoId
          : coverPhotoId as String?,
      coverThumbnailPath: coverThumbnailPath == _unchanged
          ? memory.coverThumbnailPath
          : coverThumbnailPath as String?,
      photoCount: photoCount ?? memory.photoCount,
      generatedName: memory.generatedName,
      generatedDescription: memory.generatedDescription,
      generatedLabels: memory.generatedLabels,
      aiStatus: memory.aiStatus,
      aiProvider: memory.aiProvider,
      aiModel: memory.aiModel,
      aiProcessedAt: memory.aiProcessedAt,
      aiError: memory.aiError,
      source: memory.source,
      createdAt: memory.createdAt,
      updatedAt: updatedAt ?? memory.updatedAt,
    );
  }

  PhotoRecord _replaceRecord(
    PhotoRecord record, {
    Photo? photo,
    Semantic? semantic,
  }) {
    return PhotoRecord(
      photo: photo ?? record.photo,
      metadata: record.metadata,
      semantic: semantic ?? record.semantic,
      indexState: record.indexState,
    );
  }

  PhotoRecord _mergeIndexedRecord(PhotoRecord previous, PhotoRecord incoming) {
    return PhotoRecord(
      photo: Photo(
        id: incoming.photo.id,
        path: incoming.photo.path,
        hash: incoming.photo.hash,
        size: incoming.photo.size,
        mime: incoming.photo.mime,
        thumbnailPath:
            incoming.photo.thumbnailPath ?? previous.photo.thumbnailPath,
        favorite: previous.photo.favorite,
        createdAt: previous.photo.createdAt,
        updatedAt: incoming.photo.updatedAt,
      ),
      metadata: incoming.metadata,
      semantic: Semantic(
        photoId: incoming.semantic.photoId,
        labels: previous.semantic.labels,
        caption: previous.semantic.caption,
        generatedLabels: incoming.semantic.generatedLabels,
        generatedCaption: incoming.semantic.generatedCaption,
        summary: incoming.semantic.summary,
        embeddingRef: incoming.semantic.embeddingRef,
        aiStatus: incoming.semantic.aiStatus,
        aiProvider: incoming.semantic.aiProvider,
        aiModel: incoming.semantic.aiModel,
        aiProcessedAt: incoming.semantic.aiProcessedAt,
        aiError: incoming.semantic.aiError,
      ),
      indexState: incoming.indexState,
    );
  }

  void _recordEdit({
    required String photoId,
    required String fieldName,
    required String? previousValue,
    required String? nextValue,
  }) {
    if (previousValue == nextValue) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _editHistory.add(
      EditHistory(
        id: '$photoId-$fieldName-$now-${_editHistory.length}',
        photoId: photoId,
        fieldName: fieldName,
        previousValue: previousValue,
        nextValue: nextValue,
        createdAt: now,
        rolledBackAt: null,
      ),
    );
  }

  List<String> _splitTags(String? value) {
    if (value == null || value.trim().isEmpty) return <String>[];
    return value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  int? _parseInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value);
  }

  MemoryCandidate _copyMemoryCandidate(
    MemoryCandidate candidate, {
    MemoryCandidateStatus? status,
    String? acceptedMemoryId,
    int? updatedAt,
  }) {
    return MemoryCandidate(
      id: candidate.id,
      signature: candidate.signature,
      title: candidate.title,
      description: candidate.description,
      reason: candidate.reason,
      confidence: candidate.confidence,
      source: candidate.source,
      status: status ?? candidate.status,
      photoIds: candidate.photoIds,
      coverPhotoId: candidate.coverPhotoId,
      coverThumbnailPath: candidate.coverThumbnailPath,
      generatedLabels: candidate.generatedLabels,
      acceptedMemoryId: acceptedMemoryId ?? candidate.acceptedMemoryId,
      createdAt: candidate.createdAt,
      updatedAt: updatedAt ?? candidate.updatedAt,
    );
  }
}
