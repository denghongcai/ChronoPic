import 'package:chronopic_database/chronopic_database_testing.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('Drift database restores parity fixture into typed tables', () async {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
    final db = ChronoPicDriftDatabase();
    addTearDown(db.close);

    await db.restoreBackup(backup);

    expect(await db.photoCount(), 2);
    expect(await db.memoryCount(), 1);
    expect((await db.listPhotos(favorite: true)).map((record) => record.photo.id), ['photo-lake']);
    expect((await db.listPhotos(hasGps: true)).map((record) => record.photo.id), ['photo-lake']);
    expect((await db.listMemoryCandidates()).map((candidate) => candidate.id), ['candidate-city-lake']);
  });
}
