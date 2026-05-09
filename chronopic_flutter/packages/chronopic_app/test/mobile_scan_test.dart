import 'dart:typed_data';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:test/test.dart';

void main() {
  test('scans a limited mobile source and reports progress', () async {
    final service = ChronoPicAppService(ChronoPicRepository());
    final progress = <ScanProgress>[];
    final source = FixtureMediaSource(
      permissionState: MediaSourcePermissionState.limited,
      assets: <MediaAsset>[
        _asset('asset-1', updatedAt: 1000),
        _asset('asset-2', updatedAt: 2000),
      ],
      bytesById: <String, Uint8List>{
        'asset-1': Uint8List.fromList(<int>[1, 2, 3]),
        'asset-2': Uint8List.fromList(<int>[4, 5, 6]),
      },
    );

    final stats = await service.scanMediaSource(
      'photo-library',
      source,
      onProgress: progress.add,
    );

    expect(stats.discovered, 2);
    expect(stats.imported, 2);
    expect(service.listLibrarySources().single.path, 'photo-library');
    expect(service.listPhotos(const PhotoFilter(limit: 10)), hasLength(2));
    expect(progress.first.state, ScanRunState.running);
    expect(progress.last.state, ScanRunState.completed);
    expect(progress.last.discovered, 2);
    expect(progress.last.processed, 2);
    expect(progress.last.imported, 2);
  });

  test(
    'denied mobile source reports failure without mutating photos',
    () async {
      final service = ChronoPicAppService(ChronoPicRepository());
      final progress = <ScanProgress>[];
      final source = FixtureMediaSource(
        permissionState: MediaSourcePermissionState.denied,
        assets: <MediaAsset>[_asset('denied-asset')],
        bytesById: <String, Uint8List>{
          'denied-asset': Uint8List.fromList(<int>[1]),
        },
      );

      await expectLater(
        service.scanMediaSource(
          'photo-library',
          source,
          onProgress: progress.add,
        ),
        throwsA(
          isA<MediaSourceException>().having(
            (error) => error.permissionState,
            'permissionState',
            MediaSourcePermissionState.denied,
          ),
        ),
      );

      expect(service.listPhotos(const PhotoFilter(limit: 10)), isEmpty);
      expect(progress.single.state, ScanRunState.failed);
      expect(progress.single.message, contains('Media permission denied'));
    },
  );

  test('pause stops after current mobile asset and resume skips it', () async {
    final service = ChronoPicAppService(ChronoPicRepository());
    final source = FixtureMediaSource(
      assets: <MediaAsset>[
        _asset('asset-1', updatedAt: 1000),
        _asset('asset-2', updatedAt: 2000),
        _asset('asset-3', updatedAt: 3000),
      ],
      bytesById: <String, Uint8List>{
        'asset-1': Uint8List.fromList(<int>[1]),
        'asset-2': Uint8List.fromList(<int>[2]),
        'asset-3': Uint8List.fromList(<int>[3]),
      },
    );
    final progress = <ScanProgress>[];
    var pauseChecks = 0;

    final paused = await service.scanMediaSource(
      'photo-library',
      source,
      shouldPause: () async {
        pauseChecks += 1;
        return pauseChecks == 1;
      },
      onProgress: progress.add,
    );

    expect(paused.processed, 1);
    expect(paused.imported, 1);
    expect(progress.last.state, ScanRunState.paused);
    expect(service.listPhotos(const PhotoFilter(limit: 10)), hasLength(1));

    final resumed = await service.scanMediaSource('photo-library', source);

    expect(resumed.imported, 2);
    expect(resumed.skipped, 1);
    expect(service.listPhotos(const PhotoFilter(limit: 10)), hasLength(3));
  });

  test('rescan retries assets that failed to read previously', () async {
    final service = ChronoPicAppService(ChronoPicRepository());
    final firstSource = FixtureMediaSource(
      assets: <MediaAsset>[
        _asset('asset-ok', updatedAt: 1000),
        _asset('asset-failed', updatedAt: 2000),
      ],
      bytesById: <String, Uint8List>{
        'asset-ok': Uint8List.fromList(<int>[1]),
      },
    );

    final first = await service.scanMediaSource('photo-library', firstSource);

    expect(first.imported, 1);
    expect(first.errors, 1);
    expect(service.listPhotos(const PhotoFilter(limit: 10)), hasLength(1));

    final retrySource = FixtureMediaSource(
      assets: <MediaAsset>[
        _asset('asset-ok', updatedAt: 1000),
        _asset('asset-failed', updatedAt: 2000),
      ],
      bytesById: <String, Uint8List>{
        'asset-ok': Uint8List.fromList(<int>[1]),
        'asset-failed': Uint8List.fromList(<int>[2]),
      },
    );

    final retry = await service.scanMediaSource('photo-library', retrySource);

    expect(retry.skipped, 1);
    expect(retry.imported, 1);
    expect(retry.errors, 0);
    expect(service.listPhotos(const PhotoFilter(limit: 10)), hasLength(2));
  });
}

MediaAsset _asset(String id, {int updatedAt = 1000}) {
  return MediaAsset(
    id: id,
    path: 'asset://$id',
    metadata: MediaAssetMetadata(
      size: 1,
      updatedAt: updatedAt,
      mime: 'video/mp4',
      datetime: updatedAt,
    ),
  );
}
