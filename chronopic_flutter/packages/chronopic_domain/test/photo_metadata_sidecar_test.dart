import 'dart:convert';

import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:test/test.dart';

void main() {
  test('round trips the versioned photo metadata sidecar contract', () {
    const sidecar = PhotoMetadataSidecar(
      app: PhotoMetadataSidecar.expectedApp,
      format: PhotoMetadataSidecar.expectedFormat,
      schemaVersion: PhotoMetadataSidecar.currentSchemaVersion,
      sha256:
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      pathFingerprint:
          'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      size: 1234,
      datetime: 1712345678000,
      lat: 37.5,
      lng: -122.25,
      camera: 'ChronoPic Camera',
      confidence: 0.9,
      originalDatetimeText: '2024:04:05 06:07:08',
      caption: 'A caption',
      tags: ['travel', 'sunset'],
      favorite: true,
    );

    final decoded = PhotoMetadataSidecar.fromJson(
      jsonDecode(jsonEncode(sidecar.toJson())) as Map<String, Object?>,
    );

    expect(decoded.toJson(), sidecar.toJson());
    expect(validatePhotoMetadataSidecar(decoded).valid, isTrue);
  });

  test('rejects unsupported identity and invalid metadata values', () {
    const sidecar = PhotoMetadataSidecar(
      app: 'Other',
      format: 'other-format',
      schemaVersion: 2,
      sha256: 'not-a-digest',
      pathFingerprint: 'not-a-path-fingerprint',
      size: -1,
      datetime: null,
      lat: 91,
      lng: null,
      camera: null,
      confidence: 1.5,
      originalDatetimeText: null,
      caption: null,
      tags: [''],
      favorite: false,
    );

    final validation = validatePhotoMetadataSidecar(sidecar);

    expect(validation.valid, isFalse);
    expect(validation.errors, hasLength(10));
  });
}
