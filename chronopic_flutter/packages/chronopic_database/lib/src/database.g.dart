// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LibrarySourcesTable extends LibrarySources
    with TableInfo<$LibrarySourcesTable, LibrarySource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibrarySourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastScanAtMeta = const VerificationMeta(
    'lastScanAt',
  );
  @override
  late final GeneratedColumn<int> lastScanAt = GeneratedColumn<int>(
    'last_scan_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    isActive,
    createdAt,
    updatedAt,
    lastScanAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibrarySource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_scan_at')) {
      context.handle(
        _lastScanAtMeta,
        lastScanAt.isAcceptableOrUnknown(
          data['last_scan_at']!,
          _lastScanAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibrarySource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibrarySource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastScanAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_scan_at'],
      ),
    );
  }

  @override
  $LibrarySourcesTable createAlias(String alias) {
    return $LibrarySourcesTable(attachedDatabase, alias);
  }
}

class LibrarySource extends DataClass implements Insertable<LibrarySource> {
  final String id;
  final String path;
  final bool isActive;
  final int createdAt;
  final int updatedAt;
  final int? lastScanAt;
  const LibrarySource({
    required this.id,
    required this.path,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastScanAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || lastScanAt != null) {
      map['last_scan_at'] = Variable<int>(lastScanAt);
    }
    return map;
  }

  LibrarySourcesCompanion toCompanion(bool nullToAbsent) {
    return LibrarySourcesCompanion(
      id: Value(id),
      path: Value(path),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastScanAt: lastScanAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScanAt),
    );
  }

  factory LibrarySource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibrarySource(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastScanAt: serializer.fromJson<int?>(json['lastScanAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastScanAt': serializer.toJson<int?>(lastScanAt),
    };
  }

  LibrarySource copyWith({
    String? id,
    String? path,
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    Value<int?> lastScanAt = const Value.absent(),
  }) => LibrarySource(
    id: id ?? this.id,
    path: path ?? this.path,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastScanAt: lastScanAt.present ? lastScanAt.value : this.lastScanAt,
  );
  LibrarySource copyWithCompanion(LibrarySourcesCompanion data) {
    return LibrarySource(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastScanAt: data.lastScanAt.present
          ? data.lastScanAt.value
          : this.lastScanAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySource(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastScanAt: $lastScanAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, path, isActive, createdAt, updatedAt, lastScanAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibrarySource &&
          other.id == this.id &&
          other.path == this.path &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastScanAt == this.lastScanAt);
}

class LibrarySourcesCompanion extends UpdateCompanion<LibrarySource> {
  final Value<String> id;
  final Value<String> path;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> lastScanAt;
  final Value<int> rowid;
  const LibrarySourcesCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastScanAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibrarySourcesCompanion.insert({
    required String id,
    required String path,
    required bool isActive,
    required int createdAt,
    required int updatedAt,
    this.lastScanAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path),
       isActive = Value(isActive),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LibrarySource> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lastScanAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastScanAt != null) 'last_scan_at': lastScanAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibrarySourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? path,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? lastScanAt,
    Value<int>? rowid,
  }) {
    return LibrarySourcesCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastScanAt.present) {
      map['last_scan_at'] = Variable<int>(lastScanAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySourcesCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoRecordsTable extends PhotoRecords
    with TableInfo<$PhotoRecordsTable, PhotoRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasGpsMeta = const VerificationMeta('hasGps');
  @override
  late final GeneratedColumn<bool> hasGps = GeneratedColumn<bool>(
    'has_gps',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_gps" IN (0, 1))',
    ),
  );
  static const VerificationMeta _jsonPayloadMeta = const VerificationMeta(
    'jsonPayload',
  );
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
    'json_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    favorite,
    hasGps,
    jsonPayload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    } else if (isInserting) {
      context.missing(_favoriteMeta);
    }
    if (data.containsKey('has_gps')) {
      context.handle(
        _hasGpsMeta,
        hasGps.isAcceptableOrUnknown(data['has_gps']!, _hasGpsMeta),
      );
    } else if (isInserting) {
      context.missing(_hasGpsMeta);
    }
    if (data.containsKey('json_payload')) {
      context.handle(
        _jsonPayloadMeta,
        jsonPayload.isAcceptableOrUnknown(
          data['json_payload']!,
          _jsonPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jsonPayloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      hasGps: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_gps'],
      )!,
      jsonPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_payload'],
      )!,
    );
  }

  @override
  $PhotoRecordsTable createAlias(String alias) {
    return $PhotoRecordsTable(attachedDatabase, alias);
  }
}

