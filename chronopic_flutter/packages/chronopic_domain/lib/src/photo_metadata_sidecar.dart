import 'models.dart';

final class PhotoMetadataSidecar {
  const PhotoMetadataSidecar({
    required this.app,
    required this.format,
    required this.schemaVersion,
    required this.sha256,
    required this.pathFingerprint,
    required this.size,
    required this.datetime,
    required this.lat,
    required this.lng,
    required this.camera,
    required this.confidence,
    required this.originalDatetimeText,
    required this.caption,
    required this.tags,
    required this.favorite,
  });

  factory PhotoMetadataSidecar.fromJson(JsonMap json) {
    _requireKeys(json, const [
      'app',
      'format',
      'schemaVersion',
      'identity',
      'metadata',
      'authored',
    ]);
    final identity = _requiredObject(json, 'identity');
    final metadata = _requiredObject(json, 'metadata');
    final authored = _requiredObject(json, 'authored');
    _requireKeys(identity, const ['sha256', 'pathFingerprint', 'size']);
    _requireKeys(metadata, const [
      'datetime',
      'lat',
      'lng',
      'camera',
      'confidence',
      'originalDatetimeText',
    ]);
    _requireKeys(authored, const ['caption', 'tags', 'favorite']);
    return PhotoMetadataSidecar(
      app: json['app'] as String,
      format: json['format'] as String,
      schemaVersion: _sidecarInt(json['schemaVersion']),
      sha256: identity['sha256'] as String,
      pathFingerprint: identity['pathFingerprint'] as String,
      size: _sidecarInt(identity['size']),
      datetime: _sidecarIntOrNull(metadata['datetime']),
      lat: (metadata['lat'] as num?)?.toDouble(),
      lng: (metadata['lng'] as num?)?.toDouble(),
      camera: metadata['camera'] as String?,
      confidence: (metadata['confidence'] as num).toDouble(),
      originalDatetimeText: metadata['originalDatetimeText'] as String?,
      caption: authored['caption'] as String?,
      tags: (authored['tags'] as List).cast<String>(),
      favorite: authored['favorite'] as bool,
    );
  }

  static const String expectedApp = 'ChronoPic';
  static const String expectedFormat = 'chronopic-photo-metadata';
  static const int currentSchemaVersion = 1;

  final String app;
  final String format;
  final int schemaVersion;
  final String sha256;
  final String pathFingerprint;
  final int size;
  final int? datetime;
  final double? lat;
  final double? lng;
  final String? camera;
  final double confidence;
  final String? originalDatetimeText;
  final String? caption;
  final List<String> tags;
  final bool favorite;

  JsonMap toJson() => {
    'app': app,
    'format': format,
    'schemaVersion': schemaVersion,
    'identity': {
      'sha256': sha256,
      'pathFingerprint': pathFingerprint,
      'size': size,
    },
    'metadata': {
      'datetime': datetime,
      'lat': lat,
      'lng': lng,
      'camera': camera,
      'confidence': confidence,
      'originalDatetimeText': originalDatetimeText,
    },
    'authored': {'caption': caption, 'tags': tags, 'favorite': favorite},
  };
}

final class SidecarValidationResult {
  const SidecarValidationResult({required this.valid, required this.errors});

  final bool valid;
  final List<String> errors;
}

SidecarValidationResult validatePhotoMetadataSidecar(
  PhotoMetadataSidecar sidecar,
) {
  final errors = <String>[];
  if (sidecar.app != PhotoMetadataSidecar.expectedApp) {
    errors.add('Unexpected app ${sidecar.app}');
  }
  if (sidecar.format != PhotoMetadataSidecar.expectedFormat) {
    errors.add('Unexpected format ${sidecar.format}');
  }
  if (sidecar.schemaVersion != PhotoMetadataSidecar.currentSchemaVersion) {
    errors.add('Unsupported schemaVersion ${sidecar.schemaVersion}');
  }
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sidecar.sha256)) {
    errors.add('identity.sha256 must be a lowercase SHA-256 digest');
  }
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sidecar.pathFingerprint)) {
    errors.add('identity.pathFingerprint must be a lowercase SHA-256 digest');
  }
  if (sidecar.size < 0) errors.add('identity.size must not be negative');
  if ((sidecar.lat == null) != (sidecar.lng == null)) {
    errors.add('metadata.lat and metadata.lng must both be present or null');
  }
  if (sidecar.lat != null &&
      (!sidecar.lat!.isFinite || sidecar.lat! < -90 || sidecar.lat! > 90)) {
    errors.add('metadata.lat must be between -90 and 90');
  }
  if (sidecar.lng != null &&
      (!sidecar.lng!.isFinite || sidecar.lng! < -180 || sidecar.lng! > 180)) {
    errors.add('metadata.lng must be between -180 and 180');
  }
  if (!sidecar.confidence.isFinite ||
      sidecar.confidence < 0 ||
      sidecar.confidence > 1) {
    errors.add('metadata.confidence must be between 0 and 1');
  }
  if (sidecar.tags.any((tag) => tag.trim().isEmpty)) {
    errors.add('authored.tags must not contain empty values');
  }
  return SidecarValidationResult(valid: errors.isEmpty, errors: errors);
}

int _sidecarInt(Object? value) {
  if (value is int) return value;
  throw FormatException('Expected integer JSON value, got $value');
}

int? _sidecarIntOrNull(Object? value) {
  if (value == null) return null;
  return _sidecarInt(value);
}

JsonMap _requiredObject(JsonMap parent, String key) {
  final value = parent[key];
  if (value is! Map) throw FormatException('$key must be a JSON object');
  return value.cast<String, Object?>();
}

void _requireKeys(JsonMap object, List<String> keys) {
  for (final key in keys) {
    if (!object.containsKey(key)) {
      throw FormatException('Missing required sidecar field $key');
    }
  }
}
