import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:test/test.dart';

final class _CapturedRequest {
  String method = '';
  String path = '';
  String? authorization;
  String body = '';
}

Future<HttpServer> _serve(
  _CapturedRequest capture, {
  int statusCode = HttpStatus.ok,
  String? responseBody,
  Duration delay = Duration.zero,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen((request) async {
    capture
      ..method = request.method
      ..path = request.uri.path
      ..authorization = request.headers.value(HttpHeaders.authorizationHeader)
      ..body = await utf8.decodeStream(request);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      responseBody ??
          jsonEncode({
            'object': 'list',
            'data': [
              {'id': 'photo-model', 'object': 'model'},
            ],
          }),
    );
    try {
      await request.response.close();
    } on SocketException {
      // A timeout test may close the client before the delayed response.
    }
  });
  return server;
}

AiSettings _settings(String baseURL) => AiSettings(
  apiKey: 'secret-test-key',
  baseURL: baseURL,
  model: 'photo-model',
  providerName: 'local-provider',
);

void main() {
  test(
    'checks the configured model with one authenticated metadata request',
    () async {
      final capture = _CapturedRequest();
      final server = await _serve(capture);

      final result = await checkAiConnection(
        _settings('http://127.0.0.1:${server.port}/v1/'),
      );

      expect(result.status, AiConnectionStatus.connected);
      expect(result.connected, isTrue);
      expect(result.model, 'photo-model');
      expect(capture.method, 'GET');
      expect(capture.path, '/v1/models');
      expect(capture.authorization, 'Bearer secret-test-key');
      expect(capture.body, isEmpty);
    },
  );

  test('returns missing fields without making a request', () async {
    final result = await checkAiConnection(
      const AiSettings(apiKey: '', baseURL: '', model: '', providerName: ''),
    );

    expect(result.status, AiConnectionStatus.incompleteSettings);
    expect(result.missingFields, [
      'apiKey',
      'baseURL',
      'model',
      'providerName',
    ]);
    expect(result.connected, isFalse);
  });

  test('rejects malformed URL components before making a request', () async {
    final result = await checkAiConnection(_settings('file:///tmp/model'));
    expect(result.status, AiConnectionStatus.invalidBaseUrl);

    final queryResult = await checkAiConnection(
      _settings('https://provider.example/v1?token=should-not-be-here'),
    );
    expect(queryResult.status, AiConnectionStatus.invalidBaseUrl);
  });

  test(
    'maps provider HTTP errors without returning response details',
    () async {
      final cases = <int, AiConnectionStatus>{
        HttpStatus.unauthorized: AiConnectionStatus.unauthorized,
        HttpStatus.forbidden: AiConnectionStatus.forbidden,
        HttpStatus.notFound: AiConnectionStatus.endpointUnavailable,
        HttpStatus.tooManyRequests: AiConnectionStatus.rateLimited,
        HttpStatus.internalServerError: AiConnectionStatus.providerError,
      };

      for (final entry in cases.entries) {
        final server = await _serve(
          _CapturedRequest(),
          statusCode: entry.key,
          responseBody: '{"error":"secret response detail"}',
        );
        final result = await checkAiConnection(
          _settings('http://127.0.0.1:${server.port}/v1'),
        );

        expect(result.status, entry.value);
        expect(result.toString(), isNot(contains('secret response detail')));
        expect(result.toString(), isNot(contains('secret-test-key')));
      }
    },
  );

  test('reports a missing configured model', () async {
    final server = await _serve(
      _CapturedRequest(),
      responseBody: jsonEncode({
        'object': 'list',
        'data': [
          {'id': 'another-model'},
        ],
      }),
    );

    final result = await checkAiConnection(
      _settings('http://127.0.0.1:${server.port}/v1'),
    );

    expect(result.status, AiConnectionStatus.modelNotListed);
  });

  test('rejects malformed model catalogs', () async {
    final server = await _serve(
      _CapturedRequest(),
      responseBody: '{"data":"not-a-list"}',
    );

    final result = await checkAiConnection(
      _settings('http://127.0.0.1:${server.port}/v1'),
    );

    expect(result.status, AiConnectionStatus.invalidResponse);
  });

  test('rejects model catalogs larger than the response limit', () async {
    final server = await _serve(
      _CapturedRequest(),
      responseBody: '{"data":[]}${' ' * (1024 * 1024)}',
    );

    final result = await checkAiConnection(
      _settings('http://127.0.0.1:${server.port}/v1'),
    );

    expect(result.status, AiConnectionStatus.invalidResponse);
  });

  test('reports timeout and unreachable providers', () async {
    final delayed = await _serve(
      _CapturedRequest(),
      delay: const Duration(milliseconds: 150),
    );
    final timeoutResult = await checkAiConnection(
      _settings('http://127.0.0.1:${delayed.port}/v1'),
      timeout: const Duration(milliseconds: 20),
    );
    expect(timeoutResult.status, AiConnectionStatus.timedOut);

    final unreachable = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = unreachable.port;
    await unreachable.close(force: true);
    final networkResult = await checkAiConnection(
      _settings('http://127.0.0.1:$port/v1'),
      timeout: const Duration(milliseconds: 250),
    );
    expect(networkResult.status, AiConnectionStatus.networkError);
  });
}
