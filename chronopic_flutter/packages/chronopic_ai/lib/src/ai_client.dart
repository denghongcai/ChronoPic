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

final class MemoryAiResult {
  const MemoryAiResult({
    required this.status,
    this.generatedLabels = const <String>[],
    this.generatedName,
    this.generatedDescription,
    this.provider,
    this.model,
    this.error,
  });

  final AiPipelineStatus status;
  final List<String> generatedLabels;
  final String? generatedName;
  final String? generatedDescription;
  final String? provider;
  final String? model;
  final String? error;
}

/// Extra context threaded into photo prompts.
final class PhotoAiContext {
  const PhotoAiContext({this.outputLocale});

  /// Desired output language for generated caption/summary/labels, e.g.
  /// `zh-CN`. `null` means the default English output.
  final String? outputLocale;
}

/// Extra context threaded into memory prompts.
///
/// The [name] / [description] fields carry the user's current *unsaved draft*
/// title/description so the model can optimize instead of regenerate. A `null`
/// value means "not provided": the saved memory value is used as the working
/// draft. (The TypeScript reference additionally distinguishes an explicit
/// `null` meaning "the draft was cleared"; no current caller uses that, so Dart
/// treats absent and null identically.)
///
/// The `MemoryAIContext` vs `PhotoAiContext` casing split is deliberate
/// TypeScript parity: the Electron reference names these types
/// `MemoryAIContext` and `PhotoAIContext`, and the photo type is respelled
/// here because `AI`-initial acronyms are flagged by Dart's `camel_case_types`
/// lint.
final class MemoryAIContext {
  const MemoryAIContext({this.name, this.description, this.outputLocale});

  final String? name;
  final String? description;
  final String? outputLocale;
}

abstract interface class ChronoPicAiClient {
  bool get isEnabled;

  Future<PhotoAiResult> analyzePhoto({
    required String photoId,
    required List<int> bytes,
    required String mime,
    DateTime? datetime,
    double? lat,
    double? lng,
    String? path,
    PhotoAiContext context = const PhotoAiContext(),
  });

  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  });
}

final class DisabledAiClient implements ChronoPicAiClient {
  const DisabledAiClient();

  @override
  bool get isEnabled => false;

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
    return const PhotoAiResult(status: AiPipelineStatus.disabled);
  }

  @override
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  }) async {
    return const MemoryAiResult(status: AiPipelineStatus.disabled);
  }
}

final class FixtureSuccessAiClient implements ChronoPicAiClient {
  const FixtureSuccessAiClient({
    this.provider = 'fixture-provider',
    this.model = 'fixture-model',
  });

  final String provider;
  final String model;

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
    return PhotoAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: <String>['fixture', mime.split('/').first],
      generatedCaption: 'Generated caption for $photoId',
      summary: 'Generated summary for $photoId.',
      provider: provider,
      model: model,
    );
  }

  @override
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  }) async {
    return MemoryAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: const <String>['fixture', 'memory'],
      generatedName: 'Generated title for ${memory.id}',
      generatedDescription: 'Generated description for ${memory.id}.',
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
    return PhotoAiResult(status: AiPipelineStatus.failed, error: 'fixture failure for $photoId');
  }

  @override
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  }) async {
    return MemoryAiResult(status: AiPipelineStatus.failed, error: 'fixture failure for ${memory.id}');
  }
}
