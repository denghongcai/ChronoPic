import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('restores and exports the Flutter parity backup fixture', () {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
    final expected = FlutterParityFixtures.readExpectedJson();
    final counts = (expected['counts'] as Map).cast<String, Object?>();
    final repository = ChronoPicRepository();

    final preview = repository.previewBackupRestore(backup);
    expect(preview.photoCount, counts['photoCount']);

    final result = repository.restoreBackup(backup);
    expect(result.restoredPhotoCount, counts['photoCount']);
    expect(result.restoredMemoryCount, counts['memoryCount']);
    expect(result.restoredMemoryPhotoCount, counts['memoryPhotoCount']);

    final exported = repository.createBackup();
    expect(exported.photos.length, counts['photoCount']);
    expect(exported.memories.length, counts['memoryCount']);
    expect(exported.memoryCandidates.length, counts['memoryCandidateCount']);
    expect(validateChronoPicBackup(exported).valid, isTrue);
  });

  test('supports critical photo, memory, and candidate repository operations', () {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
    final repository = ChronoPicRepository()..restoreBackup(backup);

    expect(repository.listPhotos(const PhotoFilter(favorite: true)).map((record) => record.photo.id), ['photo-lake']);
    expect(repository.listPhotos(const PhotoFilter(hasGps: true)).map((record) => record.photo.id), ['photo-lake']);
    expect(repository.listPhotosByMemory('memory-weekend').map((record) => record.photo.id), ['photo-lake']);
    expect(repository.listMemoryCandidates().map((candidate) => candidate.id), ['candidate-city-lake']);

    expect(repository.updatePhotoCaption('photo-city', 'Manual city caption').semantic.caption, 'Manual city caption');
    expect(repository.updatePhotoTags('photo-city', ['city', 'manual']).semantic.labels, ['city', 'manual']);
    expect(repository.updatePhotoFavorite('photo-city', true).photo.favorite, isTrue);

    repository.createMemory('memory-extra', 'Extra Memory', description: 'Created by repository test');
    repository.addPhotoToMemory('memory-extra', 'photo-city');
    expect(repository.listPhotosByMemory('memory-extra').map((record) => record.photo.id), ['photo-city']);
  });
}
