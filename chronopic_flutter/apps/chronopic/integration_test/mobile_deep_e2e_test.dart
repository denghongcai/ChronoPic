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

    expect(find.byKey(const Key('mobile-browse-surface')), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);

    final firstId = service
        .listPhotos(
          const PhotoFilter(
            sortBy: PhotoSortBy.path,
            sortDirection: SortDirection.asc,
            limit: 10,
          ),
        )
        .first
        .photo
        .id;
    final secondId = service
        .listPhotos(
          const PhotoFilter(
            sortBy: PhotoSortBy.path,
            sortDirection: SortDirection.asc,
            limit: 10,
          ),
        )[1]
        .photo
        .id;

    await _selectPhoto(tester, firstId);
    expect(
      find.byKey(const Key('browse-selected-photo-banner')),
      findsOneWidget,
    );

    await _openAndCloseFocusedDetail(tester, firstId);
    await _openAndCloseGallery(tester);

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
  await _tapVisible(tester, card);
  await tester.pump(const Duration(milliseconds: 360));
}

Future<void> _openAndCloseFocusedDetail(
  WidgetTester tester,
  String photoId,
) async {
  final card = find.byKey(Key('photo-card-$photoId'));
  expect(card, findsOneWidget);
  final cardGesture = find.descendant(
    of: card,
    matching: find.byKey(const Key('mobile-open-detail')),
  );
  await tester.ensureVisible(cardGesture);
  await tester.pump();
  await tester.tap(cardGesture);
  await tester.pump(const Duration(milliseconds: 80));
  await tester.tap(cardGesture);
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
  await _tapVisible(
    tester,
    find.byKey(const Key('focused-detail-close-button')),
  );
  expect(find.byKey(const Key('focused-detail-view')), findsNothing);
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
  await _tapVisible(tester, find.byKey(const Key('memories-nav')));
  await _enterVisibleText(
    tester,
    find.byKey(const Key('memory-name-field')),
    'Mobile E2E Memory',
  );
  await _tapVisible(tester, find.byKey(const Key('mobile-create-memory')));

  final memory = service.listMemories().single;
  expect(find.byKey(const Key('memory-detail-panel')), findsOneWidget);

  await _tapVisible(tester, find.byKey(const Key('add-to-memory-button')));
  expect(service.createBackup().memoryPhotos.single.photoId, photoId);

  await _tapVisible(tester, find.byKey(const Key('set-memory-cover-button')));
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
  await _tapVisible(tester, find.byKey(const Key('all-photos-nav')));
  await _enterVisibleText(
    tester,
    find.byKey(const Key('search-field')),
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

  await _tapVisible(tester, find.byKey(const Key('sort-direction-control')));
  await _tapVisible(tester, find.text('Asc').last);
  expect(find.text('Asc'), findsWidgets);
}

Future<void> _changeLocale(
  WidgetTester tester,
  ChronoPicAppService service,
) async {
  await _tapVisible(tester, find.byKey(const Key('settings-nav')));
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

FixtureMediaSource _mobileSource() {
  return FixtureMediaSource(
    assets: <MediaAsset>[
      _asset('asset-1', updatedAt: 1000),
      _asset('asset-2', updatedAt: 2000),
    ],
    bytesById: <String, Uint8List>{
      'asset-1': Uint8List.fromList(<int>[1, 2, 3]),
      'asset-2': Uint8List.fromList(<int>[4, 5, 6]),
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
