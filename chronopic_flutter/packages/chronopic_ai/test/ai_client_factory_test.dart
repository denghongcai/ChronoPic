import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:test/test.dart';

void main() {
  AiSettings settings({
    String apiKey = 'test-key',
    String baseURL = 'http://localhost:8080/v1',
    String model = 'test-model',
    String providerName = '',
  }) {
    return AiSettings(
      apiKey: apiKey,
      baseURL: baseURL,
      model: model,
      providerName: providerName,
    );
  }

  group('createAiClient', () {
    test('returns DisabledAiClient when apiKey is missing', () {
      final client = createAiClient(settings(apiKey: ''));
      expect(client.isEnabled, isFalse);
      expect(client, isA<DisabledAiClient>());
    });

    test('returns DisabledAiClient when baseURL is missing', () {
      final client = createAiClient(settings(baseURL: ''));
      expect(client.isEnabled, isFalse);
      expect(client, isA<DisabledAiClient>());
    });

    test('returns DisabledAiClient when model is missing', () {
      final client = createAiClient(settings(model: ''));
      expect(client.isEnabled, isFalse);
      expect(client, isA<DisabledAiClient>());
    });

    test('returns DisabledAiClient when all fields are empty', () {
      final client = createAiClient(
        settings(apiKey: '', baseURL: '', model: ''),
      );
      expect(client.isEnabled, isFalse);
      expect(client, isA<DisabledAiClient>());
    });

    test('treats whitespace-only apiKey as missing', () {
      final client = createAiClient(settings(apiKey: '   '));
      expect(client.isEnabled, isFalse);
      expect(client, isA<DisabledAiClient>());
    });

    test('treats whitespace-only baseURL as missing', () {
      final client = createAiClient(settings(baseURL: '   '));
      expect(client.isEnabled, isFalse);
      expect(client, isA<DisabledAiClient>());
    });

    test('treats whitespace-only model as missing', () {
      final client = createAiClient(settings(model: '\t'));
      expect(client.isEnabled, isFalse);
      expect(client, isA<DisabledAiClient>());
    });

    test('defaults whitespace-only providerName to openai-compatible', () {
      final client =
          createAiClient(settings(providerName: '  ')) as OpenAiCompatibleAiClient;
      expect(client.providerName, 'openai-compatible');
    });

    test('returns OpenAiCompatibleAiClient for complete settings', () {
      final client = createAiClient(
        settings(
          apiKey: 'sk-test',
          baseURL: 'http://localhost:8080/v1',
          model: 'gemma-4-E4B-it-GGUF',
        ),
      );
      expect(client, isA<OpenAiCompatibleAiClient>());
      expect(client.isEnabled, isTrue);
    });

    test('exposes provider and model from settings', () {
      final client = createAiClient(
        settings(providerName: 'llama.cpp', model: 'gemma-4-E4B-it-GGUF'),
      ) as OpenAiCompatibleAiClient;
      expect(client.providerName, 'llama.cpp');
      expect(client.model, 'gemma-4-E4B-it-GGUF');
    });

    test('defaults empty providerName to openai-compatible', () {
      final client =
          createAiClient(settings()) as OpenAiCompatibleAiClient;
      expect(client.providerName, 'openai-compatible');
    });

    test(
        'factory and readiness split deliberately on providerName '
        '(Electron parity: readiness requires it, client defaults it)', () {
      final settingsWithoutProvider = settings(providerName: '');
      // Readiness gate: providerName is a required credential.
      expect(getAiReadiness(settingsWithoutProvider).configured, isFalse);
      // Factory gate: credentials apiKey/baseURL/model alone enable the client.
      final client = createAiClient(settingsWithoutProvider);
      expect(client.isEnabled, isTrue);
    });

    test('factory and readiness agree on missing apiKey', () {
      final incomplete = settings(apiKey: ' ');
      expect(getAiReadiness(incomplete).configured, isFalse);
      expect(createAiClient(incomplete).isEnabled, isFalse);
    });
  });
}
