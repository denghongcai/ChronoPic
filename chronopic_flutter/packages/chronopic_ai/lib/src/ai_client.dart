import 'package:chronopic_domain/chronopic_domain.dart';

final class PhotoAiResult {
  const PhotoAiResult({
    required this.status,
    this.generatedLabels = const <String>[],
    this.generatedCaption,
    this.summary,
    this.provider,
    this.model,
    this.error,
  });

  final AiPipelineStatus status;
  final List<String> generatedLabels;
  final String? generatedCaption;
  final String? summary;
  final String? provider;
  final String? model;
  final String? error;
}

abstract interface class ChronoPicAiClient {
  bool get isEnabled;

  Future<PhotoAiResult> analyzePhoto({required String photoId, required List<int> bytes, required String mime});
}

final class DisabledAiClient implements ChronoPicAiClient {
  const DisabledAiClient();

  @override
  bool get isEnabled => false;

  @override
  Future<PhotoAiResult> analyzePhoto({required String photoId, required List<int> bytes, required String mime}) async {
    return const PhotoAiResult(status: AiPipelineStatus.disabled);
  }
}

final class FixtureSuccessAiClient implements ChronoPicAiClient {
  const FixtureSuccessAiClient({this.provider = 'fixture-provider', this.model = 'fixture-model'});

  final String provider;
  final String model;

  @override
  bool get isEnabled => true;

  @override
  Future<PhotoAiResult> analyzePhoto({required String photoId, required List<int> bytes, required String mime}) async {
    return PhotoAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: <String>['fixture', mime.split('/').first],
      generatedCaption: 'Generated caption for $photoId',
      summary: 'Generated summary for $photoId.',
      provider: provider,
      model: model,
    );
  }
}

final class FixtureFailureAiClient implements ChronoPicAiClient {
  const FixtureFailureAiClient();

  @override
  bool get isEnabled => true;

  @override
  Future<PhotoAiResult> analyzePhoto({required String photoId, required List<int> bytes, required String mime}) async {
    return PhotoAiResult(status: AiPipelineStatus.failed, error: 'fixture failure for $photoId');
  }
}

