// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ayahId,
    folderId,
    label,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final int ayahId;
  final int? folderId;
  final String? label;
  final DateTime createdAt;
  const Bookmark({
    required this.id,
    required this.ayahId,
    this.folderId,
    this.label,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      label: serializer.fromJson<String?>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'folderId': serializer.toJson<int?>(folderId),
      'label': serializer.toJson<String?>(label),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith({
    int? id,
    int? ayahId,
    Value<int?> folderId = const Value.absent(),
    Value<String?> label = const Value.absent(),
    DateTime? createdAt,
  }) => Bookmark(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    folderId: folderId.present ? folderId.value : this.folderId,
    label: label.present ? label.value : this.label,
    createdAt: createdAt ?? this.createdAt,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('folderId: $folderId, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ayahId, folderId, label, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.folderId == this.folderId &&
          other.label == this.label &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<int?> folderId;
  final Value<String?> label;
  final Value<DateTime> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    this.folderId = const Value.absent(),
    this.label = const Value.absent(),
    required DateTime createdAt,
  }) : ayahId = Value(ayahId),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<int>? folderId,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (folderId != null) 'folder_id': folderId,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<int?>? folderId,
    Value<String?>? label,
    Value<DateTime>? createdAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      folderId: folderId ?? this.folderId,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('folderId: $folderId, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressTable extends ReadingProgress
    with TableInfo<$ReadingProgressTable, ReadingProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastPageMeta = const VerificationMeta(
    'lastPage',
  );
  @override
  late final GeneratedColumn<int> lastPage = GeneratedColumn<int>(
    'last_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streakDaysMeta = const VerificationMeta(
    'streakDays',
  );
  @override
  late final GeneratedColumn<int> streakDays = GeneratedColumn<int>(
    'streak_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _streakLastDayMeta = const VerificationMeta(
    'streakLastDay',
  );
  @override
  late final GeneratedColumn<String> streakLastDay = GeneratedColumn<String>(
    'streak_last_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lastPage,
    streakDays,
    streakLastDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_page')) {
      context.handle(
        _lastPageMeta,
        lastPage.isAcceptableOrUnknown(data['last_page']!, _lastPageMeta),
      );
    }
    if (data.containsKey('streak_days')) {
      context.handle(
        _streakDaysMeta,
        streakDays.isAcceptableOrUnknown(data['streak_days']!, _streakDaysMeta),
      );
    }
    if (data.containsKey('streak_last_day')) {
      context.handle(
        _streakLastDayMeta,
        streakLastDay.isAcceptableOrUnknown(
          data['streak_last_day']!,
          _streakLastDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_page'],
      ),
      streakDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_days'],
      )!,
      streakLastDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}streak_last_day'],
      ),
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }
}

