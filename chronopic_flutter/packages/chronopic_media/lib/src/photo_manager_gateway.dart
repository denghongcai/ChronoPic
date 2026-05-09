import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import 'media_source.dart';
import 'photo_library_gateway.dart';

final class PhotoManagerGateway implements PhotoLibraryGateway {
  const PhotoManagerGateway();

  @override
  Future<PhotoLibraryPermissionSnapshot> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return PhotoLibraryPermissionSnapshot(
      state: _permissionStateFromResult(result),
      canOpenSettings: true,
    );
  }

  @override
  Future<List<PhotoLibraryAsset>> listAssets() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (paths.isEmpty) return const <PhotoLibraryAsset>[];
    final entities = await paths.first.getAssetListPaged(page: 0, size: 100000);
    return entities.map(_assetFromEntity).toList();
  }

  @override
  Future<Uint8List?> readAssetBytes(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    return entity?.originBytes;
  }

  @override
  Future<PhotoLibraryAsset?> statAsset(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    return entity == null ? null : _assetFromEntity(entity);
  }

  @override
  Future<void> openSettings() => PhotoManager.openSetting();

  MediaSourcePermissionState _permissionStateFromResult(
    PermissionState result,
  ) {
    if (result == PermissionState.authorized) {
      return MediaSourcePermissionState.granted;
    }
    if (result == PermissionState.limited) {
      return MediaSourcePermissionState.limited;
    }
    return MediaSourcePermissionState.denied;
  }

  PhotoLibraryAsset _assetFromEntity(AssetEntity entity) {
    final title = entity.title ?? entity.id;
    return PhotoLibraryAsset(
      id: entity.id,
      path: 'asset://${entity.id}',
      title: title,
      size: entity.width * entity.height,
      updatedAt: entity.modifiedDateTime.millisecondsSinceEpoch,
      mime: entity.mimeType,
      datetime: entity.createDateTime.millisecondsSinceEpoch,
      lat: entity.latitude,
      lng: entity.longitude,
    );
  }
}
