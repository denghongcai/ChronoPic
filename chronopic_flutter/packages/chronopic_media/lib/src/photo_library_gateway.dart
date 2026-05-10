import 'dart:typed_data';

import 'media_source.dart';

final class PhotoLibraryPermissionSnapshot {
  const PhotoLibraryPermissionSnapshot({
    required this.state,
    required this.canOpenSettings,
  });

  final MediaSourcePermissionState state;
  final bool canOpenSettings;
}

final class PhotoLibraryAsset {
  const PhotoLibraryAsset({
    required this.id,
    required this.path,
    required this.title,
    required this.size,
    required this.updatedAt,
    this.mime,
    this.datetime,
    this.lat,
    this.lng,
    this.camera,
  });

  final String id;
  final String path;
  final String title;
  final int size;
  final int updatedAt;
  final String? mime;
  final int? datetime;
  final double? lat;
  final double? lng;
  final String? camera;
}

final class PhotoLibraryScope {
  const PhotoLibraryScope({
    required this.id,
    required this.name,
    required this.isAll,
    required this.assetCount,
  });

  final String id;
  final String name;
  final bool isAll;
  final int assetCount;
}

abstract interface class PhotoLibraryGateway {
  Future<PhotoLibraryPermissionSnapshot> requestPermission();

  Future<List<PhotoLibraryScope>> listScopes();

  Future<List<PhotoLibraryAsset>> listAssets({String? scopeId});

  Future<Uint8List?> readAssetBytes(String assetId);

  Future<Uint8List?> readThumbnailBytes(String assetId, {int size = 512});

  Future<PhotoLibraryAsset?> statAsset(String assetId);

  Future<void> openSettings();
}