class ReadingProgressData extends DataClass
    implements Insertable<ReadingProgressData> {
  final int id;
  final int? lastPage;
  final int streakDays;
  final String? streakLastDay;
  const ReadingProgressData({
    required this.id,
    this.lastPage,
    required this.streakDays,
    this.streakLastDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lastPage != null) {
      map['last_page'] = Variable<int>(lastPage);
    }
    map['streak_days'] = Variable<int>(streakDays);
    if (!nullToAbsent || streakLastDay != null) {
      map['streak_last_day'] = Variable<String>(streakLastDay);
    }
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      id: Value(id),
      lastPage: lastPage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPage),
      streakDays: Value(streakDays),
      streakLastDay: streakLastDay == null && nullToAbsent
          ? const Value.absent()
          : Value(streakLastDay),
    );
  }

  factory ReadingProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressData(
      id: serializer.fromJson<int>(json['id']),
      lastPage: serializer.fromJson<int?>(json['lastPage']),
      streakDays: serializer.fromJson<int>(json['streakDays']),
      streakLastDay: serializer.fromJson<String?>(json['streakLastDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastPage': serializer.toJson<int?>(lastPage),
      'streakDays': serializer.toJson<int>(streakDays),
      'streakLastDay': serializer.toJson<String?>(streakLastDay),
    };
  }

  ReadingProgressData copyWith({
    int? id,
    Value<int?> lastPage = const Value.absent(),
    int? streakDays,
    Value<String?> streakLastDay = const Value.absent(),
  }) => ReadingProgressData(
    id: id ?? this.id,
    lastPage: lastPage.present ? lastPage.value : this.lastPage,
    streakDays: streakDays ?? this.streakDays,
    streakLastDay: streakLastDay.present
        ? streakLastDay.value
        : this.streakLastDay,
  );
  ReadingProgressData copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressData(
      id: data.id.present ? data.id.value : this.id,
      lastPage: data.lastPage.present ? data.lastPage.value : this.lastPage,
      streakDays: data.streakDays.present
          ? data.streakDays.value
          : this.streakDays,
      streakLastDay: data.streakLastDay.present
          ? data.streakLastDay.value
          : this.streakLastDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressData(')
          ..write('id: $id, ')
          ..write('lastPage: $lastPage, ')
          ..write('streakDays: $streakDays, ')
          ..write('streakLastDay: $streakLastDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastPage, streakDays, streakLastDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressData &&
          other.id == this.id &&
          other.lastPage == this.lastPage &&
          other.streakDays == this.streakDays &&
          other.streakLastDay == this.streakLastDay);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressData> {
  final Value<int> id;
  final Value<int?> lastPage;
  final Value<int> streakDays;
  final Value<String?> streakLastDay;
  const ReadingProgressCompanion({
    this.id = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.streakLastDay = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    this.id = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.streakLastDay = const Value.absent(),
  });
  static Insertable<ReadingProgressData> custom({
    Expression<int>? id,
    Expression<int>? lastPage,
    Expression<int>? streakDays,
    Expression<String>? streakLastDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastPage != null) 'last_page': lastPage,
      if (streakDays != null) 'streak_days': streakDays,
      if (streakLastDay != null) 'streak_last_day': streakLastDay,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<int>? id,
    Value<int?>? lastPage,
    Value<int>? streakDays,
    Value<String?>? streakLastDay,
  }) {
    return ReadingProgressCompanion(
      id: id ?? this.id,
      lastPage: lastPage ?? this.lastPage,
      streakDays: streakDays ?? this.streakDays,
      streakLastDay: streakLastDay ?? this.streakLastDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastPage.present) {
      map['last_page'] = Variable<int>(lastPage.value);
    }
    if (streakDays.present) {
      map['streak_days'] = Variable<int>(streakDays.value);
    }
    if (streakLastDay.present) {
      map['streak_last_day'] = Variable<String>(streakLastDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('id: $id, ')
          ..write('lastPage: $lastPage, ')
          ..write('streakDays: $streakDays, ')
          ..write('streakLastDay: $streakLastDay')
          ..write(')'))
        .toString();
  }
}

class $KhatmaPlansTable extends KhatmaPlans
    with TableInfo<$KhatmaPlansTable, KhatmaPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhatmaPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDaysMeta = const VerificationMeta(
    'targetDays',
  );
  @override
  late final GeneratedColumn<int> targetDays = GeneratedColumn<int>(
    'target_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, startDate, targetDays, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'khatma_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<KhatmaPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('target_days')) {
      context.handle(
        _targetDaysMeta,
        targetDays.isAcceptableOrUnknown(data['target_days']!, _targetDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDaysMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KhatmaPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KhatmaPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      targetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_days'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $KhatmaPlansTable createAlias(String alias) {
    return $KhatmaPlansTable(attachedDatabase, alias);
  }
}

class KhatmaPlan extends DataClass implements Insertable<KhatmaPlan> {
  final int id;
  final DateTime startDate;
  final int targetDays;
  final bool active;
  const KhatmaPlan({
    required this.id,
    required this.startDate,
    required this.targetDays,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_date'] = Variable<DateTime>(startDate);
    map['target_days'] = Variable<int>(targetDays);
    map['active'] = Variable<bool>(active);
    return map;
  }

  KhatmaPlansCompanion toCompanion(bool nullToAbsent) {
    return KhatmaPlansCompanion(
      id: Value(id),
      startDate: Value(startDate),
      targetDays: Value(targetDays),
      active: Value(active),
    );
  }

  factory KhatmaPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KhatmaPlan(
      id: serializer.fromJson<int>(json['id']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      targetDays: serializer.fromJson<int>(json['targetDays']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startDate': serializer.toJson<DateTime>(startDate),
      'targetDays': serializer.toJson<int>(targetDays),
      'active': serializer.toJson<bool>(active),
    };
  }

  KhatmaPlan copyWith({
    int? id,
    DateTime? startDate,
    int? targetDays,
    bool? active,
  }) => KhatmaPlan(
    id: id ?? this.id,
    startDate: startDate ?? this.startDate,
    targetDays: targetDays ?? this.targetDays,
    active: active ?? this.active,
  );
  KhatmaPlan copyWithCompanion(KhatmaPlansCompanion data) {
    return KhatmaPlan(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      targetDays: data.targetDays.present
          ? data.targetDays.value
          : this.targetDays,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaPlan(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('targetDays: $targetDays, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startDate, targetDays, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhatmaPlan &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.targetDays == this.targetDays &&
          other.active == this.active);
}

class KhatmaPlansCompanion extends UpdateCompanion<KhatmaPlan> {
  final Value<int> id;
  final Value<DateTime> startDate;
  final Value<int> targetDays;
  final Value<bool> active;
  const KhatmaPlansCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.targetDays = const Value.absent(),
    this.active = const Value.absent(),
  });
  KhatmaPlansCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startDate,
    required int targetDays,
    this.active = const Value.absent(),
  }) : startDate = Value(startDate),
       targetDays = Value(targetDays);
  static Insertable<KhatmaPlan> custom({
    Expression<int>? id,
    Expression<DateTime>? startDate,
    Expression<int>? targetDays,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (targetDays != null) 'target_days': targetDays,
      if (active != null) 'active': active,
    });
  }

  KhatmaPlansCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startDate,
    Value<int>? targetDays,
    Value<bool>? active,
  }) {
    return KhatmaPlansCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      targetDays: targetDays ?? this.targetDays,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (targetDays.present) {
      map['target_days'] = Variable<int>(targetDays.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaPlansCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('targetDays: $targetDays, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $AudioSettingsTable extends AudioSettings
    with TableInfo<$AudioSettingsTable, AudioSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _reciterIdMeta = const VerificationMeta(
    'reciterId',
  );
  @override
  late final GeneratedColumn<String> reciterId = GeneratedColumn<String>(
    'reciter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('husary'),
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, reciterId, speed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reciter_id')) {
      context.handle(
        _reciterIdMeta,
        reciterId.isAcceptableOrUnknown(data['reciter_id']!, _reciterIdMeta),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reciterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reciter_id'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
    );
  }

  @override
  $AudioSettingsTable createAlias(String alias) {
    return $AudioSettingsTable(attachedDatabase, alias);
  }
}

class AudioSetting extends DataClass implements Insertable<AudioSetting> {
  final int id;
  final String reciterId;
  final double speed;
  const AudioSetting({
    required this.id,
    required this.reciterId,
    required this.speed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reciter_id'] = Variable<String>(reciterId);
    map['speed'] = Variable<double>(speed);
    return map;
  }

  AudioSettingsCompanion toCompanion(bool nullToAbsent) {
    return AudioSettingsCompanion(
      id: Value(id),
      reciterId: Value(reciterId),
      speed: Value(speed),
    );
  }

  factory AudioSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioSetting(
      id: serializer.fromJson<int>(json['id']),
      reciterId: serializer.fromJson<String>(json['reciterId']),
      speed: serializer.fromJson<double>(json['speed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reciterId': serializer.toJson<String>(reciterId),
      'speed': serializer.toJson<double>(speed),
    };
  }

  AudioSetting copyWith({int? id, String? reciterId, double? speed}) =>
      AudioSetting(
        id: id ?? this.id,
        reciterId: reciterId ?? this.reciterId,
        speed: speed ?? this.speed,
      );
  AudioSetting copyWithCompanion(AudioSettingsCompanion data) {
    return AudioSetting(
      id: data.id.present ? data.id.value : this.id,
      reciterId: data.reciterId.present ? data.reciterId.value : this.reciterId,
      speed: data.speed.present ? data.speed.value : this.speed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioSetting(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reciterId, speed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioSetting &&
          other.id == this.id &&
          other.reciterId == this.reciterId &&
          other.speed == this.speed);
}

class AudioSettingsCompanion extends UpdateCompanion<AudioSetting> {
  final Value<int> id;
  final Value<String> reciterId;
  final Value<double> speed;
  const AudioSettingsCompanion({
    this.id = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.speed = const Value.absent(),
  });
  AudioSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.speed = const Value.absent(),
  });
  static Insertable<AudioSetting> custom({
    Expression<int>? id,
    Expression<String>? reciterId,
    Expression<double>? speed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reciterId != null) 'reciter_id': reciterId,
      if (speed != null) 'speed': speed,
    });
  }

  AudioSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? reciterId,
    Value<double>? speed,
  }) {
    return AudioSettingsCompanion(
      id: id ?? this.id,
      reciterId: reciterId ?? this.reciterId,
      speed: speed ?? this.speed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reciterId.present) {
      map['reciter_id'] = Variable<String>(reciterId.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioSettingsCompanion(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }
}

class $LocationSettingsTable extends LocationSettings
    with TableInfo<$LocationSettingsTable, LocationSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityNameMeta = const VerificationMeta(
    'cityName',
  );
  @override
  late final GeneratedColumn<String> cityName = GeneratedColumn<String>(
    'city_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calcMethodMeta = const VerificationMeta(
    'calcMethod',
  );
  @override
  late final GeneratedColumn<String> calcMethod = GeneratedColumn<String>(
    'calc_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ummAlQura'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, lat, lon, cityName, calcMethod];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    }
    if (data.containsKey('city_name')) {
      context.handle(
        _cityNameMeta,
        cityName.isAcceptableOrUnknown(data['city_name']!, _cityNameMeta),
      );
    }
    if (data.containsKey('calc_method')) {
      context.handle(
        _calcMethodMeta,
        calcMethod.isAcceptableOrUnknown(data['calc_method']!, _calcMethodMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      ),
      cityName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city_name'],
      ),
      calcMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calc_method'],
      )!,
    );
  }

  @override
  $LocationSettingsTable createAlias(String alias) {
    return $LocationSettingsTable(attachedDatabase, alias);
  }
}

class LocationSetting extends DataClass implements Insertable<LocationSetting> {
  final int id;
  final double? lat;
  final double? lon;
  final String? cityName;
  final String calcMethod;
  const LocationSetting({
    required this.id,
    this.lat,
    this.lon,
    this.cityName,
    required this.calcMethod,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lon != null) {
      map['lon'] = Variable<double>(lon);
    }
    if (!nullToAbsent || cityName != null) {
      map['city_name'] = Variable<String>(cityName);
    }
    map['calc_method'] = Variable<String>(calcMethod);
    return map;
  }

  LocationSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocationSettingsCompanion(
      id: Value(id),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lon: lon == null && nullToAbsent ? const Value.absent() : Value(lon),
      cityName: cityName == null && nullToAbsent
          ? const Value.absent()
          : Value(cityName),
      calcMethod: Value(calcMethod),
    );
  }

  factory LocationSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationSetting(
      id: serializer.fromJson<int>(json['id']),
      lat: serializer.fromJson<double?>(json['lat']),
      lon: serializer.fromJson<double?>(json['lon']),
      cityName: serializer.fromJson<String?>(json['cityName']),
      calcMethod: serializer.fromJson<String>(json['calcMethod']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lat': serializer.toJson<double?>(lat),
      'lon': serializer.toJson<double?>(lon),
      'cityName': serializer.toJson<String?>(cityName),
      'calcMethod': serializer.toJson<String>(calcMethod),
    };
  }

  LocationSetting copyWith({
    int? id,
    Value<double?> lat = const Value.absent(),
    Value<double?> lon = const Value.absent(),
    Value<String?> cityName = const Value.absent(),
    String? calcMethod,
  }) => LocationSetting(
    id: id ?? this.id,
    lat: lat.present ? lat.value : this.lat,
    lon: lon.present ? lon.value : this.lon,
    cityName: cityName.present ? cityName.value : this.cityName,
    calcMethod: calcMethod ?? this.calcMethod,
  );
  LocationSetting copyWithCompanion(LocationSettingsCompanion data) {
    return LocationSetting(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      cityName: data.cityName.present ? data.cityName.value : this.cityName,
      calcMethod: data.calcMethod.present
          ? data.calcMethod.value
          : this.calcMethod,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationSetting(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('cityName: $cityName, ')
          ..write('calcMethod: $calcMethod')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lat, lon, cityName, calcMethod);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationSetting &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.cityName == this.cityName &&
          other.calcMethod == this.calcMethod);
}

class LocationSettingsCompanion extends UpdateCompanion<LocationSetting> {
  final Value<int> id;
  final Value<double?> lat;
  final Value<double?> lon;
  final Value<String?> cityName;
  final Value<String> calcMethod;
  const LocationSettingsCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.cityName = const Value.absent(),
    this.calcMethod = const Value.absent(),
  });
  LocationSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.cityName = const Value.absent(),
    this.calcMethod = const Value.absent(),
  });
  static Insertable<LocationSetting> custom({
    Expression<int>? id,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? cityName,
    Expression<String>? calcMethod,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (cityName != null) 'city_name': cityName,
      if (calcMethod != null) 'calc_method': calcMethod,
    });
  }

  LocationSettingsCompanion copyWith({
    Value<int>? id,
    Value<double?>? lat,
    Value<double?>? lon,
    Value<String?>? cityName,
    Value<String>? calcMethod,
  }) {
    return LocationSettingsCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      cityName: cityName ?? this.cityName,
      calcMethod: calcMethod ?? this.calcMethod,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (cityName.present) {
      map['city_name'] = Variable<String>(cityName.value);
    }
    if (calcMethod.present) {
      map['calc_method'] = Variable<String>(calcMethod.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationSettingsCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('cityName: $cityName, ')
          ..write('calcMethod: $calcMethod')
          ..write(')'))
        .toString();
  }
}

