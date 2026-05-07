import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:test/test.dart';

void main() {
  test('orchestrates backup restore and photo actions through repository boundary', () {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
    final service = ChronoPicAppService(ChronoPicRepository());

    expect(service.previewBackupRestore(backup).photoCount, 2);
    expect(service.restoreBackup(backup).restoredPhotoCount, 2);
    expect(service.listPhotos(const PhotoFilter(favorite: true)).single.photo.id, 'photo-lake');
    expect(service.updatePhotoCaption('photo-city', 'Caption from app').semantic.caption, 'Caption from app');
    expect(service.updatePhotoFavorite('photo-city', true).photo.favorite, isTrue);
    expect(service.createBackup().photos.length, 2);
  });
}
