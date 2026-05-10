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

  test(
    'mobile source lists assets from the selected photo-library scope',
    () async {
      final gateway = FakePhotoLibraryGateway(
        permission: const PhotoLibraryPermissionSnapshot(
          state: MediaSourcePermissionState.granted,
          canOpenSettings: true,
        ),
        assets: const <PhotoLibraryAsset>[
          PhotoLibraryAsset(
            id: 'all-asset',
            path: 'asset://all-asset',
            title: 'ALL.JPG',
            size: 1,
            updatedAt: 1000,
          ),
        ],
        scopedAssets: const <String, List<PhotoLibraryAsset>>{
          'camera': <PhotoLibraryAsset>[
            PhotoLibraryAsset(
              id: 'camera-asset',
              path: 'asset://camera-asset',
              title: 'CAMERA.JPG',
              size: 2,
              updatedAt: 2000,
            ),
          ],
        },
        bytesById: <String, Uint8List>{
          'camera-asset': Uint8List.fromList(<int>[5, 6]),
        },
      );

      final source = MobilePhotoLibraryMediaSource(
        gateway,
        scope: const PhotoLibraryScope(
          id: 'camera',
          name: 'Camera',
          isAll: false,
          assetCount: 1,
        ),
      );
      final assets = await source.listAssets();
      final read = await source.readAsset('camera-asset');

      expect(assets.map((asset) => asset.id), ['camera-asset']);
      expect(read.bytes, <int>[5, 6]);
      expect(gateway.listAssetScopeIds, ['camera']);
    },
  );

  test('gateway exposes photo-library scopes', () async {
    final gateway = FakePhotoLibraryGateway(
      permission: const PhotoLibraryPermissionSnapshot(
        state: MediaSourcePermissionState.granted,
        canOpenSettings: true,
      ),
      assets: const <PhotoLibraryAsset>[],
      scopes: const <PhotoLibraryScope>[
        PhotoLibraryScope(
          id: 'all',
          name: 'All Photos',
          isAll: true,
          assetCount: 20,
        ),
        PhotoLibraryScope(
          id: 'camera',
          name: 'Camera',
          isAll: false,
          assetCount: 3,
        ),
      ],
      bytesById: const <String, Uint8List>{},
    );

    expect(await gateway.listScopes(), hasLength(2));
    expect((await gateway.listScopes()).map((scope) => scope.name), [
      'All Photos',
      'Camera',
    ]);
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
    List<PhotoLibraryScope> scopes = const <PhotoLibraryScope>[],
    Map<String, List<PhotoLibraryAsset>> scopedAssets =
        const <String, List<PhotoLibraryAsset>>{},
  }) : _assets = List<PhotoLibraryAsset>.of(assets),
       _bytesById = Map<String, Uint8List>.of(bytesById),
       _scopes = List<PhotoLibraryScope>.of(scopes),
       _scopedAssets = Map<String, List<PhotoLibraryAsset>>.from(scopedAssets);

  final PhotoLibraryPermissionSnapshot permission;
  final List<PhotoLibraryAsset> _assets;
  final Map<String, Uint8List> _bytesById;
  final List<PhotoLibraryScope> _scopes;
  final Map<String, List<PhotoLibraryAsset>> _scopedAssets;
  final List<String?> listAssetScopeIds = <String?>[];

  @override
  Future<PhotoLibraryPermissionSnapshot> requestPermission() async =>
      permission;

  @override
  Future<List<PhotoLibraryScope>> listScopes() async => _scopes;

  @override
  Future<List<PhotoLibraryAsset>> listAssets({String? scopeId}) async {
    listAssetScopeIds.add(scopeId);
    return scopeId == null ? _assets : _scopedAssets[scopeId] ?? _assets;
  }

  @override
  Future<Uint8List?> readAssetBytes(String assetId) async =>
      _bytesById[assetId];

  @override
  Future<Uint8List?> readThumbnailBytes(
    String assetId, {
    int size = 512,
  }) async => _bytesById[assetId];

  @override
  Future<PhotoLibraryAsset?> statAsset(String assetId) async => [
    ..._assets,
    ..._scopedAssets.values.expand((assets) => assets),
  ].where((asset) => asset.id == assetId).firstOrNull;

  @override
  Future<void> openSettings() async {}
}
