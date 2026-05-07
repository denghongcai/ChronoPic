typedef JsonMap = Map<String, Object?>;

enum AiPipelineStatus {
  disabled,
  pending,
  processing,
  completed,
  failed;

  static AiPipelineStatus parse(String value) {
    return AiPipelineStatus.values.byName(value);
  }
}

enum MemorySource {
  manual,
  ai;

  static MemorySource parse(String value) => MemorySource.values.byName(value);
}

enum MemoryCandidateSource {
  place,
  time,
  semantic,
  person,
  mixed;

  static MemoryCandidateSource parse(String value) => MemoryCandidateSource.values.byName(value);
}

enum MemoryCandidateStatus {
  pending,
  accepted,
  rejected;

  static MemoryCandidateStatus parse(String value) => MemoryCandidateStatus.values.byName(value);
}

enum LocaleSetting {
  enUS('en-US'),
  zhCN('zh-CN');

  const LocaleSetting(this.wireName);

  final String wireName;

  static LocaleSetting parse(String value) {
    return LocaleSetting.values.firstWhere((locale) => locale.wireName == value);
  }
}

enum AiOutputLocale {
  enUS('en-US'),
  zhCN('zh-CN'),
  followUi('follow-ui');

  const AiOutputLocale(this.wireName);

  final String wireName;

  static AiOutputLocale parse(String value) {
    return AiOutputLocale.values.firstWhere((locale) => locale.wireName == value);
  }
}

enum BrowseMode {
  waterfall,
  map,
  timeline;
}

enum PhotoSortBy {
  datetime,
  updatedAt,
  path;
}

enum SortDirection {
  asc,
  desc;
}

final class AiSettings {
  const AiSettings({
    required this.apiKey,
    required this.baseURL,
    required this.model,
    required this.providerName,
  });

  factory AiSettings.fromJson(JsonMap json) {
    return AiSettings(
      apiKey: json['apiKey'] as String? ?? '',
      baseURL: json['baseURL'] as String? ?? '',
      model: json['model'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
    );
  }

  final String apiKey;
  final String baseURL;
  final String model;
  final String providerName;

  JsonMap toJson() => {
        'apiKey': apiKey,
        'baseURL': baseURL,
        'model': model,
        'providerName': providerName,
      };
}

final class AiReadiness {
  const AiReadiness({
    required this.configured,
    required this.presentFields,
    required this.missingFields,
  });

  final bool configured;
  final List<String> presentFields;
  final List<String> missingFields;
}

AiReadiness getAiReadiness(AiSettings settings) {
  final fields = <String, String>{
    'apiKey': settings.apiKey,
    'baseURL': settings.baseURL,
    'model': settings.model,
    'providerName': settings.providerName,
  };
  final present = <String>[];
  final missing = <String>[];
  for (final entry in fields.entries) {
    if (entry.value.trim().isEmpty) {
      missing.add(entry.key);
    } else {
      present.add(entry.key);
    }
  }
  return AiReadiness(configured: missing.isEmpty, presentFields: present, missingFields: missing);
}

final class MapSettings {
  const MapSettings({required this.apiKey, required this.securityJsCode});

  factory MapSettings.fromJson(JsonMap json) {
    return MapSettings(
      apiKey: json['apiKey'] as String? ?? '',
      securityJsCode: json['securityJsCode'] as String? ?? '',
    );
  }

  final String apiKey;
  final String securityJsCode;

  JsonMap toJson() => {
        'apiKey': apiKey,
        'securityJsCode': securityJsCode,
      };
}

final class LocaleSettings {
  const LocaleSettings({required this.locale, required this.aiOutputLocale});

  factory LocaleSettings.fromJson(JsonMap json) {
    return LocaleSettings(
      locale: LocaleSetting.parse(json['locale'] as String? ?? 'en-US'),
      aiOutputLocale: AiOutputLocale.parse(json['aiOutputLocale'] as String? ?? 'follow-ui'),
    );
  }

  final LocaleSetting locale;
  final AiOutputLocale aiOutputLocale;

  JsonMap toJson() => {
        'locale': locale.wireName,
        'aiOutputLocale': aiOutputLocale.wireName,
      };
}

final class BackupSettings {
  const BackupSettings({required this.ai, required this.map, required this.locale});

