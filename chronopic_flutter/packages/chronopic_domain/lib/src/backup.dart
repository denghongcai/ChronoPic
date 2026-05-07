import 'models.dart';

final class ChronoPicBackup {
  const ChronoPicBackup({
    required this.app,
    required this.schemaVersion,
    required this.exportedAt,
    required this.settings,
    required this.librarySources,
    required this.photos,
    required this.memories,
    required this.memoryPhotos,
    required this.editHistory,
    required this.memoryCandidates,
  });

  factory ChronoPicBackup.fromJson(JsonMap json) {
    return ChronoPicBackup(
      app: json['app'] as String,
      schemaVersion: json['schemaVersion'] as int,
      exportedAt: json['exportedAt'] as int,
      settings: BackupSettings.fromJson((json['settings'] as Map).cast<String, Object?>()),
      librarySources: _list(json['librarySources'], LibrarySource.fromJson),
      photos: _list(json['photos'], PhotoRecord.fromJson),
      memories: _list(json['memories'], Memory.fromJson),
      memoryPhotos: _list(json['memoryPhotos'], MemoryPhoto.fromJson),
      editHistory: _list(json['editHistory'], EditHistory.fromJson),
      memoryCandidates: _list(json['memoryCandidates'], MemoryCandidate.fromJson),
    );
  }

  final String app;
  final int schemaVersion;
  final int exportedAt;
  final BackupSettings settings;
  final List<LibrarySource> librarySources;
  final List<PhotoRecord> photos;
  final List<Memory> memories;
  final List<MemoryPhoto> memoryPhotos;
  final List<EditHistory> editHistory;
  final List<MemoryCandidate> memoryCandidates;

  JsonMap toJson() => {
        'app': app,
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt,
        'settings': settings.toJson(),
        'librarySources': librarySources.map((source) => source.toJson()).toList(),
        'photos': photos.map((record) => record.toJson()).toList(),
        'memories': memories.map((memory) => memory.toJson()).toList(),
        'memoryPhotos': memoryPhotos.map((membership) => membership.toJson()).toList(),
        'editHistory': editHistory.map((edit) => edit.toJson()).toList(),
        'memoryCandidates': memoryCandidates.map((candidate) => candidate.toJson()).toList(),
      };
}

final class BackupValidationResult {
  const BackupValidationResult({required this.valid, required this.errors});

  final bool valid;
  final List<String> errors;
}

BackupValidationResult validateChronoPicBackup(ChronoPicBackup backup) {
  final errors = <String>[];
  if (backup.app != 'ChronoPic') errors.add('Unexpected app ${backup.app}');
  if (backup.schemaVersion != 1) errors.add('Unsupported schemaVersion ${backup.schemaVersion}');

  final photoIds = backup.photos.map((record) => record.photo.id).toSet();
  for (final record in backup.photos) {
    if (record.metadata.photoId != record.photo.id) {
      errors.add('Metadata photoId mismatch for ${record.photo.id}');
    }
    if (record.semantic.photoId != record.photo.id) {
      errors.add('Semantic photoId mismatch for ${record.photo.id}');
    }
    if (record.indexState.photoId != record.photo.id) {
      errors.add('IndexState photoId mismatch for ${record.photo.id}');
    }
  }
  for (final membership in backup.memoryPhotos) {
    if (!photoIds.contains(membership.photoId)) {
      errors.add('Missing memory photo ${membership.photoId}');
    }
  }
  for (final candidate in backup.memoryCandidates) {
    for (final photoId in candidate.photoIds) {
      if (!photoIds.contains(photoId)) errors.add('Missing candidate photo $photoId');
    }
  }
  return BackupValidationResult(valid: errors.isEmpty, errors: errors);
}

final class BackupRestorePreview {
  const BackupRestorePreview({
    required this.schemaVersion,
    required this.sourceCount,
    required this.photoCount,
    required this.memoryCount,
    required this.memoryPhotoCount,
    required this.editHistoryCount,
    required this.memoryCandidateCount,
    required this.settingsIncluded,
  });

  factory BackupRestorePreview.fromBackup(ChronoPicBackup backup) {
    return BackupRestorePreview(
      schemaVersion: backup.schemaVersion,
      sourceCount: backup.librarySources.length,
      photoCount: backup.photos.length,
      memoryCount: backup.memories.length,
      memoryPhotoCount: backup.memoryPhotos.length,
      editHistoryCount: backup.editHistory.length,
      memoryCandidateCount: backup.memoryCandidates.length,
      settingsIncluded: true,
    );
  }

  final int schemaVersion;
  final int sourceCount;
  final int photoCount;
  final int memoryCount;
  final int memoryPhotoCount;
  final int editHistoryCount;
  final int memoryCandidateCount;
  final bool settingsIncluded;
}

List<T> _list<T>(Object? value, T Function(JsonMap json) parse) {
  return ((value as List?) ?? const <Object?>[])
      .map((entry) => parse((entry as Map).cast<String, Object?>()))
      .toList();
}
