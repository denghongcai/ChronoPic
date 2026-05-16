import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile app workflows survive backup and restart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final seeded = ChronoPicAppService(ChronoPicRepository());
    await tester.runAsync(() async {
      await seeded.scanMediaSource('mobile-e2e-fixture', _mobileSource());
    });

    final service = _restoredService(seeded.createBackup());
    await _pumpMobileApp(tester, service);

    expect(service.countPhotos(), 25);
    expect(find.byKey(const Key('mobile-browse-surface')), findsOneWidget);
    expect(find.byKey(const Key('mobile-scan-progress-card')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-dashboard-primary-count')),
      findsOneWidget,
    );
    expect(find.text('25 indexed'), findsOneWidget);
    expect(find.text('25 indexed locally'), findsNothing);
    expect(find.text('Ready for local browsing'), findsOneWidget);
    expect(find.text('20 loaded / 25 total'), findsOneWidget);
    expect(find.text('20 indexed'), findsNothing);

    final firstId = service
        .listPhotos(const PhotoFilter(limit: 10))
        .first
        .photo
        .id;
    final secondId = service
        .listPhotos(const PhotoFilter(limit: 10))[1]
        .photo
        .id;

    await _selectPhoto(tester, firstId);
    expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
    await _openAndCloseGallery(tester);
    await _selectPhoto(tester, firstId);

    await _tapVisible(tester, find.byKey(const Key('detail-favorite-button')));
    expect(service.getPhoto(firstId)!.photo.favorite, isTrue);

    await _editSelectedPhoto(tester, service, firstId);
    await _exerciseMemoryLifecycle(tester, service, firstId);
    await _exerciseSearchFilterAndSort(tester, firstId, secondId);
    await _changeLocale(tester, service);

    final restored = _restoredService(service.createBackup());
    await _pumpMobileApp(tester, restored, key: const ValueKey('restored-app'));
    expect(find.text('全部照片'), findsOneWidget);

    final restoredFirst = restored.getPhoto(firstId)!;
    expect(restoredFirst.photo.favorite, isTrue);
    expect(restoredFirst.semantic.caption, 'Mobile E2E Caption');
    expect(
      restoredFirst.semantic.labels,
      containsAll(<String>['e2e', 'mobile']),
    );
    expect(
      restoredFirst.metadata.datetime,
      DateTime(2026, 5, 9, 14, 30).millisecondsSinceEpoch,
    );
    expect(restored.createBackup().settings.locale.locale, LocaleSetting.zhCN);
    expect(restored.listMemories().single.name, 'Mobile E2E Memory Renamed');
    expect(
      restored.listMemories().single.description,
      'Mobile workflow verified.',
    );
  });
}

Future<void> _pumpMobileApp(
  WidgetTester tester,
  ChronoPicAppService service, {
  Key? key,
}) async {
  await tester.pumpWidget(
    ChronoPicHome(
      key: key,
      service: service,
      entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
      mobileMediaSourceFactory: () => _mobileSource(),
    ),
  );
  await tester.pumpAndSettle();
}

ChronoPicAppService _restoredService(ChronoPicBackup backup) {
  final service = ChronoPicAppService(ChronoPicRepository());
  service.restoreBackup(backup);
  return service;
}

Future<void> _selectPhoto(WidgetTester tester, String photoId) async {
  final card = find.byKey(Key('photo-card-$photoId'));
  await _scrollHomeUntilVisible(tester, card);
  await tester.tap(card);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 360));
}

Future<void> _openAndCloseGallery(WidgetTester tester) async {
  await _tapVisible(tester, find.byKey(const Key('open-gallery-button')).first);
  expect(find.byKey(const Key('gallery-dialog')), findsOneWidget);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('gallery-dialog')), findsNothing);
}

Future<void> _editSelectedPhoto(
  WidgetTester tester,
  ChronoPicAppService service,
  String photoId,
) async {
  await _enterVisibleText(
    tester,
    find.byKey(const Key('caption-field')),
    'Mobile E2E Caption',
  );
  await _tapVisible(tester, find.byKey(const Key('save-caption-button')));
  expect(service.getPhoto(photoId)!.semantic.caption, 'Mobile E2E Caption');

  await _enterVisibleText(
    tester,
    find.byKey(const Key('tags-field')),
    'e2e, mobile',
  );
  await _tapVisible(tester, find.byKey(const Key('save-tags-button')));
  expect(service.getPhoto(photoId)!.semantic.labels, <String>['e2e', 'mobile']);

  await _enterVisibleText(
    tester,
    find.byKey(const Key('date-field')),
    '2026-05-09',
  );
  await _enterVisibleText(tester, find.byKey(const Key('time-field')), '14:30');
  await _tapVisible(tester, find.byKey(const Key('save-datetime-button')));
  expect(
    service.getPhoto(photoId)!.metadata.datetime,
    DateTime(2026, 5, 9, 14, 30).millisecondsSinceEpoch,
  );
}

