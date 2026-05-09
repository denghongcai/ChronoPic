import 'dart:typed_data';

import 'package:chronopic_media/chronopic_media.dart';
import 'package:test/test.dart';

void main() {
  test('mobile source lists granted library assets and reads bytes', () async {
    final gateway = FakePhotoLibraryGateway(
      permission: const PhotoLibraryPermissionSnapshot(
        state: MediaSourcePermissionState.granted,
        canOpenSettings: true,
      ),
      assets: const <PhotoLibraryAsset>[
        PhotoLibraryAsset(
          id: 'asset-1',
          path: 'asset://asset-1',
          title: 'IMG_0001.JPG',
          size: 4,
          updatedAt: 1000,
          mime: 'image/jpeg',
          datetime: 900,
          lat: 31.2,
          lng: 121.4,
        ),
      ],
      bytesById: <String, Uint8List>{
        'asset-1': Uint8List.fromList(<int>[1, 2, 3, 4]),
      },
    );

    final source = MobilePhotoLibraryMediaSource(gateway);
    final assets = await source.listAssets();
    final read = await source.readAsset('asset-1');

    expect(source.permissionState, MediaSourcePermissionState.granted);
    expect(assets.single.id, 'asset-1');
    expect(assets.single.path, 'asset://asset-1');
    expect(read.bytes, <int>[1, 2, 3, 4]);
  });

  test('mobile source exposes limited permission state', () async {
    final gateway = FakePhotoLibraryGateway(
      permission: const PhotoLibraryPermissionSnapshot(
        state: MediaSourcePermissionState.limited,
        canOpenSettings: true,
      ),
      assets: const <PhotoLibraryAsset>[],
      bytesById: const <String, Uint8List>{},
    );

    final source = MobilePhotoLibraryMediaSource(gateway);
    expect(await source.listAssets(), isEmpty);
    expect(source.permissionState, MediaSourcePermissionState.limited);
  });

  test('mobile source throws denied permission with state', () async {
    final gateway = FakePhotoLibraryGateway(
      permission: const PhotoLibraryPermissionSnapshot(
        state: MediaSourcePermissionState.denied,
        canOpenSettings: true,
      ),
      assets: const <PhotoLibraryAsset>[],
      bytesById: const <String, Uint8List>{},
    );

    final source = MobilePhotoLibraryMediaSource(gateway);

    expect(
      source.listAssets,
      throwsA(
        isA<MediaSourceException>().having(
          (error) => error.permissionState,
          'permissionState',
          MediaSourcePermissionState.denied,
        ),
      ),
    );
  });
}

final class FakePhotoLibraryGateway implements PhotoLibraryGateway {
  FakePhotoLibraryGateway({
    required this.permission,
    required List<PhotoLibraryAsset> assets,
    required Map<String, Uint8List> bytesById,
  }) : _assets = List<PhotoLibraryAsset>.of(assets),
       _bytesById = Map<String, Uint8List>.of(bytesById);

  final PhotoLibraryPermissionSnapshot permission;
  final List<PhotoLibraryAsset> _assets;
  final Map<String, Uint8List> _bytesById;

  @override
  Future<PhotoLibraryPermissionSnapshot> requestPermission() async =>
      permission;

  @override
  Future<List<PhotoLibraryAsset>> listAssets() async => _assets;

  @override
  Future<Uint8List?> readAssetBytes(String assetId) async =>
      _bytesById[assetId];

  @override
  Future<PhotoLibraryAsset?> statAsset(String assetId) async =>
      _assets.where((asset) => asset.id == assetId).firstOrNull;

  @override
  Future<void> openSettings() async {}
}
