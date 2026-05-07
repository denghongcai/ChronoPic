import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'media_source.dart';

final class DesktopDirectoryMediaSource implements MediaSourceAdapter {
  const DesktopDirectoryMediaSource(this.rootDirectory);

  final Directory rootDirectory;

  @override
  MediaSourcePermissionState get permissionState => MediaSourcePermissionState.granted;

  @override
  Future<List<MediaAsset>> listAssets() async {
    if (!rootDirectory.existsSync()) {
      throw MediaSourceException('Directory does not exist: ${rootDirectory.path}');
    }
    final assets = <MediaAsset>[];
    await for (final entity in rootDirectory.list(recursive: true, followLinks: false)) {
      if (entity is! File || !isSupportedMediaPath(entity.path)) continue;
      assets.add(_assetForFile(entity));
    }
    assets.sort((a, b) => a.path.compareTo(b.path));
    return assets;
  }

  @override
  Future<MediaReadResult> readAsset(String assetId) async {
    final file = File(assetId);
    if (!file.existsSync()) throw MediaSourceException('Missing desktop asset $assetId');
    final asset = _assetForFile(file);
    return MediaReadResult(asset: asset, bytes: Uint8List.fromList(await file.readAsBytes()));
  }

  @override
  Future<MediaAsset?> statAsset(String assetId) async {
    final file = File(assetId);
    if (!file.existsSync() || !isSupportedMediaPath(file.path)) return null;
    return _assetForFile(file);
  }

  @override
  Future<List<String>> listMissingAssetIds(Iterable<String> knownAssetIds) async {
    return knownAssetIds.where((id) => !File(id).existsSync()).toList();
  }

  MediaAsset _assetForFile(File file) {
    final stat = file.statSync();
    final absolutePath = p.normalize(file.absolute.path);
    return MediaAsset(
      id: absolutePath,
      path: absolutePath,
      metadata: MediaAssetMetadata(
        size: stat.size,
        updatedAt: stat.modified.millisecondsSinceEpoch,
        mime: mimeFromPath(file.path),
        datetime: stat.modified.millisecondsSinceEpoch,
      ),
    );
  }
}

