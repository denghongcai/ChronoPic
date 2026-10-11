import 'dart:async';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyAiSettings = AiSettings(
  apiKey: '',
  baseURL: '',
  model: '',
  providerName: '',
);

/// Lets real async work (file reads inside enrichment) complete under the
/// widget-test fake clock before settling frames.
Future<void> flushRealAsync(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
}

void main() {
  Future<void> pumpDesktop(WidgetTester tester, ChronoPicHome home) async {
    tester.view.physicalSize = const Size(1440, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(home);
    await tester.pump();
  }

  Future<void> openFocusedDetail(WidgetTester tester, String photoId) async {
    final card = find.byKey(Key('photo-card-$photoId'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focused-detail-view')), findsOneWidget);
  }

  testWidgets(
    'inspector shows generated AI content for completed photos and failed state for failed ones',
    (tester) async {
      final repository = ChronoPicRepository()..restoreBackup(_backup());
      await pumpDesktop(
        tester,
        ChronoPicHome(service: ChronoPicAppService(repository)),
      );

      await openFocusedDetail(tester, 'photo-lake');
      await tester.ensureVisible(
        find.byKey(const Key('focused-detail-ai-insights')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Generated lake caption'), findsWidgets);
      expect(find.text('WATER'), findsOneWidget);
      expect(find.text('TRAVEL'), findsOneWidget);
      expect(find.byKey(const Key('photo-ai-status-chip')), findsOneWidget);
      expect(find.text('AI: completed'), findsOneWidget);

      // Switch to the failed photo and check the failed state + error surface.
      await tester.tap(find.byKey(const Key('focused-detail-close-button')));
      await tester.pumpAndSettle();
      final cityCard = find.byKey(const Key('photo-card-photo-city'));
      await tester.ensureVisible(cityCard);
      await tester.tap(cityCard);
      await tester.pump();
      await tester.tap(cityCard);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('focused-detail-ai-insights')),
      );
      await tester.pumpAndSettle();
      expect(find.text('AI: failed'), findsOneWidget);
      expect(find.textContaining('fixture transient failure'), findsWidgets);
    },
  );

  testWidgets(
    'generate-photo-ai-button enriches the selected photo and reflects generated content',
    (tester) async {
      final repository = ChronoPicRepository()..restoreBackup(_backup());
      await pumpDesktop(
        tester,
        ChronoPicHome(
          service: ChronoPicAppService(repository),
          aiClient: const FixtureSuccessAiClient(),
        ),
      );

      await openFocusedDetail(tester, 'photo-city');
      final generate = find.byKey(const Key('generate-photo-ai-button'));
      await tester.ensureVisible(generate);
      await tester.tap(generate);
      await flushRealAsync(tester);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Generated caption for photo-city'),
        findsWidgets,
      );
      final record = repository.getPhoto('photo-city');
      expect(record!.semantic.aiStatus, AiPipelineStatus.completed);
      // Generated content stays separate from the manual caption draft.
      expect(find.byKey(const Key('caption-field')), findsOneWidget);
    },
  );

  testWidgets(
    'memory AI suggestions open behind an explicit action and use-suggestion fills drafts without saving',
    (tester) async {
      final repository = ChronoPicRepository()..restoreBackup(_backup());
      final service = ChronoPicAppService(repository);
      await pumpDesktop(
        tester,
        ChronoPicHome(
          service: service,
          aiClient: const FixtureSuccessAiClient(),
        ),
      );

      await tester.tap(find.byKey(const Key('memories-nav')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('memory-card-memory-weekend')),
      );
      await tester.tap(find.byKey(const Key('memory-card-memory-weekend')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memory-detail-panel')), findsOneWidget);

      final suggest = find.byKey(const Key('memory-ai-suggest-button'));
      await tester.ensureVisible(suggest);
      await tester.tap(suggest);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('memory-ai-suggestions-dialog')),
        findsOneWidget,
      );

      final generate = find.byKey(const Key('memory-ai-generate-button'));
      await tester.ensureVisible(generate);
      await tester.tap(generate);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Generated title for memory-weekend'),
        findsWidgets,
      );
      expect(
        find.textContaining('Generated description for memory-weekend'),
        findsWidgets,
      );

      final useTitle = find.byKey(const Key('use-ai-title-button'));
      await tester.ensureVisible(useTitle);
      await tester.tap(useTitle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('memory-ai-suggestions-dialog')),
        findsNothing,
      );

      // Draft filled, persisted memory untouched until the user saves.
      final titleField = tester.widget<TextField>(
        find.byKey(const Key('memory-title-field')),
      );
      expect(titleField.controller!.text, 'Generated title for memory-weekend');
      expect(repository.getMemory('memory-weekend')!.name, 'Fixture Weekend');
    },
  );

  testWidgets('enrich-pending-button processes the queue and surfaces counts', (
    tester,
  ) async {
    final repository = ChronoPicRepository()..restoreBackup(_backup());
    await pumpDesktop(
      tester,
      ChronoPicHome(
        service: ChronoPicAppService(repository),
        aiClient: const FixtureSuccessAiClient(),
      ),
    );

    await tester.tap(find.byKey(const Key('notifications-nav')));
    await tester.pumpAndSettle();
    final enrich = find.byKey(const Key('enrich-pending-button'));
    expect(enrich, findsOneWidget);
    await tester.ensureVisible(enrich);
    await tester.tap(enrich);
    await flushRealAsync(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('1 processed'), findsOneWidget);
    expect(
      repository.getPhoto('photo-city')!.semantic.aiStatus,
      AiPipelineStatus.completed,
    );
  });

  testWidgets('not-configured AI surfaces feedback instead of crashing', (
    tester,
  ) async {
    final repository = ChronoPicRepository()
      ..restoreBackup(_backup(ai: _emptyAiSettings));
    await pumpDesktop(
      tester,
      ChronoPicHome(service: ChronoPicAppService(repository)),
    );

    await openFocusedDetail(tester, 'photo-lake');
    final generate = find.byKey(const Key('generate-photo-ai-button'));
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pumpAndSettle();

    expect(find.textContaining('not configured'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enrich-pending is guarded against re-entrant runs', (
    tester,
  ) async {
    final repository = ChronoPicRepository()..restoreBackup(_backup());
    final blocking = _BlockingAiClient();
    await pumpDesktop(
      tester,
      ChronoPicHome(
        service: ChronoPicAppService(repository),
        aiClient: blocking,
      ),
    );

    await tester.tap(find.byKey(const Key('notifications-nav')));
    await tester.pumpAndSettle();
    final enrich = find.byKey(const Key('enrich-pending-button'));

    await tester.ensureVisible(enrich);
    await tester.tap(enrich);
    await flushRealAsync(tester);
    await tester.pump();

    // The button is disabled while the run is in flight.
    expect(tester.widget<OutlinedButton>(enrich).onPressed, isNull);

    await tester.tap(enrich, warnIfMissed: false);
    await tester.pump();
    expect(blocking.callCount, 1);

    blocking.completer.complete();
    await flushRealAsync(tester);
    await tester.pumpAndSettle();
    expect(blocking.callCount, 1);
    expect(find.textContaining('1 processed'), findsOneWidget);
  });

  testWidgets('retry-ai-queue-button is disabled while a run is in flight', (
    tester,
  ) async {
    final repository = ChronoPicRepository()..restoreBackup(_backup());
    final blocking = _BlockingAiClient();
    await pumpDesktop(
      tester,
      ChronoPicHome(
        service: ChronoPicAppService(repository),
        aiClient: blocking,
      ),
    );

    await tester.tap(find.byKey(const Key('notifications-nav')));
    await tester.pumpAndSettle();
    final retry = find.byKey(const Key('retry-ai-queue-button'));
    final enrich = find.byKey(const Key('enrich-pending-button'));
    expect(tester.widget<OutlinedButton>(retry).onPressed, isNotNull);

    await tester.ensureVisible(enrich);
    await tester.tap(enrich);
    await flushRealAsync(tester);
    await tester.pump();

    // Both queue actions share the busy gate while the run is in flight.
    expect(tester.widget<OutlinedButton>(retry).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(enrich).onPressed, isNull);

    blocking.completer.complete();
    await flushRealAsync(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(retry).onPressed, isNotNull);
  });

  testWidgets(
    'enriching a photo that no longer exists surfaces the real error instead of the not-configured message',
    (tester) async {
      final repository = ChronoPicRepository()..restoreBackup(_backup());
      await pumpDesktop(
        tester,
        ChronoPicHome(
          service: ChronoPicAppService(repository),
          aiClient: const FixtureSuccessAiClient(),
        ),
      );

      await openFocusedDetail(tester, 'photo-city');

      // AI stays configured here; the selected photo disappears behind the
      // shell's back (for example removed by a concurrent scan), so the
      // not-found StateError must reach the user verbatim.
      final full = _backup();
      repository.restoreBackup(
        ChronoPicBackup(
          app: full.app,
          schemaVersion: full.schemaVersion,
          exportedAt: full.exportedAt,
          settings: full.settings,
          librarySources: full.librarySources,
          photos: full.photos
              .where((record) => record.photo.id != 'photo-city')
              .toList(),
          memories: full.memories,
          memoryPhotos: full.memoryPhotos
              .where((membership) => membership.photoId != 'photo-city')
              .toList(),
          editHistory: full.editHistory,
          memoryCandidates: const <MemoryCandidate>[],
        ),
      );

      final generate = find.byKey(const Key('generate-photo-ai-button'));
      await tester.ensureVisible(generate);
      await tester.tap(generate);
      await flushRealAsync(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Photo not found: photo-city'), findsWidgets);
      expect(find.textContaining('not configured'), findsNothing);
    },
  );
}

ChronoPicBackup _backup({AiSettings? ai}) {
  final backup = ChronoPicBackup.fromJson(
    FlutterParityFixtures.readBackupJson(),
  );
  return ChronoPicBackup(
    app: backup.app,
    schemaVersion: backup.schemaVersion,
    exportedAt: backup.exportedAt,
    settings: BackupSettings(
      ai: ai ?? backup.settings.ai,
      map: backup.settings.map,
      locale: const LocaleSettings(
        locale: LocaleSetting.enUS,
        aiOutputLocale: AiOutputLocale.followUi,
      ),
    ),
    librarySources: backup.librarySources,
    photos: backup.photos,
    memories: backup.memories,
    memoryPhotos: backup.memoryPhotos,
    editHistory: backup.editHistory,
    memoryCandidates: backup.memoryCandidates,
  );
}

final class _BlockingAiClient implements ChronoPicAiClient {
  final Completer<void> completer = Completer<void>();
  int callCount = 0;

  @override
  bool get isEnabled => true;

  @override
  Future<PhotoAiResult> analyzePhoto({
    required String photoId,
    required List<int> bytes,
    required String mime,
    DateTime? datetime,
    double? lat,
    double? lng,
    String? path,
    PhotoAiContext context = const PhotoAiContext(),
  }) async {
    callCount += 1;
    await completer.future;
    return PhotoAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: const <String>['blocking'],
      generatedCaption: 'Blocking caption for $photoId',
      summary: 'Blocking summary for $photoId.',
    );
  }

  @override
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  }) async {
    callCount += 1;
    await completer.future;
    return const MemoryAiResult(status: AiPipelineStatus.completed);
  }
}
