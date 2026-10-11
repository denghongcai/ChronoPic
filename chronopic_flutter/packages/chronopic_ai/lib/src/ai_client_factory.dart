import 'package:chronopic_domain/chronopic_domain.dart';

import 'ai_client.dart';
import 'openai_compatible_ai_client.dart';

/// Default provider label used when persisted settings do not name one.
const _defaultProviderName = 'openai-compatible';

/// Builds the AI client from persisted [AiSettings].
///
/// Returns a [DisabledAiClient] unless every required credential field
/// (`apiKey`, `baseURL`, `model`) is non-empty. The stored `providerName` is
/// optional and falls back to `openai-compatible`.
///
/// This is a pure synchronous factory: URL normalization/validation and
/// connection probing are deliberately out of scope here.
ChronoPicAiClient createAiClient(AiSettings settings) {
  final apiKey = settings.apiKey;
  final baseURL = settings.baseURL;
  final model = settings.model;
  if (apiKey.isEmpty || baseURL.isEmpty || model.isEmpty) {
    return const DisabledAiClient();
  }
  return OpenAiCompatibleAiClient(
    providerName:
        settings.providerName.isEmpty ? _defaultProviderName : settings.providerName,
    model: model,
    apiKey: apiKey,
    baseUrl: baseURL,
  );
}
