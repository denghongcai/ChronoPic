import 'dart:typed_data';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:test/test.dart';

void main() {
  MediaAsset asset(String id, int updatedAt) {
    return MediaAsset(
      id: id,
      path: '/fixture/$id.png',
      metadata: MediaAssetMetadata(
        size: 3,
        updatedAt: updatedAt,
        mime: 'image/png',
        datetime: updatedAt,
      ),
    );
  }

  test('indexes new assets and skips unchanged assets', () async {
    final source = FixtureMediaSource(
      assets: <MediaAsset>[asset('photo-1', 100), asset('photo-2', 110)],
      bytesById: <String, Uint8List>{
        'photo-1': Uint8List.fromList(<int>[1, 2, 3]),
        'photo-2': Uint8List.fromList(<int>[4, 5, 6]),
      },
    );
    final repository = ChronoPicRepository();
    final indexer = ChronoPicIndexerService(
      repository: repository,
      mediaSource: source,
      aiClient: const FixtureSuccessAiClient(),
    );

    final firstScan = await indexer.scanLibrary();
    expect(firstScan.imported, 2);
    expect(firstScan.updated, 0);
    final secondScan = await indexer.scanLibrary();
    expect(secondScan.imported, 0);
    expect(secondScan.updated, 0);
    expect(secondScan.skipped, 2);
    expect(
      repository
          .listPhotos(const PhotoFilter(limit: 100))
          .map((record) => record.photo.id),
      <String>['photo-2', 'photo-1'],
    );
    expect(repository.getPhoto('photo-1')?.semantic.aiStatus.name, 'completed');
  });

  test('records failed and disabled AI states', () async {
    final failedRepository = ChronoPicRepository();
    final failedIndexer = ChronoPicIndexerService(
      repository: failedRepository,
      mediaSource: FixtureMediaSource(
        assets: <MediaAsset>[asset('photo-failed', 100)],
        bytesById: <String, Uint8List>{
          'photo-failed': Uint8List.fromList(<int>[1]),
        },
      ),
      aiClient: const FixtureFailureAiClient(),
    );
    await failedIndexer.scanLibrary();
    expect(
      failedRepository.getPhoto('photo-failed')?.semantic.aiStatus.name,
      'failed',
    );

    final disabledRepository = ChronoPicRepository();
    final disabledIndexer = ChronoPicIndexerService(
      repository: disabledRepository,
      mediaSource: FixtureMediaSource(
        assets: <MediaAsset>[asset('photo-disabled', 100)],
        bytesById: <String, Uint8List>{
          'photo-disabled': Uint8List.fromList(<int>[1]),
        },
      ),
      aiClient: const DisabledAiClient(),
    );
    await disabledIndexer.scanLibrary();
    expect(
      disabledRepository.getPhoto('photo-disabled')?.semantic.aiStatus.name,
      'disabled',
    );
  });

  test('non-image assets skip original reads for AI enrichment', () async {
    final recordingClient = _RecordingAiClient();
    final repository = ChronoPicRepository();
    final indexer = ChronoPicIndexerService(
      repository: repository,
      mediaSource: FixtureMediaSource(
        assets: <MediaAsset>[
          asset('photo-image', 100),
          const MediaAsset(
            id: 'clip-video',
            path: '/fixture/clip-video.mp4',
            metadata: MediaAssetMetadata(
              size: 9,
              updatedAt: 100,
              mime: 'video/mp4',
              datetime: 100,
            ),
          ),
        ],
        bytesById: <String, Uint8List>{
          'photo-image': Uint8List.fromList(<int>[1, 2, 3]),
          'clip-video': Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9]),
        },
      ),
      aiClient: recordingClient,
    );

    final stats = await indexer.scanLibrary();
    expect(stats.imported, 2);
    expect(stats.errors, 0);

    final videoCall = recordingClient.calls
        .singleWhere((call) => call.mime == 'video/mp4');
    expect(videoCall.bytes, isEmpty);
    final imageCall = recordingClient.calls
        .singleWhere((call) => call.mime == 'image/png');
    expect(imageCall.bytes, <int>[1, 2, 3]);
  });
}

final class _RecordingAiClient implements ChronoPicAiClient {
  final calls = <({String mime, List<int> bytes})>[];

  @override
  bool get isEnabled => true;

  @override
  Future<PhotoAiResult> analyzePhoto({
    required String photoId,
    required List<int> bytes,
    required String mime,
    DateTime? datetime,
    double? lat,
    double? lng,
    String? path,
    PhotoAiContext context = const PhotoAiContext(),
  }) async {
    calls.add((mime: mime, bytes: bytes));
    return const PhotoAiResult(status: AiPipelineStatus.completed);
  }

  @override
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  }) async {
    return const MemoryAiResult(status: AiPipelineStatus.disabled);
  }
}
