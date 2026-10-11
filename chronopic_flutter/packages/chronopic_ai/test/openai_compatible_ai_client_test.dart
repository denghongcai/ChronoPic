import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:test/test.dart';

/// Starts a local fake OpenAI-compatible SSE server.
///
/// Mirrors the known llama.cpp quirk: the endpoint returns
/// `text/event-stream` responses even though the client always requests
/// streaming, so the fake server always emits SSE chunks.
Future<HttpServer> _startFakeServer({
  required List<String> chunks,
  required void Function(String rawBody) onRequest,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    onRequest(await utf8.decodeStream(req));
    req.response.headers.contentType = ContentType(
      'text',
      'event-stream',
      charset: 'utf-8',
    );
    for (final chunk in chunks) {
      req.response.write(
        'data: ${jsonEncode({
          'choices': [
            {'delta': {'content': chunk}},
          ],
        })}\n\n',
      );
    }
    req.response.write('data: [DONE]\n\n');
    await req.response.close();
  });
  return server;
}

Memory _memory() => const Memory(
      id: 'm1',
      name: 'Saved name',
      description: 'Saved description',
      coverPhotoId: null,
      coverThumbnailPath: null,
      photoCount: 2,
      generatedName: null,
      generatedDescription: null,
      generatedLabels: <String>[],
      aiStatus: AiPipelineStatus.pending,
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
      source: MemorySource.manual,
      createdAt: 1,
      updatedAt: 1,
    );

PhotoRecord _photo({
  required String path,
  String? caption,
  String? generatedCaption,
  String? summary,
  List<String> labels = const <String>[],
  List<String> generatedLabels = const <String>[],
  int? datetime,
  double? lat,
  double? lng,
}) {
  return PhotoRecord(
    photo: Photo(
      id: path,
      path: path,
      hash: null,
      size: 1,
      mime: 'image/jpeg',
      thumbnailPath: null,
      favorite: false,
      createdAt: 1,
      updatedAt: 1,
    ),
    metadata: Metadata(
      photoId: path,
      datetime: datetime,
      lat: lat,
      lng: lng,
      camera: null,
      confidence: 0.5,
      originalDatetimeText: null,
    ),
    semantic: Semantic(
      photoId: path,
      labels: labels,
      caption: caption,
      generatedLabels: generatedLabels,
      generatedCaption: generatedCaption,
      summary: summary,
      embeddingRef: null,
      aiStatus: AiPipelineStatus.pending,
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
    ),
    indexState: IndexState(
      photoId: path,
      indexed: true,
      aiProcessed: false,
      error: null,
      lastIndexedAt: null,
      duplicateOf: null,
      sourceUpdatedAt: null,
      missingAt: null,
    ),
  );
}

