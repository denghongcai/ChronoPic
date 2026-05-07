import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';

final class ChronoPicAppService {
  ChronoPicAppService(this.repository);

  final ChronoPicRepository repository;

  BackupRestorePreview previewBackupRestore(ChronoPicBackup backup) => repository.previewBackupRestore(backup);

  BackupRestoreResult restoreBackup(ChronoPicBackup backup) => repository.restoreBackup(backup);

  ChronoPicBackup createBackup() => repository.createBackup();

  List<PhotoRecord> listPhotos([PhotoFilter filter = const PhotoFilter()]) => repository.listPhotos(filter);

  PhotoRecord? getPhoto(String photoId) => repository.getPhoto(photoId);

  PhotoRecord updatePhotoCaption(String photoId, String? caption) => repository.updatePhotoCaption(photoId, caption);

  PhotoRecord updatePhotoTags(String photoId, List<String> labels) => repository.updatePhotoTags(photoId, labels);

  PhotoRecord updatePhotoFavorite(String photoId, bool favorite) => repository.updatePhotoFavorite(photoId, favorite);
}

