import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

typedef JsonMap = Map<String, Object?>;

final class FlutterParityFixtures {
  FlutterParityFixtures._();

  static File get backupFile => File(p.join(_repoRoot.path, 'tests', 'fixtures', 'flutter-parity', 'chronopic-backup-v1.json'));

  static File get expectedFile =>
      File(p.join(_repoRoot.path, 'tests', 'fixtures', 'flutter-parity', 'chronopic-backup-v1.expected.json'));

  static JsonMap readBackupJson() {
    return (jsonDecode(backupFile.readAsStringSync()) as Map).cast<String, Object?>();
  }

  static JsonMap readExpectedJson() {
    return (jsonDecode(expectedFile.readAsStringSync()) as Map).cast<String, Object?>();
  }

  static Directory get _repoRoot {
    var current = Directory.current.absolute;
    while (true) {
      final marker = File(p.join(current.path, 'PLAN.md'));
      final fixture = File(p.join(current.path, 'tests', 'fixtures', 'flutter-parity', 'chronopic-backup-v1.json'));
      if (marker.existsSync() && fixture.existsSync()) return current;
      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError('Could not locate ChronoPic repository root from ${Directory.current.path}');
      }
      current = parent;
    }
  }
}
