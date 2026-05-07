import 'dart:io';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'scans a Linux desktop directory and preserves catalog records incrementally',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chronopic-app-linux-scan-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final pngBytes = <int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        0x00,
        0x00,
        0x00,
        0x0d,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1f,
        0x15,
        0xc4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0a,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9c,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0d,
        0x0a,
        0x2d,
        0xb4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4e,
        0x44,
        0xae,
        0x42,
        0x60,
        0x82,
      ];
      await File('${directory.path}/lake.jpg').writeAsBytes(pngBytes);
      await File('${directory.path}/city.png').writeAsBytes(pngBytes);
      await File('${directory.path}/notes.txt').writeAsString('not media');

      final repository = ChronoPicRepository();
      final service = ChronoPicAppService(repository);

      final firstScan = await service.scanDesktopDirectory(directory.path);
      expect(firstScan.discovered, 2);
      expect(firstScan.imported, 2);
      expect(firstScan.updated, 0);
      expect(firstScan.skipped, 0);
      expect(service.listLibrarySources().single.path, directory.path);

      final photos = service.listPhotos(const PhotoFilter(limit: 100));
      expect(
        photos.map(
          (record) =>
              record.photo.path.endsWith('.jpg') ||
              record.photo.path.endsWith('.png'),
        ),
        everyElement(isTrue),
      );
      expect(photos.length, 2);
      expect(
        photos.map((record) => record.photo.thumbnailPath),
        everyElement(isNotNull),
      );
      expect(
        photos.map((record) => File(record.photo.thumbnailPath!).existsSync()),
        everyElement(isTrue),
      );

      final secondScan = await service.scanDesktopDirectory(directory.path);
      expect(secondScan.imported, 0);
      expect(secondScan.updated, 0);
      expect(secondScan.skipped, 2);
      expect(service.createBackup().photos.length, 2);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await File('${directory.path}/lake.jpg').writeAsBytes(pngBytes);
      final changedScan = await service.scanDesktopDirectory(directory.path);
      expect(changedScan.imported, 0);
      expect(changedScan.updated, 1);
      expect(changedScan.skipped, 1);
    },
  );
}
