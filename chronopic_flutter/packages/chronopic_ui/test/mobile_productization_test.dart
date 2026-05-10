import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile first run uses photo library as the primary entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChronoPicHome(
        service: ChronoPicAppService(ChronoPicRepository()),
        entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
        mobileMediaSourceFactory: () => _mobileSource(),
      ),
    );

    expect(find.text('Choose Photos'), findsOneWidget);
    expect(find.byKey(const Key('mobile-entry-actions')), findsOneWidget);
    expect(
      find.byKey(const Key('choose-photo-library-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('choose-photos-button')), findsOneWidget);
    expect(find.byKey(const Key('mobile-choose-photos')), findsOneWidget);
    expect(find.byKey(const Key('add-library-button')), findsNothing);
    expect(find.byKey(const Key('choose-library-folder-button')), findsNothing);
    expect(find.text('Start with your photo library'), findsOneWidget);
  });

  testWidgets('mobile photo library scan reports limited progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final service = ChronoPicAppService(ChronoPicRepository());
    await tester.pumpWidget(
      ChronoPicHome(
        service: service,
        entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
        mobileMediaSourceFactory: () =>
            _mobileSource(permissionState: MediaSourcePermissionState.limited),
      ),
    );

    await tester.tap(find.byKey(const Key('choose-photo-library-button')));
    await tester.pump();
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 40; attempt += 1) {
        if (service.listPhotos(const PhotoFilter(limit: 10)).length == 2) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(service.listPhotos(const PhotoFilter(limit: 10)), hasLength(2));
    expect(find.textContaining('Limited photo access'), findsOneWidget);
    expect(find.textContaining('2 imported'), findsOneWidget);
    expect(find.byKey(const Key('mobile-browse-surface')), findsOneWidget);
    expect(find.byKey(const Key('mobile-select-mode')), findsOneWidget);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -900),
      10000,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-open-detail')), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const Key('mobile-open-detail')).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-open-detail')).first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
    expect(find.byKey(const Key('focused-detail-inspector')), findsOneWidget);
    expect(find.byKey(const Key('mobile-open-gallery')), findsWidgets);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focused-detail-view')), findsNothing);

    await tester.tap(find.byKey(const Key('memories-nav')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memories-page')), findsOneWidget);
    expect(find.byKey(const Key('mobile-create-memory')), findsOneWidget);
  });

  testWidgets('mobile browse starts at 20 items and lazy-loads more', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final service = ChronoPicAppService(ChronoPicRepository());
    await tester.pumpWidget(
      ChronoPicHome(
        service: service,
        entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
        mobileMediaSourceFactory: () => _mobileSource(count: 25),
      ),
    );

    await tester.tap(find.byKey(const Key('choose-photo-library-button')));
    await tester.pump();
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 80; attempt += 1) {
        if (service.listPhotos(const PhotoFilter(limit: 30)).length == 25) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(service.listPhotos(const PhotoFilter(limit: 30)), hasLength(25));
    expect(find.byKey(const Key('mobile-browse-surface')), findsOneWidget);
    expect(find.byKey(const Key('filter-toggle-button')), findsOneWidget);
    expect(find.byKey(const Key('mobile-select-mode')), findsOneWidget);
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
    scrollable.position.jumpTo(0);
    await tester.pump();

    expect(find.text('25 items'), findsOneWidget);
  });

  testWidgets('mobile denied permission shows recoverable status', (
    tester,
  ) async {
    final service = ChronoPicAppService(ChronoPicRepository());
    await tester.pumpWidget(
      ChronoPicHome(
        service: service,
        entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
        mobileMediaSourceFactory: () =>
            _mobileSource(permissionState: MediaSourcePermissionState.denied),
      ),
    );

    await tester.tap(find.byKey(const Key('choose-photo-library-button')));
    await tester.pumpAndSettle();

    expect(service.listPhotos(const PhotoFilter(limit: 10)), isEmpty);
    expect(
      find.textContaining('Photo library permission denied'),
      findsOneWidget,
    );
  });

  testWidgets('settings state metadata-only backup wording', (tester) async {
    await tester.pumpWidget(
      ChronoPicHome(
        service: ChronoPicAppService(ChronoPicRepository()),
        entryModeOverride: ChronoPicEntryMode.mobilePhotoLibrary,
        mobileMediaSourceFactory: () => _mobileSource(),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-nav')));
    await tester.pump();

    expect(
      find.textContaining(
        'Original media files are referenced by path, not copied',
      ),
      findsOneWidget,
    );
  });
}

FixtureMediaSource _mobileSource({
  MediaSourcePermissionState permissionState =
      MediaSourcePermissionState.granted,
  int count = 2,
}) {
  final ids = List<String>.generate(count, (index) => 'asset-${index + 1}');
  return FixtureMediaSource(
    permissionState: permissionState,
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
