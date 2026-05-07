import 'dart:io';
import 'dart:typed_data';

import 'package:chronopic_media/chronopic_media.dart';
import 'package:test/test.dart';

void main() {
  test('fixture adapter lists, stats, reads, and reports missing assets', () async {
    final source = FixtureMediaSource(
      assets: const <MediaAsset>[
        MediaAsset(
          id: 'asset-1',
          path: '/fixture/asset-1.png',
          metadata: MediaAssetMetadata(size: 3, updatedAt: 100, mime: 'image/png'),
        ),
        MediaAsset(
          id: 'asset-2',
          path: '/fixture/asset-2.jpg',
          metadata: MediaAssetMetadata(size: 2, updatedAt: 200, mime: 'image/jpeg'),
        ),
      ],
      bytesById: <String, Uint8List>{
        'asset-1': Uint8List.fromList(<int>[1, 2, 3]),
        'asset-2': Uint8List.fromList(<int>[4, 5]),
      },
      missingAssetIds: const <String>{'asset-2'},
    );

    expect((await source.listAssets()).map((asset) => asset.id), ['asset-1']);
    expect((await source.statAsset('asset-1'))?.metadata.mime, 'image/png');
    expect((await source.readAsset('asset-1')).bytes, [1, 2, 3]);
    expect(await source.listMissingAssetIds(['asset-1', 'asset-2', 'asset-3']), ['asset-2', 'asset-3']);
  });

  test('fixture adapter simulates permission denied', () async {
    final source = FixtureMediaSource(assets: const <MediaAsset>[], bytesById: const <String, Uint8List>{}, permissionState: MediaSourcePermissionState.denied);

    expect(source.listAssets, throwsA(isA<MediaSourceException>()));
  });

  test('desktop directory adapter filters supported media and reads bytes', () async {
    final root = Directory.systemTemp.createTempSync('chronopic-media-');
    addTearDown(() => root.deleteSync(recursive: true));
    final nested = Directory('${root.path}/nested')..createSync();
    final image = File('${nested.path}/photo.png')..writeAsBytesSync(<int>[10, 20, 30]);
    File('${root.path}/notes.txt').writeAsStringSync('not media');

    final source = DesktopDirectoryMediaSource(root);
    final assets = await source.listAssets();

    expect(assets.map((asset) => asset.path), [image.absolute.path]);
    expect(assets.single.metadata.mime, 'image/png');
    expect((await source.readAsset(image.absolute.path)).bytes, [10, 20, 30]);

    image.deleteSync();
    expect(await source.listMissingAssetIds([image.absolute.path]), [image.absolute.path]);
  });
}
