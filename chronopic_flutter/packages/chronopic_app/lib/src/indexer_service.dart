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

final class ChronoPicIndexerService {
  ChronoPicIndexerService({
    required this.repository,
    required this.mediaSource,
    required this.aiClient,
    this.thumbnailDirectory,
  });

  final ChronoPicRepository repository;
  final MediaSourceAdapter mediaSource;
  final ChronoPicAiClient aiClient;
  final Directory? thumbnailDirectory;

  Future<IndexerStats> scanLibrary() async {
    final assets = await mediaSource.listAssets();
    var imported = 0;
    var updated = 0;
    var skipped = 0;
    var errors = 0;
    final seen = <String>{};

    for (final asset in assets) {
      seen.add(asset.id);
      final previous = repository.getPhoto(asset.id);
      final unchanged =
          previous?.indexState.sourceUpdatedAt == asset.metadata.updatedAt &&
          previous?.indexState.missingAt == null;
      if (unchanged) {
        skipped += 1;
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
    }

    final knownIds = repository
        .listPhotos(const PhotoFilter(limit: 1000000))
        .map((record) => record.photo.id)
        .toSet();
    final missing = await mediaSource.listMissingAssetIds(
      knownIds.difference(seen),
    );
    repository.markMissingAssets(missing);
    return IndexerStats(
      discovered: assets.length,
      processed: assets.length - skipped,
      imported: imported,
      updated: updated,
      duplicates: 0,
      errors: errors,
      skipped: skipped,
      missing: missing.length,
    );
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
}
