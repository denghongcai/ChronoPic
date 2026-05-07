import 'dart:convert';
import 'package:chronopic_domain/chronopic_domain.dart' as domain;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

class LibrarySources extends Table {
  TextColumn get id => text()();
  TextColumn get path => text()();
  BoolColumn get isActive => boolean()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastScanAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PhotoRecords extends Table {
  TextColumn get id => text()();
  TextColumn get path => text()();
  BoolColumn get favorite => boolean()();
  BoolColumn get hasGps => boolean()();
  TextColumn get jsonPayload => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Memories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get jsonPayload => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MemoryPhotos extends Table {
  TextColumn get memoryId => text()();
  TextColumn get photoId => text()();
  IntColumn get addedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {memoryId, photoId};
}

class EditHistoryRows extends Table {
  TextColumn get id => text()();
  TextColumn get photoId => text()();
  TextColumn get jsonPayload => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MemoryCandidateRows extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()();
  TextColumn get jsonPayload => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [LibrarySources, PhotoRecords, Memories, MemoryPhotos, EditHistoryRows, MemoryCandidateRows])
class ChronoPicDriftDatabase extends _$ChronoPicDriftDatabase {
  ChronoPicDriftDatabase() : super(_openMemoryDatabase());

  @override
  int get schemaVersion => 1;

  Future<void> restoreBackup(domain.ChronoPicBackup backup) async {
    final validation = domain.validateChronoPicBackup(backup);
    if (!validation.valid) {
      throw StateError('Invalid ChronoPic backup: ${validation.errors.join(', ')}');
    }
    await transaction(() async {
      await delete(memoryCandidateRows).go();
      await delete(editHistoryRows).go();
      await delete(memoryPhotos).go();
      await delete(memories).go();
      await delete(photoRecords).go();
      await delete(librarySources).go();

      for (final source in backup.librarySources) {
        await into(librarySources).insert(
          LibrarySourcesCompanion.insert(
            id: source.id,
            path: source.path,
            isActive: source.isActive,
            createdAt: source.createdAt,
            updatedAt: source.updatedAt,
            lastScanAt: Value(source.lastScanAt),
          ),
        );
      }
      for (final record in backup.photos) {
        await into(photoRecords).insert(
          PhotoRecordsCompanion.insert(
            id: record.photo.id,
            path: record.photo.path,
            favorite: record.photo.favorite,
            hasGps: record.metadata.lat != null && record.metadata.lng != null,
            jsonPayload: jsonEncode(record.toJson()),
          ),
        );
      }
      for (final memory in backup.memories) {
        await into(memories).insert(
          MemoriesCompanion.insert(id: memory.id, name: memory.name, jsonPayload: jsonEncode(memory.toJson())),
        );
      }
      for (final membership in backup.memoryPhotos) {
        await into(memoryPhotos).insert(
          MemoryPhotosCompanion.insert(memoryId: membership.memoryId, photoId: membership.photoId, addedAt: membership.addedAt),
        );
      }
      for (final edit in backup.editHistory) {
        await into(editHistoryRows).insert(
          EditHistoryRowsCompanion.insert(id: edit.id, photoId: edit.photoId, jsonPayload: jsonEncode(edit.toJson())),
        );
      }
      for (final candidate in backup.memoryCandidates) {
        await into(memoryCandidateRows).insert(
          MemoryCandidateRowsCompanion.insert(id: candidate.id, status: candidate.status.name, jsonPayload: jsonEncode(candidate.toJson())),
        );
      }
    });
  }

  Future<List<domain.PhotoRecord>> listPhotos({bool? favorite, bool? hasGps}) async {
    var query = select(photoRecords);
    if (favorite != null) query = query..where((row) => row.favorite.equals(favorite));
    if (hasGps != null) query = query..where((row) => row.hasGps.equals(hasGps));
    final rows = await query.get();
    return rows.map((row) => domain.PhotoRecord.fromJson((jsonDecode(row.jsonPayload) as Map).cast<String, Object?>())).toList();
  }

  Future<List<domain.MemoryCandidate>> listMemoryCandidates() async {
    final rows = await select(memoryCandidateRows).get();
    return rows.map((row) => domain.MemoryCandidate.fromJson((jsonDecode(row.jsonPayload) as Map).cast<String, Object?>())).toList();
  }

  Future<int> photoCount() async => (select(photoRecords)..limit(1000000)).get().then((rows) => rows.length);

  Future<int> memoryCount() async => (select(memories)..limit(1000000)).get().then((rows) => rows.length);
}

QueryExecutor _openMemoryDatabase() {
  return NativeDatabase.memory();
}
