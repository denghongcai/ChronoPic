import 'dart:typed_data';

import 'media_source.dart';

final class FixtureMediaSource implements MediaSourceAdapter {
  FixtureMediaSource({
    required List<MediaAsset> assets,
    required Map<String, Uint8List> bytesById,
    this.permissionState = MediaSourcePermissionState.granted,
    Set<String> missingAssetIds = const <String>{},
  }) : _assets = List<MediaAsset>.of(assets),
       _bytesById = Map<String, Uint8List>.of(bytesById),
       _missingAssetIds = Set<String>.of(missingAssetIds);

  final List<MediaAsset> _assets;
  final Map<String, Uint8List> _bytesById;
  final Set<String> _missingAssetIds;

  @override
  final MediaSourcePermissionState permissionState;

  @override
  Future<List<MediaAsset>> listAssets() async {
    _throwIfDenied();
    return _assets
        .where((asset) => !_missingAssetIds.contains(asset.id))
        .toList();
  }

  @override
  Future<MediaReadResult> readAsset(String assetId) async {
    _throwIfDenied();
    final asset = await statAsset(assetId);
    final bytes = _bytesById[assetId];
    if (asset == null || bytes == null || _missingAssetIds.contains(assetId)) {
      throw MediaSourceException('Missing fixture asset $assetId');
    }
    return MediaReadResult(asset: asset, bytes: bytes);
  }

  @override
  Future<MediaAsset?> statAsset(String assetId) async {
    _throwIfDenied();
    if (_missingAssetIds.contains(assetId)) return null;
    return _assets.where((asset) => asset.id == assetId).firstOrNull;
  }

  @override
  Future<List<String>> listMissingAssetIds(
    Iterable<String> knownAssetIds,
  ) async {
    _throwIfDenied();
    final available = _assets
        .where((asset) => !_missingAssetIds.contains(asset.id))
        .map((asset) => asset.id)
        .toSet();
    return knownAssetIds.where((id) => !available.contains(id)).toList();
  }

  void _throwIfDenied() {
    if (permissionState == MediaSourcePermissionState.denied) {
      throw const MediaSourceException(
        'Media permission denied',
        permissionState: MediaSourcePermissionState.denied,
      );
    }
  }
}