  factory BackupSettings.fromJson(JsonMap json) {
    return BackupSettings(
      ai: AiSettings.fromJson((json['ai'] as Map).cast<String, Object?>()),
      map: MapSettings.fromJson((json['map'] as Map).cast<String, Object?>()),
      locale: LocaleSettings.fromJson((json['locale'] as Map).cast<String, Object?>()),
    );
  }

  final AiSettings ai;
  final MapSettings map;
  final LocaleSettings locale;

  JsonMap toJson() => {
        'ai': ai.toJson(),
        'map': map.toJson(),
        'locale': locale.toJson(),
      };
}

final class Photo {
  const Photo({
    required this.id,
    required this.path,
    required this.hash,
    required this.size,
    required this.mime,
    required this.thumbnailPath,
    required this.favorite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Photo.fromJson(JsonMap json) {
    return Photo(
      id: json['id'] as String,
      path: json['path'] as String,
      hash: json['hash'] as String?,
      size: json['size'] as int,
      mime: json['mime'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      favorite: json['favorite'] as bool? ?? false,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  final String id;
  final String path;
  final String? hash;
  final int size;
  final String mime;
  final String? thumbnailPath;
  final bool favorite;
  final int createdAt;
  final int updatedAt;

  JsonMap toJson() => {
        'id': id,
        'path': path,
        'hash': hash,
        'size': size,
        'mime': mime,
        'thumbnailPath': thumbnailPath,
        'favorite': favorite,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

final class Metadata {
  const Metadata({
    required this.photoId,
    required this.datetime,
    required this.lat,
    required this.lng,
    required this.camera,
    required this.confidence,
    required this.originalDatetimeText,
  });

  factory Metadata.fromJson(JsonMap json) {
    return Metadata(
      photoId: json['photoId'] as String,
      datetime: json['datetime'] as int?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      camera: json['camera'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      originalDatetimeText: json['originalDatetimeText'] as String?,
    );
  }

  final String photoId;
  final int? datetime;
  final double? lat;
  final double? lng;
  final String? camera;
  final double confidence;
  final String? originalDatetimeText;

  JsonMap toJson() => {
        'photoId': photoId,
        'datetime': datetime,
        'lat': lat,
        'lng': lng,
        'camera': camera,
        'confidence': confidence,
        'originalDatetimeText': originalDatetimeText,
      };
}

final class Semantic {
  const Semantic({
    required this.photoId,
    required this.labels,
    required this.caption,
    required this.generatedLabels,
    required this.generatedCaption,
    required this.summary,
    required this.embeddingRef,
    required this.aiStatus,
    required this.aiProvider,
    required this.aiModel,
    required this.aiProcessedAt,
    required this.aiError,
  });

  factory Semantic.fromJson(JsonMap json) {
    return Semantic(
      photoId: json['photoId'] as String,
      labels: _stringList(json['labels']),
      caption: json['caption'] as String?,
      generatedLabels: _stringList(json['generatedLabels']),
      generatedCaption: json['generatedCaption'] as String?,
      summary: json['summary'] as String?,
      embeddingRef: json['embeddingRef'] as String?,
      aiStatus: AiPipelineStatus.parse(json['aiStatus'] as String),
      aiProvider: json['aiProvider'] as String?,
      aiModel: json['aiModel'] as String?,
      aiProcessedAt: json['aiProcessedAt'] as int?,
      aiError: json['aiError'] as String?,
    );
  }

  final String photoId;
  final List<String> labels;
  final String? caption;
  final List<String> generatedLabels;
  final String? generatedCaption;
  final String? summary;
  final String? embeddingRef;
  final AiPipelineStatus aiStatus;
  final String? aiProvider;
  final String? aiModel;
  final int? aiProcessedAt;
  final String? aiError;

  JsonMap toJson() => {
        'photoId': photoId,
        'labels': labels,
        'caption': caption,
        'generatedLabels': generatedLabels,
        'generatedCaption': generatedCaption,
        'summary': summary,
        'embeddingRef': embeddingRef,
        'aiStatus': aiStatus.name,
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'aiProcessedAt': aiProcessedAt,
        'aiError': aiError,
      };
}

final class IndexState {
  const IndexState({
    required this.photoId,
    required this.indexed,
    required this.aiProcessed,
    required this.error,
    required this.lastIndexedAt,
    required this.duplicateOf,
    required this.sourceUpdatedAt,
    required this.missingAt,
  });

  factory IndexState.fromJson(JsonMap json) {
    return IndexState(
      photoId: json['photoId'] as String,
      indexed: json['indexed'] as bool,
      aiProcessed: json['aiProcessed'] as bool,
      error: json['error'] as String?,
      lastIndexedAt: json['lastIndexedAt'] as int?,
      duplicateOf: json['duplicateOf'] as String?,
      sourceUpdatedAt: json['sourceUpdatedAt'] as int?,
      missingAt: json['missingAt'] as int?,
    );
  }

  final String photoId;
  final bool indexed;
  final bool aiProcessed;
  final String? error;
  final int? lastIndexedAt;
  final String? duplicateOf;
  final int? sourceUpdatedAt;
  final int? missingAt;

  JsonMap toJson() => {
        'photoId': photoId,
        'indexed': indexed,
        'aiProcessed': aiProcessed,
        'error': error,
        'lastIndexedAt': lastIndexedAt,
        'duplicateOf': duplicateOf,
        'sourceUpdatedAt': sourceUpdatedAt,
        'missingAt': missingAt,
      };
}

final class PhotoRecord {
  const PhotoRecord({
    required this.photo,
    required this.metadata,
    required this.semantic,
    required this.indexState,
  });

  factory PhotoRecord.fromJson(JsonMap json) {
    return PhotoRecord(
      photo: Photo.fromJson((json['photo'] as Map).cast<String, Object?>()),
      metadata: Metadata.fromJson((json['metadata'] as Map).cast<String, Object?>()),
      semantic: Semantic.fromJson((json['semantic'] as Map).cast<String, Object?>()),
      indexState: IndexState.fromJson((json['indexState'] as Map).cast<String, Object?>()),
    );
  }

  final Photo photo;
  final Metadata metadata;
  final Semantic semantic;
  final IndexState indexState;

  JsonMap toJson() => {
        'photo': photo.toJson(),
        'metadata': metadata.toJson(),
        'semantic': semantic.toJson(),
        'indexState': indexState.toJson(),
      };
}

final class LibrarySource {
  const LibrarySource({
    required this.id,
    required this.path,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.lastScanAt,
  });

  factory LibrarySource.fromJson(JsonMap json) {
    return LibrarySource(
      id: json['id'] as String,
      path: json['path'] as String,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      lastScanAt: json['lastScanAt'] as int?,
    );
  }

  final String id;
  final String path;
  final bool isActive;
  final int createdAt;
  final int updatedAt;
  final int? lastScanAt;

  JsonMap toJson() => {
        'id': id,
        'path': path,
        'isActive': isActive,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'lastScanAt': lastScanAt,
      };
}

final class EditHistory {
  const EditHistory({
    required this.id,
    required this.photoId,
    required this.fieldName,
    required this.previousValue,
    required this.nextValue,
    required this.createdAt,
    required this.rolledBackAt,
  });

  factory EditHistory.fromJson(JsonMap json) {
    return EditHistory(
      id: json['id'] as String,
      photoId: json['photoId'] as String,
      fieldName: json['fieldName'] as String,
      previousValue: json['previousValue'] as String?,
      nextValue: json['nextValue'] as String?,
      createdAt: json['createdAt'] as int,
      rolledBackAt: json['rolledBackAt'] as int?,
    );
  }

  final String id;
  final String photoId;
  final String fieldName;
  final String? previousValue;
  final String? nextValue;
  final int createdAt;
  final int? rolledBackAt;

  JsonMap toJson() => {
        'id': id,
        'photoId': photoId,
        'fieldName': fieldName,
        'previousValue': previousValue,
        'nextValue': nextValue,
        'createdAt': createdAt,
        'rolledBackAt': rolledBackAt,
      };
}

final class Memory {
  const Memory({
    required this.id,
    required this.name,
    required this.description,
    required this.coverPhotoId,
    required this.coverThumbnailPath,
    required this.photoCount,
    required this.generatedName,
    required this.generatedDescription,
    required this.generatedLabels,
    required this.aiStatus,
    required this.aiProvider,
    required this.aiModel,
    required this.aiProcessedAt,
    required this.aiError,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memory.fromJson(JsonMap json) {
    return Memory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverPhotoId: json['coverPhotoId'] as String?,
      coverThumbnailPath: json['coverThumbnailPath'] as String?,
      photoCount: json['photoCount'] as int,
      generatedName: json['generatedName'] as String?,
      generatedDescription: json['generatedDescription'] as String?,
      generatedLabels: _stringList(json['generatedLabels']),
      aiStatus: AiPipelineStatus.parse(json['aiStatus'] as String),
      aiProvider: json['aiProvider'] as String?,
      aiModel: json['aiModel'] as String?,
      aiProcessedAt: json['aiProcessedAt'] as int?,
      aiError: json['aiError'] as String?,
      source: MemorySource.parse(json['source'] as String),
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? coverPhotoId;
  final String? coverThumbnailPath;
  final int photoCount;
  final String? generatedName;
  final String? generatedDescription;
  final List<String> generatedLabels;
  final AiPipelineStatus aiStatus;
  final String? aiProvider;
  final String? aiModel;
  final int? aiProcessedAt;
  final String? aiError;
  final MemorySource source;
  final int createdAt;
  final int updatedAt;

  JsonMap toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'coverPhotoId': coverPhotoId,
        'coverThumbnailPath': coverThumbnailPath,
        'photoCount': photoCount,
        'generatedName': generatedName,
        'generatedDescription': generatedDescription,
        'generatedLabels': generatedLabels,
        'aiStatus': aiStatus.name,
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'aiProcessedAt': aiProcessedAt,
        'aiError': aiError,
        'source': source.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

final class MemoryPhoto {
  const MemoryPhoto({required this.memoryId, required this.photoId, required this.addedAt});

  factory MemoryPhoto.fromJson(JsonMap json) {
    return MemoryPhoto(
      memoryId: json['memoryId'] as String,
      photoId: json['photoId'] as String,
      addedAt: json['addedAt'] as int,
    );
  }

  final String memoryId;
  final String photoId;
  final int addedAt;

  JsonMap toJson() => {
        'memoryId': memoryId,
        'photoId': photoId,
        'addedAt': addedAt,
      };
}

final class MemoryCandidate {
  const MemoryCandidate({
    required this.id,
    required this.signature,
    required this.title,
    required this.description,
    required this.reason,
    required this.confidence,
    required this.source,
    required this.status,
    required this.photoIds,
    required this.coverPhotoId,
    required this.coverThumbnailPath,
    required this.generatedLabels,
    required this.acceptedMemoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemoryCandidate.fromJson(JsonMap json) {
    return MemoryCandidate(
      id: json['id'] as String,
      signature: json['signature'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      reason: json['reason'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      source: MemoryCandidateSource.parse(json['source'] as String),
      status: MemoryCandidateStatus.parse(json['status'] as String),
      photoIds: _stringList(json['photoIds']),
      coverPhotoId: json['coverPhotoId'] as String?,
      coverThumbnailPath: json['coverThumbnailPath'] as String?,
      generatedLabels: _stringList(json['generatedLabels']),
      acceptedMemoryId: json['acceptedMemoryId'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  final String id;
  final String signature;
  final String title;
  final String? description;
  final String reason;
  final double confidence;
  final MemoryCandidateSource source;
  final MemoryCandidateStatus status;
  final List<String> photoIds;
  final String? coverPhotoId;
  final String? coverThumbnailPath;
  final List<String> generatedLabels;
  final String? acceptedMemoryId;
  final int createdAt;
  final int updatedAt;

  JsonMap toJson() => {
        'id': id,
        'signature': signature,
        'title': title,
        'description': description,
        'reason': reason,
        'confidence': confidence,
        'source': source.name,
        'status': status.name,
        'photoIds': photoIds,
        'coverPhotoId': coverPhotoId,
        'coverThumbnailPath': coverThumbnailPath,
        'generatedLabels': generatedLabels,
        'acceptedMemoryId': acceptedMemoryId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

final class PhotoFilter {
  const PhotoFilter({
    this.query,
    this.mimePrefix,
    this.tag,
    this.aiStatus,
    this.favorite,
    this.memoryId,
    this.indexed,
    this.hasError,
    this.hasGps,
    this.fromDatetime,
    this.toDatetime,
    this.sortBy = PhotoSortBy.datetime,
    this.sortDirection = SortDirection.desc,
    this.limit = 60,
    this.offset = 0,
  });

  final String? query;
  final String? mimePrefix;
  final String? tag;
  final AiPipelineStatus? aiStatus;
  final bool? favorite;
  final String? memoryId;
  final bool? indexed;
  final bool? hasError;
  final bool? hasGps;
  final int? fromDatetime;
  final int? toDatetime;
  final PhotoSortBy sortBy;
  final SortDirection sortDirection;
  final int limit;
  final int offset;
}

List<String> _stringList(Object? value) {
  return ((value as List?) ?? const <Object?>[]).cast<String>();
}
