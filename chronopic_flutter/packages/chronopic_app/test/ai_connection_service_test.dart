import 'dart:io';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:test/test.dart';

void main() {
  test('checks draft AI settings without persisting them', () async {
    AiSettings? checkedSettings;
    final service = ChronoPicAppService(
      ChronoPicRepository(),
      aiConnectionChecker: (settings) async {
        checkedSettings = settings;
        return AiConnectionCheckResult(
          status: AiConnectionStatus.connected,
          model: settings.model,
        );
      },
    );
    const settings = AiSettings(
      apiKey: 'draft-secret',
      baseURL: 'https://draft-provider.example/v1',
      model: 'draft-model',
      providerName: 'draft-provider',
    );

    final result = await service.testAiConnection(settings);

    expect(result.status, AiConnectionStatus.connected);
    expect(checkedSettings, settings);
    expect(service.createBackup().settings.ai.apiKey, isEmpty);
    expect(service.createBackup().settings.ai.baseURL, isEmpty);
  });

  test('saved AI settings persist across service restarts', () {
    final directory = Directory.systemTemp.createTempSync(
      'chronopic-ai-settings-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final persistencePath = '${directory.path}/settings.json';
    final firstService = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: persistencePath,
    );
    const settings = AiSettings(
      apiKey: 'persisted-secret',
      baseURL: 'https://provider.example/v1',
      model: 'persisted-model',
      providerName: 'persisted-provider',
    );

    firstService.updateAiSettings(settings);

    final restartedService = ChronoPicAppService(
      ChronoPicRepository(),
      persistencePath: persistencePath,
    );
    final restoredSettings = restartedService.createBackup().settings.ai;
    expect(restoredSettings.apiKey, settings.apiKey);
    expect(restoredSettings.baseURL, settings.baseURL);
    expect(restoredSettings.model, settings.model);
    expect(restoredSettings.providerName, settings.providerName);
  });
}
