import 'package:chronopic_domain/chronopic_domain.dart';

import 'ai_client.dart';

/// Describes the requested model output language for prompts.
///
/// Ported verbatim from the Electron reference
/// (`packages/services-ai-pipeline/src/index.ts`).
String describeOutputLocale(String? locale) {
  return locale == 'zh-CN' ? 'Simplified Chinese (zh-CN)' : 'English (en-US)';
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final index = normalized.lastIndexOf('/');
  return index == -1 ? normalized : normalized.substring(index + 1);
}

/// Builds the strict-JSON photo analysis prompt.
///
/// Ported verbatim from the Electron reference `buildAnalysisPrompt`.
String buildPhotoAnalysisPrompt({
  required String mime,
  DateTime? datetime,
  double? lat,
  double? lng,
  String? path,
  PhotoAiContext context = const PhotoAiContext(),
}) {
  final datetimeText =
      datetime?.toUtc().toIso8601String() ?? 'unknown';
  final gps = lat != null && lng != null ? '$lat, $lng' : 'unknown';

  return [
    'You are enriching a personal photo library for desktop browsing and search.',
    'Analyze the provided image and return strict JSON only.',
    'JSON shape:',
    '{ "caption": string | null, "summary": string | null, "labels": string[] }',
    'Rules:',
    '- caption: short natural title for the image, max 12 words.',
    '- summary: 1 concise sentence describing the scene, useful for semantic browsing.',
    '- labels: 3 to 8 lowercase tags, concise nouns/adjectives only, no duplicates.',
    '- Do not include reasoning, think tags, markdown explanation, or any text outside the JSON object.',
    '- Use the visual content as the primary source of truth.',
    '- If the image is ambiguous, stay conservative.',
    'Output language for caption, summary, and labels: ${describeOutputLocale(context.outputLocale)}.',
    'Known metadata: mime=$mime; datetime=$datetimeText; gps=$gps; path=${path == null ? 'unknown' : _basename(path)}.',
  ].join('\n');
}

/// Builds the strict-JSON memory analysis prompt.
///
/// Ported verbatim from the Electron reference `buildMemoryAnalysisPrompt`.
/// The working title/description come from [context]; a null context field
/// means "not provided" and falls back to the saved memory value.
String buildMemoryAnalysisPrompt({
  required Memory memory,
  required List<PhotoRecord> photos,
  MemoryAIContext context = const MemoryAIContext(),
}) {
  // `context.name` is non-nullable after the fallback because `memory.name`
  // is required; the description stays nullable.
  final workingName = (context.name ?? memory.name).trim();
  final workingDescriptionText = context.description?.trim() ??
      memory.description?.trim();
  final hasWorkingName = workingName.isNotEmpty;
  final hasWorkingDescription =
      workingDescriptionText?.isNotEmpty ?? false;
  final sampleLines = photos.take(12).toList().asMap().entries.map((entry) {
    final index = entry.key;
    final photo = entry.value;
    final datetimeMs = photo.metadata.datetime;
    final date = datetimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(
            datetimeMs,
          ).toUtc().toIso8601String().substring(0, 10)
        : 'unknown-date';
    final lat = photo.metadata.lat;
    final lng = photo.metadata.lng;
    final gps = lat != null && lng != null ? '$lat,$lng' : 'unknown-gps';
    final caption = photo.semantic.generatedCaption ??
        photo.semantic.caption ??
        _basename(photo.photo.path);
    final summary = photo.semantic.summary ?? 'no-summary';
    final labels = [
      ...photo.semantic.labels,
      ...photo.semantic.generatedLabels,
    ].take(6).join(', ');
    return '${index + 1}. date=$date; gps=$gps; caption=$caption; '
        'summary=$summary; labels=${labels.isEmpty ? 'no-tags' : labels}';
  });

  return [
    'You are generating metadata for a photo memory inside a local-first desktop library.',
    'Return strict JSON only.',
    'JSON shape:',
    '{ "title": string | null, "description": string | null, "labels": string[] }',
    'Rules:',
    hasWorkingName
        ? '- title: optimize the current working title while preserving its intent; max 6 words.'
        : '- title: generate a short evocative memory title, max 6 words.',
    hasWorkingDescription
        ? '- description: optimize the current working description while preserving its user-provided intent and concrete details.'
        : '- description: generate 1 to 3 sentences, concise but specific, describing the trip/story/theme across the photos.',
    '- labels: 3 to 8 lowercase tags describing the whole memory.',
    '- Use the provided photo summaries as the source of truth. Do not invent people, places, or events not supported by the inputs.',
    '- Do not output markdown, bullets, or explanatory text outside the JSON object.',
    'Output language for title, description, and labels: ${describeOutputLocale(context.outputLocale)}.',
    'Saved memory name: ${memory.name}.',
    'Saved description: ${memory.description ?? 'none'}.',
    'Current working title draft: ${hasWorkingName ? workingName : 'none'}.',
    'Current working description draft: ${hasWorkingDescription ? workingDescriptionText : 'none'}.',
    'Photo sample set:',
    ...sampleLines,
  ].join('\n');
}
