import 'dart:typed_data';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:test/test.dart';

void main() {
  MediaAsset asset(String id, int updatedAt) {
    return MediaAsset(
      id: id,
      path: '/fixture/$id.png',
      metadata: MediaAssetMetadata(size: 3, updatedAt: updatedAt, mime: 'image/png', datetime: updatedAt),
    );
  }

  test('indexes new assets and skips unchanged assets', () async {
    final source = FixtureMediaSource(
      assets: <MediaAsset>[asset('photo-1', 100)],
      bytesById: <String, Uint8List>{'photo-1': Uint8List.fromList(<int>[1, 2, 3])},
    );
    final repository = ChronoPicRepository();
    final indexer = ChronoPicIndexerService(repository: repository, mediaSource: source, aiClient: const FixtureSuccessAiClient());

    expect((await indexer.scanLibrary()).imported, 1);
    expect((await indexer.scanLibrary()).skipped, 1);
    expect(repository.getPhoto('photo-1')?.semantic.aiStatus.name, 'completed');
  });

  test('records failed and disabled AI states', () async {
    final failedRepository = ChronoPicRepository();
    final failedIndexer = ChronoPicIndexerService(
      repository: failedRepository,
      mediaSource: FixtureMediaSource(
        assets: <MediaAsset>[asset('photo-failed', 100)],
        bytesById: <String, Uint8List>{'photo-failed': Uint8List.fromList(<int>[1])},
      ),
      aiClient: const FixtureFailureAiClient(),
    );
    await failedIndexer.scanLibrary();
    expect(failedRepository.getPhoto('photo-failed')?.semantic.aiStatus.name, 'failed');

    final disabledRepository = ChronoPicRepository();
    final disabledIndexer = ChronoPicIndexerService(
      repository: disabledRepository,
      mediaSource: FixtureMediaSource(
        assets: <MediaAsset>[asset('photo-disabled', 100)],
        bytesById: <String, Uint8List>{'photo-disabled': Uint8List.fromList(<int>[1])},
      ),
      aiClient: const DisabledAiClient(),
    );
    await disabledIndexer.scanLibrary();
    expect(disabledRepository.getPhoto('photo-disabled')?.semantic.aiStatus.name, 'disabled');
  });
}

