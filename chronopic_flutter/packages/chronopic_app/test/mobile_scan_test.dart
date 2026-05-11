import 'dart:io';
import 'dart:typed_data';

import 'package:chronopic_ai/chronopic_ai.dart';
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

    final first = await service.scanMediaSource(
      'photo-library',
      firstSource,
      aiClient: const FixtureSuccessAiClient(),
    );

    expect(first.imported, 1);
    expect(first.errors, 1);
    expect(first.lastError, contains('asset-failed'));
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

    final retry = await service.scanMediaSource(
      'photo-library',
      retrySource,
      aiClient: const FixtureSuccessAiClient(),
    );

    expect(retry.skipped, 1);
    expect(retry.imported, 1);
    expect(retry.errors, 0);
    expect(retry.lastError, isNull);
    expect(service.listPhotos(const PhotoFilter(limit: 10)), hasLength(2));
  });

  test('rescan progress counts skipped assets as processed', () async {
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

    await service.scanMediaSource('photo-library', source);

    final progress = <ScanProgress>[];
    final rescan = await service.scanMediaSource(
      'photo-library',
      source,
      onProgress: progress.add,
    );

    expect(rescan.skipped, 3);
    expect(progress.last.state, ScanRunState.completed);
    expect(progress.last.discovered, 3);
    expect(progress.last.skipped, 3);
    expect(progress.last.processed, 3);
  });

  test('imports image assets even when thumbnail decoding fails', () async {
    final repository = ChronoPicRepository();
    final thumbnailDirectory = Directory.systemTemp.createTempSync(
      'chronopic-thumbnails-',
    );
    addTearDown(() {
      if (thumbnailDirectory.existsSync()) {
        thumbnailDirectory.deleteSync(recursive: true);
      }
    });
    final indexer = ChronoPicIndexerService(
      repository: repository,
      mediaSource: FixtureMediaSource(
        assets: <MediaAsset>[_asset('asset-image', mime: 'image/png')],
        bytesById: <String, Uint8List>{
          'asset-image': Uint8List.fromList(<int>[1, 2, 3]),
        },
      ),
      aiClient: const DisabledAiClient(),
      thumbnailDirectory: thumbnailDirectory,
    );

    final stats = await indexer.scanLibrary();

    expect(stats.imported, 1);
    expect(stats.errors, 0);
    expect(repository.getPhoto('asset-image')?.photo.thumbnailPath, isNull);
  });

  test(
    'lazy mobile scan skips thumbnail reads while indexing metadata',
    () async {
      final repository = ChronoPicRepository();
      final source = CountingThumbnailMediaSource(
        assets: <MediaAsset>[_asset('asset-image', mime: 'image/jpeg')],
        thumbnailBytesById: <String, Uint8List>{
          'asset-image': Uint8List.fromList(<int>[1, 2, 3]),
        },
      );
      final indexer = ChronoPicIndexerService(
        repository: repository,
        mediaSource: source,
        aiClient: const DisabledAiClient(),
      );

      final stats = await indexer.scanLibrary();

      expect(stats.imported, 1);
      expect(stats.errors, 0);
      expect(source.thumbnailReadCount, 0);
      expect(source.originalReadCount, 0);
      expect(repository.getPhoto('asset-image'), isNotNull);
      expect(repository.getPhoto('asset-image')?.photo.thumbnailPath, isNull);
    },
  );

  test('large scans throttle progress callbacks', () async {
    final service = ChronoPicAppService(ChronoPicRepository());
    final assets = <MediaAsset>[
      for (var index = 0; index < 100; index += 1)
        _asset('asset-$index', updatedAt: index + 1),
    ];
    final source = FixtureMediaSource(
      assets: assets,
      bytesById: <String, Uint8List>{
        for (final asset in assets) asset.id: Uint8List.fromList(<int>[1]),
      },
    );
    final progress = <ScanProgress>[];

    final stats = await service.scanMediaSource(
      'photo-library',
      source,
      onProgress: progress.add,
    );

    expect(stats.imported, 100);
    expect(progress.first.processed, 0);
    expect(progress.last.state, ScanRunState.completed);
    expect(progress.last.processed, 100);
    expect(progress.length, lessThanOrEqualTo(15));
  });
}

MediaAsset _asset(
  String id, {
  int updatedAt = 1000,
  String mime = 'video/mp4',
}) {
  return MediaAsset(
    id: id,
    path: 'asset://$id',
    metadata: MediaAssetMetadata(
      size: 1,
      updatedAt: updatedAt,
      mime: mime,
      datetime: updatedAt,
    ),
  );
}

final class CountingThumbnailMediaSource implements MediaSourceAdapter {
  CountingThumbnailMediaSource({
    required List<MediaAsset> assets,
    required Map<String, Uint8List> thumbnailBytesById,
  }) : _assets = List<MediaAsset>.of(assets),
       _thumbnailBytesById = Map<String, Uint8List>.of(thumbnailBytesById);

  final List<MediaAsset> _assets;
  final Map<String, Uint8List> _thumbnailBytesById;
  var thumbnailReadCount = 0;
  var originalReadCount = 0;

  @override
  MediaSourcePermissionState get permissionState =>
      MediaSourcePermissionState.granted;

  @override
  bool get supportsLazyThumbnails => true;

  @override
  Future<List<MediaAsset>> listAssets() async => _assets;

  @override
  Future<MediaReadResult> readAsset(String assetId) async {
    originalReadCount += 1;
    throw StateError('Original bytes should not be read for disabled AI');
  }

  @override
  Future<Uint8List?> readThumbnailBytes(
    String assetId, {
    int size = 512,
  }) async {
    thumbnailReadCount += 1;
    return _thumbnailBytesById[assetId];
  }

  @override
  Future<MediaAsset?> statAsset(String assetId) async =>
      _assets.where((asset) => asset.id == assetId).firstOrNull;

  @override
  Future<List<String>> listMissingAssetIds(
    Iterable<String> knownAssetIds,
  ) async {
    return const <String>[];
  }
}
