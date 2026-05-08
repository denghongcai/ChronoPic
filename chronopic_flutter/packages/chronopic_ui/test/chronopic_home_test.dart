import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps empty first-run home focused on onboarding', (
    tester,
  ) async {
    final repository = ChronoPicRepository();

    tester.view.physicalSize = const Size(1440, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChronoPicHome(service: ChronoPicAppService(repository)),
    );

    expect(find.text('ChronoPic'), findsOneWidget);
    expect(find.text('Start with a local folder'), findsOneWidget);
    expect(
      find.byKey(const Key('choose-library-folder-button')),
      findsOneWidget,
    );
    expect(find.text('Recent Memories'), findsOneWidget);
    expect(find.text('No recent memories yet'), findsOneWidget);
    expect(find.byKey(const Key('create-first-memory-button')), findsOneWidget);
    expect(find.text('Search and filters'), findsOneWidget);
    expect(find.text('0 items'), findsOneWidget);
    expect(
      find.text('Add a folder, scan, then browse photos here.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('library-path-field')), findsNothing);
    expect(find.byKey(const Key('add-library-button')), findsNothing);
    expect(find.byKey(const Key('scan-library-button')), findsNothing);
    expect(find.byKey(const Key('tag-filter-field')), findsNothing);
    expect(find.byKey(const Key('gps-filter-chip')), findsNothing);
    expect(find.byKey(const Key('apply-filter-button')), findsNothing);
    expect(find.byKey(const Key('clear-filter-button')), findsNothing);

    await tester.tap(find.byKey(const Key('create-first-memory-button')));
    await tester.pump();
    expect(find.byKey(const Key('memory-name-field')), findsOneWidget);
  });

  testWidgets('renders the Flutter desktop MVP surfaces', (tester) async {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final repository = ChronoPicRepository()..restoreBackup(backup);
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ChronoPicHome(service: ChronoPicAppService(repository)),
    );

    expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
    expect(find.text('ChronoPic'), findsOneWidget);
    expect(find.text('Recent Memories'), findsOneWidget);
    expect(find.byKey(const Key('memory-cover-memory-weekend')), findsWidgets);
    expect(find.text('Search and filters'), findsOneWidget);
    expect(find.byKey(const Key('discovery-lens-chips')), findsOneWidget);
    expect(find.byKey(const Key('discover-map-chip')), findsOneWidget);
    expect(find.byKey(const Key('discover-timeline-chip')), findsOneWidget);
    expect(find.byKey(const Key('discover-memory-chip')), findsOneWidget);
    expect(find.text('Memories'), findsWidgets);
    expect(find.textContaining('Favorite'), findsWidgets);

    await tester.tap(find.byKey(const Key('discover-map-chip')));
    await tester.pump();
    expect(find.byKey(const Key('map-view')), findsOneWidget);

    await tester.tap(find.byKey(const Key('discover-timeline-chip')));
    await tester.pump();
    expect(find.byKey(const Key('timeline-view')), findsOneWidget);

    await tester.tap(find.byKey(const Key('discover-memory-chip')));
    await tester.pump();
    expect(find.byKey(const Key('memory-detail-panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('settings-nav')));
    await tester.pump();
    expect(find.text('Add Library'), findsOneWidget);
    expect(find.text('Scan Library'), findsOneWidget);
    expect(find.text('Export Backup File'), findsOneWidget);
    expect(find.text('Preview Backup File'), findsOneWidget);
    expect(find.text('Restore Backup File'), findsOneWidget);
    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();
    await tester.tap(find.text('Waterfall'));
    await tester.pump();

    final lakeCard = find.byKey(const Key('photo-card-photo-lake'));
    await tester.ensureVisible(lakeCard);
    await tester.tap(lakeCard);
    await tester.pump();
    expect(
      find.byKey(const Key('browse-selected-photo-banner')),
      findsOneWidget,
    );
    expect(find.text('SELECTED PHOTO'), findsOneWidget);
    expect(find.text('Detail view and gallery view'), findsOneWidget);
    expect(find.text('Edit caption'), findsOneWidget);
  });

  testWidgets('adapts the desktop photo grid to available width', (
    tester,
  ) async {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final repository = ChronoPicRepository()..restoreBackup(backup);

    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChronoPicHome(service: ChronoPicAppService(repository)),
    );
    expect(_photoGridColumns(tester), 3);

    tester.view.physicalSize = const Size(840, 1200);
    await tester.pump();
    expect(_photoGridColumns(tester), 1);
  });

  testWidgets('supports desktop keyboard shortcuts from detail selection', (
    tester,
  ) async {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final repository = ChronoPicRepository()..restoreBackup(backup);
    final service = ChronoPicAppService(repository);

    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(ChronoPicHome(service: service));
    final cityCard = find.byKey(const Key('photo-card-photo-city'));
    await tester.ensureVisible(cityCard);
    await tester.tap(cityCard);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(service.getPhoto('photo-city')?.photo.favorite, isTrue);

    service.updatePhotoCaption('photo-city', 'Keyboard caption');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(service.getPhoto('photo-city')?.semantic.caption, isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-dialog')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-dialog')), findsNothing);
  });

  testWidgets(
    'renders focused detail with actionable memory and close controls',
    (tester) async {
      final backup = ChronoPicBackup.fromJson(
        FlutterParityFixtures.readBackupJson(),
      );
      final repository = ChronoPicRepository()..restoreBackup(backup);
      final photos = ChronoPicAppService(
        repository,
      ).listPhotos(const PhotoFilter(limit: 10));
      var addPressed = 0;
      var closePressed = 0;

      tester.view.physicalSize = const Size(1440, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailSurface(
              captionController: TextEditingController(text: 'Caption'),
              dateController: TextEditingController(text: '2024-05-06'),
              focusedMode: true,
              labels: uiStrings[UiLocale.en]!,
              onAddToMemory: () => addPressed += 1,
              onCloseFocused: () => closePressed += 1,
              onOpenGallery: (_) {},
              onRollback: () {},
              onSaveCaption: () {},
              onSaveDatetime: () {},
              onSaveTags: () {},
              onSelectPhoto: (_) {},
              onToggleFavorite: () {},
              photos: photos,
              record: photos.first,
              tagsController: TextEditingController(text: 'city'),
              timeController: TextEditingController(text: '20:53'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
      expect(find.byKey(const Key('focused-detail-inspector')), findsOneWidget);
      expect(
        find.byKey(const Key('focused-detail-inspector-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('focused-detail-ai-insights')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('focused-detail-filmstrip')), findsOneWidget);
      expect(
        find.byKey(const Key('focused-detail-add-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('focused-detail-close-button')),
        findsOneWidget,
      );
      expect(find.text('AI INSIGHTS'), findsOneWidget);
      expect(find.textContaining('Generated'), findsWidgets);

      await tester.tap(find.byKey(const Key('focused-detail-add-button')));
      await tester.tap(find.byKey(const Key('focused-detail-close-button')));

      expect(addPressed, 1);
      expect(closePressed, 1);
    },
  );

  testWidgets('renders map and timeline browse modes from shared results', (
    tester,
  ) async {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final repository = ChronoPicRepository()..restoreBackup(backup);

    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChronoPicHome(service: ChronoPicAppService(repository)),
    );

    await tester.tap(find.text('Map'));
    await tester.pump();
    expect(find.byKey(const Key('map-view')), findsOneWidget);
    expect(find.byKey(const Key('map-disabled-canvas')), findsOneWidget);
    expect(find.text('Map view failed to initialize'), findsOneWidget);
    expect(find.byKey(const Key('map-photo-photo-lake')), findsOneWidget);
    expect(find.byKey(const Key('map-photo-photo-city')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('map-photo-photo-lake')));
    await tester.tap(find.byKey(const Key('map-photo-photo-lake')));
    await tester.pump();
    expect(
      find.text('/fixture/chronopic/library/backup-lake.png'),
      findsWidgets,
    );

    await tester.tap(find.text('Timeline'));
    await tester.pump();
    expect(find.byKey(const Key('timeline-view')), findsOneWidget);
    expect(find.text('TIMELINE SCOPE'), findsOneWidget);
    expect(
      find.byKey(const Key('timeline-selected-photo-banner')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('timeline-open-detail-button')),
      findsOneWidget,
    );
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.byKey(const Key('timeline-photo-photo-lake')), findsOneWidget);
    expect(find.byKey(const Key('timeline-photo-photo-city')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('timeline-photo-photo-city')),
    );
    await tester.tap(find.byKey(const Key('timeline-photo-photo-city')));
    await tester.pump();
    expect(
      find.text('/fixture/chronopic/library/backup-city.png'),
      findsWidgets,
    );
  });

  testWidgets('supports AI settings, queue retry, and candidate actions', (
    tester,
  ) async {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final repository = ChronoPicRepository()..restoreBackup(backup);
    final service = ChronoPicAppService(repository);

    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(ChronoPicHome(service: service));
    await tester.tap(find.byKey(const Key('notifications-nav')));
    await tester.pump();
    expect(find.byKey(const Key('memory-candidate-count')), findsOneWidget);
    expect(find.byKey(const Key('notification-center-panel')), findsOneWidget);
    expect(find.byKey(const Key('ai-provider-field')), findsNothing);

    await tester.tap(find.byKey(const Key('retry-ai-queue-button')));
    await tester.pump();
    expect(service.getAiStatusCounts()[AiPipelineStatus.pending], 1);

    await tester.tap(find.byKey(const Key('settings-nav')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('ai-provider-field')), '');
    await tester.enterText(find.byKey(const Key('ai-base-url-field')), '');
    await tester.enterText(find.byKey(const Key('ai-model-field')), '');
    await tester.enterText(find.byKey(const Key('ai-api-key-field')), '');
    await tester.ensureVisible(
      find.byKey(const Key('save-ai-settings-button')),
    );
    await tester.tap(find.byKey(const Key('save-ai-settings-button')));
    await tester.pump();
    expect(find.text('AI readiness: incomplete'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('ai-provider-field')),
      'test-provider',
    );
    await tester.enterText(
      find.byKey(const Key('ai-base-url-field')),
      'https://ai.example/v1',
    );
    await tester.enterText(find.byKey(const Key('ai-model-field')), 'vision');
    await tester.enterText(find.byKey(const Key('ai-api-key-field')), 'key');
    await tester.ensureVisible(
      find.byKey(const Key('save-ai-settings-button')),
    );
    await tester.tap(find.byKey(const Key('save-ai-settings-button')));
    await tester.pump();
    expect(find.text('AI readiness: configured'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('map-api-key-field')),
      'map-key',
    );
    await tester.enterText(
      find.byKey(const Key('map-security-js-code-field')),
      'map-secret',
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-map-settings-button')),
    );
    await tester.tap(find.byKey(const Key('save-map-settings-button')));
    await tester.pump();
    expect(service.createBackup().settings.map.apiKey, 'map-key');

    await tester.tap(find.byKey(const Key('memories-nav')));
    await tester.pump();
    expect(
      find.byKey(const Key('generate-memory-candidates-button')),
      findsOneWidget,
    );
    expect(find.text('Adjust photos'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('generate-memory-candidates-button')),
    );
    await tester.pump();
    expect(find.text('Memory suggestions refreshed: 1 ready'), findsOneWidget);
    expect(
      find.byKey(const Key('memory-candidate-candidate-city-lake')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('accept-candidate-candidate-city-lake')),
    );
    await tester.pump();
    expect(service.listMemoryCandidates(), isEmpty);
    expect(
      service.listMemories().map((memory) => memory.name),
      contains('Fixture Trip'),
    );
  });

  testWidgets('switches critical Flutter desktop shell text to Chinese', (
    tester,
  ) async {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final repository = ChronoPicRepository()..restoreBackup(backup);
    final service = ChronoPicAppService(repository);

    await tester.pumpWidget(ChronoPicHome(service: service));
    expect(find.text('Search and filters'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-nav')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('interface-locale-control')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pump();

    expect(service.createBackup().settings.locale.locale, LocaleSetting.zhCN);
    expect(find.text('语言设置已保存'), findsOneWidget);
    expect(find.text('资料库'), findsOneWidget);
    expect(find.text('照片工作区'), findsOneWidget);
    expect(find.text('创建回忆'), findsOneWidget);
    expect(find.byKey(const Key('interface-locale-control')), findsOneWidget);
    expect(find.byKey(const Key('ai-output-locale-control')), findsOneWidget);
    expect(
      find.byKey(const Key('save-locale-settings-button')),
      findsOneWidget,
    );
    expect(find.text('添加图库'), findsOneWidget);
    expect(find.text('扫描图库'), findsOneWidget);
    expect(find.text('导出备份文件'), findsOneWidget);
    expect(find.text('回忆'), findsWidgets);
    await tester.tap(find.byKey(const Key('all-photos-nav')));
    await tester.pump();
    expect(find.text('最近记忆'), findsOneWidget);
    expect(find.text('搜索和筛选'), findsOneWidget);
    final filterToggle = find.byKey(const Key('filter-toggle-button'));
    await tester.ensureVisible(filterToggle);
    await tester.tap(filterToggle);
    await tester.pump();
    expect(find.text('标签'), findsOneWidget);
    expect(find.text('仅 GPS'), findsOneWidget);
    expect(find.text('AI：全部'), findsOneWidget);
    expect(find.text('瀑布流'), findsOneWidget);
    expect(find.text('地图'), findsOneWidget);
    expect(find.text('时间线'), findsOneWidget);
  });
}

int _photoGridColumns(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byKey(const Key('photo-grid')));
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}
