import 'dart:typed_data';

import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_media/chronopic_media.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile first run uses photo library as the primary entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
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
    expect(
      find.byKey(const Key('choose-photo-library-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mobile-choose-photos')), findsOneWidget);
    expect(find.byKey(const Key('choose-library-folder-button')), findsNothing);
    expect(find.text('Start with your photo library'), findsOneWidget);
  });

  testWidgets('mobile photo library scan reports limited progress', (
    tester,
  ) async {
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
    expect(find.byKey(const Key('mobile-open-detail')), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const Key('mobile-open-detail')).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-open-detail')).first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-open-gallery')), findsWidgets);

    await tester.tap(find.byKey(const Key('memories-nav')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-create-memory')), findsOneWidget);
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
}) {
  return FixtureMediaSource(
    permissionState: permissionState,
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
