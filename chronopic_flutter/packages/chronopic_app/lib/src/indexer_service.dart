import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:image/image.dart' as img;

final class IndexerStats {
  const IndexerStats({
    required this.discovered,
    required this.processed,
    required this.imported,
    required this.updated,
    required this.duplicates,
    required this.errors,
    required this.skipped,
    required this.missing,
  });

  final int discovered;
  final int processed;
  final int imported;
  final int updated;
  final int duplicates;
  final int errors;
  final int skipped;
  final int missing;
}

enum ScanRunState { idle, running, paused, completed, failed }

final class ScanProgress {
  const ScanProgress({
    required this.state,
    required this.discovered,
    required this.processed,
    required this.imported,
    required this.updated,
    required this.errors,
    required this.skipped,
    required this.missing,
    this.message,
  });

  final ScanRunState state;
  final int discovered;
  final int processed;
  final int imported;
  final int updated;
  final int errors;
  final int skipped;
  final int missing;
  final String? message;
}

final class ChronoPicIndexerService {
  ChronoPicIndexerService({
    required this.repository,
    required this.mediaSource,
    required this.aiClient,
    this.thumbnailDirectory,
    this.shouldPause,
    this.onProgress,
  });

  final ChronoPicRepository repository;
  final MediaSourceAdapter mediaSource;
  final ChronoPicAiClient aiClient;
  final Directory? thumbnailDirectory;
  final Future<bool> Function()? shouldPause;
  final void Function(ScanProgress progress)? onProgress;

  Future<IndexerStats> scanLibrary() async {
    late final List<MediaAsset> assets;
    try {
      assets = await mediaSource.listAssets();
    } on Object catch (error) {
      _report(
        ScanRunState.failed,
        const _ScanCounters(),
        discovered: 0,
        missing: 0,
        message: error.toString(),
      );
      rethrow;
    }
    var imported = 0;
    var updated = 0;
    var skipped = 0;
    var errors = 0;
    final seen = <String>{};
    _report(
      ScanRunState.running,
      const _ScanCounters(),
      discovered: assets.length,
      missing: 0,
    );

    for (final asset in assets) {
      seen.add(asset.id);
      final previous = repository.getPhoto(asset.id);
      final unchanged =
          previous?.indexState.sourceUpdatedAt == asset.metadata.updatedAt &&
          previous?.indexState.missingAt == null;
      if (unchanged) {
        skipped += 1;
        _report(
          ScanRunState.running,
          _ScanCounters(
            imported: imported,
            updated: updated,
            errors: errors,
            skipped: skipped,
          ),
          discovered: assets.length,
          missing: 0,
        );
        continue;
      }
      try {
        final read = await mediaSource.readAsset(asset.id);
        final ai = await aiClient.analyzePhoto(
          photoId: asset.id,
          bytes: read.bytes,
          mime: asset.metadata.mime ?? mimeFromPath(asset.path),
        );
        repository.upsertPhotoRecord(
          _recordForAsset(
            asset,
            ai,
            thumbnailPath: _writeThumbnail(asset, read.bytes),
          ),
        );
        if (previous == null) {
          imported += 1;
        } else {
          updated += 1;
        }
      } on Object {
        errors += 1;
      }
      final counters = _ScanCounters(
        imported: imported,
        updated: updated,
        errors: errors,
        skipped: skipped,
      );
      _report(
        ScanRunState.running,
        counters,
        discovered: assets.length,
        missing: 0,
      );
      if (await shouldPause?.call() == true) {
        _report(
          ScanRunState.paused,
          counters,
          discovered: assets.length,
          missing: 0,
        );
        return _stats(counters, discovered: assets.length, missing: 0);
      }
    }

    final knownIds = repository
        .listPhotos(const PhotoFilter(limit: 1000000))
        .map((record) => record.photo.id)
        .toSet();
    final missing = await mediaSource.listMissingAssetIds(
      knownIds.difference(seen),
    );
    repository.markMissingAssets(missing);
    final counters = _ScanCounters(
      imported: imported,
      updated: updated,
      errors: errors,
      skipped: skipped,
    );
    _report(
      ScanRunState.completed,
      counters,
      discovered: assets.length,
      missing: missing.length,
    );
    return _stats(counters, discovered: assets.length, missing: missing.length);
  }

  PhotoRecord _recordForAsset(
    MediaAsset asset,
    PhotoAiResult ai, {
    String? thumbnailPath,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return PhotoRecord(
      photo: Photo(
        id: asset.id,
        path: asset.path,
        hash: asset.id,
        size: asset.metadata.size,
        mime: asset.metadata.mime ?? mimeFromPath(asset.path),
        thumbnailPath: thumbnailPath,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      metadata: Metadata(
        photoId: asset.id,
        datetime: asset.metadata.datetime,
        lat: asset.metadata.lat,
        lng: asset.metadata.lng,
        camera: asset.metadata.camera,
        confidence: 0.5,
        originalDatetimeText: null,
      ),
      semantic: Semantic(
        photoId: asset.id,
        labels: const <String>[],
        caption: null,
        generatedLabels: ai.generatedLabels,
        generatedCaption: ai.generatedCaption,
        summary: ai.summary,
        embeddingRef: null,
        aiStatus: ai.status,
        aiProvider: ai.provider,
        aiModel: ai.model,
        aiProcessedAt: ai.status == AiPipelineStatus.completed ? now : null,
        aiError: ai.error,
      ),
      indexState: IndexState(
        photoId: asset.id,
        indexed: true,
        aiProcessed: ai.status == AiPipelineStatus.completed,
        error: null,
        lastIndexedAt: now,
        duplicateOf: null,
        sourceUpdatedAt: asset.metadata.updatedAt,
        missingAt: null,
      ),
    );
  }

  String? _writeThumbnail(MediaAsset asset, Uint8List bytes) {
    final directory = thumbnailDirectory;
    final mime = asset.metadata.mime ?? mimeFromPath(asset.path);
    if (directory == null || !mime.startsWith('image/')) return null;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    directory.createSync(recursive: true);
    final thumbnail = img.copyResize(decoded, width: 256);
    final filename =
        '${base64Url.encode(utf8.encode(asset.id)).replaceAll('=', '')}.jpg';
    final file = File('${directory.path}/$filename');
    file.writeAsBytesSync(img.encodeJpg(thumbnail, quality: 82));
    return file.path;
  }

  void _report(
    ScanRunState state,
    _ScanCounters counters, {
    required int discovered,
    required int missing,
    String? message,
  }) {
    onProgress?.call(
      ScanProgress(
        state: state,
        discovered: discovered,
        processed: counters.processed,
        imported: counters.imported,
        updated: counters.updated,
        errors: counters.errors,
        skipped: counters.skipped,
        missing: missing,
        message: message,
      ),
    );
  }

  IndexerStats _stats(
    _ScanCounters counters, {
    required int discovered,
    required int missing,
  }) {
    return IndexerStats(
      discovered: discovered,
      processed: counters.processed,
      imported: counters.imported,
      updated: counters.updated,
      duplicates: 0,
      errors: counters.errors,
      skipped: counters.skipped,
      missing: missing,
    );
  }
}

final class _ScanCounters {
  const _ScanCounters({
    this.imported = 0,
    this.updated = 0,
    this.errors = 0,
    this.skipped = 0,
  });

  final int imported;
  final int updated;
  final int errors;
  final int skipped;

  int get processed => imported + updated + errors;
}
