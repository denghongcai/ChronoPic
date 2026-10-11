import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:test/test.dart';

/// Captures request facts from the fake server.
final class _RequestCapture {
  String path = '';
  String? authorization;
  String body = '';
}

/// Starts a local fake OpenAI-compatible SSE server.
///
/// Mirrors the known llama.cpp quirk: the endpoint returns
/// `text/event-stream` responses even though the client always requests
/// streaming, so the fake server always emits SSE chunks. The server is
/// registered with [addTearDown] so failing tests do not leak it.
Future<HttpServer> _startFakeServer(
  _RequestCapture capture, {
  List<String> chunks = const <String>[],
  int statusCode = 200,
  bool inlineSseError = false,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen((req) async {
    capture
      ..path = req.uri.toString()
      ..authorization = req.headers.value(HttpHeaders.authorizationHeader)
      ..body = await utf8.decodeStream(req);
    if (statusCode != 200) {
      req.response.statusCode = statusCode;
      req.response.headers.contentType = ContentType.json;
      req.response.write(
        jsonEncode({
          'error': {'message': 'boom', 'type': 'server_error'},
        }),
      );
      await req.response.close();
      return;
    }
    req.response.headers.contentType = ContentType(
      'text',
      'event-stream',
      charset: 'utf-8',
    );
    if (inlineSseError) {
      req.response.write(
        'data: {"error": {"message": "inference failed", '
        '"type": "server_error"}}\n\n',
      );
      await req.response.close();
      return;
    }
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

OpenAiCompatibleAiClient _clientFor(HttpServer server) {
  return OpenAiCompatibleAiClient(
    providerName: 'test-provider',
    model: 'test-model',
    apiKey: 'sk-test',
    baseUrl: 'http://localhost:${server.port}/v1',
  );
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
    final capture = _RequestCapture();
    final server = await _startFakeServer(
      capture,
      chunks: [
        '{"caption":"City night","summary":"A city street at night.","labels":["city","night"]}',
      ],
    );
    final client = _clientFor(server);
    final result = await client.analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
    );

    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedCaption, 'City night');
    expect(result.summary, 'A city street at night.');
    expect(result.generatedLabels, ['city', 'night']);
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
    expect(result.error, isNull);
    expect(capture.body, contains('"stream":true'));
    expect(capture.body, contains('data:image/png;base64,'));
    expect(capture.body, contains('English (en-US)'));
    // Request hygiene: bearer auth, model field, chat-completions path.
    expect(capture.authorization, 'Bearer sk-test');
    expect(capture.body, contains('"model":"test-model"'));
    expect(capture.path, '/v1/chat/completions');
  });

  test('text split across multiple SSE events is accumulated', () async {
    final capture = _RequestCapture();
    final server = await _startFakeServer(
      capture,
      chunks: [
        '{"caption":"City',
        ' night","summary":"A city street',
        ' at night.","labels":["city","night"]}',
      ],
    );
    final result = await _clientFor(server).analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
    );

    expect(capture.body, contains('"stream":true'));
    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedCaption, 'City night');
    expect(result.summary, 'A city street at night.');
    expect(result.generatedLabels, ['city', 'night']);
  });

  test('non-image mime sends a text-only prompt and still parses JSON', () async {
    final capture = _RequestCapture();
    final server = await _startFakeServer(
      capture,
      chunks: [
        '{"caption":"Clip title","summary":"A short clip.","labels":["clip"]}',
      ],
    );
    final result = await _clientFor(server).analyzePhoto(
      photoId: 'v1',
      bytes: <int>[1, 2, 3, 4],
      mime: 'video/mp4',
    );

    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedCaption, 'Clip title');
    expect(result.generatedLabels, ['clip']);
    expect(capture.body, contains('"stream":true'));
    expect(capture.body, isNot(contains('image_url')));
    expect(capture.body, isNot(contains('data:video/mp4;base64,')));
  });

  test('non-JSON model output surfaces a failed result', () async {
    final server = await _startFakeServer(
      _RequestCapture(),
      chunks: ['not json at all'],
    );
    final result = await _clientFor(server).analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
    );

    expect(result.status, AiPipelineStatus.failed);
    expect(result.error, contains('non-JSON'));
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
    expect(result.generatedLabels, isEmpty);
    expect(result.generatedCaption, isNull);
  });

  test('zh-CN output locale is threaded into the prompt', () async {
    final capture = _RequestCapture();
    final server = await _startFakeServer(
      capture,
      chunks: [
        '{"caption":"城市夜晚","summary":"夜晚的城市街道。","labels":["城市","夜晚"]}',
      ],
    );
    final result = await _clientFor(server).analyzePhoto(
      photoId: 'p1',
      bytes: [1, 2, 3],
      mime: 'image/png',
      context: const PhotoAiContext(outputLocale: 'zh-CN'),
    );

    expect(capture.body, contains('Simplified Chinese (zh-CN)'));
    expect(capture.body, isNot(contains('English (en-US)')));
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
    final capture = _RequestCapture();
    final server = await _startFakeServer(
      capture,
      chunks: [
        '{"title":"Weekend trip","description":"A weekend by the coast.","labels":["trip","coast"]}',
      ],
    );
    final result = await _clientFor(server).analyzeMemory(
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

    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedName, 'Weekend trip');
    expect(result.generatedDescription, 'A weekend by the coast.');
    expect(result.generatedLabels, ['trip', 'coast']);
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
    expect(result.error, isNull);

    expect(capture.body, contains('"stream":true'));
    expect(capture.body, isNot(contains('data:image')));
    // Saved memory values and the sample set are present.
    expect(capture.body, contains('Saved memory name: Saved name.'));
    expect(capture.body, contains('Saved description: Saved description.'));
    expect(capture.body, contains('date=2024-05-01; gps=36.0,120.0; '
        'caption=Coast at dawn; summary=Sunrise over the coast.; '
        'labels=beach, sunrise, ocean'));
    expect(capture.body, contains('date=unknown-date; gps=unknown-gps; '
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
      _RequestCapture(),
      chunks: ['<think>reasoning only</think> still not json'],
    );
    final result = await _clientFor(server).analyzeMemory(
      memory: _memory(),
      photos: const <PhotoRecord>[],
    );

    expect(result.status, AiPipelineStatus.failed);
    expect(result.error, contains('non-JSON'));
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
  });

  test('HTTP error responses throw a typed ApiException', () async {
    final server = await _startFakeServer(
      _RequestCapture(),
      statusCode: 500,
    );
    await expectLater(
      _clientFor(server).analyzePhoto(
        photoId: 'p1',
        bytes: [1, 2, 3],
        mime: 'image/png',
      ),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      _clientFor(server).analyzeMemory(
        memory: _memory(),
        photos: const <PhotoRecord>[],
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('inline SSE error events throw a typed StreamException', () async {
    final server = await _startFakeServer(
      _RequestCapture(),
      inlineSseError: true,
    );
    await expectLater(
      _clientFor(server).analyzePhoto(
        photoId: 'p1',
        bytes: [1, 2, 3],
        mime: 'image/png',
      ),
      throwsA(
        isA<StreamException>().having(
          (error) => error.message,
          'message',
          contains('inference failed'),
        ),
      ),
    );
  });
}