class $TasbihCounterTable extends TasbihCounter
    with TableInfo<$TasbihCounterTable, TasbihCounterData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasbihCounterTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasbih_counter';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasbihCounterData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TasbihCounterData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasbihCounterData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $TasbihCounterTable createAlias(String alias) {
    return $TasbihCounterTable(attachedDatabase, alias);
  }
}

class TasbihCounterData extends DataClass
    implements Insertable<TasbihCounterData> {
  final int id;
  final int count;
  const TasbihCounterData({required this.id, required this.count});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['count'] = Variable<int>(count);
    return map;
  }

  TasbihCounterCompanion toCompanion(bool nullToAbsent) {
    return TasbihCounterCompanion(id: Value(id), count: Value(count));
  }

  factory TasbihCounterData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasbihCounterData(
      id: serializer.fromJson<int>(json['id']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'count': serializer.toJson<int>(count),
    };
  }

  TasbihCounterData copyWith({int? id, int? count}) =>
      TasbihCounterData(id: id ?? this.id, count: count ?? this.count);
  TasbihCounterData copyWithCompanion(TasbihCounterCompanion data) {
    return TasbihCounterData(
      id: data.id.present ? data.id.value : this.id,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasbihCounterData(')
          ..write('id: $id, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasbihCounterData &&
          other.id == this.id &&
          other.count == this.count);
}

class TasbihCounterCompanion extends UpdateCompanion<TasbihCounterData> {
  final Value<int> id;
  final Value<int> count;
  const TasbihCounterCompanion({
    this.id = const Value.absent(),
    this.count = const Value.absent(),
  });
  TasbihCounterCompanion.insert({
    this.id = const Value.absent(),
    this.count = const Value.absent(),
  });
  static Insertable<TasbihCounterData> custom({
    Expression<int>? id,
    Expression<int>? count,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (count != null) 'count': count,
    });
  }

  TasbihCounterCompanion copyWith({Value<int>? id, Value<int>? count}) {
    return TasbihCounterCompanion(
      id: id ?? this.id,
      count: count ?? this.count,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasbihCounterCompanion(')
          ..write('id: $id, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }
}

class $CategoryStreaksTable extends CategoryStreaks
    with TableInfo<$CategoryStreaksTable, CategoryStreak> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryStreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streakDaysMeta = const VerificationMeta(
    'streakDays',
  );
  @override
  late final GeneratedColumn<int> streakDays = GeneratedColumn<int>(
    'streak_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _streakLastDayMeta = const VerificationMeta(
    'streakLastDay',
  );
  @override
  late final GeneratedColumn<String> streakLastDay = GeneratedColumn<String>(
    'streak_last_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [category, streakDays, streakLastDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_streaks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryStreak> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('streak_days')) {
      context.handle(
        _streakDaysMeta,
        streakDays.isAcceptableOrUnknown(data['streak_days']!, _streakDaysMeta),
      );
    }
    if (data.containsKey('streak_last_day')) {
      context.handle(
        _streakLastDayMeta,
        streakLastDay.isAcceptableOrUnknown(
          data['streak_last_day']!,
          _streakLastDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {category};
  @override
  CategoryStreak map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryStreak(
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      streakDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_days'],
      )!,
      streakLastDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}streak_last_day'],
      ),
    );
  }

  @override
  $CategoryStreaksTable createAlias(String alias) {
    return $CategoryStreaksTable(attachedDatabase, alias);
  }
}

class CategoryStreak extends DataClass implements Insertable<CategoryStreak> {
  final String category;
  final int streakDays;
  final String? streakLastDay;
  const CategoryStreak({
    required this.category,
    required this.streakDays,
    this.streakLastDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category'] = Variable<String>(category);
    map['streak_days'] = Variable<int>(streakDays);
    if (!nullToAbsent || streakLastDay != null) {
      map['streak_last_day'] = Variable<String>(streakLastDay);
    }
    return map;
  }

  CategoryStreaksCompanion toCompanion(bool nullToAbsent) {
    return CategoryStreaksCompanion(
      category: Value(category),
      streakDays: Value(streakDays),
      streakLastDay: streakLastDay == null && nullToAbsent
          ? const Value.absent()
          : Value(streakLastDay),
    );
  }

  factory CategoryStreak.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryStreak(
      category: serializer.fromJson<String>(json['category']),
      streakDays: serializer.fromJson<int>(json['streakDays']),
      streakLastDay: serializer.fromJson<String?>(json['streakLastDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'category': serializer.toJson<String>(category),
      'streakDays': serializer.toJson<int>(streakDays),
      'streakLastDay': serializer.toJson<String?>(streakLastDay),
    };
  }

  CategoryStreak copyWith({
    String? category,
    int? streakDays,
    Value<String?> streakLastDay = const Value.absent(),
  }) => CategoryStreak(
    category: category ?? this.category,
    streakDays: streakDays ?? this.streakDays,
    streakLastDay: streakLastDay.present
        ? streakLastDay.value
        : this.streakLastDay,
  );
  CategoryStreak copyWithCompanion(CategoryStreaksCompanion data) {
    return CategoryStreak(
      category: data.category.present ? data.category.value : this.category,
      streakDays: data.streakDays.present
          ? data.streakDays.value
          : this.streakDays,
      streakLastDay: data.streakLastDay.present
          ? data.streakLastDay.value
          : this.streakLastDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryStreak(')
          ..write('category: $category, ')
          ..write('streakDays: $streakDays, ')
          ..write('streakLastDay: $streakLastDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(category, streakDays, streakLastDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryStreak &&
          other.category == this.category &&
          other.streakDays == this.streakDays &&
          other.streakLastDay == this.streakLastDay);
}

class CategoryStreaksCompanion extends UpdateCompanion<CategoryStreak> {
  final Value<String> category;
  final Value<int> streakDays;
  final Value<String?> streakLastDay;
  final Value<int> rowid;
  const CategoryStreaksCompanion({
    this.category = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.streakLastDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryStreaksCompanion.insert({
    required String category,
    this.streakDays = const Value.absent(),
    this.streakLastDay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : category = Value(category);
  static Insertable<CategoryStreak> custom({
    Expression<String>? category,
    Expression<int>? streakDays,
    Expression<String>? streakLastDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (category != null) 'category': category,
      if (streakDays != null) 'streak_days': streakDays,
      if (streakLastDay != null) 'streak_last_day': streakLastDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryStreaksCompanion copyWith({
    Value<String>? category,
    Value<int>? streakDays,
    Value<String?>? streakLastDay,
    Value<int>? rowid,
  }) {
    return CategoryStreaksCompanion(
      category: category ?? this.category,
      streakDays: streakDays ?? this.streakDays,
      streakLastDay: streakLastDay ?? this.streakLastDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (streakDays.present) {
      map['streak_days'] = Variable<int>(streakDays.value);
    }
    if (streakLastDay.present) {
      map['streak_last_day'] = Variable<String>(streakLastDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryStreaksCompanion(')
          ..write('category: $category, ')
          ..write('streakDays: $streakDays, ')
          ..write('streakLastDay: $streakLastDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QiyamSettingsTable extends QiyamSettings
    with TableInfo<$QiyamSettingsTable, QiyamSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QiyamSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reminderHour,
    reminderMinute,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qiyam_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<QiyamSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QiyamSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QiyamSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      ),
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $QiyamSettingsTable createAlias(String alias) {
    return $QiyamSettingsTable(attachedDatabase, alias);
  }
}

class QiyamSetting extends DataClass implements Insertable<QiyamSetting> {
  final int id;
  final int? reminderHour;
  final int reminderMinute;
  final bool enabled;
  const QiyamSetting({
    required this.id,
    this.reminderHour,
    required this.reminderMinute,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || reminderHour != null) {
      map['reminder_hour'] = Variable<int>(reminderHour);
    }
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  QiyamSettingsCompanion toCompanion(bool nullToAbsent) {
    return QiyamSettingsCompanion(
      id: Value(id),
      reminderHour: reminderHour == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      enabled: Value(enabled),
    );
  }

  factory QiyamSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QiyamSetting(
      id: serializer.fromJson<int>(json['id']),
      reminderHour: serializer.fromJson<int?>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderHour': serializer.toJson<int?>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  QiyamSetting copyWith({
    int? id,
    Value<int?> reminderHour = const Value.absent(),
    int? reminderMinute,
    bool? enabled,
  }) => QiyamSetting(
    id: id ?? this.id,
    reminderHour: reminderHour.present ? reminderHour.value : this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    enabled: enabled ?? this.enabled,
  );
  QiyamSetting copyWithCompanion(QiyamSettingsCompanion data) {
    return QiyamSetting(
      id: data.id.present ? data.id.value : this.id,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QiyamSetting(')
          ..write('id: $id, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reminderHour, reminderMinute, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QiyamSetting &&
          other.id == this.id &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.enabled == this.enabled);
}

class QiyamSettingsCompanion extends UpdateCompanion<QiyamSetting> {
  final Value<int> id;
  final Value<int?> reminderHour;
  final Value<int> reminderMinute;
  final Value<bool> enabled;
  const QiyamSettingsCompanion({
    this.id = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  QiyamSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  static Insertable<QiyamSetting> custom({
    Expression<int>? id,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (enabled != null) 'enabled': enabled,
    });
  }

  QiyamSettingsCompanion copyWith({
    Value<int>? id,
    Value<int?>? reminderHour,
    Value<int>? reminderMinute,
    Value<bool>? enabled,
  }) {
    return QiyamSettingsCompanion(
      id: id ?? this.id,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QiyamSettingsCompanion(')
          ..write('id: $id, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $AzkarFavoritesTable extends AzkarFavorites
    with TableInfo<$AzkarFavoritesTable, AzkarFavorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AzkarFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, categoryId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'azkar_favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<AzkarFavorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AzkarFavorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AzkarFavorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AzkarFavoritesTable createAlias(String alias) {
    return $AzkarFavoritesTable(attachedDatabase, alias);
  }
}

class AzkarFavorite extends DataClass implements Insertable<AzkarFavorite> {
  final int id;
  final int categoryId;
  final DateTime createdAt;
  const AzkarFavorite({
    required this.id,
    required this.categoryId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AzkarFavoritesCompanion toCompanion(bool nullToAbsent) {
    return AzkarFavoritesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      createdAt: Value(createdAt),
    );
  }

  factory AzkarFavorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AzkarFavorite(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AzkarFavorite copyWith({int? id, int? categoryId, DateTime? createdAt}) =>
      AzkarFavorite(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        createdAt: createdAt ?? this.createdAt,
      );
  AzkarFavorite copyWithCompanion(AzkarFavoritesCompanion data) {
    return AzkarFavorite(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AzkarFavorite(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AzkarFavorite &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.createdAt == this.createdAt);
}

class AzkarFavoritesCompanion extends UpdateCompanion<AzkarFavorite> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<DateTime> createdAt;
  const AzkarFavoritesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AzkarFavoritesCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required DateTime createdAt,
  }) : categoryId = Value(categoryId),
       createdAt = Value(createdAt);
  static Insertable<AzkarFavorite> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AzkarFavoritesCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<DateTime>? createdAt,
  }) {
    return AzkarFavoritesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AzkarFavoritesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $KhatmaPlansTable khatmaPlans = $KhatmaPlansTable(this);
  late final $AudioSettingsTable audioSettings = $AudioSettingsTable(this);
  late final $LocationSettingsTable locationSettings = $LocationSettingsTable(
    this,
  );
  late final $TasbihCounterTable tasbihCounter = $TasbihCounterTable(this);
  late final $CategoryStreaksTable categoryStreaks = $CategoryStreaksTable(
    this,
  );
  late final $QiyamSettingsTable qiyamSettings = $QiyamSettingsTable(this);
  late final $AzkarFavoritesTable azkarFavorites = $AzkarFavoritesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bookmarks,
    readingProgress,
    khatmaPlans,
    audioSettings,
    locationSettings,
    tasbihCounter,
    categoryStreaks,
    qiyamSettings,
    azkarFavorites,
  ];
}

typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required int ayahId,
      Value<int?> folderId,
      Value<String?> label,
      required DateTime createdAt,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<int?> folderId,
      Value<String?> label,
      Value<DateTime> createdAt,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$UserDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$UserDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$UserDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<int> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$UserDatabase, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$UserDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                ayahId: ayahId,
                folderId: folderId,
                label: label,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                Value<int?> folderId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                required DateTime createdAt,
              }) => BookmarksCompanion.insert(
                id: id,
                ayahId: ayahId,
                folderId: folderId,
                label: label,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$UserDatabase, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;
typedef $$ReadingProgressTableCreateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<int> id,
      Value<int?> lastPage,
      Value<int> streakDays,
      Value<String?> streakLastDay,
    });
typedef $$ReadingProgressTableUpdateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<int> id,
      Value<int?> lastPage,
      Value<int> streakDays,
      Value<String?> streakLastDay,
    });

class $$ReadingProgressTableFilterComposer
    extends Composer<_$UserDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streakLastDay => $composableBuilder(
    column: $table.streakLastDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingProgressTableOrderingComposer
    extends Composer<_$UserDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streakLastDay => $composableBuilder(
    column: $table.streakLastDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingProgressTableAnnotationComposer
    extends Composer<_$UserDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lastPage =>
      $composableBuilder(column: $table.lastPage, builder: (column) => column);

  GeneratedColumn<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streakLastDay => $composableBuilder(
    column: $table.streakLastDay,
    builder: (column) => column,
  );
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ReadingProgressTable,
          ReadingProgressData,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (
            ReadingProgressData,
            BaseReferences<
              _$UserDatabase,
              $ReadingProgressTable,
              ReadingProgressData
            >,
          ),
          ReadingProgressData,
          PrefetchHooks Function()
        > {
  $$ReadingProgressTableTableManager(
    _$UserDatabase db,
    $ReadingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> lastPage = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<String?> streakLastDay = const Value.absent(),
              }) => ReadingProgressCompanion(
                id: id,
                lastPage: lastPage,
                streakDays: streakDays,
                streakLastDay: streakLastDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> lastPage = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<String?> streakLastDay = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                id: id,
                lastPage: lastPage,
                streakDays: streakDays,
                streakLastDay: streakLastDay,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ReadingProgressTable,
      ReadingProgressData,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (
        ReadingProgressData,
        BaseReferences<
          _$UserDatabase,
          $ReadingProgressTable,
          ReadingProgressData
        >,
      ),
      ReadingProgressData,
      PrefetchHooks Function()
    >;
typedef $$KhatmaPlansTableCreateCompanionBuilder =
    KhatmaPlansCompanion Function({
      Value<int> id,
      required DateTime startDate,
      required int targetDays,
      Value<bool> active,
    });
typedef $$KhatmaPlansTableUpdateCompanionBuilder =
    KhatmaPlansCompanion Function({
      Value<int> id,
      Value<DateTime> startDate,
      Value<int> targetDays,
      Value<bool> active,
    });

class $$KhatmaPlansTableFilterComposer
    extends Composer<_$UserDatabase, $KhatmaPlansTable> {
  $$KhatmaPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KhatmaPlansTableOrderingComposer
    extends Composer<_$UserDatabase, $KhatmaPlansTable> {
  $$KhatmaPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KhatmaPlansTableAnnotationComposer
    extends Composer<_$UserDatabase, $KhatmaPlansTable> {
  $$KhatmaPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$KhatmaPlansTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $KhatmaPlansTable,
          KhatmaPlan,
          $$KhatmaPlansTableFilterComposer,
          $$KhatmaPlansTableOrderingComposer,
          $$KhatmaPlansTableAnnotationComposer,
          $$KhatmaPlansTableCreateCompanionBuilder,
          $$KhatmaPlansTableUpdateCompanionBuilder,
          (
            KhatmaPlan,
            BaseReferences<_$UserDatabase, $KhatmaPlansTable, KhatmaPlan>,
          ),
          KhatmaPlan,
          PrefetchHooks Function()
        > {
  $$KhatmaPlansTableTableManager(_$UserDatabase db, $KhatmaPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhatmaPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhatmaPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhatmaPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> targetDays = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => KhatmaPlansCompanion(
                id: id,
                startDate: startDate,
                targetDays: targetDays,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startDate,
                required int targetDays,
                Value<bool> active = const Value.absent(),
              }) => KhatmaPlansCompanion.insert(
                id: id,
                startDate: startDate,
                targetDays: targetDays,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KhatmaPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $KhatmaPlansTable,
      KhatmaPlan,
      $$KhatmaPlansTableFilterComposer,
      $$KhatmaPlansTableOrderingComposer,
      $$KhatmaPlansTableAnnotationComposer,
      $$KhatmaPlansTableCreateCompanionBuilder,
      $$KhatmaPlansTableUpdateCompanionBuilder,
      (
        KhatmaPlan,
        BaseReferences<_$UserDatabase, $KhatmaPlansTable, KhatmaPlan>,
      ),
      KhatmaPlan,
      PrefetchHooks Function()
    >;
typedef $$AudioSettingsTableCreateCompanionBuilder =
    AudioSettingsCompanion Function({
      Value<int> id,
      Value<String> reciterId,
      Value<double> speed,
    });
typedef $$AudioSettingsTableUpdateCompanionBuilder =
    AudioSettingsCompanion Function({
      Value<int> id,
      Value<String> reciterId,
      Value<double> speed,
    });

class $$AudioSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $AudioSettingsTable> {
  $$AudioSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AudioSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $AudioSettingsTable> {
  $$AudioSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $AudioSettingsTable> {
  $$AudioSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reciterId =>
      $composableBuilder(column: $table.reciterId, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);
}

class $$AudioSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AudioSettingsTable,
          AudioSetting,
          $$AudioSettingsTableFilterComposer,
          $$AudioSettingsTableOrderingComposer,
          $$AudioSettingsTableAnnotationComposer,
          $$AudioSettingsTableCreateCompanionBuilder,
          $$AudioSettingsTableUpdateCompanionBuilder,
          (
            AudioSetting,
            BaseReferences<_$UserDatabase, $AudioSettingsTable, AudioSetting>,
          ),
          AudioSetting,
          PrefetchHooks Function()
        > {
  $$AudioSettingsTableTableManager(_$UserDatabase db, $AudioSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reciterId = const Value.absent(),
                Value<double> speed = const Value.absent(),
              }) => AudioSettingsCompanion(
                id: id,
                reciterId: reciterId,
                speed: speed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reciterId = const Value.absent(),
                Value<double> speed = const Value.absent(),
              }) => AudioSettingsCompanion.insert(
                id: id,
                reciterId: reciterId,
                speed: speed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AudioSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AudioSettingsTable,
      AudioSetting,
      $$AudioSettingsTableFilterComposer,
      $$AudioSettingsTableOrderingComposer,
      $$AudioSettingsTableAnnotationComposer,
      $$AudioSettingsTableCreateCompanionBuilder,
      $$AudioSettingsTableUpdateCompanionBuilder,
      (
        AudioSetting,
        BaseReferences<_$UserDatabase, $AudioSettingsTable, AudioSetting>,
      ),
      AudioSetting,
      PrefetchHooks Function()
    >;
typedef $$LocationSettingsTableCreateCompanionBuilder =
    LocationSettingsCompanion Function({
      Value<int> id,
      Value<double?> lat,
      Value<double?> lon,
      Value<String?> cityName,
      Value<String> calcMethod,
    });
typedef $$LocationSettingsTableUpdateCompanionBuilder =
    LocationSettingsCompanion Function({
      Value<int> id,
      Value<double?> lat,
      Value<double?> lon,
      Value<String?> cityName,
      Value<String> calcMethod,
    });

class $$LocationSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $LocationSettingsTable> {
  $$LocationSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cityName => $composableBuilder(
    column: $table.cityName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calcMethod => $composableBuilder(
    column: $table.calcMethod,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $LocationSettingsTable> {
  $$LocationSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cityName => $composableBuilder(
    column: $table.cityName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calcMethod => $composableBuilder(
    column: $table.calcMethod,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $LocationSettingsTable> {
  $$LocationSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get cityName =>
      $composableBuilder(column: $table.cityName, builder: (column) => column);

  GeneratedColumn<String> get calcMethod => $composableBuilder(
    column: $table.calcMethod,
    builder: (column) => column,
  );
}

class $$LocationSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $LocationSettingsTable,
          LocationSetting,
          $$LocationSettingsTableFilterComposer,
          $$LocationSettingsTableOrderingComposer,
          $$LocationSettingsTableAnnotationComposer,
          $$LocationSettingsTableCreateCompanionBuilder,
          $$LocationSettingsTableUpdateCompanionBuilder,
          (
            LocationSetting,
            BaseReferences<
              _$UserDatabase,
              $LocationSettingsTable,
              LocationSetting
            >,
          ),
          LocationSetting,
          PrefetchHooks Function()
        > {
  $$LocationSettingsTableTableManager(
    _$UserDatabase db,
    $LocationSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lon = const Value.absent(),
                Value<String?> cityName = const Value.absent(),
                Value<String> calcMethod = const Value.absent(),
              }) => LocationSettingsCompanion(
                id: id,
                lat: lat,
                lon: lon,
                cityName: cityName,
                calcMethod: calcMethod,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lon = const Value.absent(),
                Value<String?> cityName = const Value.absent(),
                Value<String> calcMethod = const Value.absent(),
              }) => LocationSettingsCompanion.insert(
                id: id,
                lat: lat,
                lon: lon,
                cityName: cityName,
                calcMethod: calcMethod,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $LocationSettingsTable,
      LocationSetting,
      $$LocationSettingsTableFilterComposer,
      $$LocationSettingsTableOrderingComposer,
      $$LocationSettingsTableAnnotationComposer,
      $$LocationSettingsTableCreateCompanionBuilder,
      $$LocationSettingsTableUpdateCompanionBuilder,
      (
        LocationSetting,
        BaseReferences<_$UserDatabase, $LocationSettingsTable, LocationSetting>,
      ),
      LocationSetting,
      PrefetchHooks Function()
    >;
typedef $$TasbihCounterTableCreateCompanionBuilder =
    TasbihCounterCompanion Function({Value<int> id, Value<int> count});
typedef $$TasbihCounterTableUpdateCompanionBuilder =
    TasbihCounterCompanion Function({Value<int> id, Value<int> count});

class $$TasbihCounterTableFilterComposer
    extends Composer<_$UserDatabase, $TasbihCounterTable> {
  $$TasbihCounterTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasbihCounterTableOrderingComposer
    extends Composer<_$UserDatabase, $TasbihCounterTable> {
  $$TasbihCounterTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasbihCounterTableAnnotationComposer
    extends Composer<_$UserDatabase, $TasbihCounterTable> {
  $$TasbihCounterTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$TasbihCounterTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $TasbihCounterTable,
          TasbihCounterData,
          $$TasbihCounterTableFilterComposer,
          $$TasbihCounterTableOrderingComposer,
          $$TasbihCounterTableAnnotationComposer,
          $$TasbihCounterTableCreateCompanionBuilder,
          $$TasbihCounterTableUpdateCompanionBuilder,
          (
            TasbihCounterData,
            BaseReferences<
              _$UserDatabase,
              $TasbihCounterTable,
              TasbihCounterData
            >,
          ),
          TasbihCounterData,
          PrefetchHooks Function()
        > {
  $$TasbihCounterTableTableManager(_$UserDatabase db, $TasbihCounterTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasbihCounterTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasbihCounterTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasbihCounterTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> count = const Value.absent(),
              }) => TasbihCounterCompanion(id: id, count: count),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> count = const Value.absent(),
              }) => TasbihCounterCompanion.insert(id: id, count: count),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasbihCounterTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $TasbihCounterTable,
      TasbihCounterData,
      $$TasbihCounterTableFilterComposer,
      $$TasbihCounterTableOrderingComposer,
      $$TasbihCounterTableAnnotationComposer,
      $$TasbihCounterTableCreateCompanionBuilder,
      $$TasbihCounterTableUpdateCompanionBuilder,
      (
        TasbihCounterData,
        BaseReferences<_$UserDatabase, $TasbihCounterTable, TasbihCounterData>,
      ),
      TasbihCounterData,
      PrefetchHooks Function()
    >;
typedef $$CategoryStreaksTableCreateCompanionBuilder =
    CategoryStreaksCompanion Function({
      required String category,
      Value<int> streakDays,
      Value<String?> streakLastDay,
      Value<int> rowid,
    });
typedef $$CategoryStreaksTableUpdateCompanionBuilder =
    CategoryStreaksCompanion Function({
      Value<String> category,
      Value<int> streakDays,
      Value<String?> streakLastDay,
      Value<int> rowid,
    });

class $$CategoryStreaksTableFilterComposer
    extends Composer<_$UserDatabase, $CategoryStreaksTable> {
  $$CategoryStreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streakLastDay => $composableBuilder(
    column: $table.streakLastDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryStreaksTableOrderingComposer
    extends Composer<_$UserDatabase, $CategoryStreaksTable> {
  $$CategoryStreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streakLastDay => $composableBuilder(
    column: $table.streakLastDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryStreaksTableAnnotationComposer
    extends Composer<_$UserDatabase, $CategoryStreaksTable> {
  $$CategoryStreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streakLastDay => $composableBuilder(
    column: $table.streakLastDay,
    builder: (column) => column,
  );
}

class $$CategoryStreaksTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $CategoryStreaksTable,
          CategoryStreak,
          $$CategoryStreaksTableFilterComposer,
          $$CategoryStreaksTableOrderingComposer,
          $$CategoryStreaksTableAnnotationComposer,
          $$CategoryStreaksTableCreateCompanionBuilder,
          $$CategoryStreaksTableUpdateCompanionBuilder,
          (
            CategoryStreak,
            BaseReferences<
              _$UserDatabase,
              $CategoryStreaksTable,
              CategoryStreak
            >,
          ),
          CategoryStreak,
          PrefetchHooks Function()
        > {
  $$CategoryStreaksTableTableManager(
    _$UserDatabase db,
    $CategoryStreaksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryStreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryStreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryStreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> category = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<String?> streakLastDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryStreaksCompanion(
                category: category,
                streakDays: streakDays,
                streakLastDay: streakLastDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String category,
                Value<int> streakDays = const Value.absent(),
                Value<String?> streakLastDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryStreaksCompanion.insert(
                category: category,
                streakDays: streakDays,
                streakLastDay: streakLastDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryStreaksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $CategoryStreaksTable,
      CategoryStreak,
      $$CategoryStreaksTableFilterComposer,
      $$CategoryStreaksTableOrderingComposer,
      $$CategoryStreaksTableAnnotationComposer,
      $$CategoryStreaksTableCreateCompanionBuilder,
      $$CategoryStreaksTableUpdateCompanionBuilder,
      (
        CategoryStreak,
        BaseReferences<_$UserDatabase, $CategoryStreaksTable, CategoryStreak>,
      ),
      CategoryStreak,
      PrefetchHooks Function()
    >;
typedef $$QiyamSettingsTableCreateCompanionBuilder =
    QiyamSettingsCompanion Function({
      Value<int> id,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> enabled,
    });
typedef $$QiyamSettingsTableUpdateCompanionBuilder =
    QiyamSettingsCompanion Function({
      Value<int> id,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> enabled,
    });

class $$QiyamSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $QiyamSettingsTable> {
  $$QiyamSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QiyamSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $QiyamSettingsTable> {
  $$QiyamSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QiyamSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $QiyamSettingsTable> {
  $$QiyamSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$QiyamSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $QiyamSettingsTable,
          QiyamSetting,
          $$QiyamSettingsTableFilterComposer,
          $$QiyamSettingsTableOrderingComposer,
          $$QiyamSettingsTableAnnotationComposer,
          $$QiyamSettingsTableCreateCompanionBuilder,
          $$QiyamSettingsTableUpdateCompanionBuilder,
          (
            QiyamSetting,
            BaseReferences<_$UserDatabase, $QiyamSettingsTable, QiyamSetting>,
          ),
          QiyamSetting,
          PrefetchHooks Function()
        > {
  $$QiyamSettingsTableTableManager(_$UserDatabase db, $QiyamSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QiyamSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QiyamSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QiyamSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => QiyamSettingsCompanion(
                id: id,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => QiyamSettingsCompanion.insert(
                id: id,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QiyamSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $QiyamSettingsTable,
      QiyamSetting,
      $$QiyamSettingsTableFilterComposer,
      $$QiyamSettingsTableOrderingComposer,
      $$QiyamSettingsTableAnnotationComposer,
      $$QiyamSettingsTableCreateCompanionBuilder,
      $$QiyamSettingsTableUpdateCompanionBuilder,
      (
        QiyamSetting,
        BaseReferences<_$UserDatabase, $QiyamSettingsTable, QiyamSetting>,
      ),
      QiyamSetting,
      PrefetchHooks Function()
    >;
typedef $$AzkarFavoritesTableCreateCompanionBuilder =
    AzkarFavoritesCompanion Function({
      Value<int> id,
      required int categoryId,
      required DateTime createdAt,
    });
typedef $$AzkarFavoritesTableUpdateCompanionBuilder =
    AzkarFavoritesCompanion Function({
      Value<int> id,
      Value<int> categoryId,
      Value<DateTime> createdAt,
    });

class $$AzkarFavoritesTableFilterComposer
    extends Composer<_$UserDatabase, $AzkarFavoritesTable> {
  $$AzkarFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AzkarFavoritesTableOrderingComposer
    extends Composer<_$UserDatabase, $AzkarFavoritesTable> {
  $$AzkarFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AzkarFavoritesTableAnnotationComposer
    extends Composer<_$UserDatabase, $AzkarFavoritesTable> {
  $$AzkarFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AzkarFavoritesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AzkarFavoritesTable,
          AzkarFavorite,
          $$AzkarFavoritesTableFilterComposer,
          $$AzkarFavoritesTableOrderingComposer,
          $$AzkarFavoritesTableAnnotationComposer,
          $$AzkarFavoritesTableCreateCompanionBuilder,
          $$AzkarFavoritesTableUpdateCompanionBuilder,
          (
            AzkarFavorite,
            BaseReferences<_$UserDatabase, $AzkarFavoritesTable, AzkarFavorite>,
          ),
          AzkarFavorite,
          PrefetchHooks Function()
        > {
  $$AzkarFavoritesTableTableManager(
    _$UserDatabase db,
    $AzkarFavoritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AzkarFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AzkarFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AzkarFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AzkarFavoritesCompanion(
                id: id,
                categoryId: categoryId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int categoryId,
                required DateTime createdAt,
              }) => AzkarFavoritesCompanion.insert(
                id: id,
                categoryId: categoryId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AzkarFavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AzkarFavoritesTable,
      AzkarFavorite,
      $$AzkarFavoritesTableFilterComposer,
      $$AzkarFavoritesTableOrderingComposer,
      $$AzkarFavoritesTableAnnotationComposer,
      $$AzkarFavoritesTableCreateCompanionBuilder,
      $$AzkarFavoritesTableUpdateCompanionBuilder,
      (
        AzkarFavorite,
        BaseReferences<_$UserDatabase, $AzkarFavoritesTable, AzkarFavorite>,
      ),
      AzkarFavorite,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$KhatmaPlansTableTableManager get khatmaPlans =>
      $$KhatmaPlansTableTableManager(_db, _db.khatmaPlans);
  $$AudioSettingsTableTableManager get audioSettings =>
      $$AudioSettingsTableTableManager(_db, _db.audioSettings);
  $$LocationSettingsTableTableManager get locationSettings =>
      $$LocationSettingsTableTableManager(_db, _db.locationSettings);
  $$TasbihCounterTableTableManager get tasbihCounter =>
      $$TasbihCounterTableTableManager(_db, _db.tasbihCounter);
  $$CategoryStreaksTableTableManager get categoryStreaks =>
      $$CategoryStreaksTableTableManager(_db, _db.categoryStreaks);
  $$QiyamSettingsTableTableManager get qiyamSettings =>
      $$QiyamSettingsTableTableManager(_db, _db.qiyamSettings);
  $$AzkarFavoritesTableTableManager get azkarFavorites =>
      $$AzkarFavoritesTableTableManager(_db, _db.azkarFavorites);
}
