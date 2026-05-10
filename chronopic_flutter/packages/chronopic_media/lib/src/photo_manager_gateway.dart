import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import 'media_source.dart';
import 'photo_library_gateway.dart';

final class PhotoManagerGateway implements PhotoLibraryGateway {
  PhotoManagerGateway();

  static const int _assetPageSize = 200;

  final Map<String, AssetEntity> _entitiesById = <String, AssetEntity>{};
  final Map<String, AssetPathEntity> _pathsById = <String, AssetPathEntity>{};

  @override
  Future<PhotoLibraryPermissionSnapshot> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return PhotoLibraryPermissionSnapshot(
      state: _permissionStateFromResult(result),
      canOpenSettings: true,
    );
  }

  @override
  Future<List<PhotoLibraryScope>> listScopes() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: false,
    );
    _pathsById
      ..clear()
      ..addEntries(paths.map((path) => MapEntry(path.id, path)));
    final scopes = <PhotoLibraryScope>[];
    for (final path in paths.where((path) => path.albumType == 1)) {
      scopes.add(
        PhotoLibraryScope(
          id: path.id,
          name: path.isAll ? 'All Photos' : path.name,
          isAll: path.isAll,
          assetCount: await path.assetCountAsync,
        ),
      );
    }
    scopes.sort((a, b) {
      if (a.isAll != b.isAll) return a.isAll ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return scopes;
  }

  @override
  Future<List<PhotoLibraryAsset>> listAssets({String? scopeId}) async {
    final path = await _pathForScope(scopeId);
    if (path == null) return const <PhotoLibraryAsset>[];
    final count = await path.assetCountAsync;
    final entities = <AssetEntity>[];
    for (var page = 0; page * _assetPageSize < count; page += 1) {
      final pageEntities = await path.getAssetListPaged(
        page: page,
        size: _assetPageSize,
      );
      if (pageEntities.isEmpty) break;
      entities.addAll(pageEntities);
      if (pageEntities.length < _assetPageSize) break;
    }
    _entitiesById
      ..clear()
      ..addEntries(entities.map((entity) => MapEntry(entity.id, entity)));
    return entities.map(_assetFromEntity).toList();
  }

  @override
  Future<Uint8List?> readAssetBytes(String assetId) async {
    final entity = _entitiesById[assetId] ?? await AssetEntity.fromId(assetId);
    if (entity == null) return null;
    final originBytes = await entity.originBytes;
    if (originBytes != null && originBytes.isNotEmpty) return originBytes;
    final File? file = await entity.file;
    final fileBytes = await file?.readAsBytes();
    return fileBytes?.isNotEmpty == true ? fileBytes : originBytes;
  }

  @override
  Future<Uint8List?> readThumbnailBytes(
    String assetId, {
    int size = 512,
  }) async {
    final entity = _entitiesById[assetId] ?? await AssetEntity.fromId(assetId);
    if (entity == null) return null;
    final bytes = await entity.thumbnailDataWithSize(
      ThumbnailSize.square(size),
      quality: 82,
    );
    return bytes?.isNotEmpty == true ? bytes : null;
  }

  @override
  Future<PhotoLibraryAsset?> statAsset(String assetId) async {
    final entity = _entitiesById[assetId] ?? await AssetEntity.fromId(assetId);
    return entity == null ? null : _assetFromEntity(entity);
  }

  @override
  Future<void> openSettings() => PhotoManager.openSetting();

  Future<AssetPathEntity?> _pathForScope(String? scopeId) async {
    if (scopeId != null && _pathsById.containsKey(scopeId)) {
      return _pathsById[scopeId];
    }
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: scopeId == null,
    );
    _pathsById.addEntries(paths.map((path) => MapEntry(path.id, path)));
    if (scopeId == null) {
      return paths.where((path) => path.albumType == 1).firstOrNull;
    }
    return paths
        .where((path) => path.albumType == 1 && path.id == scopeId)
        .firstOrNull;
  }

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
