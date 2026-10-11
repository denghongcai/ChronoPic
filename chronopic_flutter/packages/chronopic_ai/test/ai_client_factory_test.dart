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
  });
}
