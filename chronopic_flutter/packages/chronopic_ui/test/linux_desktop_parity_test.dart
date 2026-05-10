import 'dart:convert';
import 'dart:io';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pngBytes = <int>[
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

void main() {
  testWidgets('runs a Linux directory scan from the Flutter UI controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late final Directory directory;
    late final File lake;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp(
        'chronopic-linux-ui-scan-',
      );
      lake = File('${directory.path}/lake.jpg');
      await lake.writeAsBytes(_pngBytes);
      await File('${directory.path}/city.png').writeAsBytes(_pngBytes);
      await File('${directory.path}/clip.mp4').writeAsBytes(<int>[1, 2, 3]);
      await File('${directory.path}/notes.txt').writeAsString('not media');
    });
    addTearDown(() => directory.delete(recursive: true));

    final repository = ChronoPicRepository();
    final service = ChronoPicAppService(repository);

    await tester.pumpWidget(ChronoPicHome(service: service));
    expect(find.text('Start with a local folder'), findsOneWidget);
    expect(
      find.byKey(const Key('choose-library-folder-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('library-path-field')), findsNothing);

    await tester.tap(find.byKey(const Key('settings-nav')));
    await tester.pump();
    expect(find.text('Add Library'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('library-path-field')),
      directory.path,
    );
    await tester.ensureVisible(find.byKey(const Key('add-library-button')));
    await tester.tap(find.byKey(const Key('add-library-button')));
    await tester.pump();
    expect(find.textContaining('Added library:'), findsOneWidget);
    expect(service.listLibrarySources().single.path, directory.path);

    final scanButton = find.byKey(const Key('scan-library-button'));
    await tester.ensureVisible(scanButton);
    await tester.runAsync(() async {
      await tester.tap(scanButton);
      for (var attempt = 0; attempt < 40; attempt += 1) {
        if (service.listPhotos(const PhotoFilter(limit: 10)).length == 3) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Scan complete: 3 imported, 0 updated, 0 skipped'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();
    expect(find.text('lake.jpg'), findsOneWidget);
    expect(find.text('city.png'), findsOneWidget);
    expect(find.text('clip.mp4'), findsOneWidget);
    expect(find.text('notes.txt'), findsNothing);
    await tester.tap(find.byKey(const Key('notifications-nav')));
    await tester.pump();
    expect(find.byKey(const Key('notification-center-panel')), findsOneWidget);
    expect(find.text('Memory candidates: 0'), findsOneWidget);
    expect(find.byKey(const Key('ai-provider-field')), findsNothing);
    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();
    expect(
      find.byKey(Key('media-preview-${lake.absolute.path}')),
      findsOneWidget,
    );

    final records = service.listPhotos(const PhotoFilter(limit: 10));
    expect(records, hasLength(3));
    final imageRecords = records.where(
      (record) => record.photo.mime.startsWith('image/'),
    );
    expect(
      imageRecords.map((record) => record.photo.thumbnailPath),
      everyElement(isNotNull),
    );
    expect(
      imageRecords.map(
        (record) => File(record.photo.thumbnailPath!).existsSync(),
      ),
      everyElement(isTrue),
    );
    final video = records.singleWhere(
      (record) => record.photo.path.endsWith('clip.mp4'),
    );
    expect(find.byKey(Key('video-preview-${video.photo.id}')), findsOneWidget);

    final first = records.first;
    final second = records[1];
    final firstCard = find.byKey(Key('photo-card-${first.photo.id}'));
    await _scrollHomeUntilVisible(tester, firstCard);
    await tester.tap(firstCard);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('gallery-dialog')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
    expect(find.byKey(const Key('focused-detail-inspector')), findsOneWidget);
    expect(
      find.byKey(const Key('focused-detail-gallery-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('focused-detail-gallery-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-dialog')), findsOneWidget);
    expect(find.byKey(const Key('gallery-counter')), findsOneWidget);
    expect(find.byKey(const Key('gallery-keyboard-hint')), findsOneWidget);
    expect(find.byKey(const Key('gallery-filmstrip')), findsOneWidget);
    expect(find.byKey(const Key('gallery-captured-at')), findsOneWidget);
    expect(find.byKey(const Key('gallery-memory-badge')), findsOneWidget);
    expect(find.byKey(const Key('open-inspector-button')), findsOneWidget);
    expect(find.byKey(Key('gallery-title-${first.photo.id}')), findsOneWidget);
    expect(
      find.byKey(Key('gallery-filmstrip-${second.photo.id}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('next-gallery-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gallery-title-${second.photo.id}')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gallery-title-${first.photo.id}')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gallery-title-${second.photo.id}')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-dialog')), findsNothing);
    expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focused-detail-view')), findsNothing);

    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('open-gallery-button')),
    );
    await tester.tap(find.byKey(const Key('open-gallery-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-dialog')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-dialog')), findsNothing);
    expect(find.text(second.photo.path), findsOneWidget);
  });

  testWidgets('renders and filters a real scanned Linux desktop directory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late final Directory directory;
    late final File lake;
    final repository = ChronoPicRepository();
    final service = ChronoPicAppService(repository);
    final stats = (await tester.runAsync<IndexerStats>(() async {
      directory = await Directory.systemTemp.createTemp(
        'chronopic-linux-parity-',
      );
      lake = File('${directory.path}/lake.jpg');
      await lake.writeAsBytes(_pngBytes);
      await File('${directory.path}/city.png').writeAsBytes(_pngBytes);
      await File('${directory.path}/notes.txt').writeAsString('not media');
      return service.scanDesktopDirectory(directory.path);
    }))!;
    addTearDown(() => directory.delete(recursive: true));
    expect(stats.imported, 2);

    await tester.pumpWidget(ChronoPicHome(service: service));
    expect(find.text('lake.jpg'), findsOneWidget);
    expect(find.text('city.png'), findsOneWidget);
    expect(find.text('notes.txt'), findsNothing);
    expect(
      find.byKey(Key('media-preview-${lake.absolute.path}')),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'lake');
    await tester.pump();
    expect(find.text('lake.jpg'), findsOneWidget);
    expect(find.text('city.png'), findsNothing);

    final lakeCard = find.byKey(Key('photo-card-${lake.absolute.path}'));
    await _scrollHomeUntilVisible(tester, lakeCard);
    await tester.tap(lakeCard);
    await tester.pump();
    await _scrollHomeUntilVisible(tester, find.byKey(const Key('date-field')));
    await tester.enterText(find.byKey(const Key('date-field')), '2024-03-09');
    await tester.enterText(find.byKey(const Key('time-field')), '12:30');
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('save-datetime-button')),
    );
    await tester.tap(find.byKey(const Key('save-datetime-button')));
    await tester.pump();
    final correctedDatetime = DateTime(
      2024,
      3,
      9,
      12,
      30,
    ).millisecondsSinceEpoch;
    expect(
      service.getPhoto(lake.absolute.path)?.metadata.datetime,
      correctedDatetime,
    );
    expect(find.byKey(const Key('metadata-grid')), findsOneWidget);
    expect(find.textContaining('Captured: 2024-03-09 12:30'), findsOneWidget);
    expect(find.textContaining('Time zone: UTC'), findsOneWidget);
    expect(find.textContaining('MIME: image/'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('date-field')), '2024-02-31');
    await tester.enterText(find.byKey(const Key('time-field')), '25:99');
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('save-datetime-button')),
    );
    await tester.tap(find.byKey(const Key('save-datetime-button')));
    await tester.pump();
    expect(
      find.textContaining('Datetime must use YYYY-MM-DD and HH:mm'),
      findsOneWidget,
    );
    expect(
      service.getPhoto(lake.absolute.path)?.metadata.datetime,
      correctedDatetime,
    );
    await tester.tap(find.byKey(const Key('open-gallery-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-inspector-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focused-detail-view')), findsNothing);
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('rollback-button')),
    );
    await tester.tap(find.byKey(const Key('rollback-button')));
    await tester.pump();
    expect(
      service.getPhoto(lake.absolute.path)?.metadata.datetime,
      isNot(correctedDatetime),
    );
    await tester.enterText(
      find.byKey(const Key('caption-field')),
      'Linux parity lake',
    );
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('save-caption-button')),
    );
    await tester.tap(find.byKey(const Key('save-caption-button')));
    await tester.pump();
    expect(find.textContaining('Saved caption'), findsOneWidget);
    expect(
      service.getPhoto(lake.absolute.path)?.semantic.caption,
      'Linux parity lake',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('caption-field')))
          .controller
          ?.text,
      'Linux parity lake',
    );
    await tester.enterText(find.byKey(const Key('caption-field')), 'x' * 161);
    await tester.tap(find.byKey(const Key('save-caption-button')));
    await tester.pump();
    expect(
      find.textContaining('Caption must be 160 characters or fewer'),
      findsOneWidget,
    );
    expect(
      service.getPhoto(lake.absolute.path)?.semantic.caption,
      'Linux parity lake',
    );
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('rollback-button')),
    );
    await tester.tap(find.byKey(const Key('rollback-button')));
    await tester.pump();
    expect(service.getPhoto(lake.absolute.path)?.semantic.caption, isNull);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('caption-field')))
          .controller
          ?.text,
      isEmpty,
    );

    await tester.enterText(
      find.byKey(const Key('tags-field')),
      'linux, Linux, parity',
    );
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('save-tags-button')),
    );
    await tester.tap(find.byKey(const Key('save-tags-button')));
    await tester.pump();
    expect(find.textContaining('Saved tags: 2'), findsOneWidget);
    expect(service.getPhoto(lake.absolute.path)?.semantic.labels, <String>[
      'linux',
      'parity',
    ]);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('tags-field')))
          .controller
          ?.text,
      'linux, parity',
    );
    await tester.enterText(
      find.byKey(const Key('tags-field')),
      'this-tag-name-is-longer-than-thirty-two-characters',
    );
    await tester.tap(find.byKey(const Key('save-tags-button')));
    await tester.pump();
    expect(
      find.textContaining('Tags must be 32 characters or fewer'),
      findsOneWidget,
    );
    expect(service.getPhoto(lake.absolute.path)?.semantic.labels, <String>[
      'linux',
      'parity',
    ]);
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('rollback-button')),
    );
    await tester.tap(find.byKey(const Key('rollback-button')));
    await tester.pump();
    expect(service.getPhoto(lake.absolute.path)?.semantic.labels, isEmpty);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('tags-field')))
          .controller
          ?.text,
      isEmpty,
    );
    await tester.enterText(
      find.byKey(const Key('tags-field')),
      'linux, parity',
    );
    await tester.tap(find.byKey(const Key('save-tags-button')));
    await tester.pump();

    await _scrollHomeToTop(tester);
    await tester.enterText(find.byKey(const Key('search-field')), '');
    await tester.pump();
    expect(find.text('city.png'), findsOneWidget);

    final filterToggle = find.byKey(const Key('filter-toggle-button'));
    await _scrollHomeUntilVisible(tester, filterToggle);
    await tester.tap(filterToggle);
    await tester.pump();
    final tagFilterField = find.byKey(const Key('tag-filter-field'));
    final applyFilterButton = find.byKey(const Key('apply-filter-button'));
    final clearFilterButton = find.byKey(const Key('clear-filter-button'));
    await _scrollHomeUntilVisible(tester, tagFilterField);
    await tester.enterText(tagFilterField, 'linux');
    await _scrollHomeUntilVisible(tester, applyFilterButton);
    _pressButton(tester, applyFilterButton);
    await tester.pump();
    expect(find.text('lake.jpg'), findsOneWidget);
    expect(find.text('city.png'), findsNothing);
    expect(find.byKey(const Key('active-filter-summary')), findsOneWidget);
    expect(find.text('Tag: linux'), findsOneWidget);
    await _scrollHomeUntilVisible(tester, clearFilterButton);
    await tester.pumpAndSettle();
    _pressButton(tester, clearFilterButton);
    await tester.pump();
    expect(find.text('city.png'), findsOneWidget);

    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('gps-filter-chip')),
    );
    await tester.tap(find.byKey(const Key('gps-filter-chip')));
    await _scrollHomeUntilVisible(tester, applyFilterButton);
    _pressButton(tester, applyFilterButton);
    await tester.pump();
    expect(find.text('lake.jpg'), findsNothing);
    expect(find.text('city.png'), findsNothing);
    await _scrollHomeUntilVisible(tester, clearFilterButton);
    await tester.pumpAndSettle();
    _pressButton(tester, clearFilterButton);
    await tester.pump();

    final aiStatusControl = find.byKey(const Key('ai-status-filter-control'));
    await _scrollHomeUntilVisible(tester, aiStatusControl);
    tester
        .widget<DropdownButton<AiPipelineStatus?>>(aiStatusControl)
        .onChanged!(AiPipelineStatus.disabled);
    await tester.pump();
    await _scrollHomeUntilVisible(tester, applyFilterButton);
    _pressButton(tester, applyFilterButton);
    await tester.pump();
    expect(find.text('lake.jpg'), findsOneWidget);
    expect(find.text('city.png'), findsOneWidget);

    tester
        .widget<DropdownButton<AiPipelineStatus?>>(aiStatusControl)
        .onChanged!(AiPipelineStatus.completed);
    await tester.pump();
    await _scrollHomeUntilVisible(tester, applyFilterButton);
    _pressButton(tester, applyFilterButton);
    await tester.pump();
    expect(find.text('lake.jpg'), findsNothing);
    expect(find.text('city.png'), findsNothing);
    await _scrollHomeUntilVisible(tester, clearFilterButton);
    _pressButton(tester, clearFilterButton);
    await tester.pump();

    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('from-date-filter-field')),
    );
    await tester.enterText(
      find.byKey(const Key('from-date-filter-field')),
      '2024-02-31',
    );
    await _scrollHomeUntilVisible(tester, applyFilterButton);
    _pressButton(tester, applyFilterButton);
    await tester.pump();
    expect(
      find.textContaining('Date filters must use YYYY-MM-DD'),
      findsOneWidget,
    );
    await _scrollHomeUntilVisible(tester, clearFilterButton);
    await tester.pumpAndSettle();
    _pressButton(tester, clearFilterButton);
    await tester.pump();

    await _scrollHomeUntilVisible(tester, lakeCard);
    await tester.tap(lakeCard);
    await tester.pump();
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('detail-favorite-button')),
    );
    await tester.tap(find.byKey(const Key('detail-favorite-button')));
    await tester.pump();
    expect(service.getPhoto(lake.absolute.path)?.photo.favorite, isTrue);
    expect(find.text('Unfavorite'), findsWidgets);
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('rollback-button')),
    );
    await tester.tap(find.byKey(const Key('rollback-button')));
    await tester.pump();
    expect(service.getPhoto(lake.absolute.path)?.photo.favorite, isFalse);
    expect(find.text('Favorite'), findsWidgets);
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('detail-favorite-button')),
    );
    await tester.tap(find.byKey(const Key('detail-favorite-button')));
    await tester.pump();
    expect(service.getPhoto(lake.absolute.path)?.photo.favorite, isTrue);
    await tester.tap(find.byKey(const Key('favorites-nav')));
    await tester.pump();
    expect(find.text('lake.jpg'), findsOneWidget);
    expect(find.text('city.png'), findsNothing);
    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('memories-nav')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('memory-name-field')),
      'Linux Trip',
    );
    await tester.tap(find.byKey(const Key('create-memory-button')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('add-to-memory-button')));
    await tester.tap(find.byKey(const Key('add-to-memory-button')));
    await tester.pump();
    expect(service.createBackup().memories.single.name, 'Linux Trip');
    expect(
      service.createBackup().memoryPhotos.single.photoId,
      lake.absolute.path,
    );
    expect(find.byKey(const Key('memory-detail-panel')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('memory-title-field')),
      'Linux Trip Renamed',
    );
    await tester.enterText(
      find.byKey(const Key('memory-description-field')),
      'Desktop memory description',
    );
    await tester.ensureVisible(find.byKey(const Key('save-memory-button')));
    await tester.tap(find.byKey(const Key('save-memory-button')));
    await tester.pump();
    expect(service.createBackup().memories.single.name, 'Linux Trip Renamed');
    expect(
      service.createBackup().memories.single.description,
      'Desktop memory description',
    );
    await tester.ensureVisible(
      find.byKey(const Key('set-memory-cover-button')),
    );
    tester
        .widget<OutlinedButton>(
          find.byKey(const Key('set-memory-cover-button')),
        )
        .onPressed!();
    await tester.pump();
    expect(
      service.createBackup().memories.single.coverPhotoId,
      lake.absolute.path,
    );
    await tester.ensureVisible(
      find.byKey(const Key('remove-from-memory-button')),
    );
    tester
        .widget<OutlinedButton>(
          find.byKey(const Key('remove-from-memory-button')),
        )
        .onPressed!();
    await tester.pump();
    expect(service.createBackup().memoryPhotos, isEmpty);
    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();
    await _scrollHomeUntilVisible(tester, lakeCard);
    await tester.tap(lakeCard);
    await tester.pump();

    await tester.tap(find.byKey(const Key('settings-nav')));
    await tester.pump();
    final backupFile = File('${directory.path}/chronopic-backup.json');
    await tester.enterText(
      find.byKey(const Key('backup-path-field')),
      backupFile.path,
    );
    await tester.ensureVisible(find.byKey(const Key('export-backup-file')));
    await tester.tap(find.byKey(const Key('export-backup-file')));
    await tester.pump();
    expect(find.textContaining('Exported backup file:'), findsOneWidget);
    expect(backupFile.existsSync(), isTrue);
    final exportedJson =
        jsonDecode(backupFile.readAsStringSync()) as Map<String, Object?>;
    final liveJson = service.createBackup().toJson();
    expect(exportedJson['photos'], liveJson['photos']);
    expect(exportedJson['memories'], liveJson['memories']);
    expect(exportedJson['memoryPhotos'], liveJson['memoryPhotos']);
    expect(exportedJson['settings'], liveJson['settings']);
    await tester.ensureVisible(find.byKey(const Key('preview-backup-file')));
    await tester.tap(find.byKey(const Key('preview-backup-file')));
    await tester.pump();
    expect(
      find.textContaining('Preview restore: 2 photos, 1 memories'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();
    await _scrollHomeUntilVisible(tester, lakeCard);
    await tester.tap(lakeCard);
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('caption-field')),
      'Unsaved after export',
    );
    await _scrollHomeUntilVisible(
      tester,
      find.byKey(const Key('save-caption-button')),
    );
    await tester.tap(find.byKey(const Key('save-caption-button')));
    await tester.pump();
    expect(
      service.getPhoto(lake.absolute.path)?.semantic.caption,
      'Unsaved after export',
    );
    await tester.tap(find.byKey(const Key('settings-nav')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('restore-backup-file')));
    await tester.tap(find.byKey(const Key('restore-backup-file')));
    await tester.pump();
    expect(
      find.textContaining('Restored backup: 2 photos, 1 memories'),
      findsOneWidget,
    );
    expect(service.getPhoto(lake.absolute.path)?.semantic.caption, isNull);

    final malformedBackupFile = File('${directory.path}/malformed-backup.json');
    await tester.runAsync(
      () => malformedBackupFile.writeAsString('{not valid json'),
    );
    await tester.enterText(
      find.byKey(const Key('backup-path-field')),
      malformedBackupFile.path,
    );
    await tester.tap(find.byKey(const Key('preview-backup-file')));
    await tester.pump();
    expect(find.textContaining('Preview restore failed:'), findsOneWidget);

    final backup = repository.createBackup();
    expect(backup.photos.length, 2);
    expect(
      backup.photos.any((record) => record.photo.path == lake.absolute.path),
      isTrue,
    );
  });

  testWidgets('reloads persisted desktop edits in a fresh Flutter shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late final Directory directory;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp(
        'chronopic-ui-restart-',
      );
    });
    addTearDown(() => directory.delete(recursive: true));
    final dataFile = File('${directory.path}/chronopic-state.json');
    final backup = _fixtureBackup();
    final firstService = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: dataFile.path,
    )..restoreBackup(backup);
    firstService.updatePhotoCaption('photo-city', 'Persisted city caption');
    firstService.updatePhotoTags('photo-city', <String>['persisted']);
    firstService.updatePhotoFavorite('photo-city', true);
    final memory = firstService.createMemory('Restart Memory');
    firstService.addPhotoToMemory(memory.id, 'photo-city');

    expect(dataFile.existsSync(), isTrue);

    final restartedService = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: dataFile.path,
    );
    await tester.pumpWidget(ChronoPicHome(service: restartedService));
    await tester.pump();

    expect(find.text('Persisted city caption'), findsOneWidget);
    await tester.tap(find.byKey(const Key('favorites-nav')));
    await tester.pump();
    expect(find.text('Persisted city caption'), findsOneWidget);
    expect(find.text('Manual lake caption'), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo-card-photo-city')));
    await tester.pump();
    expect(find.text('Persisted city caption'), findsWidgets);
    expect(find.textContaining('persisted'), findsOneWidget);
    expect(
      restartedService.listMemories().map((memory) => memory.name),
      contains('Restart Memory'),
    );
    expect(
      restartedService.listPhotos(PhotoFilter(memoryId: memory.id)),
      isNotEmpty,
    );
  });

  testWidgets('renders a larger scanned Linux library with adaptive grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late final Directory directory;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp(
        'chronopic-large-linux-library-',
      );
      for (var index = 0; index < 25; index += 1) {
        final padded = index.toString().padLeft(2, '0');
        await File(
          '${directory.path}/photo-$padded.png',
        ).writeAsBytes(_pngBytes);
      }
    });
    addTearDown(() => directory.delete(recursive: true));

    final service = ChronoPicAppService(ChronoPicRepository());
    final stats = (await tester.runAsync<IndexerStats>(
      () => service.scanDesktopDirectory(directory.path),
    ))!;
    expect(stats.imported, 25);

    await tester.pumpWidget(ChronoPicHome(service: service));
    expect(service.listPhotos(const PhotoFilter(limit: 100)).length, 25);
    expect(find.byKey(const Key('photo-grid')), findsOneWidget);
    expect(_photoGridColumns(tester), 3);
    expect(find.text('20 items'), findsOneWidget);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -5000),
      10000,
    );
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('home-page')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    scrollable.position.jumpTo(0);
    await tester.pump();
    expect(find.text('25 items'), findsOneWidget);

    tester.view.physicalSize = const Size(840, 1200);
    await tester.pump();
    expect(_photoGridColumns(tester), 1);
  });
}

