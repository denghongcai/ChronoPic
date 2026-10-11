import 'dart:convert';

final RegExp _thinkBlock = RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false);
final RegExp _fencedBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
final RegExp _objectCandidate = RegExp(r'\{[\s\S]*?\}');

/// Normalizes raw model label output into trimmed, non-empty, de-duplicated labels.
///
/// Mirrors the TypeScript reference: labels are trimmed, empties and non-strings
/// dropped, the first 12 surviving entries kept, and only then de-duplicated in
/// first-occurrence order.
List<String> normalizeLabels(Object? labels) {
  if (labels is! List) {
    return const <String>[];
  }

  final trimmed = labels
      .map((value) => value is String ? value.trim() : '')
      .where((value) => value.isNotEmpty)
      .take(12);
  return <String>{...trimmed}.toList(growable: false);
}

/// Normalizes raw model text output: trims strings, and maps empty or non-string
/// values to `null`.
String? normalizeText(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isNotEmpty ? trimmed : null;
}

/// Extracts the first usable JSON object from raw model output.
///
/// Tolerates `<think>` reasoning blocks, fenced code blocks, and surrounding
/// prose. Returns `null` when no parseable object exists, and short-circuits to
/// `null` when a fenced block is present but its content fails to parse.
///
/// Note on the prose-fallback candidate regex: it is non-greedy
/// (`\{[\s\S]*?\}`), so it cannot parse prose-wrapped *nested* JSON such as
/// `result: {"a": {"b": 1}} end` — the first candidate `{"a": {"b": 1}` is
/// unbalanced and fails to parse. The bare-object fast path (input starting
/// with `{` and ending with `}`) does handle nesting, because the whole input
/// is parsed as one JSON document.
Map<String, Object?>? extractJsonObject(String input) {
  final trimmed = input.replaceAll(_thinkBlock, '').trim();

  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      return jsonDecode(trimmed) as Map<String, Object?>;
    } on Object {
      // Fall through to fenced extraction.
    }
  }

  final fencedBody = _fencedBlock.firstMatch(trimmed)?.group(1);
  if (fencedBody != null && fencedBody.isNotEmpty) {
    try {
      return jsonDecode(fencedBody) as Map<String, Object?>;
    } on Object {
      return null;
    }
  }

  final candidates = _objectCandidate.allMatches(trimmed).toList(growable: false);
  for (final match in candidates.reversed) {
    try {
      return jsonDecode(match.group(0)!) as Map<String, Object?>;
    } on Object {
      continue;
    }
  }

  return null;
}
