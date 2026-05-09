import 'media_source.dart';
import 'photo_library_gateway.dart';

final class MobilePhotoLibraryMediaSource implements MediaSourceAdapter {
  MobilePhotoLibraryMediaSource(this.gateway);

  final PhotoLibraryGateway gateway;
  MediaSourcePermissionState _permissionState =
      MediaSourcePermissionState.denied;

  @override
  MediaSourcePermissionState get permissionState => _permissionState;

  @override
  Future<List<MediaAsset>> listAssets() async {
    final permission = await gateway.requestPermission();
    _permissionState = permission.state;
    if (permission.state == MediaSourcePermissionState.denied) {
      throw const MediaSourceException(
        'Photo library permission denied',
        permissionState: MediaSourcePermissionState.denied,
      );
    }
    final assets = await gateway.listAssets();
    return assets.map(_toMediaAsset).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  @override
  Future<MediaReadResult> readAsset(String assetId) async {
    final asset = await gateway.statAsset(assetId);
    final bytes = await gateway.readAssetBytes(assetId);
    if (asset == null || bytes == null) {
      throw MediaSourceException('Missing mobile asset $assetId');
    }
    return MediaReadResult(asset: _toMediaAsset(asset), bytes: bytes);
  }

  @override
  Future<MediaAsset?> statAsset(String assetId) async {
    final asset = await gateway.statAsset(assetId);
    return asset == null ? null : _toMediaAsset(asset);
  }

  @override
  Future<List<String>> listMissingAssetIds(
    Iterable<String> knownAssetIds,
  ) async {
    final current = (await gateway.listAssets())
        .map((asset) => asset.id)
        .toSet();
    return knownAssetIds.where((id) => !current.contains(id)).toList();
  }

  MediaAsset _toMediaAsset(PhotoLibraryAsset asset) {
    return MediaAsset(
      id: asset.id,
      path: asset.path,
      metadata: MediaAssetMetadata(
        size: asset.size,
        updatedAt: asset.updatedAt,
        mime: asset.mime ?? mimeFromPath(asset.title),
        datetime: asset.datetime,
        lat: asset.lat,
        lng: asset.lng,
        camera: asset.camera,
      ),
    );
  }
}