Future<void> _exerciseMemoryLifecycle(
  WidgetTester tester,
  ChronoPicAppService service,
  String photoId,
) async {
  await _tapVisible(
    tester,
    find.byKey(const Key('focused-detail-close-button')),
  );
  await _tapVisible(tester, find.byKey(const Key('mobile-shortcut-memories')));
  await _tapVisible(tester, find.byKey(const Key('mobile-create-memory')));
  expect(find.byKey(const Key('mobile-memory-creation-sheet')), findsOneWidget);
  expect(find.byKey(const Key('mobile-memory-step-select')), findsOneWidget);
  await _tapVisible(tester, find.byKey(Key('mobile-memory-select-$photoId')));
  await _tapVisible(tester, find.byKey(const Key('mobile-memory-next')));
  await _enterVisibleText(
    tester,
    find.byKey(const Key('mobile-memory-title-field')),
    'Mobile E2E Memory',
  );
  await _enterVisibleText(
    tester,
    find.byKey(const Key('mobile-memory-description-field')),
    'Mobile workflow verified.',
  );
  await _tapVisible(tester, find.byKey(Key('mobile-memory-cover-$photoId')));
  await _tapVisible(tester, find.byKey(const Key('mobile-memory-next')));
  expect(find.byKey(const Key('mobile-memory-step-confirm')), findsOneWidget);
  await _tapVisible(
    tester,
    find.byKey(const Key('mobile-memory-create-confirm')),
  );

  final memory = service.listMemories().single;
  expect(find.byKey(const Key('memory-detail-panel')), findsOneWidget);
  expect(service.createBackup().memoryPhotos.single.photoId, photoId);
  expect(service.getMemory(memory.id)!.coverPhotoId, photoId);

  await _enterVisibleText(
    tester,
    find.byKey(const Key('memory-title-field')),
    'Mobile E2E Memory Renamed',
  );
  await _enterVisibleText(
    tester,
    find.byKey(const Key('memory-description-field')),
    'Mobile workflow verified.',
  );
  await _tapVisible(tester, find.byKey(const Key('save-memory-button')));
  expect(service.getMemory(memory.id)!.name, 'Mobile E2E Memory Renamed');
  expect(
    service.getMemory(memory.id)!.description,
    'Mobile workflow verified.',
  );

  await _tapVisible(tester, find.byKey(const Key('remove-from-memory-button')));
  expect(service.createBackup().memoryPhotos, isEmpty);
}

Future<void> _exerciseSearchFilterAndSort(
  WidgetTester tester,
  String firstId,
  String secondId,
) async {
  await _tapVisible(tester, find.byKey(const Key('mobile-bottom-waterfall')));
  await _tapVisible(tester, find.byKey(const Key('mobile-shortcut-all')));
  await _enterVisibleText(
    tester,
    find.byKey(const Key('mobile-dashboard-search')),
    'Mobile E2E Caption',
  );
  await tester.pumpAndSettle();
  expect(find.byKey(Key('photo-card-$firstId')), findsOneWidget);
  expect(find.byKey(Key('photo-card-$secondId')), findsNothing);

  await _tapVisible(tester, find.byKey(const Key('filter-toggle-button')));
  await _enterVisibleText(
    tester,
    find.byKey(const Key('tag-filter-field')),
    'e2e',
  );
  await _tapVisible(tester, find.byKey(const Key('apply-filter-button')));
  expect(find.byKey(Key('active-filter-Tag: e2e')), findsOneWidget);

  await _tapVisible(tester, find.byKey(const Key('filter-toggle-button')));
  await _tapVisible(tester, find.byKey(const Key('sort-direction-control')));
  await _tapVisible(tester, find.text('Asc').last);
  await _tapVisible(tester, find.byKey(const Key('apply-filter-button')));
  expect(
    find.byKey(const Key('active-filter-Sort: datetime Asc')),
    findsOneWidget,
  );
}

Future<void> _changeLocale(
  WidgetTester tester,
  ChronoPicAppService service,
) async {
  await _tapVisible(tester, find.byKey(const Key('mobile-bottom-settings')));
  await _tapVisible(tester, find.byKey(const Key('mobile-settings-language')));
  await _tapVisible(tester, find.byKey(const Key('interface-locale-control')));
  await _tapVisible(tester, find.text('中文').last);
  await _tapVisible(
    tester,
    find.byKey(const Key('save-locale-settings-button')),
  );
  expect(service.createBackup().settings.locale.locale, LocaleSetting.zhCN);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollHomeUntilVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      520,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('home-page')),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 12,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pump();
}

Future<void> _enterVisibleText(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

FixtureMediaSource _mobileSource({int count = 25}) {
  final ids = List<String>.generate(count, (index) => 'asset-${index + 1}');
  return FixtureMediaSource(
    supportsLazyThumbnails: true,
    assets: <MediaAsset>[
      for (final (index, id) in ids.indexed)
        _asset(id, updatedAt: (index + 1) * 1000),
    ],
    bytesById: <String, Uint8List>{
      for (final (index, id) in ids.indexed)
        id: Uint8List.fromList(<int>[index + 1, index + 2, index + 3]),
    },
  );
}

MediaAsset _asset(String id, {required int updatedAt}) {
  return MediaAsset(
    id: id,
    path: 'asset://$id',
    metadata: MediaAssetMetadata(
      size: 3,
      updatedAt: updatedAt,
      mime: 'video/mp4',
      datetime: updatedAt,
    ),
  );
}