class PhotoRecord extends DataClass implements Insertable<PhotoRecord> {
  final String id;
  final String path;
  final bool favorite;
  final bool hasGps;
  final String jsonPayload;
  const PhotoRecord({
    required this.id,
    required this.path,
    required this.favorite,
    required this.hasGps,
    required this.jsonPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    map['favorite'] = Variable<bool>(favorite);
    map['has_gps'] = Variable<bool>(hasGps);
    map['json_payload'] = Variable<String>(jsonPayload);
    return map;
  }

  PhotoRecordsCompanion toCompanion(bool nullToAbsent) {
    return PhotoRecordsCompanion(
      id: Value(id),
      path: Value(path),
      favorite: Value(favorite),
      hasGps: Value(hasGps),
      jsonPayload: Value(jsonPayload),
    );
  }

  factory PhotoRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoRecord(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      hasGps: serializer.fromJson<bool>(json['hasGps']),
      jsonPayload: serializer.fromJson<String>(json['jsonPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'favorite': serializer.toJson<bool>(favorite),
      'hasGps': serializer.toJson<bool>(hasGps),
      'jsonPayload': serializer.toJson<String>(jsonPayload),
    };
  }

  PhotoRecord copyWith({
    String? id,
    String? path,
    bool? favorite,
    bool? hasGps,
    String? jsonPayload,
  }) => PhotoRecord(
    id: id ?? this.id,
    path: path ?? this.path,
    favorite: favorite ?? this.favorite,
    hasGps: hasGps ?? this.hasGps,
    jsonPayload: jsonPayload ?? this.jsonPayload,
  );
  PhotoRecord copyWithCompanion(PhotoRecordsCompanion data) {
    return PhotoRecord(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      hasGps: data.hasGps.present ? data.hasGps.value : this.hasGps,
      jsonPayload: data.jsonPayload.present
          ? data.jsonPayload.value
          : this.jsonPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoRecord(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('favorite: $favorite, ')
          ..write('hasGps: $hasGps, ')
          ..write('jsonPayload: $jsonPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, favorite, hasGps, jsonPayload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoRecord &&
          other.id == this.id &&
          other.path == this.path &&
          other.favorite == this.favorite &&
          other.hasGps == this.hasGps &&
          other.jsonPayload == this.jsonPayload);
}

class PhotoRecordsCompanion extends UpdateCompanion<PhotoRecord> {
  final Value<String> id;
  final Value<String> path;
  final Value<bool> favorite;
  final Value<bool> hasGps;
  final Value<String> jsonPayload;
  final Value<int> rowid;
  const PhotoRecordsCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.favorite = const Value.absent(),
    this.hasGps = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoRecordsCompanion.insert({
    required String id,
    required String path,
    required bool favorite,
    required bool hasGps,
    required String jsonPayload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path),
       favorite = Value(favorite),
       hasGps = Value(hasGps),
       jsonPayload = Value(jsonPayload);
  static Insertable<PhotoRecord> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<bool>? favorite,
    Expression<bool>? hasGps,
    Expression<String>? jsonPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (favorite != null) 'favorite': favorite,
      if (hasGps != null) 'has_gps': hasGps,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? path,
    Value<bool>? favorite,
    Value<bool>? hasGps,
    Value<String>? jsonPayload,
    Value<int>? rowid,
  }) {
    return PhotoRecordsCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      favorite: favorite ?? this.favorite,
      hasGps: hasGps ?? this.hasGps,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (hasGps.present) {
      map['has_gps'] = Variable<bool>(hasGps.value);
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoRecordsCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('favorite: $favorite, ')
          ..write('hasGps: $hasGps, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoriesTable extends Memories with TableInfo<$MemoriesTable, Memory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonPayloadMeta = const VerificationMeta(
    'jsonPayload',
  );
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
    'json_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, jsonPayload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Memory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('json_payload')) {
      context.handle(
        _jsonPayloadMeta,
        jsonPayload.isAcceptableOrUnknown(
          data['json_payload']!,
          _jsonPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jsonPayloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Memory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Memory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      jsonPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_payload'],
      )!,
    );
  }

  @override
  $MemoriesTable createAlias(String alias) {
    return $MemoriesTable(attachedDatabase, alias);
  }
}

class Memory extends DataClass implements Insertable<Memory> {
  final String id;
  final String name;
  final String jsonPayload;
  const Memory({
    required this.id,
    required this.name,
    required this.jsonPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['json_payload'] = Variable<String>(jsonPayload);
    return map;
  }

  MemoriesCompanion toCompanion(bool nullToAbsent) {
    return MemoriesCompanion(
      id: Value(id),
      name: Value(name),
      jsonPayload: Value(jsonPayload),
    );
  }

  factory Memory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Memory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      jsonPayload: serializer.fromJson<String>(json['jsonPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'jsonPayload': serializer.toJson<String>(jsonPayload),
    };
  }

  Memory copyWith({String? id, String? name, String? jsonPayload}) => Memory(
    id: id ?? this.id,
    name: name ?? this.name,
    jsonPayload: jsonPayload ?? this.jsonPayload,
  );
  Memory copyWithCompanion(MemoriesCompanion data) {
    return Memory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      jsonPayload: data.jsonPayload.present
          ? data.jsonPayload.value
          : this.jsonPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Memory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('jsonPayload: $jsonPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, jsonPayload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Memory &&
          other.id == this.id &&
          other.name == this.name &&
          other.jsonPayload == this.jsonPayload);
}

class MemoriesCompanion extends UpdateCompanion<Memory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> jsonPayload;
  final Value<int> rowid;
  const MemoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoriesCompanion.insert({
    required String id,
    required String name,
    required String jsonPayload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       jsonPayload = Value(jsonPayload);
  static Insertable<Memory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? jsonPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? jsonPayload,
    Value<int>? rowid,
  }) {
    return MemoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryPhotosTable extends MemoryPhotos
    with TableInfo<$MemoryPhotosTable, MemoryPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memoryIdMeta = const VerificationMeta(
    'memoryId',
  );
  @override
  late final GeneratedColumn<String> memoryId = GeneratedColumn<String>(
    'memory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [memoryId, photoId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('memory_id')) {
      context.handle(
        _memoryIdMeta,
        memoryId.isAcceptableOrUnknown(data['memory_id']!, _memoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memoryIdMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memoryId, photoId};
  @override
  MemoryPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryPhoto(
      memoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $MemoryPhotosTable createAlias(String alias) {
    return $MemoryPhotosTable(attachedDatabase, alias);
  }
}

class MemoryPhoto extends DataClass implements Insertable<MemoryPhoto> {
  final String memoryId;
  final String photoId;
  final int addedAt;
  const MemoryPhoto({
    required this.memoryId,
    required this.photoId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['memory_id'] = Variable<String>(memoryId);
    map['photo_id'] = Variable<String>(photoId);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  MemoryPhotosCompanion toCompanion(bool nullToAbsent) {
    return MemoryPhotosCompanion(
      memoryId: Value(memoryId),
      photoId: Value(photoId),
      addedAt: Value(addedAt),
    );
  }

  factory MemoryPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryPhoto(
      memoryId: serializer.fromJson<String>(json['memoryId']),
      photoId: serializer.fromJson<String>(json['photoId']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memoryId': serializer.toJson<String>(memoryId),
      'photoId': serializer.toJson<String>(photoId),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  MemoryPhoto copyWith({String? memoryId, String? photoId, int? addedAt}) =>
      MemoryPhoto(
        memoryId: memoryId ?? this.memoryId,
        photoId: photoId ?? this.photoId,
        addedAt: addedAt ?? this.addedAt,
      );
  MemoryPhoto copyWithCompanion(MemoryPhotosCompanion data) {
    return MemoryPhoto(
      memoryId: data.memoryId.present ? data.memoryId.value : this.memoryId,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryPhoto(')
          ..write('memoryId: $memoryId, ')
          ..write('photoId: $photoId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memoryId, photoId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryPhoto &&
          other.memoryId == this.memoryId &&
          other.photoId == this.photoId &&
          other.addedAt == this.addedAt);
}

class MemoryPhotosCompanion extends UpdateCompanion<MemoryPhoto> {
  final Value<String> memoryId;
  final Value<String> photoId;
  final Value<int> addedAt;
  final Value<int> rowid;
  const MemoryPhotosCompanion({
    this.memoryId = const Value.absent(),
    this.photoId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryPhotosCompanion.insert({
    required String memoryId,
    required String photoId,
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : memoryId = Value(memoryId),
       photoId = Value(photoId),
       addedAt = Value(addedAt);
  static Insertable<MemoryPhoto> custom({
    Expression<String>? memoryId,
    Expression<String>? photoId,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memoryId != null) 'memory_id': memoryId,
      if (photoId != null) 'photo_id': photoId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryPhotosCompanion copyWith({
    Value<String>? memoryId,
    Value<String>? photoId,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return MemoryPhotosCompanion(
      memoryId: memoryId ?? this.memoryId,
      photoId: photoId ?? this.photoId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memoryId.present) {
      map['memory_id'] = Variable<String>(memoryId.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryPhotosCompanion(')
          ..write('memoryId: $memoryId, ')
          ..write('photoId: $photoId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EditHistoryRowsTable extends EditHistoryRows
    with TableInfo<$EditHistoryRowsTable, EditHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditHistoryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonPayloadMeta = const VerificationMeta(
    'jsonPayload',
  );
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
    'json_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, photoId, jsonPayload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'edit_history_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<EditHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('json_payload')) {
      context.handle(
        _jsonPayloadMeta,
        jsonPayload.isAcceptableOrUnknown(
          data['json_payload']!,
          _jsonPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jsonPayloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EditHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EditHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      jsonPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_payload'],
      )!,
    );
  }

  @override
  $EditHistoryRowsTable createAlias(String alias) {
    return $EditHistoryRowsTable(attachedDatabase, alias);
  }
}

class EditHistoryRow extends DataClass implements Insertable<EditHistoryRow> {
  final String id;
  final String photoId;
  final String jsonPayload;
  const EditHistoryRow({
    required this.id,
    required this.photoId,
    required this.jsonPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['photo_id'] = Variable<String>(photoId);
    map['json_payload'] = Variable<String>(jsonPayload);
    return map;
  }

  EditHistoryRowsCompanion toCompanion(bool nullToAbsent) {
    return EditHistoryRowsCompanion(
      id: Value(id),
      photoId: Value(photoId),
      jsonPayload: Value(jsonPayload),
    );
  }

  factory EditHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EditHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      photoId: serializer.fromJson<String>(json['photoId']),
      jsonPayload: serializer.fromJson<String>(json['jsonPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'photoId': serializer.toJson<String>(photoId),
      'jsonPayload': serializer.toJson<String>(jsonPayload),
    };
  }

  EditHistoryRow copyWith({String? id, String? photoId, String? jsonPayload}) =>
      EditHistoryRow(
        id: id ?? this.id,
        photoId: photoId ?? this.photoId,
        jsonPayload: jsonPayload ?? this.jsonPayload,
      );
  EditHistoryRow copyWithCompanion(EditHistoryRowsCompanion data) {
    return EditHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      jsonPayload: data.jsonPayload.present
          ? data.jsonPayload.value
          : this.jsonPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EditHistoryRow(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('jsonPayload: $jsonPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, photoId, jsonPayload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditHistoryRow &&
          other.id == this.id &&
          other.photoId == this.photoId &&
          other.jsonPayload == this.jsonPayload);
}

class EditHistoryRowsCompanion extends UpdateCompanion<EditHistoryRow> {
  final Value<String> id;
  final Value<String> photoId;
  final Value<String> jsonPayload;
  final Value<int> rowid;
  const EditHistoryRowsCompanion({
    this.id = const Value.absent(),
    this.photoId = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EditHistoryRowsCompanion.insert({
    required String id,
    required String photoId,
    required String jsonPayload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       photoId = Value(photoId),
       jsonPayload = Value(jsonPayload);
  static Insertable<EditHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? photoId,
    Expression<String>? jsonPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoId != null) 'photo_id': photoId,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EditHistoryRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? photoId,
    Value<String>? jsonPayload,
    Value<int>? rowid,
  }) {
    return EditHistoryRowsCompanion(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditHistoryRowsCompanion(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryCandidateRowsTable extends MemoryCandidateRows
    with TableInfo<$MemoryCandidateRowsTable, MemoryCandidateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryCandidateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonPayloadMeta = const VerificationMeta(
    'jsonPayload',
  );
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
    'json_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, status, jsonPayload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_candidate_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryCandidateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('json_payload')) {
      context.handle(
        _jsonPayloadMeta,
        jsonPayload.isAcceptableOrUnknown(
          data['json_payload']!,
          _jsonPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jsonPayloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryCandidateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryCandidateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      jsonPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_payload'],
      )!,
    );
  }

  @override
  $MemoryCandidateRowsTable createAlias(String alias) {
    return $MemoryCandidateRowsTable(attachedDatabase, alias);
  }
}

class MemoryCandidateRow extends DataClass
    implements Insertable<MemoryCandidateRow> {
  final String id;
  final String status;
  final String jsonPayload;
  const MemoryCandidateRow({
    required this.id,
    required this.status,
    required this.jsonPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['json_payload'] = Variable<String>(jsonPayload);
    return map;
  }

  MemoryCandidateRowsCompanion toCompanion(bool nullToAbsent) {
    return MemoryCandidateRowsCompanion(
      id: Value(id),
      status: Value(status),
      jsonPayload: Value(jsonPayload),
    );
  }

  factory MemoryCandidateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryCandidateRow(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      jsonPayload: serializer.fromJson<String>(json['jsonPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'jsonPayload': serializer.toJson<String>(jsonPayload),
    };
  }

  MemoryCandidateRow copyWith({
    String? id,
    String? status,
    String? jsonPayload,
  }) => MemoryCandidateRow(
    id: id ?? this.id,
    status: status ?? this.status,
    jsonPayload: jsonPayload ?? this.jsonPayload,
  );
  MemoryCandidateRow copyWithCompanion(MemoryCandidateRowsCompanion data) {
    return MemoryCandidateRow(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      jsonPayload: data.jsonPayload.present
          ? data.jsonPayload.value
          : this.jsonPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCandidateRow(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('jsonPayload: $jsonPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, status, jsonPayload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryCandidateRow &&
          other.id == this.id &&
          other.status == this.status &&
          other.jsonPayload == this.jsonPayload);
}

class MemoryCandidateRowsCompanion extends UpdateCompanion<MemoryCandidateRow> {
  final Value<String> id;
  final Value<String> status;
  final Value<String> jsonPayload;
  final Value<int> rowid;
  const MemoryCandidateRowsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryCandidateRowsCompanion.insert({
    required String id,
    required String status,
    required String jsonPayload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       jsonPayload = Value(jsonPayload);
  static Insertable<MemoryCandidateRow> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? jsonPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryCandidateRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String>? jsonPayload,
    Value<int>? rowid,
  }) {
    return MemoryCandidateRowsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCandidateRowsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChronoPicDriftDatabase extends GeneratedDatabase {
  _$ChronoPicDriftDatabase(QueryExecutor e) : super(e);
  $ChronoPicDriftDatabaseManager get managers =>
      $ChronoPicDriftDatabaseManager(this);
  late final $LibrarySourcesTable librarySources = $LibrarySourcesTable(this);
  late final $PhotoRecordsTable photoRecords = $PhotoRecordsTable(this);
  late final $MemoriesTable memories = $MemoriesTable(this);
  late final $MemoryPhotosTable memoryPhotos = $MemoryPhotosTable(this);
  late final $EditHistoryRowsTable editHistoryRows = $EditHistoryRowsTable(
    this,
  );
  late final $MemoryCandidateRowsTable memoryCandidateRows =
      $MemoryCandidateRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    librarySources,
    photoRecords,
    memories,
    memoryPhotos,
    editHistoryRows,
    memoryCandidateRows,
  ];
}

typedef $$LibrarySourcesTableCreateCompanionBuilder =
    LibrarySourcesCompanion Function({
      required String id,
      required String path,
      required bool isActive,
      required int createdAt,
      required int updatedAt,
      Value<int?> lastScanAt,
      Value<int> rowid,
    });
typedef $$LibrarySourcesTableUpdateCompanionBuilder =
    LibrarySourcesCompanion Function({
      Value<String> id,
      Value<String> path,
      Value<bool> isActive,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> lastScanAt,
      Value<int> rowid,
    });

class $$LibrarySourcesTableFilterComposer
    extends Composer<_$ChronoPicDriftDatabase, $LibrarySourcesTable> {
  $$LibrarySourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibrarySourcesTableOrderingComposer
    extends Composer<_$ChronoPicDriftDatabase, $LibrarySourcesTable> {
  $$LibrarySourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibrarySourcesTableAnnotationComposer
    extends Composer<_$ChronoPicDriftDatabase, $LibrarySourcesTable> {
  $$LibrarySourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => column,
  );
}

class $$LibrarySourcesTableTableManager
    extends
        RootTableManager<
          _$ChronoPicDriftDatabase,
          $LibrarySourcesTable,
          LibrarySource,
          $$LibrarySourcesTableFilterComposer,
          $$LibrarySourcesTableOrderingComposer,
          $$LibrarySourcesTableAnnotationComposer,
          $$LibrarySourcesTableCreateCompanionBuilder,
          $$LibrarySourcesTableUpdateCompanionBuilder,
          (
            LibrarySource,
            BaseReferences<
              _$ChronoPicDriftDatabase,
              $LibrarySourcesTable,
              LibrarySource
            >,
          ),
          LibrarySource,
          PrefetchHooks Function()
        > {
  $$LibrarySourcesTableTableManager(
    _$ChronoPicDriftDatabase db,
    $LibrarySourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibrarySourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibrarySourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibrarySourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> lastScanAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibrarySourcesCompanion(
                id: id,
                path: path,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastScanAt: lastScanAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String path,
                required bool isActive,
                required int createdAt,
                required int updatedAt,
                Value<int?> lastScanAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibrarySourcesCompanion.insert(
                id: id,
                path: path,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastScanAt: lastScanAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibrarySourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$ChronoPicDriftDatabase,
      $LibrarySourcesTable,
      LibrarySource,
      $$LibrarySourcesTableFilterComposer,
      $$LibrarySourcesTableOrderingComposer,
      $$LibrarySourcesTableAnnotationComposer,
      $$LibrarySourcesTableCreateCompanionBuilder,
      $$LibrarySourcesTableUpdateCompanionBuilder,
      (
        LibrarySource,
        BaseReferences<
          _$ChronoPicDriftDatabase,
          $LibrarySourcesTable,
          LibrarySource
        >,
      ),
      LibrarySource,
      PrefetchHooks Function()
    >;
typedef $$PhotoRecordsTableCreateCompanionBuilder =
    PhotoRecordsCompanion Function({
      required String id,
      required String path,
      required bool favorite,
      required bool hasGps,
      required String jsonPayload,
      Value<int> rowid,
    });
typedef $$PhotoRecordsTableUpdateCompanionBuilder =
    PhotoRecordsCompanion Function({
      Value<String> id,
      Value<String> path,
      Value<bool> favorite,
      Value<bool> hasGps,
      Value<String> jsonPayload,
      Value<int> rowid,
    });

class $$PhotoRecordsTableFilterComposer
    extends Composer<_$ChronoPicDriftDatabase, $PhotoRecordsTable> {
  $$PhotoRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasGps => $composableBuilder(
    column: $table.hasGps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotoRecordsTableOrderingComposer
    extends Composer<_$ChronoPicDriftDatabase, $PhotoRecordsTable> {
  $$PhotoRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasGps => $composableBuilder(
    column: $table.hasGps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotoRecordsTableAnnotationComposer
    extends Composer<_$ChronoPicDriftDatabase, $PhotoRecordsTable> {
  $$PhotoRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<bool> get hasGps =>
      $composableBuilder(column: $table.hasGps, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => column,
  );
}

class $$PhotoRecordsTableTableManager
    extends
        RootTableManager<
          _$ChronoPicDriftDatabase,
          $PhotoRecordsTable,
          PhotoRecord,
          $$PhotoRecordsTableFilterComposer,
          $$PhotoRecordsTableOrderingComposer,
          $$PhotoRecordsTableAnnotationComposer,
          $$PhotoRecordsTableCreateCompanionBuilder,
          $$PhotoRecordsTableUpdateCompanionBuilder,
          (
            PhotoRecord,
            BaseReferences<
              _$ChronoPicDriftDatabase,
              $PhotoRecordsTable,
              PhotoRecord
            >,
          ),
          PhotoRecord,
          PrefetchHooks Function()
        > {
  $$PhotoRecordsTableTableManager(
    _$ChronoPicDriftDatabase db,
    $PhotoRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<bool> hasGps = const Value.absent(),
                Value<String> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoRecordsCompanion(
                id: id,
                path: path,
                favorite: favorite,
                hasGps: hasGps,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String path,
                required bool favorite,
                required bool hasGps,
                required String jsonPayload,
                Value<int> rowid = const Value.absent(),
              }) => PhotoRecordsCompanion.insert(
                id: id,
                path: path,
                favorite: favorite,
                hasGps: hasGps,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotoRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChronoPicDriftDatabase,
      $PhotoRecordsTable,
      PhotoRecord,
      $$PhotoRecordsTableFilterComposer,
      $$PhotoRecordsTableOrderingComposer,
      $$PhotoRecordsTableAnnotationComposer,
      $$PhotoRecordsTableCreateCompanionBuilder,
      $$PhotoRecordsTableUpdateCompanionBuilder,
      (
        PhotoRecord,
        BaseReferences<
          _$ChronoPicDriftDatabase,
          $PhotoRecordsTable,
          PhotoRecord
        >,
      ),
      PhotoRecord,
      PrefetchHooks Function()
    >;
typedef $$MemoriesTableCreateCompanionBuilder =
    MemoriesCompanion Function({
      required String id,
      required String name,
      required String jsonPayload,
      Value<int> rowid,
    });
typedef $$MemoriesTableUpdateCompanionBuilder =
    MemoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> jsonPayload,
      Value<int> rowid,
    });

class $$MemoriesTableFilterComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoriesTable> {
  $$MemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoriesTableOrderingComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoriesTable> {
  $$MemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoriesTableAnnotationComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoriesTable> {
  $$MemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => column,
  );
}

class $$MemoriesTableTableManager
    extends
        RootTableManager<
          _$ChronoPicDriftDatabase,
          $MemoriesTable,
          Memory,
          $$MemoriesTableFilterComposer,
          $$MemoriesTableOrderingComposer,
          $$MemoriesTableAnnotationComposer,
          $$MemoriesTableCreateCompanionBuilder,
          $$MemoriesTableUpdateCompanionBuilder,
          (
            Memory,
            BaseReferences<_$ChronoPicDriftDatabase, $MemoriesTable, Memory>,
          ),
          Memory,
          PrefetchHooks Function()
        > {
  $$MemoriesTableTableManager(_$ChronoPicDriftDatabase db, $MemoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion(
                id: id,
                name: name,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String jsonPayload,
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion.insert(
                id: id,
                name: name,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ChronoPicDriftDatabase,
      $MemoriesTable,
      Memory,
      $$MemoriesTableFilterComposer,
      $$MemoriesTableOrderingComposer,
      $$MemoriesTableAnnotationComposer,
      $$MemoriesTableCreateCompanionBuilder,
      $$MemoriesTableUpdateCompanionBuilder,
      (
        Memory,
        BaseReferences<_$ChronoPicDriftDatabase, $MemoriesTable, Memory>,
      ),
      Memory,
      PrefetchHooks Function()
    >;
typedef $$MemoryPhotosTableCreateCompanionBuilder =
    MemoryPhotosCompanion Function({
      required String memoryId,
      required String photoId,
      required int addedAt,
      Value<int> rowid,
    });
typedef $$MemoryPhotosTableUpdateCompanionBuilder =
    MemoryPhotosCompanion Function({
      Value<String> memoryId,
      Value<String> photoId,
      Value<int> addedAt,
      Value<int> rowid,
    });

class $$MemoryPhotosTableFilterComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoryPhotosTable> {
  $$MemoryPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memoryId => $composableBuilder(
    column: $table.memoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryPhotosTableOrderingComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoryPhotosTable> {
  $$MemoryPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memoryId => $composableBuilder(
    column: $table.memoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryPhotosTableAnnotationComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoryPhotosTable> {
  $$MemoryPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memoryId =>
      $composableBuilder(column: $table.memoryId, builder: (column) => column);

  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$MemoryPhotosTableTableManager
    extends
        RootTableManager<
          _$ChronoPicDriftDatabase,
          $MemoryPhotosTable,
          MemoryPhoto,
          $$MemoryPhotosTableFilterComposer,
          $$MemoryPhotosTableOrderingComposer,
          $$MemoryPhotosTableAnnotationComposer,
          $$MemoryPhotosTableCreateCompanionBuilder,
          $$MemoryPhotosTableUpdateCompanionBuilder,
          (
            MemoryPhoto,
            BaseReferences<
              _$ChronoPicDriftDatabase,
              $MemoryPhotosTable,
              MemoryPhoto
            >,
          ),
          MemoryPhoto,
          PrefetchHooks Function()
        > {
  $$MemoryPhotosTableTableManager(
    _$ChronoPicDriftDatabase db,
    $MemoryPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memoryId = const Value.absent(),
                Value<String> photoId = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryPhotosCompanion(
                memoryId: memoryId,
                photoId: photoId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memoryId,
                required String photoId,
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => MemoryPhotosCompanion.insert(
                memoryId: memoryId,
                photoId: photoId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$ChronoPicDriftDatabase,
      $MemoryPhotosTable,
      MemoryPhoto,
      $$MemoryPhotosTableFilterComposer,
      $$MemoryPhotosTableOrderingComposer,
      $$MemoryPhotosTableAnnotationComposer,
      $$MemoryPhotosTableCreateCompanionBuilder,
      $$MemoryPhotosTableUpdateCompanionBuilder,
      (
        MemoryPhoto,
        BaseReferences<
          _$ChronoPicDriftDatabase,
          $MemoryPhotosTable,
          MemoryPhoto
        >,
      ),
      MemoryPhoto,
      PrefetchHooks Function()
    >;
typedef $$EditHistoryRowsTableCreateCompanionBuilder =
    EditHistoryRowsCompanion Function({
      required String id,
      required String photoId,
      required String jsonPayload,
      Value<int> rowid,
    });
typedef $$EditHistoryRowsTableUpdateCompanionBuilder =
    EditHistoryRowsCompanion Function({
      Value<String> id,
      Value<String> photoId,
      Value<String> jsonPayload,
      Value<int> rowid,
    });

class $$EditHistoryRowsTableFilterComposer
    extends Composer<_$ChronoPicDriftDatabase, $EditHistoryRowsTable> {
  $$EditHistoryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EditHistoryRowsTableOrderingComposer
    extends Composer<_$ChronoPicDriftDatabase, $EditHistoryRowsTable> {
  $$EditHistoryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EditHistoryRowsTableAnnotationComposer
    extends Composer<_$ChronoPicDriftDatabase, $EditHistoryRowsTable> {
  $$EditHistoryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => column,
  );
}

class $$EditHistoryRowsTableTableManager
    extends
        RootTableManager<
          _$ChronoPicDriftDatabase,
          $EditHistoryRowsTable,
          EditHistoryRow,
          $$EditHistoryRowsTableFilterComposer,
          $$EditHistoryRowsTableOrderingComposer,
          $$EditHistoryRowsTableAnnotationComposer,
          $$EditHistoryRowsTableCreateCompanionBuilder,
          $$EditHistoryRowsTableUpdateCompanionBuilder,
          (
            EditHistoryRow,
            BaseReferences<
              _$ChronoPicDriftDatabase,
              $EditHistoryRowsTable,
              EditHistoryRow
            >,
          ),
          EditHistoryRow,
          PrefetchHooks Function()
        > {
  $$EditHistoryRowsTableTableManager(
    _$ChronoPicDriftDatabase db,
    $EditHistoryRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditHistoryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditHistoryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EditHistoryRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> photoId = const Value.absent(),
                Value<String> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EditHistoryRowsCompanion(
                id: id,
                photoId: photoId,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String photoId,
                required String jsonPayload,
                Value<int> rowid = const Value.absent(),
              }) => EditHistoryRowsCompanion.insert(
                id: id,
                photoId: photoId,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EditHistoryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChronoPicDriftDatabase,
      $EditHistoryRowsTable,
      EditHistoryRow,
      $$EditHistoryRowsTableFilterComposer,
      $$EditHistoryRowsTableOrderingComposer,
      $$EditHistoryRowsTableAnnotationComposer,
      $$EditHistoryRowsTableCreateCompanionBuilder,
      $$EditHistoryRowsTableUpdateCompanionBuilder,
      (
        EditHistoryRow,
        BaseReferences<
          _$ChronoPicDriftDatabase,
          $EditHistoryRowsTable,
          EditHistoryRow
        >,
      ),
      EditHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$MemoryCandidateRowsTableCreateCompanionBuilder =
    MemoryCandidateRowsCompanion Function({
      required String id,
      required String status,
      required String jsonPayload,
      Value<int> rowid,
    });
typedef $$MemoryCandidateRowsTableUpdateCompanionBuilder =
    MemoryCandidateRowsCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<String> jsonPayload,
      Value<int> rowid,
    });

class $$MemoryCandidateRowsTableFilterComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoryCandidateRowsTable> {
  $$MemoryCandidateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryCandidateRowsTableOrderingComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoryCandidateRowsTable> {
  $$MemoryCandidateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryCandidateRowsTableAnnotationComposer
    extends Composer<_$ChronoPicDriftDatabase, $MemoryCandidateRowsTable> {
  $$MemoryCandidateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => column,
  );
}

class $$MemoryCandidateRowsTableTableManager
    extends
        RootTableManager<
          _$ChronoPicDriftDatabase,
          $MemoryCandidateRowsTable,
          MemoryCandidateRow,
          $$MemoryCandidateRowsTableFilterComposer,
          $$MemoryCandidateRowsTableOrderingComposer,
          $$MemoryCandidateRowsTableAnnotationComposer,
          $$MemoryCandidateRowsTableCreateCompanionBuilder,
          $$MemoryCandidateRowsTableUpdateCompanionBuilder,
          (
            MemoryCandidateRow,
            BaseReferences<
              _$ChronoPicDriftDatabase,
              $MemoryCandidateRowsTable,
              MemoryCandidateRow
            >,
          ),
          MemoryCandidateRow,
          PrefetchHooks Function()
        > {
  $$MemoryCandidateRowsTableTableManager(
    _$ChronoPicDriftDatabase db,
    $MemoryCandidateRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryCandidateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryCandidateRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MemoryCandidateRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryCandidateRowsCompanion(
                id: id,
                status: status,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required String jsonPayload,
                Value<int> rowid = const Value.absent(),
              }) => MemoryCandidateRowsCompanion.insert(
                id: id,
                status: status,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryCandidateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChronoPicDriftDatabase,
      $MemoryCandidateRowsTable,
      MemoryCandidateRow,
      $$MemoryCandidateRowsTableFilterComposer,
      $$MemoryCandidateRowsTableOrderingComposer,
      $$MemoryCandidateRowsTableAnnotationComposer,
      $$MemoryCandidateRowsTableCreateCompanionBuilder,
      $$MemoryCandidateRowsTableUpdateCompanionBuilder,
      (
        MemoryCandidateRow,
        BaseReferences<
          _$ChronoPicDriftDatabase,
          $MemoryCandidateRowsTable,
          MemoryCandidateRow
        >,
      ),
      MemoryCandidateRow,
      PrefetchHooks Function()
    >;

class $ChronoPicDriftDatabaseManager {
  final _$ChronoPicDriftDatabase _db;
  $ChronoPicDriftDatabaseManager(this._db);
  $$LibrarySourcesTableTableManager get librarySources =>
      $$LibrarySourcesTableTableManager(_db, _db.librarySources);
  $$PhotoRecordsTableTableManager get photoRecords =>
      $$PhotoRecordsTableTableManager(_db, _db.photoRecords);
  $$MemoriesTableTableManager get memories =>
      $$MemoriesTableTableManager(_db, _db.memories);
  $$MemoryPhotosTableTableManager get memoryPhotos =>
      $$MemoryPhotosTableTableManager(_db, _db.memoryPhotos);
  $$EditHistoryRowsTableTableManager get editHistoryRows =>
      $$EditHistoryRowsTableTableManager(_db, _db.editHistoryRows);
  $$MemoryCandidateRowsTableTableManager get memoryCandidateRows =>
      $$MemoryCandidateRowsTableTableManager(_db, _db.memoryCandidateRows);
}
