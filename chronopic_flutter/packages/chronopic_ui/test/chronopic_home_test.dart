import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Flutter desktop MVP surfaces', (tester) async {
    final backup = ChronoPicBackup.fromJson(
      FlutterParityFixtures.readBackupJson(),
    );
    final repository = ChronoPicRepository()..restoreBackup(backup);
    await tester.pumpWidget(
      ChronoPicHome(service: ChronoPicAppService(repository)),
    );

    expect(find.text('ChronoPic Flutter'), findsOneWidget);
    expect(find.text('Add Library'), findsOneWidget);
    expect(find.text('Scan Library'), findsOneWidget);
    expect(find.text('Search and filters'), findsOneWidget);
    expect(find.text('Export Backup'), findsOneWidget);
    expect(find.text('Preview Restore'), findsOneWidget);
    expect(find.text('Restore Backup'), findsOneWidget);
    expect(find.text('Memories'), findsOneWidget);
    expect(find.textContaining('Favorite'), findsWidgets);

    final lakeCard = find.byKey(const Key('photo-card-photo-lake'));
    await tester.ensureVisible(lakeCard);
    await tester.tap(lakeCard);
    await tester.pump();
    expect(find.text('Detail view and gallery view'), findsOneWidget);
    expect(find.text('Edit caption'), findsOneWidget);
    expect(find.text('Add to Memory'), findsOneWidget);
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
    expect(_photoGridColumns(tester), 5);

    tester.view.physicalSize = const Size(840, 1200);
    await tester.pump();
    expect(_photoGridColumns(tester), 3);
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
    expect(find.byKey(const Key('close-gallery-button')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('close-gallery-button')), findsNothing);
  });

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
    expect(find.byKey(const Key('map-photo-photo-lake')), findsOneWidget);
    expect(find.byKey(const Key('map-photo-photo-city')), findsNothing);
    await tester.tap(find.byKey(const Key('map-photo-photo-lake')));
    await tester.pump();
    expect(
      find.text('/fixture/chronopic/library/backup-lake.png'),
      findsOneWidget,
    );

    await tester.tap(find.text('Timeline'));
    await tester.pump();
    expect(find.byKey(const Key('timeline-view')), findsOneWidget);
    expect(find.byKey(const Key('timeline-photo-photo-lake')), findsOneWidget);
    expect(find.byKey(const Key('timeline-photo-photo-city')), findsOneWidget);
    await tester.tap(find.byKey(const Key('timeline-photo-photo-city')));
    await tester.pump();
    expect(
      find.text('/fixture/chronopic/library/backup-city.png'),
      findsOneWidget,
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
    expect(find.byKey(const Key('memory-candidate-count')), findsOneWidget);
    expect(
      find.byKey(const Key('memory-candidate-candidate-city-lake')),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('ai-provider-field')), '');
    await tester.enterText(find.byKey(const Key('ai-base-url-field')), '');
    await tester.enterText(find.byKey(const Key('ai-model-field')), '');
    await tester.enterText(find.byKey(const Key('ai-api-key-field')), '');
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
    await tester.tap(find.byKey(const Key('save-ai-settings-button')));
    await tester.pump();
    expect(find.text('AI readiness: configured'), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry-ai-queue-button')));
    await tester.pump();
    expect(service.getAiStatusCounts()[AiPipelineStatus.pending], 1);

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

    await tester.pumpWidget(
      ChronoPicHome(service: ChronoPicAppService(repository)),
    );
    expect(find.text('Add Library'), findsOneWidget);

    await tester.tap(find.text('中文'));
    await tester.pump();

    expect(find.text('添加图库'), findsOneWidget);
    expect(find.text('扫描图库'), findsOneWidget);
    expect(find.text('搜索和筛选'), findsOneWidget);
    expect(find.text('导出备份'), findsOneWidget);
    expect(find.text('回忆'), findsWidgets);
    expect(find.text('网格'), findsOneWidget);
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
