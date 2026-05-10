import 'dart:typed_data';

enum MediaSourcePermissionState { granted, denied, limited }

final class MediaAssetMetadata {
  const MediaAssetMetadata({
    required this.size,
    required this.updatedAt,
    this.mime,
    this.datetime,
    this.lat,
    this.lng,
    this.camera,
  });

  final int size;
  final int updatedAt;
  final String? mime;
  final int? datetime;
  final double? lat;
  final double? lng;
  final String? camera;
}

final class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.path,
    required this.metadata,
    this.missing = false,
  });

  final String id;
  final String path;
  final MediaAssetMetadata metadata;
  final bool missing;
}

final class MediaReadResult {
  const MediaReadResult({required this.asset, required this.bytes});

  final MediaAsset asset;
  final Uint8List bytes;
}

final class MediaSourceException implements Exception {
  const MediaSourceException(
    this.message, {
    this.permissionState = MediaSourcePermissionState.granted,
  });

  final String message;
  final MediaSourcePermissionState permissionState;

  @override
  String toString() => 'MediaSourceException($message)';
}

abstract interface class MediaSourceAdapter {
  MediaSourcePermissionState get permissionState;

  Future<List<MediaAsset>> listAssets();

  Future<MediaReadResult> readAsset(String assetId);

  Future<Uint8List?> readThumbnailBytes(String assetId, {int size = 512});

  Future<MediaAsset?> statAsset(String assetId);

  Future<List<String>> listMissingAssetIds(Iterable<String> knownAssetIds);
}

bool isSupportedMediaPath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.heic') ||
      lower.endsWith('.mp4') ||
      lower.endsWith('.mov');
}

String mimeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  return 'application/octet-stream';
}