ChronoPicBackup _fixtureBackup({
  LocaleSetting locale = LocaleSetting.enUS,
  AiOutputLocale aiOutputLocale = AiOutputLocale.followUi,
}) {
  final backup = ChronoPicBackup.fromJson(
    FlutterParityFixtures.readBackupJson(),
  );
  return ChronoPicBackup(
    app: backup.app,
    schemaVersion: backup.schemaVersion,
    exportedAt: backup.exportedAt,
    settings: BackupSettings(
      ai: backup.settings.ai,
      map: backup.settings.map,
      locale: LocaleSettings(locale: locale, aiOutputLocale: aiOutputLocale),
    ),
    librarySources: backup.librarySources,
    photos: backup.photos,
    memories: backup.memories,
    memoryPhotos: backup.memoryPhotos,
    editHistory: backup.editHistory,
    memoryCandidates: backup.memoryCandidates,
  );
}

int _photoGridColumns(WidgetTester tester) {
  final grid = tester.widget<SliverGrid>(find.byKey(const Key('photo-grid')));
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

Future<void> _scrollHomeUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    260,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('home-page')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
}

Future<void> _scrollHomeToTop(WidgetTester tester) async {
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byKey(const Key('home-page')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  scrollable.position.jumpTo(0);
  await tester.pump();
}

void _pressButton(WidgetTester tester, Finder finder) {
  tester.widget<ButtonStyleButton>(finder).onPressed!();
}
