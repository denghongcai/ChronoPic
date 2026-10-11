import 'dart:convert';

import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:openai_dart/openai_dart.dart';

import 'ai_client.dart';
import 'normalize.dart';
import 'prompts.dart';

/// Real AI client for OpenAI-compatible chat-completions endpoints
/// (llama.cpp servers, OpenAI, and friends).
///
/// Streaming-only: this client always uses `chat.completions.createStream` and
/// accumulates the text deltas. The target endpoint family returns
/// Server-Sent-Events even for non-streaming requests, so the non-streaming
/// `create` call is never used.
///
/// Image gating (Electron `resolvePhotoInput` parity): only `image/*` mimes are
/// sent as data-URL image parts. Non-image assets get the text-only prompt and
/// their bytes are ignored, so callers should not read original media for them.
///
/// [baseUrl] must already include the `/v1` segment (e.g.
/// `http://host:8080/v1`); neither this client nor [createAiClient] normalizes
/// partially specified base URLs — user-facing guidance belongs to the
/// settings form.
///
/// Error contract: model output that contains no parseable JSON object
/// resolves to a `failed` result carrying provider/model and an error message.
/// Transport failures throw typed `OpenAIException`s (HTTP error statuses as
/// `ApiException` subclasses, inline SSE error events as `StreamException`);
/// callers (the enrichment orchestration) are responsible for catching them.
final class OpenAiCompatibleAiClient implements ChronoPicAiClient {
  OpenAiCompatibleAiClient({
    required this.providerName,
    required this.model,
    required String apiKey,
    required String baseUrl,
  }) : _client = OpenAIClient(
          config: OpenAIConfig(
            authProvider: ApiKeyProvider(apiKey),
            baseUrl: baseUrl,
          ),
        );

  final String providerName;
  final String model;
  final OpenAIClient _client;

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
    // Electron `resolvePhotoInput` parity: only images contribute bytes to the
    // request; non-image mimes fall back to the text-only prompt.
    final isImage = mime.startsWith('image/');
    final parts = <ContentPart>[
      ContentPart.text(buildPhotoAnalysisPrompt(
        mime: mime,
        datetime: datetime,
        lat: lat,
        lng: lng,
        path: path,
        context: context,
      )),
      if (isImage)
        ContentPart.imageUrl('data:$mime;base64,${base64Encode(bytes)}'),
    ];
    final text = await _streamText(ChatMessage.user(parts));

    final payload = extractJsonObject(text);
    if (payload == null) {
      return PhotoAiResult(
        status: AiPipelineStatus.failed,
        error: 'Model returned non-JSON semantic output',
        provider: providerName,
        model: model,
      );
    }

    return PhotoAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: normalizeLabels(payload['labels']),
      generatedCaption: normalizeText(payload['caption']),
      summary: normalizeText(payload['summary']),
      provider: providerName,
      model: model,
    );
  }

  @override
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  }) async {
    // Memory synthesis is text-only: no image parts are sent.
    final text = await _streamText(
      ChatMessage.user([
        ContentPart.text(
          buildMemoryAnalysisPrompt(memory: memory, photos: photos, context: context),
        ),
      ]),
    );

    final payload = extractJsonObject(text);
    if (payload == null) {
      return MemoryAiResult(
        status: AiPipelineStatus.failed,
        error: 'Model returned non-JSON memory output',
        provider: providerName,
        model: model,
      );
    }

    return MemoryAiResult(
      status: AiPipelineStatus.completed,
      generatedName: normalizeText(payload['title']),
      generatedDescription: normalizeText(payload['description']),
      generatedLabels: normalizeLabels(payload['labels']),
      provider: providerName,
      model: model,
    );
  }

  Future<String> _streamText(ChatMessage message) {
    return _client.chat.completions
        .createStream(
          ChatCompletionCreateRequest(
            model: model,
            messages: [message],
          ),
        )
        .collectText();
  }
}