void main() {
  test('analyzePhoto streams, sends data-URL image, parses strict JSON', () async {
    String? capturedBody;
    final server = await _startFakeServer(
      chunks: [
        '{"caption":"City night","summary":"A city street at night.","labels":["city","night"]}',
      ],
      onRequest: (body) => capturedBody = body,
    );
    final client = OpenAiCompatibleAiClient(
      providerName: 'test-provider',
      model: 'test-model',
      apiKey: 'sk-test',
      baseUrl: 'http://localhost:${server.port}/v1',
    );
    final result = await client.analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
    );
    await server.close(force: true);

    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedCaption, 'City night');
    expect(result.summary, 'A city street at night.');
    expect(result.generatedLabels, ['city', 'night']);
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
    expect(result.error, isNull);
    expect(capturedBody!, contains('"stream":true'));
    expect(capturedBody!, contains('data:image/png;base64,'));
    expect(capturedBody!, contains('English (en-US)'));
  });

  test('text split across multiple SSE events is accumulated', () async {
    String? capturedBody;
    final server = await _startFakeServer(
      chunks: [
        '{"caption":"City',
        ' night","summary":"A city street',
        ' at night.","labels":["city","night"]}',
      ],
      onRequest: (body) => capturedBody = body,
    );
    final client = OpenAiCompatibleAiClient(
      providerName: 'test-provider',
      model: 'test-model',
      apiKey: 'sk-test',
      baseUrl: 'http://localhost:${server.port}/v1',
    );
    final result = await client.analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
    );
    await server.close(force: true);

    expect(capturedBody!, contains('"stream":true'));
    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedCaption, 'City night');
    expect(result.summary, 'A city street at night.');
    expect(result.generatedLabels, ['city', 'night']);
  });

  test('non-JSON model output surfaces a failed result', () async {
    final server = await _startFakeServer(
      chunks: ['not json at all'],
      onRequest: (_) {},
    );
    final client = OpenAiCompatibleAiClient(
      providerName: 'test-provider',
      model: 'test-model',
      apiKey: 'sk-test',
      baseUrl: 'http://localhost:${server.port}/v1',
    );
    final result = await client.analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
    );
    await server.close(force: true);

    expect(result.status, AiPipelineStatus.failed);
    expect(result.error, contains('non-JSON'));
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
    expect(result.generatedLabels, isEmpty);
    expect(result.generatedCaption, isNull);
  });

  test('zh-CN output locale is threaded into the prompt', () async {
    String? capturedBody;
    final server = await _startFakeServer(
      chunks: [
        '{"caption":"城市夜晚","summary":"夜晚的城市街道。","labels":["城市","夜晚"]}',
      ],
      onRequest: (body) => capturedBody = body,
    );
    final client = OpenAiCompatibleAiClient(
      providerName: 'test-provider',
      model: 'test-model',
      apiKey: 'sk-test',
      baseUrl: 'http://localhost:${server.port}/v1',
    );
    final result = await client.analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
      context: const PhotoAiContext(outputLocale: 'zh-CN'),
    );
    await server.close(force: true);

    expect(capturedBody!, contains('Simplified Chinese (zh-CN)'));
    expect(capturedBody!, isNot(contains('English (en-US)')));
    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedCaption, '城市夜晚');
  });

  test('known metadata is included in the photo prompt', () {
    final prompt = buildPhotoAnalysisPrompt(
      mime: 'image/jpeg',
      datetime: DateTime.utc(2024, 3, 4, 5, 6, 7),
      lat: 31.2304,
      lng: 121.4737,
      path: '/lib/shanghai.jpg',
    );
    expect(
      prompt,
      contains('mime=image/jpeg; datetime=2024-03-04T05:06:07.000Z; '
          'gps=31.2304, 121.4737; path=shanghai.jpg'),
    );
  });

  test('photo prompt defaults missing metadata to unknown', () {
    final prompt = buildPhotoAnalysisPrompt(mime: 'image/png');
    expect(prompt, contains('datetime=unknown'));
    expect(prompt, contains('gps=unknown'));
  });

  test('memory analysis is text-only and maps title/description/labels', () async {
    String? capturedBody;
    final server = await _startFakeServer(
      chunks: [
        '{"title":"Weekend trip","description":"A weekend by the coast.","labels":["trip","coast"]}',
      ],
      onRequest: (body) => capturedBody = body,
    );
    final client = OpenAiCompatibleAiClient(
      providerName: 'test-provider',
      model: 'test-model',
      apiKey: 'sk-test',
      baseUrl: 'http://localhost:${server.port}/v1',
    );
    final result = await client.analyzeMemory(
      memory: _memory(),
      photos: [
        _photo(
          path: '/lib/a.jpg',
          generatedCaption: 'Coast at dawn',
          summary: 'Sunrise over the coast.',
          labels: const ['beach'],
          generatedLabels: const ['sunrise', 'ocean'],
          datetime: DateTime.utc(2024, 5, 1, 8, 0, 0)
              .millisecondsSinceEpoch,
          lat: 36.0,
          lng: 120.0,
        ),
        _photo(path: '/lib/b.jpg'),
      ],
    );
    await server.close(force: true);

    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedName, 'Weekend trip');
    expect(result.generatedDescription, 'A weekend by the coast.');
    expect(result.generatedLabels, ['trip', 'coast']);
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
    expect(result.error, isNull);

    expect(capturedBody!, contains('"stream":true'));
    expect(capturedBody!, isNot(contains('data:image')));
    // Saved memory values and the sample set are present.
    expect(capturedBody!, contains('Saved memory name: Saved name.'));
    expect(capturedBody!, contains('Saved description: Saved description.'));
    expect(capturedBody!, contains('date=2024-05-01; gps=36.0,120.0; '
        'caption=Coast at dawn; summary=Sunrise over the coast.; '
        'labels=beach, sunrise, ocean'));
    expect(capturedBody!, contains('date=unknown-date; gps=unknown-gps; '
        'caption=b.jpg; summary=no-summary; labels=no-tags'));
  });

  test('memory prompt branches between generate and optimize', () {
    // A memory with no saved name/description takes the generate branch.
    final emptyMemory = const Memory(
      id: 'm2',
      name: '',
      description: null,
      coverPhotoId: null,
      coverThumbnailPath: null,
      photoCount: 0,
      generatedName: null,
      generatedDescription: null,
      generatedLabels: <String>[],
      aiStatus: AiPipelineStatus.pending,
      aiProvider: null,
      aiModel: null,
      aiProcessedAt: null,
      aiError: null,
      source: MemorySource.manual,
      createdAt: 1,
      updatedAt: 1,
    );
    final generatePrompt = buildMemoryAnalysisPrompt(
      memory: emptyMemory,
      photos: const <PhotoRecord>[],
    );
    expect(
      generatePrompt,
      contains('title: generate a short evocative memory title'),
    );
    expect(
      generatePrompt,
      contains('description: generate 1 to 3 sentences'),
    );
    expect(generatePrompt, contains('Current working title draft: none.'));
    expect(
      generatePrompt,
      contains('Current working description draft: none.'),
    );

    // A memory with saved name/description uses them as the working drafts
    // (mirrors the TypeScript `context.name === undefined ? memory.name : ...`
    // semantics), so it takes the optimize branch even without a context.
    final savedPrompt = buildMemoryAnalysisPrompt(
      memory: _memory(),
      photos: const <PhotoRecord>[],
    );
    expect(
      savedPrompt,
      contains('title: optimize the current working title'),
    );
    expect(
      savedPrompt,
      contains('Current working title draft: Saved name.'),
    );

    final optimizePrompt = buildMemoryAnalysisPrompt(
      memory: _memory(),
      photos: const <PhotoRecord>[],
      context: const MemoryAIContext(
        name: 'Draft title',
        description: 'Draft description',
      ),
    );
    expect(
      optimizePrompt,
      contains('title: optimize the current working title'),
    );
    expect(
      optimizePrompt,
      contains('description: optimize the current working description'),
    );
    expect(
      optimizePrompt,
      contains('Current working title draft: Draft title.'),
    );
    expect(
      optimizePrompt,
      contains('Current working description draft: Draft description.'),
    );
  });

  test('memory non-JSON output surfaces a failed result', () async {
    final server = await _startFakeServer(
      chunks: ['<think>reasoning only</think> still not json'],
      onRequest: (_) {},
    );
    final client = OpenAiCompatibleAiClient(
      providerName: 'test-provider',
      model: 'test-model',
      apiKey: 'sk-test',
      baseUrl: 'http://localhost:${server.port}/v1',
    );
    final result = await client.analyzeMemory(
      memory: _memory(),
      photos: const <PhotoRecord>[],
    );
    await server.close(force: true);

    expect(result.status, AiPipelineStatus.failed);
    expect(result.error, contains('non-JSON'));
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
  });
}
