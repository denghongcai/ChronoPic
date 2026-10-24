import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chronopic_domain/chronopic_domain.dart';

enum AiConnectionStatus {
  connected,
  incompleteSettings,
  invalidBaseUrl,
  unauthorized,
  forbidden,
  modelNotListed,
  endpointUnavailable,
  rateLimited,
  providerError,
  invalidResponse,
  timedOut,
  networkError,
}

final class AiConnectionCheckResult {
  const AiConnectionCheckResult({
    required this.status,
    required this.model,
    this.missingFields = const <String>[],
  });

  final AiConnectionStatus status;
  final String model;
  final List<String> missingFields;

  bool get connected => status == AiConnectionStatus.connected;
}

const Duration defaultAiConnectionTimeout = Duration(seconds: 8);
const int _maxModelCatalogBytes = 1024 * 1024;

final class _ResponseTooLarge implements Exception {
  const _ResponseTooLarge();
}

/// Checks endpoint access and model visibility without invoking inference.
Future<AiConnectionCheckResult> checkAiConnection(
  AiSettings settings, {
  Duration timeout = defaultAiConnectionTimeout,
}) async {
  final model = settings.model.trim();
  final readiness = getAiReadiness(settings);
  if (!readiness.configured) {
    return AiConnectionCheckResult(
      status: AiConnectionStatus.incompleteSettings,
      model: model,
      missingFields: List<String>.unmodifiable(readiness.missingFields),
    );
  }

  final uri = _modelCatalogUri(settings.baseURL);
  if (uri == null) {
    return AiConnectionCheckResult(
      status: AiConnectionStatus.invalidBaseUrl,
      model: model,
    );
  }

  final client = HttpClient()..connectionTimeout = timeout;
  final stopwatch = Stopwatch()..start();
  Duration remainingTimeout() {
    final remaining = timeout - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('AI provider check timed out');
    }
    return remaining;
  }

  try {
    final request = await client.getUrl(uri).timeout(remainingTimeout());
    request
      ..followRedirects = false
      ..headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${settings.apiKey.trim()}',
      )
      ..headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    final response = await request.close().timeout(remainingTimeout());

    final httpStatus = _statusForHttpCode(response.statusCode);
    if (httpStatus != null) {
      return AiConnectionCheckResult(status: httpStatus, model: model);
    }

    final bodyBytes = await response
        .fold<BytesBuilder>(BytesBuilder(copy: false), (builder, chunk) {
          if (builder.length + chunk.length > _maxModelCatalogBytes) {
            throw const _ResponseTooLarge();
          }
          builder.add(chunk);
          return builder;
        })
        .timeout(remainingTimeout());
    final decoded = jsonDecode(utf8.decode(bodyBytes.takeBytes()));
    if (decoded is! Map || decoded['data'] is! List) {
      return AiConnectionCheckResult(
        status: AiConnectionStatus.invalidResponse,
        model: model,
      );
    }

    final models = decoded['data'] as List;
    final modelIds = <String>[];
    for (final entry in models) {
      if (entry is Map && entry['id'] is String) {
        modelIds.add((entry['id'] as String).trim());
      }
    }
    if (models.isNotEmpty && modelIds.isEmpty) {
      return AiConnectionCheckResult(
        status: AiConnectionStatus.invalidResponse,
        model: model,
      );
    }

    return AiConnectionCheckResult(
      status: modelIds.contains(model)
          ? AiConnectionStatus.connected
          : AiConnectionStatus.modelNotListed,
      model: model,
    );
  } on TimeoutException {
    return AiConnectionCheckResult(
      status: AiConnectionStatus.timedOut,
      model: model,
    );
  } on _ResponseTooLarge {
    return AiConnectionCheckResult(
      status: AiConnectionStatus.invalidResponse,
      model: model,
    );
  } on FormatException {
    return AiConnectionCheckResult(
      status: AiConnectionStatus.invalidResponse,
      model: model,
    );
  } on IOException {
    return AiConnectionCheckResult(
      status: AiConnectionStatus.networkError,
      model: model,
    );
  } on Object {
    return AiConnectionCheckResult(
      status: AiConnectionStatus.networkError,
      model: model,
    );
  } finally {
    client.close(force: true);
  }
}

Uri? _modelCatalogUri(String baseURL) {
  final parsed = Uri.tryParse(baseURL.trim());
  if (parsed == null ||
      (parsed.scheme != 'http' && parsed.scheme != 'https') ||
      !parsed.hasAuthority ||
      parsed.host.isEmpty ||
      parsed.userInfo.isNotEmpty ||
      parsed.hasQuery ||
      parsed.hasFragment) {
    return null;
  }
  try {
    if (parsed.port < 1 || parsed.port > 65535) return null;
  } on FormatException {
    return null;
  }

  final basePath = parsed.path.replaceFirst(RegExp(r'/+$'), '');
  return parsed.replace(path: '$basePath/models');
}

AiConnectionStatus? _statusForHttpCode(int statusCode) {
  if (statusCode == HttpStatus.ok) return null;
  if (statusCode == HttpStatus.unauthorized) {
    return AiConnectionStatus.unauthorized;
  }
  if (statusCode == HttpStatus.forbidden) {
    return AiConnectionStatus.forbidden;
  }
  if (statusCode == HttpStatus.tooManyRequests) {
    return AiConnectionStatus.rateLimited;
  }
  if (statusCode >= 500) return AiConnectionStatus.providerError;
  return AiConnectionStatus.endpointUnavailable;
}
