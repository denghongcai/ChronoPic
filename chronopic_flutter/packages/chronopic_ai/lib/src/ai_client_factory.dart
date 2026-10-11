import 'package:chronopic_domain/chronopic_domain.dart';

import 'ai_client.dart';
import 'openai_compatible_ai_client.dart';

/// Default provider label used when persisted settings do not name one.
const _defaultProviderName = 'openai-compatible';

/// Builds the AI client from persisted [AiSettings].
///
/// A credential field counts as missing when it is empty or whitespace-only,
/// matching [getAiReadiness] and the Electron reference (`getAIReadiness`
/// uses `?.trim()` over `apiKey`, `baseURL`, `model`, `providerName`).
/// Returns a [DisabledAiClient] unless `apiKey`, `baseURL`, and `model` are
/// all present.
///
/// `providerName` is deliberately treated as optional here even though
/// [getAiReadiness] counts it as a required credential: the Electron client
/// has the same split (`getAIReadiness` requires it for the configured gate
/// while the pipeline falls back to `?? "openai-compatible"`), and settings
/// saved before the provider label existed must keep working. Empty or
/// whitespace-only provider names fall back to `openai-compatible`.
///
/// [AiSettings.baseURL] must already include the `/v1` segment (e.g.
/// `http://host:8080/v1`); this factory does not normalize or validate it —
/// user-facing guidance belongs to the settings form.
///
/// This is a pure synchronous factory; no connection probing happens here.
ChronoPicAiClient createAiClient(AiSettings settings) {
  final apiKey = settings.apiKey.trim();
  final baseURL = settings.baseURL.trim();
  final model = settings.model.trim();
  if (apiKey.isEmpty || baseURL.isEmpty || model.isEmpty) {
    return const DisabledAiClient();
  }
  final providerName = settings.providerName.trim();
  return OpenAiCompatibleAiClient(
    providerName: providerName.isEmpty ? _defaultProviderName : providerName,
    model: model,
    apiKey: apiKey,
    baseUrl: baseURL,
  );
}
