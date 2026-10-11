import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:test/test.dart';

void main() {
  group('extractJsonObject', () {
    test('parses a bare JSON object', () {
      expect(extractJsonObject('{"caption":"Golden sunset"}'), <String, Object?>{
        'caption': 'Golden sunset',
      });
    });

    test('strips think blocks before parsing', () {
      const payload = '''
<think>internal reasoning</think>
{"caption":"Golden sunset","labels":["sunset"]}
''';

      expect(extractJsonObject(payload), <String, Object?>{
        'caption': 'Golden sunset',
        'labels': <String>['sunset'],
      });
    });

    test('tolerates think blocks and fenced json', () {
      const payload = '''
<think>internal reasoning</think>
```json
{"caption":"Golden sunset","summary":"Warm light over a quiet shoreline.","labels":["sunset","shore","golden"]}
```
  ''';

      expect(extractJsonObject(payload), <String, Object?>{
        'caption': 'Golden sunset',
        'summary': 'Warm light over a quiet shoreline.',
        'labels': <String>['sunset', 'shore', 'golden'],
      });
    });

    test('extracts a json object from a fenced block without a language tag', () {
      const payload = '''
```{"caption":"Quiet morning"}```
''';

      expect(extractJsonObject(payload), <String, Object?>{
        'caption': 'Quiet morning',
      });
    });

    test('extracts the last balanced-looking object from mixed text', () {
      expect(extractJsonObject('noise {"a":1} middle text {"b":2} trailing'), <String, Object?>{
        'b': 2,
      });
    });

    test('returns null for non-json text', () {
      expect(extractJsonObject('no structured output here'), isNull);
    });

    test('returns null when a fenced block exists but fails to parse', () {
      expect(extractJsonObject('```json\n{not valid json}\n``` also {"ok":true}'), isNull);
    });

    test('falls through to candidates when no fenced block exists', () {
      expect(extractJsonObject('{"bad": } {"good":1}'), <String, Object?>{'good': 1});
    });
  });

  group('normalizeLabels', () {
    test('dedupes, trims, and caps label count', () {
      final labels = normalizeLabels(<Object?>[' sunset ', 'shore', '', 'shore', 'golden', 1, 'evening']);

      expect(labels, <String>['sunset', 'shore', 'golden', 'evening']);
    });

    test('returns an empty list for non-list input', () {
      expect(normalizeLabels('not a list'), isEmpty);
      expect(normalizeLabels(null), isEmpty);
    });

    test('caps the label count at 12', () {
      final labels = normalizeLabels(<Object?>[for (var i = 0; i < 14; i += 1) 'label-$i']);

      expect(labels, <String>[for (var i = 0; i < 12; i += 1) 'label-$i']);
    });

    test('deduplicates only within the first 12 trimmed entries', () {
      final labels = normalizeLabels(<Object?>[
        'x', 'x', 'y', 'y', 'z', 'z', '1', '2', '3', '4', '5', '6', '7', '8',
      ]);

      expect(labels, <String>['x', 'y', 'z', '1', '2', '3', '4', '5', '6']);
    });
  });

  group('normalizeText', () {
    test('trims strings and rejects non-strings', () {
      expect(normalizeText('  quiet scene  '), 'quiet scene');
      expect(normalizeText('   '), isNull);
      expect(normalizeText(42), isNull);
      expect(normalizeText(null), isNull);
    });
  });
}
