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
  static const VerificationMeta _startPageMeta = const VerificationMeta(
    'startPage',
  );
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
    'start_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currentPageMeta = const VerificationMeta(
    'currentPage',
  );
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
    'current_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDate,
    targetDays,
    active,
    startPage,
    currentPage,
  ];
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
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    }
    if (data.containsKey('current_page')) {
      context.handle(
        _currentPageMeta,
        currentPage.isAcceptableOrUnknown(
          data['current_page']!,
          _currentPageMeta,
        ),
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
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      )!,
      currentPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_page'],
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
  final int startPage;
  final int currentPage;
  const KhatmaPlan({
    required this.id,
    required this.startDate,
    required this.targetDays,
    required this.active,
    required this.startPage,
    required this.currentPage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_date'] = Variable<DateTime>(startDate);
    map['target_days'] = Variable<int>(targetDays);
    map['active'] = Variable<bool>(active);
    map['start_page'] = Variable<int>(startPage);
    map['current_page'] = Variable<int>(currentPage);
    return map;
  }

  KhatmaPlansCompanion toCompanion(bool nullToAbsent) {
    return KhatmaPlansCompanion(
      id: Value(id),
      startDate: Value(startDate),
      targetDays: Value(targetDays),
      active: Value(active),
      startPage: Value(startPage),
      currentPage: Value(currentPage),
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
      startPage: serializer.fromJson<int>(json['startPage']),
      currentPage: serializer.fromJson<int>(json['currentPage']),
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
      'startPage': serializer.toJson<int>(startPage),
      'currentPage': serializer.toJson<int>(currentPage),
    };
  }

  KhatmaPlan copyWith({
    int? id,
    DateTime? startDate,
    int? targetDays,
    bool? active,
    int? startPage,
    int? currentPage,
  }) => KhatmaPlan(
    id: id ?? this.id,
    startDate: startDate ?? this.startDate,
    targetDays: targetDays ?? this.targetDays,
    active: active ?? this.active,
    startPage: startPage ?? this.startPage,
    currentPage: currentPage ?? this.currentPage,
  );
  KhatmaPlan copyWithCompanion(KhatmaPlansCompanion data) {
    return KhatmaPlan(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      targetDays: data.targetDays.present
          ? data.targetDays.value
          : this.targetDays,
      active: data.active.present ? data.active.value : this.active,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      currentPage: data.currentPage.present
          ? data.currentPage.value
          : this.currentPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaPlan(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('targetDays: $targetDays, ')
          ..write('active: $active, ')
          ..write('startPage: $startPage, ')
          ..write('currentPage: $currentPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startDate, targetDays, active, startPage, currentPage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhatmaPlan &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.targetDays == this.targetDays &&
          other.active == this.active &&
          other.startPage == this.startPage &&
          other.currentPage == this.currentPage);
}

class KhatmaPlansCompanion extends UpdateCompanion<KhatmaPlan> {
  final Value<int> id;
  final Value<DateTime> startDate;
  final Value<int> targetDays;
  final Value<bool> active;
  final Value<int> startPage;
  final Value<int> currentPage;
  const KhatmaPlansCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.targetDays = const Value.absent(),
    this.active = const Value.absent(),
    this.startPage = const Value.absent(),
    this.currentPage = const Value.absent(),
  });
  KhatmaPlansCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startDate,
    required int targetDays,
    this.active = const Value.absent(),
    this.startPage = const Value.absent(),
    this.currentPage = const Value.absent(),
  }) : startDate = Value(startDate),
       targetDays = Value(targetDays);
  static Insertable<KhatmaPlan> custom({
    Expression<int>? id,
    Expression<DateTime>? startDate,
    Expression<int>? targetDays,
    Expression<bool>? active,
    Expression<int>? startPage,
    Expression<int>? currentPage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (targetDays != null) 'target_days': targetDays,
      if (active != null) 'active': active,
      if (startPage != null) 'start_page': startPage,
      if (currentPage != null) 'current_page': currentPage,
    });
  }

  KhatmaPlansCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startDate,
    Value<int>? targetDays,
    Value<bool>? active,
    Value<int>? startPage,
    Value<int>? currentPage,
  }) {
    return KhatmaPlansCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      targetDays: targetDays ?? this.targetDays,
      active: active ?? this.active,
      startPage: startPage ?? this.startPage,
      currentPage: currentPage ?? this.currentPage,
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
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaPlansCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('targetDays: $targetDays, ')
          ..write('active: $active, ')
          ..write('startPage: $startPage, ')
          ..write('currentPage: $currentPage')
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
  static const VerificationMeta _liveListenEnabledMeta = const VerificationMeta(
    'liveListenEnabled',
  );
  @override
  late final GeneratedColumn<bool> liveListenEnabled = GeneratedColumn<bool>(
    'live_listen_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("live_listen_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reciterId,
    speed,
    liveListenEnabled,
  ];
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
    if (data.containsKey('live_listen_enabled')) {
      context.handle(
        _liveListenEnabledMeta,
        liveListenEnabled.isAcceptableOrUnknown(
          data['live_listen_enabled']!,
          _liveListenEnabledMeta,
        ),
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
      liveListenEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}live_listen_enabled'],
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

  /// وضع "سماع مباشر" (بث بلا تحميل) — يتجاهل `QuranAudioController` أي
  /// ملف محلي منزَّل ويشغّل رابط كل آية/سورة مباشرة دائماً حين مفعَّل، راجع
  /// `quran_audio_bar.dart`/`audio_downloads_screen.dart`.
  final bool liveListenEnabled;
  const AudioSetting({
    required this.id,
    required this.reciterId,
    required this.speed,
    required this.liveListenEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reciter_id'] = Variable<String>(reciterId);
    map['speed'] = Variable<double>(speed);
    map['live_listen_enabled'] = Variable<bool>(liveListenEnabled);
    return map;
  }

  AudioSettingsCompanion toCompanion(bool nullToAbsent) {
    return AudioSettingsCompanion(
      id: Value(id),
      reciterId: Value(reciterId),
      speed: Value(speed),
      liveListenEnabled: Value(liveListenEnabled),
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
      liveListenEnabled: serializer.fromJson<bool>(json['liveListenEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reciterId': serializer.toJson<String>(reciterId),
      'speed': serializer.toJson<double>(speed),
      'liveListenEnabled': serializer.toJson<bool>(liveListenEnabled),
    };
  }

  AudioSetting copyWith({
    int? id,
    String? reciterId,
    double? speed,
    bool? liveListenEnabled,
  }) => AudioSetting(
    id: id ?? this.id,
    reciterId: reciterId ?? this.reciterId,
    speed: speed ?? this.speed,
    liveListenEnabled: liveListenEnabled ?? this.liveListenEnabled,
  );
  AudioSetting copyWithCompanion(AudioSettingsCompanion data) {
    return AudioSetting(
      id: data.id.present ? data.id.value : this.id,
      reciterId: data.reciterId.present ? data.reciterId.value : this.reciterId,
      speed: data.speed.present ? data.speed.value : this.speed,
      liveListenEnabled: data.liveListenEnabled.present
          ? data.liveListenEnabled.value
          : this.liveListenEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioSetting(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('speed: $speed, ')
          ..write('liveListenEnabled: $liveListenEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reciterId, speed, liveListenEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioSetting &&
          other.id == this.id &&
          other.reciterId == this.reciterId &&
          other.speed == this.speed &&
          other.liveListenEnabled == this.liveListenEnabled);
}

class AudioSettingsCompanion extends UpdateCompanion<AudioSetting> {
  final Value<int> id;
  final Value<String> reciterId;
  final Value<double> speed;
  final Value<bool> liveListenEnabled;
  const AudioSettingsCompanion({
    this.id = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.speed = const Value.absent(),
    this.liveListenEnabled = const Value.absent(),
  });
  AudioSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.speed = const Value.absent(),
    this.liveListenEnabled = const Value.absent(),
  });
  static Insertable<AudioSetting> custom({
    Expression<int>? id,
    Expression<String>? reciterId,
    Expression<double>? speed,
    Expression<bool>? liveListenEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reciterId != null) 'reciter_id': reciterId,
      if (speed != null) 'speed': speed,
      if (liveListenEnabled != null) 'live_listen_enabled': liveListenEnabled,
    });
  }

  AudioSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? reciterId,
    Value<double>? speed,
    Value<bool>? liveListenEnabled,
  }) {
    return AudioSettingsCompanion(
      id: id ?? this.id,
      reciterId: reciterId ?? this.reciterId,
      speed: speed ?? this.speed,
      liveListenEnabled: liveListenEnabled ?? this.liveListenEnabled,
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
    if (liveListenEnabled.present) {
      map['live_listen_enabled'] = Variable<bool>(liveListenEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioSettingsCompanion(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('speed: $speed, ')
          ..write('liveListenEnabled: $liveListenEnabled')
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

class $HifzPlansTable extends HifzPlans
    with TableInfo<$HifzPlansTable, HifzPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HifzPlansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fromAyahIdMeta = const VerificationMeta(
    'fromAyahId',
  );
  @override
  late final GeneratedColumn<int> fromAyahId = GeneratedColumn<int>(
    'from_ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAyahIdMeta = const VerificationMeta(
    'toAyahId',
  );
  @override
  late final GeneratedColumn<int> toAyahId = GeneratedColumn<int>(
    'to_ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentAyahIdMeta = const VerificationMeta(
    'currentAyahId',
  );
  @override
  late final GeneratedColumn<int> currentAyahId = GeneratedColumn<int>(
    'current_ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [
    id,
    fromAyahId,
    toAyahId,
    currentAyahId,
    createdAt,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hifz_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<HifzPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_ayah_id')) {
      context.handle(
        _fromAyahIdMeta,
        fromAyahId.isAcceptableOrUnknown(
          data['from_ayah_id']!,
          _fromAyahIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAyahIdMeta);
    }
    if (data.containsKey('to_ayah_id')) {
      context.handle(
        _toAyahIdMeta,
        toAyahId.isAcceptableOrUnknown(data['to_ayah_id']!, _toAyahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toAyahIdMeta);
    }
    if (data.containsKey('current_ayah_id')) {
      context.handle(
        _currentAyahIdMeta,
        currentAyahId.isAcceptableOrUnknown(
          data['current_ayah_id']!,
          _currentAyahIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentAyahIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  HifzPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HifzPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fromAyahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_ayah_id'],
      )!,
      toAyahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_ayah_id'],
      )!,
      currentAyahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_ayah_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $HifzPlansTable createAlias(String alias) {
    return $HifzPlansTable(attachedDatabase, alias);
  }
}

class HifzPlan extends DataClass implements Insertable<HifzPlan> {
  final int id;
  final int fromAyahId;
  final int toAyahId;
  final int currentAyahId;
  final DateTime createdAt;
  final bool active;
  const HifzPlan({
    required this.id,
    required this.fromAyahId,
    required this.toAyahId,
    required this.currentAyahId,
    required this.createdAt,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_ayah_id'] = Variable<int>(fromAyahId);
    map['to_ayah_id'] = Variable<int>(toAyahId);
    map['current_ayah_id'] = Variable<int>(currentAyahId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['active'] = Variable<bool>(active);
    return map;
  }

  HifzPlansCompanion toCompanion(bool nullToAbsent) {
    return HifzPlansCompanion(
      id: Value(id),
      fromAyahId: Value(fromAyahId),
      toAyahId: Value(toAyahId),
      currentAyahId: Value(currentAyahId),
      createdAt: Value(createdAt),
      active: Value(active),
    );
  }

  factory HifzPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HifzPlan(
      id: serializer.fromJson<int>(json['id']),
      fromAyahId: serializer.fromJson<int>(json['fromAyahId']),
      toAyahId: serializer.fromJson<int>(json['toAyahId']),
      currentAyahId: serializer.fromJson<int>(json['currentAyahId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromAyahId': serializer.toJson<int>(fromAyahId),
      'toAyahId': serializer.toJson<int>(toAyahId),
      'currentAyahId': serializer.toJson<int>(currentAyahId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'active': serializer.toJson<bool>(active),
    };
  }

  HifzPlan copyWith({
    int? id,
    int? fromAyahId,
    int? toAyahId,
    int? currentAyahId,
    DateTime? createdAt,
    bool? active,
  }) => HifzPlan(
    id: id ?? this.id,
    fromAyahId: fromAyahId ?? this.fromAyahId,
    toAyahId: toAyahId ?? this.toAyahId,
    currentAyahId: currentAyahId ?? this.currentAyahId,
    createdAt: createdAt ?? this.createdAt,
    active: active ?? this.active,
  );
  HifzPlan copyWithCompanion(HifzPlansCompanion data) {
    return HifzPlan(
      id: data.id.present ? data.id.value : this.id,
      fromAyahId: data.fromAyahId.present
          ? data.fromAyahId.value
          : this.fromAyahId,
      toAyahId: data.toAyahId.present ? data.toAyahId.value : this.toAyahId,
      currentAyahId: data.currentAyahId.present
          ? data.currentAyahId.value
          : this.currentAyahId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HifzPlan(')
          ..write('id: $id, ')
          ..write('fromAyahId: $fromAyahId, ')
          ..write('toAyahId: $toAyahId, ')
          ..write('currentAyahId: $currentAyahId, ')
          ..write('createdAt: $createdAt, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fromAyahId, toAyahId, currentAyahId, createdAt, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HifzPlan &&
          other.id == this.id &&
          other.fromAyahId == this.fromAyahId &&
          other.toAyahId == this.toAyahId &&
          other.currentAyahId == this.currentAyahId &&
          other.createdAt == this.createdAt &&
          other.active == this.active);
}

class HifzPlansCompanion extends UpdateCompanion<HifzPlan> {
  final Value<int> id;
  final Value<int> fromAyahId;
  final Value<int> toAyahId;
  final Value<int> currentAyahId;
  final Value<DateTime> createdAt;
  final Value<bool> active;
  const HifzPlansCompanion({
    this.id = const Value.absent(),
    this.fromAyahId = const Value.absent(),
    this.toAyahId = const Value.absent(),
    this.currentAyahId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.active = const Value.absent(),
  });
  HifzPlansCompanion.insert({
    this.id = const Value.absent(),
    required int fromAyahId,
    required int toAyahId,
    required int currentAyahId,
    required DateTime createdAt,
    this.active = const Value.absent(),
  }) : fromAyahId = Value(fromAyahId),
       toAyahId = Value(toAyahId),
       currentAyahId = Value(currentAyahId),
       createdAt = Value(createdAt);
  static Insertable<HifzPlan> custom({
    Expression<int>? id,
    Expression<int>? fromAyahId,
    Expression<int>? toAyahId,
    Expression<int>? currentAyahId,
    Expression<DateTime>? createdAt,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromAyahId != null) 'from_ayah_id': fromAyahId,
      if (toAyahId != null) 'to_ayah_id': toAyahId,
      if (currentAyahId != null) 'current_ayah_id': currentAyahId,
      if (createdAt != null) 'created_at': createdAt,
      if (active != null) 'active': active,
    });
  }

  HifzPlansCompanion copyWith({
    Value<int>? id,
    Value<int>? fromAyahId,
    Value<int>? toAyahId,
    Value<int>? currentAyahId,
    Value<DateTime>? createdAt,
    Value<bool>? active,
  }) {
    return HifzPlansCompanion(
      id: id ?? this.id,
      fromAyahId: fromAyahId ?? this.fromAyahId,
      toAyahId: toAyahId ?? this.toAyahId,
      currentAyahId: currentAyahId ?? this.currentAyahId,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromAyahId.present) {
      map['from_ayah_id'] = Variable<int>(fromAyahId.value);
    }
    if (toAyahId.present) {
      map['to_ayah_id'] = Variable<int>(toAyahId.value);
    }
    if (currentAyahId.present) {
      map['current_ayah_id'] = Variable<int>(currentAyahId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HifzPlansCompanion(')
          ..write('id: $id, ')
          ..write('fromAyahId: $fromAyahId, ')
          ..write('toAyahId: $toAyahId, ')
          ..write('currentAyahId: $currentAyahId, ')
          ..write('createdAt: $createdAt, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $HifzSettingsTable extends HifzSettings
    with TableInfo<$HifzSettingsTable, HifzSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HifzSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'hifz_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<HifzSetting> instance, {
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
  HifzSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HifzSetting(
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
  $HifzSettingsTable createAlias(String alias) {
    return $HifzSettingsTable(attachedDatabase, alias);
  }
}

class HifzSetting extends DataClass implements Insertable<HifzSetting> {
  final int id;
  final int? reminderHour;
  final int reminderMinute;
  final bool enabled;
  const HifzSetting({
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

  HifzSettingsCompanion toCompanion(bool nullToAbsent) {
    return HifzSettingsCompanion(
      id: Value(id),
      reminderHour: reminderHour == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      enabled: Value(enabled),
    );
  }

  factory HifzSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HifzSetting(
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

  HifzSetting copyWith({
    int? id,
    Value<int?> reminderHour = const Value.absent(),
    int? reminderMinute,
    bool? enabled,
  }) => HifzSetting(
    id: id ?? this.id,
    reminderHour: reminderHour.present ? reminderHour.value : this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    enabled: enabled ?? this.enabled,
  );
  HifzSetting copyWithCompanion(HifzSettingsCompanion data) {
    return HifzSetting(
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
    return (StringBuffer('HifzSetting(')
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
      (other is HifzSetting &&
          other.id == this.id &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.enabled == this.enabled);
}

class HifzSettingsCompanion extends UpdateCompanion<HifzSetting> {
  final Value<int> id;
  final Value<int?> reminderHour;
  final Value<int> reminderMinute;
  final Value<bool> enabled;
  const HifzSettingsCompanion({
    this.id = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  HifzSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  static Insertable<HifzSetting> custom({
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

  HifzSettingsCompanion copyWith({
    Value<int>? id,
    Value<int?>? reminderHour,
    Value<int>? reminderMinute,
    Value<bool>? enabled,
  }) {
    return HifzSettingsCompanion(
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
    return (StringBuffer('HifzSettingsCompanion(')
          ..write('id: $id, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $ActivityRemindersTable extends ActivityReminders
    with TableInfo<$ActivityRemindersTable, ActivityReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityRemindersTable(this.attachedDatabase, [this._alias]);
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
    category,
    reminderHour,
    reminderMinute,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityReminder> instance, {
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
  Set<GeneratedColumn> get $primaryKey => {category};
  @override
  ActivityReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityReminder(
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
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
  $ActivityRemindersTable createAlias(String alias) {
    return $ActivityRemindersTable(attachedDatabase, alias);
  }
}

class ActivityReminder extends DataClass
    implements Insertable<ActivityReminder> {
  final String category;
  final int? reminderHour;
  final int reminderMinute;
  final bool enabled;
  const ActivityReminder({
    required this.category,
    this.reminderHour,
    required this.reminderMinute,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || reminderHour != null) {
      map['reminder_hour'] = Variable<int>(reminderHour);
    }
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  ActivityRemindersCompanion toCompanion(bool nullToAbsent) {
    return ActivityRemindersCompanion(
      category: Value(category),
      reminderHour: reminderHour == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      enabled: Value(enabled),
    );
  }

  factory ActivityReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityReminder(
      category: serializer.fromJson<String>(json['category']),
      reminderHour: serializer.fromJson<int?>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'category': serializer.toJson<String>(category),
      'reminderHour': serializer.toJson<int?>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  ActivityReminder copyWith({
    String? category,
    Value<int?> reminderHour = const Value.absent(),
    int? reminderMinute,
    bool? enabled,
  }) => ActivityReminder(
    category: category ?? this.category,
    reminderHour: reminderHour.present ? reminderHour.value : this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    enabled: enabled ?? this.enabled,
  );
  ActivityReminder copyWithCompanion(ActivityRemindersCompanion data) {
    return ActivityReminder(
      category: data.category.present ? data.category.value : this.category,
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
    return (StringBuffer('ActivityReminder(')
          ..write('category: $category, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(category, reminderHour, reminderMinute, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityReminder &&
          other.category == this.category &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.enabled == this.enabled);
}

class ActivityRemindersCompanion extends UpdateCompanion<ActivityReminder> {
  final Value<String> category;
  final Value<int?> reminderHour;
  final Value<int> reminderMinute;
  final Value<bool> enabled;
  final Value<int> rowid;
  const ActivityRemindersCompanion({
    this.category = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityRemindersCompanion.insert({
    required String category,
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : category = Value(category);
  static Insertable<ActivityReminder> custom({
    Expression<String>? category,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (category != null) 'category': category,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityRemindersCompanion copyWith({
    Value<String>? category,
    Value<int?>? reminderHour,
    Value<int>? reminderMinute,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return ActivityRemindersCompanion(
      category: category ?? this.category,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRemindersCompanion(')
          ..write('category: $category, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhanSettingsTable extends AdhanSettings
    with TableInfo<$AdhanSettingsTable, AdhanSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhanSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, voiceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhan_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhanSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdhanSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhanSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      )!,
    );
  }

  @override
  $AdhanSettingsTable createAlias(String alias) {
    return $AdhanSettingsTable(attachedDatabase, alias);
  }
}

class AdhanSetting extends DataClass implements Insertable<AdhanSetting> {
  final int id;
  final String voiceId;
  const AdhanSetting({required this.id, required this.voiceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['voice_id'] = Variable<String>(voiceId);
    return map;
  }

  AdhanSettingsCompanion toCompanion(bool nullToAbsent) {
    return AdhanSettingsCompanion(id: Value(id), voiceId: Value(voiceId));
  }

  factory AdhanSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhanSetting(
      id: serializer.fromJson<int>(json['id']),
      voiceId: serializer.fromJson<String>(json['voiceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'voiceId': serializer.toJson<String>(voiceId),
    };
  }

  AdhanSetting copyWith({int? id, String? voiceId}) =>
      AdhanSetting(id: id ?? this.id, voiceId: voiceId ?? this.voiceId);
  AdhanSetting copyWithCompanion(AdhanSettingsCompanion data) {
    return AdhanSetting(
      id: data.id.present ? data.id.value : this.id,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhanSetting(')
          ..write('id: $id, ')
          ..write('voiceId: $voiceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, voiceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhanSetting &&
          other.id == this.id &&
          other.voiceId == this.voiceId);
}

class AdhanSettingsCompanion extends UpdateCompanion<AdhanSetting> {
  final Value<int> id;
  final Value<String> voiceId;
  const AdhanSettingsCompanion({
    this.id = const Value.absent(),
    this.voiceId = const Value.absent(),
  });
  AdhanSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.voiceId = const Value.absent(),
  });
  static Insertable<AdhanSetting> custom({
    Expression<int>? id,
    Expression<String>? voiceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (voiceId != null) 'voice_id': voiceId,
    });
  }

  AdhanSettingsCompanion copyWith({Value<int>? id, Value<String>? voiceId}) {
    return AdhanSettingsCompanion(
      id: id ?? this.id,
      voiceId: voiceId ?? this.voiceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhanSettingsCompanion(')
          ..write('id: $id, ')
          ..write('voiceId: $voiceId')
          ..write(')'))
        .toString();
  }
}

class $ActivityBookmarksTable extends ActivityBookmarks
    with TableInfo<$ActivityBookmarksTable, ActivityBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setAtMeta = const VerificationMeta('setAt');
  @override
  late final GeneratedColumn<DateTime> setAt = GeneratedColumn<DateTime>(
    'set_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [type, ayahId, setAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityBookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('set_at')) {
      context.handle(
        _setAtMeta,
        setAt.isAcceptableOrUnknown(data['set_at']!, _setAtMeta),
      );
    } else if (isInserting) {
      context.missing(_setAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {type};
  @override
  ActivityBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityBookmark(
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      setAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}set_at'],
      )!,
    );
  }

  @override
  $ActivityBookmarksTable createAlias(String alias) {
    return $ActivityBookmarksTable(attachedDatabase, alias);
  }
}

class ActivityBookmark extends DataClass
    implements Insertable<ActivityBookmark> {
  final String type;
  final int ayahId;
  final DateTime setAt;
  const ActivityBookmark({
    required this.type,
    required this.ayahId,
    required this.setAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type'] = Variable<String>(type);
    map['ayah_id'] = Variable<int>(ayahId);
    map['set_at'] = Variable<DateTime>(setAt);
    return map;
  }

  ActivityBookmarksCompanion toCompanion(bool nullToAbsent) {
    return ActivityBookmarksCompanion(
      type: Value(type),
      ayahId: Value(ayahId),
      setAt: Value(setAt),
    );
  }

  factory ActivityBookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityBookmark(
      type: serializer.fromJson<String>(json['type']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      setAt: serializer.fromJson<DateTime>(json['setAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'type': serializer.toJson<String>(type),
      'ayahId': serializer.toJson<int>(ayahId),
      'setAt': serializer.toJson<DateTime>(setAt),
    };
  }

  ActivityBookmark copyWith({String? type, int? ayahId, DateTime? setAt}) =>
      ActivityBookmark(
        type: type ?? this.type,
        ayahId: ayahId ?? this.ayahId,
        setAt: setAt ?? this.setAt,
      );
  ActivityBookmark copyWithCompanion(ActivityBookmarksCompanion data) {
    return ActivityBookmark(
      type: data.type.present ? data.type.value : this.type,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      setAt: data.setAt.present ? data.setAt.value : this.setAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityBookmark(')
          ..write('type: $type, ')
          ..write('ayahId: $ayahId, ')
          ..write('setAt: $setAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(type, ayahId, setAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityBookmark &&
          other.type == this.type &&
          other.ayahId == this.ayahId &&
          other.setAt == this.setAt);
}

class ActivityBookmarksCompanion extends UpdateCompanion<ActivityBookmark> {
  final Value<String> type;
  final Value<int> ayahId;
  final Value<DateTime> setAt;
  final Value<int> rowid;
  const ActivityBookmarksCompanion({
    this.type = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.setAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityBookmarksCompanion.insert({
    required String type,
    required int ayahId,
    required DateTime setAt,
    this.rowid = const Value.absent(),
  }) : type = Value(type),
       ayahId = Value(ayahId),
       setAt = Value(setAt);
  static Insertable<ActivityBookmark> custom({
    Expression<String>? type,
    Expression<int>? ayahId,
    Expression<DateTime>? setAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (type != null) 'type': type,
      if (ayahId != null) 'ayah_id': ayahId,
      if (setAt != null) 'set_at': setAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityBookmarksCompanion copyWith({
    Value<String>? type,
    Value<int>? ayahId,
    Value<DateTime>? setAt,
    Value<int>? rowid,
  }) {
    return ActivityBookmarksCompanion(
      type: type ?? this.type,
      ayahId: ayahId ?? this.ayahId,
      setAt: setAt ?? this.setAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (setAt.present) {
      map['set_at'] = Variable<DateTime>(setAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityBookmarksCompanion(')
          ..write('type: $type, ')
          ..write('ayahId: $ayahId, ')
          ..write('setAt: $setAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryDailyLogTable extends CategoryDailyLog
    with TableInfo<$CategoryDailyLogTable, CategoryDailyLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryDailyLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [category, dateKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_daily_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryDailyLogData> instance, {
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
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {category, dateKey};
  @override
  CategoryDailyLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryDailyLogData(
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
    );
  }

  @override
  $CategoryDailyLogTable createAlias(String alias) {
    return $CategoryDailyLogTable(attachedDatabase, alias);
  }
}

class CategoryDailyLogData extends DataClass
    implements Insertable<CategoryDailyLogData> {
  final String category;
  final String dateKey;
  const CategoryDailyLogData({required this.category, required this.dateKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category'] = Variable<String>(category);
    map['date_key'] = Variable<String>(dateKey);
    return map;
  }

  CategoryDailyLogCompanion toCompanion(bool nullToAbsent) {
    return CategoryDailyLogCompanion(
      category: Value(category),
      dateKey: Value(dateKey),
    );
  }

  factory CategoryDailyLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryDailyLogData(
      category: serializer.fromJson<String>(json['category']),
      dateKey: serializer.fromJson<String>(json['dateKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'category': serializer.toJson<String>(category),
      'dateKey': serializer.toJson<String>(dateKey),
    };
  }

  CategoryDailyLogData copyWith({String? category, String? dateKey}) =>
      CategoryDailyLogData(
        category: category ?? this.category,
        dateKey: dateKey ?? this.dateKey,
      );
  CategoryDailyLogData copyWithCompanion(CategoryDailyLogCompanion data) {
    return CategoryDailyLogData(
      category: data.category.present ? data.category.value : this.category,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryDailyLogData(')
          ..write('category: $category, ')
          ..write('dateKey: $dateKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(category, dateKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryDailyLogData &&
          other.category == this.category &&
          other.dateKey == this.dateKey);
}

class CategoryDailyLogCompanion extends UpdateCompanion<CategoryDailyLogData> {
  final Value<String> category;
  final Value<String> dateKey;
  final Value<int> rowid;
  const CategoryDailyLogCompanion({
    this.category = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryDailyLogCompanion.insert({
    required String category,
    required String dateKey,
    this.rowid = const Value.absent(),
  }) : category = Value(category),
       dateKey = Value(dateKey);
  static Insertable<CategoryDailyLogData> custom({
    Expression<String>? category,
    Expression<String>? dateKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (category != null) 'category': category,
      if (dateKey != null) 'date_key': dateKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryDailyLogCompanion copyWith({
    Value<String>? category,
    Value<String>? dateKey,
    Value<int>? rowid,
  }) {
    return CategoryDailyLogCompanion(
      category: category ?? this.category,
      dateKey: dateKey ?? this.dateKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryDailyLogCompanion(')
          ..write('category: $category, ')
          ..write('dateKey: $dateKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhanNotificationSettingsTable extends AdhanNotificationSettings
    with TableInfo<$AdhanNotificationSettingsTable, AdhanNotificationSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhanNotificationSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _prayerMeta = const VerificationMeta('prayer');
  @override
  late final GeneratedColumn<String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [prayer, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhan_notification_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhanNotificationSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prayer')) {
      context.handle(
        _prayerMeta,
        prayer.isAcceptableOrUnknown(data['prayer']!, _prayerMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerMeta);
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
  Set<GeneratedColumn> get $primaryKey => {prayer};
  @override
  AdhanNotificationSetting map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhanNotificationSetting(
      prayer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prayer'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $AdhanNotificationSettingsTable createAlias(String alias) {
    return $AdhanNotificationSettingsTable(attachedDatabase, alias);
  }
}

class AdhanNotificationSetting extends DataClass
    implements Insertable<AdhanNotificationSetting> {
  final String prayer;
  final bool enabled;
  const AdhanNotificationSetting({required this.prayer, required this.enabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prayer'] = Variable<String>(prayer);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  AdhanNotificationSettingsCompanion toCompanion(bool nullToAbsent) {
    return AdhanNotificationSettingsCompanion(
      prayer: Value(prayer),
      enabled: Value(enabled),
    );
  }

  factory AdhanNotificationSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhanNotificationSetting(
      prayer: serializer.fromJson<String>(json['prayer']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prayer': serializer.toJson<String>(prayer),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  AdhanNotificationSetting copyWith({String? prayer, bool? enabled}) =>
      AdhanNotificationSetting(
        prayer: prayer ?? this.prayer,
        enabled: enabled ?? this.enabled,
      );
  AdhanNotificationSetting copyWithCompanion(
    AdhanNotificationSettingsCompanion data,
  ) {
    return AdhanNotificationSetting(
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhanNotificationSetting(')
          ..write('prayer: $prayer, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(prayer, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhanNotificationSetting &&
          other.prayer == this.prayer &&
          other.enabled == this.enabled);
}

class AdhanNotificationSettingsCompanion
    extends UpdateCompanion<AdhanNotificationSetting> {
  final Value<String> prayer;
  final Value<bool> enabled;
  final Value<int> rowid;
  const AdhanNotificationSettingsCompanion({
    this.prayer = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhanNotificationSettingsCompanion.insert({
    required String prayer,
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : prayer = Value(prayer);
  static Insertable<AdhanNotificationSetting> custom({
    Expression<String>? prayer,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (prayer != null) 'prayer': prayer,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhanNotificationSettingsCompanion copyWith({
    Value<String>? prayer,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return AdhanNotificationSettingsCompanion(
      prayer: prayer ?? this.prayer,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prayer.present) {
      map['prayer'] = Variable<String>(prayer.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhanNotificationSettingsCompanion(')
          ..write('prayer: $prayer, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MushafColorSettingsTable extends MushafColorSettings
    with TableInfo<$MushafColorSettingsTable, MushafColorSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MushafColorSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _paletteIdMeta = const VerificationMeta(
    'paletteId',
  );
  @override
  late final GeneratedColumn<String> paletteId = GeneratedColumn<String>(
    'palette_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _nightModeMeta = const VerificationMeta(
    'nightMode',
  );
  @override
  late final GeneratedColumn<String> nightMode = GeneratedColumn<String>(
    'night_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, paletteId, nightMode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mushaf_color_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<MushafColorSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('palette_id')) {
      context.handle(
        _paletteIdMeta,
        paletteId.isAcceptableOrUnknown(data['palette_id']!, _paletteIdMeta),
      );
    }
    if (data.containsKey('night_mode')) {
      context.handle(
        _nightModeMeta,
        nightMode.isAcceptableOrUnknown(data['night_mode']!, _nightModeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MushafColorSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MushafColorSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      paletteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}palette_id'],
      )!,
      nightMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}night_mode'],
      )!,
    );
  }

  @override
  $MushafColorSettingsTable createAlias(String alias) {
    return $MushafColorSettingsTable(attachedDatabase, alias);
  }
}

class MushafColorSetting extends DataClass
    implements Insertable<MushafColorSetting> {
  final int id;
  final String paletteId;

  /// وضع "المصحف الليلي" (قلب ألوان الصفحة + تعتيم خفيف، راجع
  /// `mushaf_page_widget.dart`) — واحدة من `off`/`on`/`auto` (`auto` تتبع
  /// وضع الثيم العام المظلم تلقائياً، الافتراضي).
  final String nightMode;
  const MushafColorSetting({
    required this.id,
    required this.paletteId,
    required this.nightMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['palette_id'] = Variable<String>(paletteId);
    map['night_mode'] = Variable<String>(nightMode);
    return map;
  }

  MushafColorSettingsCompanion toCompanion(bool nullToAbsent) {
    return MushafColorSettingsCompanion(
      id: Value(id),
      paletteId: Value(paletteId),
      nightMode: Value(nightMode),
    );
  }

  factory MushafColorSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MushafColorSetting(
      id: serializer.fromJson<int>(json['id']),
      paletteId: serializer.fromJson<String>(json['paletteId']),
      nightMode: serializer.fromJson<String>(json['nightMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'paletteId': serializer.toJson<String>(paletteId),
      'nightMode': serializer.toJson<String>(nightMode),
    };
  }

  MushafColorSetting copyWith({
    int? id,
    String? paletteId,
    String? nightMode,
  }) => MushafColorSetting(
    id: id ?? this.id,
    paletteId: paletteId ?? this.paletteId,
    nightMode: nightMode ?? this.nightMode,
  );
  MushafColorSetting copyWithCompanion(MushafColorSettingsCompanion data) {
    return MushafColorSetting(
      id: data.id.present ? data.id.value : this.id,
      paletteId: data.paletteId.present ? data.paletteId.value : this.paletteId,
      nightMode: data.nightMode.present ? data.nightMode.value : this.nightMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MushafColorSetting(')
          ..write('id: $id, ')
          ..write('paletteId: $paletteId, ')
          ..write('nightMode: $nightMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, paletteId, nightMode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MushafColorSetting &&
          other.id == this.id &&
          other.paletteId == this.paletteId &&
          other.nightMode == this.nightMode);
}

class MushafColorSettingsCompanion extends UpdateCompanion<MushafColorSetting> {
  final Value<int> id;
  final Value<String> paletteId;
  final Value<String> nightMode;
  const MushafColorSettingsCompanion({
    this.id = const Value.absent(),
    this.paletteId = const Value.absent(),
    this.nightMode = const Value.absent(),
  });
  MushafColorSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.paletteId = const Value.absent(),
    this.nightMode = const Value.absent(),
  });
  static Insertable<MushafColorSetting> custom({
    Expression<int>? id,
    Expression<String>? paletteId,
    Expression<String>? nightMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paletteId != null) 'palette_id': paletteId,
      if (nightMode != null) 'night_mode': nightMode,
    });
  }

  MushafColorSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? paletteId,
    Value<String>? nightMode,
  }) {
    return MushafColorSettingsCompanion(
      id: id ?? this.id,
      paletteId: paletteId ?? this.paletteId,
      nightMode: nightMode ?? this.nightMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (paletteId.present) {
      map['palette_id'] = Variable<String>(paletteId.value);
    }
    if (nightMode.present) {
      map['night_mode'] = Variable<String>(nightMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MushafColorSettingsCompanion(')
          ..write('id: $id, ')
          ..write('paletteId: $paletteId, ')
          ..write('nightMode: $nightMode')
          ..write(')'))
        .toString();
  }
}

class $PrayerCheckinSettingsTable extends PrayerCheckinSettings
    with TableInfo<$PrayerCheckinSettingsTable, PrayerCheckinSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerCheckinSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _firstDelayMinutesMeta = const VerificationMeta(
    'firstDelayMinutes',
  );
  @override
  late final GeneratedColumn<int> firstDelayMinutes = GeneratedColumn<int>(
    'first_delay_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  @override
  List<GeneratedColumn> get $columns => [id, enabled, firstDelayMinutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_checkin_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerCheckinSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('first_delay_minutes')) {
      context.handle(
        _firstDelayMinutesMeta,
        firstDelayMinutes.isAcceptableOrUnknown(
          data['first_delay_minutes']!,
          _firstDelayMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrayerCheckinSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerCheckinSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      firstDelayMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_delay_minutes'],
      )!,
    );
  }

  @override
  $PrayerCheckinSettingsTable createAlias(String alias) {
    return $PrayerCheckinSettingsTable(attachedDatabase, alias);
  }
}

class PrayerCheckinSetting extends DataClass
    implements Insertable<PrayerCheckinSetting> {
  final int id;
  final bool enabled;
  final int firstDelayMinutes;
  const PrayerCheckinSetting({
    required this.id,
    required this.enabled,
    required this.firstDelayMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['first_delay_minutes'] = Variable<int>(firstDelayMinutes);
    return map;
  }

  PrayerCheckinSettingsCompanion toCompanion(bool nullToAbsent) {
    return PrayerCheckinSettingsCompanion(
      id: Value(id),
      enabled: Value(enabled),
      firstDelayMinutes: Value(firstDelayMinutes),
    );
  }

  factory PrayerCheckinSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerCheckinSetting(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      firstDelayMinutes: serializer.fromJson<int>(json['firstDelayMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'firstDelayMinutes': serializer.toJson<int>(firstDelayMinutes),
    };
  }

  PrayerCheckinSetting copyWith({
    int? id,
    bool? enabled,
    int? firstDelayMinutes,
  }) => PrayerCheckinSetting(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    firstDelayMinutes: firstDelayMinutes ?? this.firstDelayMinutes,
  );
  PrayerCheckinSetting copyWithCompanion(PrayerCheckinSettingsCompanion data) {
    return PrayerCheckinSetting(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      firstDelayMinutes: data.firstDelayMinutes.present
          ? data.firstDelayMinutes.value
          : this.firstDelayMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerCheckinSetting(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('firstDelayMinutes: $firstDelayMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, enabled, firstDelayMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerCheckinSetting &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.firstDelayMinutes == this.firstDelayMinutes);
}

class PrayerCheckinSettingsCompanion
    extends UpdateCompanion<PrayerCheckinSetting> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<int> firstDelayMinutes;
  const PrayerCheckinSettingsCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.firstDelayMinutes = const Value.absent(),
  });
  PrayerCheckinSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.firstDelayMinutes = const Value.absent(),
  });
  static Insertable<PrayerCheckinSetting> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<int>? firstDelayMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (firstDelayMinutes != null) 'first_delay_minutes': firstDelayMinutes,
    });
  }

  PrayerCheckinSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? enabled,
    Value<int>? firstDelayMinutes,
  }) {
    return PrayerCheckinSettingsCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      firstDelayMinutes: firstDelayMinutes ?? this.firstDelayMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (firstDelayMinutes.present) {
      map['first_delay_minutes'] = Variable<int>(firstDelayMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerCheckinSettingsCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('firstDelayMinutes: $firstDelayMinutes')
          ..write(')'))
        .toString();
  }
}

class $QiyamAyahLogTable extends QiyamAyahLog
    with TableInfo<$QiyamAyahLogTable, QiyamAyahLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QiyamAyahLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [dateKey, ayahCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qiyam_ayah_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<QiyamAyahLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateKey};
  @override
  QiyamAyahLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QiyamAyahLogData(
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
    );
  }

  @override
  $QiyamAyahLogTable createAlias(String alias) {
    return $QiyamAyahLogTable(attachedDatabase, alias);
  }
}

class QiyamAyahLogData extends DataClass
    implements Insertable<QiyamAyahLogData> {
  final String dateKey;
  final int ayahCount;
  const QiyamAyahLogData({required this.dateKey, required this.ayahCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_key'] = Variable<String>(dateKey);
    map['ayah_count'] = Variable<int>(ayahCount);
    return map;
  }

  QiyamAyahLogCompanion toCompanion(bool nullToAbsent) {
    return QiyamAyahLogCompanion(
      dateKey: Value(dateKey),
      ayahCount: Value(ayahCount),
    );
  }

  factory QiyamAyahLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QiyamAyahLogData(
      dateKey: serializer.fromJson<String>(json['dateKey']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateKey': serializer.toJson<String>(dateKey),
      'ayahCount': serializer.toJson<int>(ayahCount),
    };
  }

  QiyamAyahLogData copyWith({String? dateKey, int? ayahCount}) =>
      QiyamAyahLogData(
        dateKey: dateKey ?? this.dateKey,
        ayahCount: ayahCount ?? this.ayahCount,
      );
  QiyamAyahLogData copyWithCompanion(QiyamAyahLogCompanion data) {
    return QiyamAyahLogData(
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QiyamAyahLogData(')
          ..write('dateKey: $dateKey, ')
          ..write('ayahCount: $ayahCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dateKey, ayahCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QiyamAyahLogData &&
          other.dateKey == this.dateKey &&
          other.ayahCount == this.ayahCount);
}

class QiyamAyahLogCompanion extends UpdateCompanion<QiyamAyahLogData> {
  final Value<String> dateKey;
  final Value<int> ayahCount;
  final Value<int> rowid;
  const QiyamAyahLogCompanion({
    this.dateKey = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QiyamAyahLogCompanion.insert({
    required String dateKey,
    this.ayahCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dateKey = Value(dateKey);
  static Insertable<QiyamAyahLogData> custom({
    Expression<String>? dateKey,
    Expression<int>? ayahCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateKey != null) 'date_key': dateKey,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QiyamAyahLogCompanion copyWith({
    Value<String>? dateKey,
    Value<int>? ayahCount,
    Value<int>? rowid,
  }) {
    return QiyamAyahLogCompanion(
      dateKey: dateKey ?? this.dateKey,
      ayahCount: ayahCount ?? this.ayahCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QiyamAyahLogCompanion(')
          ..write('dateKey: $dateKey, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AyahNotesTable extends AyahNotes
    with TableInfo<$AyahNotesTable, AyahNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteTextMeta = const VerificationMeta(
    'noteText',
  );
  @override
  late final GeneratedColumn<String> noteText = GeneratedColumn<String>(
    'note_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ayahId, noteText, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<AyahNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    }
    if (data.containsKey('note_text')) {
      context.handle(
        _noteTextMeta,
        noteText.isAcceptableOrUnknown(data['note_text']!, _noteTextMeta),
      );
    } else if (isInserting) {
      context.missing(_noteTextMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ayahId};
  @override
  AyahNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahNote(
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      noteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_text'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AyahNotesTable createAlias(String alias) {
    return $AyahNotesTable(attachedDatabase, alias);
  }
}

class AyahNote extends DataClass implements Insertable<AyahNote> {
  final int ayahId;
  final String noteText;
  final DateTime updatedAt;
  const AyahNote({
    required this.ayahId,
    required this.noteText,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ayah_id'] = Variable<int>(ayahId);
    map['note_text'] = Variable<String>(noteText);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AyahNotesCompanion toCompanion(bool nullToAbsent) {
    return AyahNotesCompanion(
      ayahId: Value(ayahId),
      noteText: Value(noteText),
      updatedAt: Value(updatedAt),
    );
  }

  factory AyahNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahNote(
      ayahId: serializer.fromJson<int>(json['ayahId']),
      noteText: serializer.fromJson<String>(json['noteText']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ayahId': serializer.toJson<int>(ayahId),
      'noteText': serializer.toJson<String>(noteText),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AyahNote copyWith({int? ayahId, String? noteText, DateTime? updatedAt}) =>
      AyahNote(
        ayahId: ayahId ?? this.ayahId,
        noteText: noteText ?? this.noteText,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AyahNote copyWithCompanion(AyahNotesCompanion data) {
    return AyahNote(
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      noteText: data.noteText.present ? data.noteText.value : this.noteText,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahNote(')
          ..write('ayahId: $ayahId, ')
          ..write('noteText: $noteText, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ayahId, noteText, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahNote &&
          other.ayahId == this.ayahId &&
          other.noteText == this.noteText &&
          other.updatedAt == this.updatedAt);
}

class AyahNotesCompanion extends UpdateCompanion<AyahNote> {
  final Value<int> ayahId;
  final Value<String> noteText;
  final Value<DateTime> updatedAt;
  const AyahNotesCompanion({
    this.ayahId = const Value.absent(),
    this.noteText = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AyahNotesCompanion.insert({
    this.ayahId = const Value.absent(),
    required String noteText,
    required DateTime updatedAt,
  }) : noteText = Value(noteText),
       updatedAt = Value(updatedAt);
  static Insertable<AyahNote> custom({
    Expression<int>? ayahId,
    Expression<String>? noteText,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (ayahId != null) 'ayah_id': ayahId,
      if (noteText != null) 'note_text': noteText,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AyahNotesCompanion copyWith({
    Value<int>? ayahId,
    Value<String>? noteText,
    Value<DateTime>? updatedAt,
  }) {
    return AyahNotesCompanion(
      ayahId: ayahId ?? this.ayahId,
      noteText: noteText ?? this.noteText,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (noteText.present) {
      map['note_text'] = Variable<String>(noteText.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahNotesCompanion(')
          ..write('ayahId: $ayahId, ')
          ..write('noteText: $noteText, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppThemeSettingsTable extends AppThemeSettings
    with TableInfo<$AppThemeSettingsTable, AppThemeSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppThemeSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accentColorIdMeta = const VerificationMeta(
    'accentColorId',
  );
  @override
  late final GeneratedColumn<String> accentColorId = GeneratedColumn<String>(
    'accent_color_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gold'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, accentColorId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_theme_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppThemeSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('accent_color_id')) {
      context.handle(
        _accentColorIdMeta,
        accentColorId.isAcceptableOrUnknown(
          data['accent_color_id']!,
          _accentColorIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppThemeSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppThemeSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accentColorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent_color_id'],
      )!,
    );
  }

  @override
  $AppThemeSettingsTable createAlias(String alias) {
    return $AppThemeSettingsTable(attachedDatabase, alias);
  }
}

class AppThemeSetting extends DataClass implements Insertable<AppThemeSetting> {
  final int id;
  final String accentColorId;
  const AppThemeSetting({required this.id, required this.accentColorId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['accent_color_id'] = Variable<String>(accentColorId);
    return map;
  }

  AppThemeSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppThemeSettingsCompanion(
      id: Value(id),
      accentColorId: Value(accentColorId),
    );
  }

  factory AppThemeSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppThemeSetting(
      id: serializer.fromJson<int>(json['id']),
      accentColorId: serializer.fromJson<String>(json['accentColorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accentColorId': serializer.toJson<String>(accentColorId),
    };
  }

  AppThemeSetting copyWith({int? id, String? accentColorId}) => AppThemeSetting(
    id: id ?? this.id,
    accentColorId: accentColorId ?? this.accentColorId,
  );
  AppThemeSetting copyWithCompanion(AppThemeSettingsCompanion data) {
    return AppThemeSetting(
      id: data.id.present ? data.id.value : this.id,
      accentColorId: data.accentColorId.present
          ? data.accentColorId.value
          : this.accentColorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppThemeSetting(')
          ..write('id: $id, ')
          ..write('accentColorId: $accentColorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accentColorId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppThemeSetting &&
          other.id == this.id &&
          other.accentColorId == this.accentColorId);
}

class AppThemeSettingsCompanion extends UpdateCompanion<AppThemeSetting> {
  final Value<int> id;
  final Value<String> accentColorId;
  const AppThemeSettingsCompanion({
    this.id = const Value.absent(),
    this.accentColorId = const Value.absent(),
  });
  AppThemeSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.accentColorId = const Value.absent(),
  });
  static Insertable<AppThemeSetting> custom({
    Expression<int>? id,
    Expression<String>? accentColorId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accentColorId != null) 'accent_color_id': accentColorId,
    });
  }

  AppThemeSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? accentColorId,
  }) {
    return AppThemeSettingsCompanion(
      id: id ?? this.id,
      accentColorId: accentColorId ?? this.accentColorId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accentColorId.present) {
      map['accent_color_id'] = Variable<String>(accentColorId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppThemeSettingsCompanion(')
          ..write('id: $id, ')
          ..write('accentColorId: $accentColorId')
          ..write(')'))
        .toString();
  }
}

class $CustomHabitsTable extends CustomHabits
    with TableInfo<$CustomHabitsTable, CustomHabit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomHabitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDailyMeta = const VerificationMeta(
    'targetDaily',
  );
  @override
  late final GeneratedColumn<int> targetDaily = GeneratedColumn<int>(
    'target_daily',
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
  static const VerificationMeta _remindersEnabledMeta = const VerificationMeta(
    'remindersEnabled',
  );
  @override
  late final GeneratedColumn<bool> remindersEnabled = GeneratedColumn<bool>(
    'reminders_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    title,
    targetDaily,
    reminderHour,
    reminderMinute,
    remindersEnabled,
    active,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomHabit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_daily')) {
      context.handle(
        _targetDailyMeta,
        targetDaily.isAcceptableOrUnknown(
          data['target_daily']!,
          _targetDailyMeta,
        ),
      );
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
    if (data.containsKey('reminders_enabled')) {
      context.handle(
        _remindersEnabledMeta,
        remindersEnabled.isAcceptableOrUnknown(
          data['reminders_enabled']!,
          _remindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
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
  CustomHabit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomHabit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetDaily: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_daily'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      ),
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      remindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_enabled'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomHabitsTable createAlias(String alias) {
    return $CustomHabitsTable(attachedDatabase, alias);
  }
}

class CustomHabit extends DataClass implements Insertable<CustomHabit> {
  final int id;
  final String title;
  final int targetDaily;
  final int? reminderHour;
  final int reminderMinute;
  final bool remindersEnabled;
  final bool active;
  final DateTime createdAt;
  const CustomHabit({
    required this.id,
    required this.title,
    required this.targetDaily,
    this.reminderHour,
    required this.reminderMinute,
    required this.remindersEnabled,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['target_daily'] = Variable<int>(targetDaily);
    if (!nullToAbsent || reminderHour != null) {
      map['reminder_hour'] = Variable<int>(reminderHour);
    }
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['reminders_enabled'] = Variable<bool>(remindersEnabled);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomHabitsCompanion toCompanion(bool nullToAbsent) {
    return CustomHabitsCompanion(
      id: Value(id),
      title: Value(title),
      targetDaily: Value(targetDaily),
      reminderHour: reminderHour == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      remindersEnabled: Value(remindersEnabled),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory CustomHabit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomHabit(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetDaily: serializer.fromJson<int>(json['targetDaily']),
      reminderHour: serializer.fromJson<int?>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      remindersEnabled: serializer.fromJson<bool>(json['remindersEnabled']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'targetDaily': serializer.toJson<int>(targetDaily),
      'reminderHour': serializer.toJson<int?>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'remindersEnabled': serializer.toJson<bool>(remindersEnabled),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomHabit copyWith({
    int? id,
    String? title,
    int? targetDaily,
    Value<int?> reminderHour = const Value.absent(),
    int? reminderMinute,
    bool? remindersEnabled,
    bool? active,
    DateTime? createdAt,
  }) => CustomHabit(
    id: id ?? this.id,
    title: title ?? this.title,
    targetDaily: targetDaily ?? this.targetDaily,
    reminderHour: reminderHour.present ? reminderHour.value : this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomHabit copyWithCompanion(CustomHabitsCompanion data) {
    return CustomHabit(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetDaily: data.targetDaily.present
          ? data.targetDaily.value
          : this.targetDaily,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      remindersEnabled: data.remindersEnabled.present
          ? data.remindersEnabled.value
          : this.remindersEnabled,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomHabit(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDaily: $targetDaily, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    targetDaily,
    reminderHour,
    reminderMinute,
    remindersEnabled,
    active,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomHabit &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetDaily == this.targetDaily &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.remindersEnabled == this.remindersEnabled &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class CustomHabitsCompanion extends UpdateCompanion<CustomHabit> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> targetDaily;
  final Value<int?> reminderHour;
  final Value<int> reminderMinute;
  final Value<bool> remindersEnabled;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const CustomHabitsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDaily = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomHabitsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.targetDaily = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.active = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<CustomHabit> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? targetDaily,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<bool>? remindersEnabled,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetDaily != null) 'target_daily': targetDaily,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (remindersEnabled != null) 'reminders_enabled': remindersEnabled,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomHabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? targetDaily,
    Value<int?>? reminderHour,
    Value<int>? reminderMinute,
    Value<bool>? remindersEnabled,
    Value<bool>? active,
    Value<DateTime>? createdAt,
  }) {
    return CustomHabitsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDaily: targetDaily ?? this.targetDaily,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDaily.present) {
      map['target_daily'] = Variable<int>(targetDaily.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (remindersEnabled.present) {
      map['reminders_enabled'] = Variable<bool>(remindersEnabled.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomHabitsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDaily: $targetDaily, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomHabitLogsTable extends CustomHabitLogs
    with TableInfo<$CustomHabitLogsTable, CustomHabitLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomHabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [habitId, dateKey, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_habit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomHabitLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {habitId, dateKey};
  @override
  CustomHabitLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomHabitLog(
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $CustomHabitLogsTable createAlias(String alias) {
    return $CustomHabitLogsTable(attachedDatabase, alias);
  }
}

class CustomHabitLog extends DataClass implements Insertable<CustomHabitLog> {
  final int habitId;
  final String dateKey;
  final int count;
  const CustomHabitLog({
    required this.habitId,
    required this.dateKey,
    required this.count,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<int>(habitId);
    map['date_key'] = Variable<String>(dateKey);
    map['count'] = Variable<int>(count);
    return map;
  }

  CustomHabitLogsCompanion toCompanion(bool nullToAbsent) {
    return CustomHabitLogsCompanion(
      habitId: Value(habitId),
      dateKey: Value(dateKey),
      count: Value(count),
    );
  }

  factory CustomHabitLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomHabitLog(
      habitId: serializer.fromJson<int>(json['habitId']),
      dateKey: serializer.fromJson<String>(json['dateKey']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<int>(habitId),
      'dateKey': serializer.toJson<String>(dateKey),
      'count': serializer.toJson<int>(count),
    };
  }

  CustomHabitLog copyWith({int? habitId, String? dateKey, int? count}) =>
      CustomHabitLog(
        habitId: habitId ?? this.habitId,
        dateKey: dateKey ?? this.dateKey,
        count: count ?? this.count,
      );
  CustomHabitLog copyWithCompanion(CustomHabitLogsCompanion data) {
    return CustomHabitLog(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomHabitLog(')
          ..write('habitId: $habitId, ')
          ..write('dateKey: $dateKey, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitId, dateKey, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomHabitLog &&
          other.habitId == this.habitId &&
          other.dateKey == this.dateKey &&
          other.count == this.count);
}

class CustomHabitLogsCompanion extends UpdateCompanion<CustomHabitLog> {
  final Value<int> habitId;
  final Value<String> dateKey;
  final Value<int> count;
  final Value<int> rowid;
  const CustomHabitLogsCompanion({
    this.habitId = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomHabitLogsCompanion.insert({
    required int habitId,
    required String dateKey,
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId),
       dateKey = Value(dateKey);
  static Insertable<CustomHabitLog> custom({
    Expression<int>? habitId,
    Expression<String>? dateKey,
    Expression<int>? count,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (dateKey != null) 'date_key': dateKey,
      if (count != null) 'count': count,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomHabitLogsCompanion copyWith({
    Value<int>? habitId,
    Value<String>? dateKey,
    Value<int>? count,
    Value<int>? rowid,
  }) {
    return CustomHabitLogsCompanion(
      habitId: habitId ?? this.habitId,
      dateKey: dateKey ?? this.dateKey,
      count: count ?? this.count,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomHabitLogsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('dateKey: $dateKey, ')
          ..write('count: $count, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HifzAyahReviewsTable extends HifzAyahReviews
    with TableInfo<$HifzAyahReviewsTable, HifzAyahReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HifzAyahReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    planId,
    ayahId,
    easeFactor,
    intervalDays,
    repetitions,
    dueDate,
    lastReviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hifz_ayah_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<HifzAyahReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planId, ayahId};
  @override
  HifzAyahReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HifzAyahReview(
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
    );
  }

  @override
  $HifzAyahReviewsTable createAlias(String alias) {
    return $HifzAyahReviewsTable(attachedDatabase, alias);
  }
}

class HifzAyahReview extends DataClass implements Insertable<HifzAyahReview> {
  final int planId;
  final int ayahId;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final String dueDate;
  final DateTime? lastReviewedAt;
  const HifzAyahReview({
    required this.planId,
    required this.ayahId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueDate,
    this.lastReviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_id'] = Variable<int>(planId);
    map['ayah_id'] = Variable<int>(ayahId);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['due_date'] = Variable<String>(dueDate);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    return map;
  }

  HifzAyahReviewsCompanion toCompanion(bool nullToAbsent) {
    return HifzAyahReviewsCompanion(
      planId: Value(planId),
      ayahId: Value(ayahId),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      dueDate: Value(dueDate),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory HifzAyahReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HifzAyahReview(
      planId: serializer.fromJson<int>(json['planId']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planId': serializer.toJson<int>(planId),
      'ayahId': serializer.toJson<int>(ayahId),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'dueDate': serializer.toJson<String>(dueDate),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
    };
  }

  HifzAyahReview copyWith({
    int? planId,
    int? ayahId,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    String? dueDate,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
  }) => HifzAyahReview(
    planId: planId ?? this.planId,
    ayahId: ayahId ?? this.ayahId,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    dueDate: dueDate ?? this.dueDate,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
  );
  HifzAyahReview copyWithCompanion(HifzAyahReviewsCompanion data) {
    return HifzAyahReview(
      planId: data.planId.present ? data.planId.value : this.planId,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HifzAyahReview(')
          ..write('planId: $planId, ')
          ..write('ayahId: $ayahId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueDate: $dueDate, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    planId,
    ayahId,
    easeFactor,
    intervalDays,
    repetitions,
    dueDate,
    lastReviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HifzAyahReview &&
          other.planId == this.planId &&
          other.ayahId == this.ayahId &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.dueDate == this.dueDate &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class HifzAyahReviewsCompanion extends UpdateCompanion<HifzAyahReview> {
  final Value<int> planId;
  final Value<int> ayahId;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<String> dueDate;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> rowid;
  const HifzAyahReviewsCompanion({
    this.planId = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HifzAyahReviewsCompanion.insert({
    required int planId,
    required int ayahId,
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    required String dueDate,
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : planId = Value(planId),
       ayahId = Value(ayahId),
       dueDate = Value(dueDate);
  static Insertable<HifzAyahReview> custom({
    Expression<int>? planId,
    Expression<int>? ayahId,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<String>? dueDate,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planId != null) 'plan_id': planId,
      if (ayahId != null) 'ayah_id': ayahId,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (dueDate != null) 'due_date': dueDate,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HifzAyahReviewsCompanion copyWith({
    Value<int>? planId,
    Value<int>? ayahId,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<String>? dueDate,
    Value<DateTime?>? lastReviewedAt,
    Value<int>? rowid,
  }) {
    return HifzAyahReviewsCompanion(
      planId: planId ?? this.planId,
      ayahId: ayahId ?? this.ayahId,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HifzAyahReviewsCompanion(')
          ..write('planId: $planId, ')
          ..write('ayahId: $ayahId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueDate: $dueDate, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ToolUsageStatsTable extends ToolUsageStats
    with TableInfo<$ToolUsageStatsTable, ToolUsageStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToolUsageStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _toolIdMeta = const VerificationMeta('toolId');
  @override
  late final GeneratedColumn<String> toolId = GeneratedColumn<String>(
    'tool_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tapCountMeta = const VerificationMeta(
    'tapCount',
  );
  @override
  late final GeneratedColumn<int> tapCount = GeneratedColumn<int>(
    'tap_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [toolId, tapCount, lastUsedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tool_usage_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<ToolUsageStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tool_id')) {
      context.handle(
        _toolIdMeta,
        toolId.isAcceptableOrUnknown(data['tool_id']!, _toolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toolIdMeta);
    }
    if (data.containsKey('tap_count')) {
      context.handle(
        _tapCountMeta,
        tapCount.isAcceptableOrUnknown(data['tap_count']!, _tapCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {toolId};
  @override
  ToolUsageStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToolUsageStat(
      toolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_id'],
      )!,
      tapCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tap_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
    );
  }

  @override
  $ToolUsageStatsTable createAlias(String alias) {
    return $ToolUsageStatsTable(attachedDatabase, alias);
  }
}

class ToolUsageStat extends DataClass implements Insertable<ToolUsageStat> {
  final String toolId;
  final int tapCount;
  final DateTime? lastUsedAt;
  const ToolUsageStat({
    required this.toolId,
    required this.tapCount,
    this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tool_id'] = Variable<String>(toolId);
    map['tap_count'] = Variable<int>(tapCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    return map;
  }

  ToolUsageStatsCompanion toCompanion(bool nullToAbsent) {
    return ToolUsageStatsCompanion(
      toolId: Value(toolId),
      tapCount: Value(tapCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
    );
  }

  factory ToolUsageStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToolUsageStat(
      toolId: serializer.fromJson<String>(json['toolId']),
      tapCount: serializer.fromJson<int>(json['tapCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'toolId': serializer.toJson<String>(toolId),
      'tapCount': serializer.toJson<int>(tapCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
    };
  }

  ToolUsageStat copyWith({
    String? toolId,
    int? tapCount,
    Value<DateTime?> lastUsedAt = const Value.absent(),
  }) => ToolUsageStat(
    toolId: toolId ?? this.toolId,
    tapCount: tapCount ?? this.tapCount,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
  );
  ToolUsageStat copyWithCompanion(ToolUsageStatsCompanion data) {
    return ToolUsageStat(
      toolId: data.toolId.present ? data.toolId.value : this.toolId,
      tapCount: data.tapCount.present ? data.tapCount.value : this.tapCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToolUsageStat(')
          ..write('toolId: $toolId, ')
          ..write('tapCount: $tapCount, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(toolId, tapCount, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolUsageStat &&
          other.toolId == this.toolId &&
          other.tapCount == this.tapCount &&
          other.lastUsedAt == this.lastUsedAt);
}

class ToolUsageStatsCompanion extends UpdateCompanion<ToolUsageStat> {
  final Value<String> toolId;
  final Value<int> tapCount;
  final Value<DateTime?> lastUsedAt;
  final Value<int> rowid;
  const ToolUsageStatsCompanion({
    this.toolId = const Value.absent(),
    this.tapCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ToolUsageStatsCompanion.insert({
    required String toolId,
    this.tapCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : toolId = Value(toolId);
  static Insertable<ToolUsageStat> custom({
    Expression<String>? toolId,
    Expression<int>? tapCount,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (toolId != null) 'tool_id': toolId,
      if (tapCount != null) 'tap_count': tapCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ToolUsageStatsCompanion copyWith({
    Value<String>? toolId,
    Value<int>? tapCount,
    Value<DateTime?>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return ToolUsageStatsCompanion(
      toolId: toolId ?? this.toolId,
      tapCount: tapCount ?? this.tapCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (toolId.present) {
      map['tool_id'] = Variable<String>(toolId.value);
    }
    if (tapCount.present) {
      map['tap_count'] = Variable<int>(tapCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToolUsageStatsCompanion(')
          ..write('toolId: $toolId, ')
          ..write('tapCount: $tapCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingLogTable extends ReadingLog
    with TableInfo<$ReadingLogTable, ReadingLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateDayMeta = const VerificationMeta(
    'dateDay',
  );
  @override
  late final GeneratedColumn<String> dateDay = GeneratedColumn<String>(
    'date_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pagesReadMeta = const VerificationMeta(
    'pagesRead',
  );
  @override
  late final GeneratedColumn<int> pagesRead = GeneratedColumn<int>(
    'pages_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ayahsReadMeta = const VerificationMeta(
    'ayahsRead',
  );
  @override
  late final GeneratedColumn<int> ayahsRead = GeneratedColumn<int>(
    'ayahs_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minutesSpentMeta = const VerificationMeta(
    'minutesSpent',
  );
  @override
  late final GeneratedColumn<int> minutesSpent = GeneratedColumn<int>(
    'minutes_spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dateDay,
    pagesRead,
    ayahsRead,
    minutesSpent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date_day')) {
      context.handle(
        _dateDayMeta,
        dateDay.isAcceptableOrUnknown(data['date_day']!, _dateDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dateDayMeta);
    }
    if (data.containsKey('pages_read')) {
      context.handle(
        _pagesReadMeta,
        pagesRead.isAcceptableOrUnknown(data['pages_read']!, _pagesReadMeta),
      );
    }
    if (data.containsKey('ayahs_read')) {
      context.handle(
        _ayahsReadMeta,
        ayahsRead.isAcceptableOrUnknown(data['ayahs_read']!, _ayahsReadMeta),
      );
    }
    if (data.containsKey('minutes_spent')) {
      context.handle(
        _minutesSpentMeta,
        minutesSpent.isAcceptableOrUnknown(
          data['minutes_spent']!,
          _minutesSpentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dateDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_day'],
      )!,
      pagesRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages_read'],
      )!,
      ayahsRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayahs_read'],
      )!,
      minutesSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_spent'],
      )!,
    );
  }

  @override
  $ReadingLogTable createAlias(String alias) {
    return $ReadingLogTable(attachedDatabase, alias);
  }
}

class ReadingLogData extends DataClass implements Insertable<ReadingLogData> {
  final int id;
  final String dateDay;
  final int pagesRead;
  final int ayahsRead;
  final int minutesSpent;
  const ReadingLogData({
    required this.id,
    required this.dateDay,
    required this.pagesRead,
    required this.ayahsRead,
    required this.minutesSpent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date_day'] = Variable<String>(dateDay);
    map['pages_read'] = Variable<int>(pagesRead);
    map['ayahs_read'] = Variable<int>(ayahsRead);
    map['minutes_spent'] = Variable<int>(minutesSpent);
    return map;
  }

  ReadingLogCompanion toCompanion(bool nullToAbsent) {
    return ReadingLogCompanion(
      id: Value(id),
      dateDay: Value(dateDay),
      pagesRead: Value(pagesRead),
      ayahsRead: Value(ayahsRead),
      minutesSpent: Value(minutesSpent),
    );
  }

  factory ReadingLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingLogData(
      id: serializer.fromJson<int>(json['id']),
      dateDay: serializer.fromJson<String>(json['dateDay']),
      pagesRead: serializer.fromJson<int>(json['pagesRead']),
      ayahsRead: serializer.fromJson<int>(json['ayahsRead']),
      minutesSpent: serializer.fromJson<int>(json['minutesSpent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dateDay': serializer.toJson<String>(dateDay),
      'pagesRead': serializer.toJson<int>(pagesRead),
      'ayahsRead': serializer.toJson<int>(ayahsRead),
      'minutesSpent': serializer.toJson<int>(minutesSpent),
    };
  }

  ReadingLogData copyWith({
    int? id,
    String? dateDay,
    int? pagesRead,
    int? ayahsRead,
    int? minutesSpent,
  }) => ReadingLogData(
    id: id ?? this.id,
    dateDay: dateDay ?? this.dateDay,
    pagesRead: pagesRead ?? this.pagesRead,
    ayahsRead: ayahsRead ?? this.ayahsRead,
    minutesSpent: minutesSpent ?? this.minutesSpent,
  );
  ReadingLogData copyWithCompanion(ReadingLogCompanion data) {
    return ReadingLogData(
      id: data.id.present ? data.id.value : this.id,
      dateDay: data.dateDay.present ? data.dateDay.value : this.dateDay,
      pagesRead: data.pagesRead.present ? data.pagesRead.value : this.pagesRead,
      ayahsRead: data.ayahsRead.present ? data.ayahsRead.value : this.ayahsRead,
      minutesSpent: data.minutesSpent.present
          ? data.minutesSpent.value
          : this.minutesSpent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingLogData(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('ayahsRead: $ayahsRead, ')
          ..write('minutesSpent: $minutesSpent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dateDay, pagesRead, ayahsRead, minutesSpent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingLogData &&
          other.id == this.id &&
          other.dateDay == this.dateDay &&
          other.pagesRead == this.pagesRead &&
          other.ayahsRead == this.ayahsRead &&
          other.minutesSpent == this.minutesSpent);
}

class ReadingLogCompanion extends UpdateCompanion<ReadingLogData> {
  final Value<int> id;
  final Value<String> dateDay;
  final Value<int> pagesRead;
  final Value<int> ayahsRead;
  final Value<int> minutesSpent;
  const ReadingLogCompanion({
    this.id = const Value.absent(),
    this.dateDay = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.ayahsRead = const Value.absent(),
    this.minutesSpent = const Value.absent(),
  });
  ReadingLogCompanion.insert({
    this.id = const Value.absent(),
    required String dateDay,
    this.pagesRead = const Value.absent(),
    this.ayahsRead = const Value.absent(),
    this.minutesSpent = const Value.absent(),
  }) : dateDay = Value(dateDay);
  static Insertable<ReadingLogData> custom({
    Expression<int>? id,
    Expression<String>? dateDay,
    Expression<int>? pagesRead,
    Expression<int>? ayahsRead,
    Expression<int>? minutesSpent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateDay != null) 'date_day': dateDay,
      if (pagesRead != null) 'pages_read': pagesRead,
      if (ayahsRead != null) 'ayahs_read': ayahsRead,
      if (minutesSpent != null) 'minutes_spent': minutesSpent,
    });
  }

  ReadingLogCompanion copyWith({
    Value<int>? id,
    Value<String>? dateDay,
    Value<int>? pagesRead,
    Value<int>? ayahsRead,
    Value<int>? minutesSpent,
  }) {
    return ReadingLogCompanion(
      id: id ?? this.id,
      dateDay: dateDay ?? this.dateDay,
      pagesRead: pagesRead ?? this.pagesRead,
      ayahsRead: ayahsRead ?? this.ayahsRead,
      minutesSpent: minutesSpent ?? this.minutesSpent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dateDay.present) {
      map['date_day'] = Variable<String>(dateDay.value);
    }
    if (pagesRead.present) {
      map['pages_read'] = Variable<int>(pagesRead.value);
    }
    if (ayahsRead.present) {
      map['ayahs_read'] = Variable<int>(ayahsRead.value);
    }
    if (minutesSpent.present) {
      map['minutes_spent'] = Variable<int>(minutesSpent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingLogCompanion(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('ayahsRead: $ayahsRead, ')
          ..write('minutesSpent: $minutesSpent')
          ..write(')'))
        .toString();
  }
}

class $AudioLogTable extends AudioLog
    with TableInfo<$AudioLogTable, AudioLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateDayMeta = const VerificationMeta(
    'dateDay',
  );
  @override
  late final GeneratedColumn<String> dateDay = GeneratedColumn<String>(
    'date_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, dateDay, seconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date_day')) {
      context.handle(
        _dateDayMeta,
        dateDay.isAcceptableOrUnknown(data['date_day']!, _dateDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dateDayMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dateDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_day'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
    );
  }

  @override
  $AudioLogTable createAlias(String alias) {
    return $AudioLogTable(attachedDatabase, alias);
  }
}

class AudioLogData extends DataClass implements Insertable<AudioLogData> {
  final int id;
  final String dateDay;
  final int seconds;
  const AudioLogData({
    required this.id,
    required this.dateDay,
    required this.seconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date_day'] = Variable<String>(dateDay);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  AudioLogCompanion toCompanion(bool nullToAbsent) {
    return AudioLogCompanion(
      id: Value(id),
      dateDay: Value(dateDay),
      seconds: Value(seconds),
    );
  }

  factory AudioLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioLogData(
      id: serializer.fromJson<int>(json['id']),
      dateDay: serializer.fromJson<String>(json['dateDay']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dateDay': serializer.toJson<String>(dateDay),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  AudioLogData copyWith({int? id, String? dateDay, int? seconds}) =>
      AudioLogData(
        id: id ?? this.id,
        dateDay: dateDay ?? this.dateDay,
        seconds: seconds ?? this.seconds,
      );
  AudioLogData copyWithCompanion(AudioLogCompanion data) {
    return AudioLogData(
      id: data.id.present ? data.id.value : this.id,
      dateDay: data.dateDay.present ? data.dateDay.value : this.dateDay,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioLogData(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dateDay, seconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioLogData &&
          other.id == this.id &&
          other.dateDay == this.dateDay &&
          other.seconds == this.seconds);
}

class AudioLogCompanion extends UpdateCompanion<AudioLogData> {
  final Value<int> id;
  final Value<String> dateDay;
  final Value<int> seconds;
  const AudioLogCompanion({
    this.id = const Value.absent(),
    this.dateDay = const Value.absent(),
    this.seconds = const Value.absent(),
  });
  AudioLogCompanion.insert({
    this.id = const Value.absent(),
    required String dateDay,
    this.seconds = const Value.absent(),
  }) : dateDay = Value(dateDay);
  static Insertable<AudioLogData> custom({
    Expression<int>? id,
    Expression<String>? dateDay,
    Expression<int>? seconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateDay != null) 'date_day': dateDay,
      if (seconds != null) 'seconds': seconds,
    });
  }

  AudioLogCompanion copyWith({
    Value<int>? id,
    Value<String>? dateDay,
    Value<int>? seconds,
  }) {
    return AudioLogCompanion(
      id: id ?? this.id,
      dateDay: dateDay ?? this.dateDay,
      seconds: seconds ?? this.seconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dateDay.present) {
      map['date_day'] = Variable<String>(dateDay.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioLogCompanion(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }
}

class $TasbihLogTable extends TasbihLog
    with TableInfo<$TasbihLogTable, TasbihLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasbihLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateDayMeta = const VerificationMeta(
    'dateDay',
  );
  @override
  late final GeneratedColumn<String> dateDay = GeneratedColumn<String>(
    'date_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _azkarKeyMeta = const VerificationMeta(
    'azkarKey',
  );
  @override
  late final GeneratedColumn<String> azkarKey = GeneratedColumn<String>(
    'azkar_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dateDay,
    azkarKey,
    count,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasbih_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasbihLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date_day')) {
      context.handle(
        _dateDayMeta,
        dateDay.isAcceptableOrUnknown(data['date_day']!, _dateDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dateDayMeta);
    }
    if (data.containsKey('azkar_key')) {
      context.handle(
        _azkarKeyMeta,
        azkarKey.isAcceptableOrUnknown(data['azkar_key']!, _azkarKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_azkarKeyMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TasbihLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasbihLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dateDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_day'],
      )!,
      azkarKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}azkar_key'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $TasbihLogTable createAlias(String alias) {
    return $TasbihLogTable(attachedDatabase, alias);
  }
}

class TasbihLogData extends DataClass implements Insertable<TasbihLogData> {
  final int id;
  final String dateDay;
  final String azkarKey;
  final int count;
  final DateTime completedAt;
  const TasbihLogData({
    required this.id,
    required this.dateDay,
    required this.azkarKey,
    required this.count,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date_day'] = Variable<String>(dateDay);
    map['azkar_key'] = Variable<String>(azkarKey);
    map['count'] = Variable<int>(count);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  TasbihLogCompanion toCompanion(bool nullToAbsent) {
    return TasbihLogCompanion(
      id: Value(id),
      dateDay: Value(dateDay),
      azkarKey: Value(azkarKey),
      count: Value(count),
      completedAt: Value(completedAt),
    );
  }

  factory TasbihLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasbihLogData(
      id: serializer.fromJson<int>(json['id']),
      dateDay: serializer.fromJson<String>(json['dateDay']),
      azkarKey: serializer.fromJson<String>(json['azkarKey']),
      count: serializer.fromJson<int>(json['count']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dateDay': serializer.toJson<String>(dateDay),
      'azkarKey': serializer.toJson<String>(azkarKey),
      'count': serializer.toJson<int>(count),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  TasbihLogData copyWith({
    int? id,
    String? dateDay,
    String? azkarKey,
    int? count,
    DateTime? completedAt,
  }) => TasbihLogData(
    id: id ?? this.id,
    dateDay: dateDay ?? this.dateDay,
    azkarKey: azkarKey ?? this.azkarKey,
    count: count ?? this.count,
    completedAt: completedAt ?? this.completedAt,
  );
  TasbihLogData copyWithCompanion(TasbihLogCompanion data) {
    return TasbihLogData(
      id: data.id.present ? data.id.value : this.id,
      dateDay: data.dateDay.present ? data.dateDay.value : this.dateDay,
      azkarKey: data.azkarKey.present ? data.azkarKey.value : this.azkarKey,
      count: data.count.present ? data.count.value : this.count,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasbihLogData(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('azkarKey: $azkarKey, ')
          ..write('count: $count, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dateDay, azkarKey, count, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasbihLogData &&
          other.id == this.id &&
          other.dateDay == this.dateDay &&
          other.azkarKey == this.azkarKey &&
          other.count == this.count &&
          other.completedAt == this.completedAt);
}

class TasbihLogCompanion extends UpdateCompanion<TasbihLogData> {
  final Value<int> id;
  final Value<String> dateDay;
  final Value<String> azkarKey;
  final Value<int> count;
  final Value<DateTime> completedAt;
  const TasbihLogCompanion({
    this.id = const Value.absent(),
    this.dateDay = const Value.absent(),
    this.azkarKey = const Value.absent(),
    this.count = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TasbihLogCompanion.insert({
    this.id = const Value.absent(),
    required String dateDay,
    required String azkarKey,
    this.count = const Value.absent(),
    required DateTime completedAt,
  }) : dateDay = Value(dateDay),
       azkarKey = Value(azkarKey),
       completedAt = Value(completedAt);
  static Insertable<TasbihLogData> custom({
    Expression<int>? id,
    Expression<String>? dateDay,
    Expression<String>? azkarKey,
    Expression<int>? count,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateDay != null) 'date_day': dateDay,
      if (azkarKey != null) 'azkar_key': azkarKey,
      if (count != null) 'count': count,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TasbihLogCompanion copyWith({
    Value<int>? id,
    Value<String>? dateDay,
    Value<String>? azkarKey,
    Value<int>? count,
    Value<DateTime>? completedAt,
  }) {
    return TasbihLogCompanion(
      id: id ?? this.id,
      dateDay: dateDay ?? this.dateDay,
      azkarKey: azkarKey ?? this.azkarKey,
      count: count ?? this.count,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dateDay.present) {
      map['date_day'] = Variable<String>(dateDay.value);
    }
    if (azkarKey.present) {
      map['azkar_key'] = Variable<String>(azkarKey.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasbihLogCompanion(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('azkarKey: $azkarKey, ')
          ..write('count: $count, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $AyahColorTagsTable extends AyahColorTags
    with TableInfo<$AyahColorTagsTable, AyahColorTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahColorTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taggedAtMeta = const VerificationMeta(
    'taggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> taggedAt = GeneratedColumn<DateTime>(
    'tagged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [type, ayahId, taggedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah_color_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<AyahColorTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('tagged_at')) {
      context.handle(
        _taggedAtMeta,
        taggedAt.isAcceptableOrUnknown(data['tagged_at']!, _taggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_taggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {type, ayahId};
  @override
  AyahColorTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahColorTag(
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      taggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tagged_at'],
      )!,
    );
  }

  @override
  $AyahColorTagsTable createAlias(String alias) {
    return $AyahColorTagsTable(attachedDatabase, alias);
  }
}

class AyahColorTag extends DataClass implements Insertable<AyahColorTag> {
  final String type;
  final int ayahId;
  final DateTime taggedAt;
  const AyahColorTag({
    required this.type,
    required this.ayahId,
    required this.taggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type'] = Variable<String>(type);
    map['ayah_id'] = Variable<int>(ayahId);
    map['tagged_at'] = Variable<DateTime>(taggedAt);
    return map;
  }

  AyahColorTagsCompanion toCompanion(bool nullToAbsent) {
    return AyahColorTagsCompanion(
      type: Value(type),
      ayahId: Value(ayahId),
      taggedAt: Value(taggedAt),
    );
  }

  factory AyahColorTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahColorTag(
      type: serializer.fromJson<String>(json['type']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      taggedAt: serializer.fromJson<DateTime>(json['taggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'type': serializer.toJson<String>(type),
      'ayahId': serializer.toJson<int>(ayahId),
      'taggedAt': serializer.toJson<DateTime>(taggedAt),
    };
  }

  AyahColorTag copyWith({String? type, int? ayahId, DateTime? taggedAt}) =>
      AyahColorTag(
        type: type ?? this.type,
        ayahId: ayahId ?? this.ayahId,
        taggedAt: taggedAt ?? this.taggedAt,
      );
  AyahColorTag copyWithCompanion(AyahColorTagsCompanion data) {
    return AyahColorTag(
      type: data.type.present ? data.type.value : this.type,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      taggedAt: data.taggedAt.present ? data.taggedAt.value : this.taggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahColorTag(')
          ..write('type: $type, ')
          ..write('ayahId: $ayahId, ')
          ..write('taggedAt: $taggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(type, ayahId, taggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahColorTag &&
          other.type == this.type &&
          other.ayahId == this.ayahId &&
          other.taggedAt == this.taggedAt);
}

class AyahColorTagsCompanion extends UpdateCompanion<AyahColorTag> {
  final Value<String> type;
  final Value<int> ayahId;
  final Value<DateTime> taggedAt;
  final Value<int> rowid;
  const AyahColorTagsCompanion({
    this.type = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.taggedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AyahColorTagsCompanion.insert({
    required String type,
    required int ayahId,
    required DateTime taggedAt,
    this.rowid = const Value.absent(),
  }) : type = Value(type),
       ayahId = Value(ayahId),
       taggedAt = Value(taggedAt);
  static Insertable<AyahColorTag> custom({
    Expression<String>? type,
    Expression<int>? ayahId,
    Expression<DateTime>? taggedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (type != null) 'type': type,
      if (ayahId != null) 'ayah_id': ayahId,
      if (taggedAt != null) 'tagged_at': taggedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AyahColorTagsCompanion copyWith({
    Value<String>? type,
    Value<int>? ayahId,
    Value<DateTime>? taggedAt,
    Value<int>? rowid,
  }) {
    return AyahColorTagsCompanion(
      type: type ?? this.type,
      ayahId: ayahId ?? this.ayahId,
      taggedAt: taggedAt ?? this.taggedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (taggedAt.present) {
      map['tagged_at'] = Variable<DateTime>(taggedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahColorTagsCompanion(')
          ..write('type: $type, ')
          ..write('ayahId: $ayahId, ')
          ..write('taggedAt: $taggedAt, ')
          ..write('rowid: $rowid')
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
  late final $HifzPlansTable hifzPlans = $HifzPlansTable(this);
  late final $HifzSettingsTable hifzSettings = $HifzSettingsTable(this);
  late final $ActivityRemindersTable activityReminders =
      $ActivityRemindersTable(this);
  late final $AdhanSettingsTable adhanSettings = $AdhanSettingsTable(this);
  late final $ActivityBookmarksTable activityBookmarks =
      $ActivityBookmarksTable(this);
  late final $CategoryDailyLogTable categoryDailyLog = $CategoryDailyLogTable(
    this,
  );
  late final $AdhanNotificationSettingsTable adhanNotificationSettings =
      $AdhanNotificationSettingsTable(this);
  late final $MushafColorSettingsTable mushafColorSettings =
      $MushafColorSettingsTable(this);
  late final $PrayerCheckinSettingsTable prayerCheckinSettings =
      $PrayerCheckinSettingsTable(this);
  late final $QiyamAyahLogTable qiyamAyahLog = $QiyamAyahLogTable(this);
  late final $AyahNotesTable ayahNotes = $AyahNotesTable(this);
  late final $AppThemeSettingsTable appThemeSettings = $AppThemeSettingsTable(
    this,
  );
  late final $CustomHabitsTable customHabits = $CustomHabitsTable(this);
  late final $CustomHabitLogsTable customHabitLogs = $CustomHabitLogsTable(
    this,
  );
  late final $HifzAyahReviewsTable hifzAyahReviews = $HifzAyahReviewsTable(
    this,
  );
  late final $ToolUsageStatsTable toolUsageStats = $ToolUsageStatsTable(this);
  late final $ReadingLogTable readingLog = $ReadingLogTable(this);
  late final $AudioLogTable audioLog = $AudioLogTable(this);
  late final $TasbihLogTable tasbihLog = $TasbihLogTable(this);
  late final $AyahColorTagsTable ayahColorTags = $AyahColorTagsTable(this);
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
    hifzPlans,
    hifzSettings,
    activityReminders,
    adhanSettings,
    activityBookmarks,
    categoryDailyLog,
    adhanNotificationSettings,
    mushafColorSettings,
    prayerCheckinSettings,
    qiyamAyahLog,
    ayahNotes,
    appThemeSettings,
    customHabits,
    customHabitLogs,
    hifzAyahReviews,
    toolUsageStats,
    readingLog,
    audioLog,
    tasbihLog,
    ayahColorTags,
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
      Value<int> startPage,
      Value<int> currentPage,
    });
typedef $$KhatmaPlansTableUpdateCompanionBuilder =
    KhatmaPlansCompanion Function({
      Value<int> id,
      Value<DateTime> startDate,
      Value<int> targetDays,
      Value<bool> active,
      Value<int> startPage,
      Value<int> currentPage,
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

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
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

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
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

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => column,
  );
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
                Value<int> startPage = const Value.absent(),
                Value<int> currentPage = const Value.absent(),
              }) => KhatmaPlansCompanion(
                id: id,
                startDate: startDate,
                targetDays: targetDays,
                active: active,
                startPage: startPage,
                currentPage: currentPage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startDate,
                required int targetDays,
                Value<bool> active = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int> currentPage = const Value.absent(),
              }) => KhatmaPlansCompanion.insert(
                id: id,
                startDate: startDate,
                targetDays: targetDays,
                active: active,
                startPage: startPage,
                currentPage: currentPage,
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
      Value<bool> liveListenEnabled,
    });
typedef $$AudioSettingsTableUpdateCompanionBuilder =
    AudioSettingsCompanion Function({
      Value<int> id,
      Value<String> reciterId,
      Value<double> speed,
      Value<bool> liveListenEnabled,
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

  ColumnFilters<bool> get liveListenEnabled => $composableBuilder(
    column: $table.liveListenEnabled,
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

  ColumnOrderings<bool> get liveListenEnabled => $composableBuilder(
    column: $table.liveListenEnabled,
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

  GeneratedColumn<bool> get liveListenEnabled => $composableBuilder(
    column: $table.liveListenEnabled,
    builder: (column) => column,
  );
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
                Value<bool> liveListenEnabled = const Value.absent(),
              }) => AudioSettingsCompanion(
                id: id,
                reciterId: reciterId,
                speed: speed,
                liveListenEnabled: liveListenEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reciterId = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<bool> liveListenEnabled = const Value.absent(),
              }) => AudioSettingsCompanion.insert(
                id: id,
                reciterId: reciterId,
                speed: speed,
                liveListenEnabled: liveListenEnabled,
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
typedef $$HifzPlansTableCreateCompanionBuilder =
    HifzPlansCompanion Function({
      Value<int> id,
      required int fromAyahId,
      required int toAyahId,
      required int currentAyahId,
      required DateTime createdAt,
      Value<bool> active,
    });
typedef $$HifzPlansTableUpdateCompanionBuilder =
    HifzPlansCompanion Function({
      Value<int> id,
      Value<int> fromAyahId,
      Value<int> toAyahId,
      Value<int> currentAyahId,
      Value<DateTime> createdAt,
      Value<bool> active,
    });

class $$HifzPlansTableFilterComposer
    extends Composer<_$UserDatabase, $HifzPlansTable> {
  $$HifzPlansTableFilterComposer({
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

  ColumnFilters<int> get fromAyahId => $composableBuilder(
    column: $table.fromAyahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAyahId => $composableBuilder(
    column: $table.toAyahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentAyahId => $composableBuilder(
    column: $table.currentAyahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HifzPlansTableOrderingComposer
    extends Composer<_$UserDatabase, $HifzPlansTable> {
  $$HifzPlansTableOrderingComposer({
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

  ColumnOrderings<int> get fromAyahId => $composableBuilder(
    column: $table.fromAyahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAyahId => $composableBuilder(
    column: $table.toAyahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentAyahId => $composableBuilder(
    column: $table.currentAyahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HifzPlansTableAnnotationComposer
    extends Composer<_$UserDatabase, $HifzPlansTable> {
  $$HifzPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fromAyahId => $composableBuilder(
    column: $table.fromAyahId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toAyahId =>
      $composableBuilder(column: $table.toAyahId, builder: (column) => column);

  GeneratedColumn<int> get currentAyahId => $composableBuilder(
    column: $table.currentAyahId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$HifzPlansTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $HifzPlansTable,
          HifzPlan,
          $$HifzPlansTableFilterComposer,
          $$HifzPlansTableOrderingComposer,
          $$HifzPlansTableAnnotationComposer,
          $$HifzPlansTableCreateCompanionBuilder,
          $$HifzPlansTableUpdateCompanionBuilder,
          (HifzPlan, BaseReferences<_$UserDatabase, $HifzPlansTable, HifzPlan>),
          HifzPlan,
          PrefetchHooks Function()
        > {
  $$HifzPlansTableTableManager(_$UserDatabase db, $HifzPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HifzPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HifzPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HifzPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fromAyahId = const Value.absent(),
                Value<int> toAyahId = const Value.absent(),
                Value<int> currentAyahId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => HifzPlansCompanion(
                id: id,
                fromAyahId: fromAyahId,
                toAyahId: toAyahId,
                currentAyahId: currentAyahId,
                createdAt: createdAt,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fromAyahId,
                required int toAyahId,
                required int currentAyahId,
                required DateTime createdAt,
                Value<bool> active = const Value.absent(),
              }) => HifzPlansCompanion.insert(
                id: id,
                fromAyahId: fromAyahId,
                toAyahId: toAyahId,
                currentAyahId: currentAyahId,
                createdAt: createdAt,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HifzPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $HifzPlansTable,
      HifzPlan,
      $$HifzPlansTableFilterComposer,
      $$HifzPlansTableOrderingComposer,
      $$HifzPlansTableAnnotationComposer,
      $$HifzPlansTableCreateCompanionBuilder,
      $$HifzPlansTableUpdateCompanionBuilder,
      (HifzPlan, BaseReferences<_$UserDatabase, $HifzPlansTable, HifzPlan>),
      HifzPlan,
      PrefetchHooks Function()
    >;
typedef $$HifzSettingsTableCreateCompanionBuilder =
    HifzSettingsCompanion Function({
      Value<int> id,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> enabled,
    });
typedef $$HifzSettingsTableUpdateCompanionBuilder =
    HifzSettingsCompanion Function({
      Value<int> id,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> enabled,
    });

class $$HifzSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $HifzSettingsTable> {
  $$HifzSettingsTableFilterComposer({
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

class $$HifzSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $HifzSettingsTable> {
  $$HifzSettingsTableOrderingComposer({
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

class $$HifzSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $HifzSettingsTable> {
  $$HifzSettingsTableAnnotationComposer({
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

class $$HifzSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $HifzSettingsTable,
          HifzSetting,
          $$HifzSettingsTableFilterComposer,
          $$HifzSettingsTableOrderingComposer,
          $$HifzSettingsTableAnnotationComposer,
          $$HifzSettingsTableCreateCompanionBuilder,
          $$HifzSettingsTableUpdateCompanionBuilder,
          (
            HifzSetting,
            BaseReferences<_$UserDatabase, $HifzSettingsTable, HifzSetting>,
          ),
          HifzSetting,
          PrefetchHooks Function()
        > {
  $$HifzSettingsTableTableManager(_$UserDatabase db, $HifzSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HifzSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HifzSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HifzSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => HifzSettingsCompanion(
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
              }) => HifzSettingsCompanion.insert(
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

typedef $$HifzSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $HifzSettingsTable,
      HifzSetting,
      $$HifzSettingsTableFilterComposer,
      $$HifzSettingsTableOrderingComposer,
      $$HifzSettingsTableAnnotationComposer,
      $$HifzSettingsTableCreateCompanionBuilder,
      $$HifzSettingsTableUpdateCompanionBuilder,
      (
        HifzSetting,
        BaseReferences<_$UserDatabase, $HifzSettingsTable, HifzSetting>,
      ),
      HifzSetting,
      PrefetchHooks Function()
    >;
typedef $$ActivityRemindersTableCreateCompanionBuilder =
    ActivityRemindersCompanion Function({
      required String category,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$ActivityRemindersTableUpdateCompanionBuilder =
    ActivityRemindersCompanion Function({
      Value<String> category,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$ActivityRemindersTableFilterComposer
    extends Composer<_$UserDatabase, $ActivityRemindersTable> {
  $$ActivityRemindersTableFilterComposer({
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

class $$ActivityRemindersTableOrderingComposer
    extends Composer<_$UserDatabase, $ActivityRemindersTable> {
  $$ActivityRemindersTableOrderingComposer({
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

class $$ActivityRemindersTableAnnotationComposer
    extends Composer<_$UserDatabase, $ActivityRemindersTable> {
  $$ActivityRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

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

class $$ActivityRemindersTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ActivityRemindersTable,
          ActivityReminder,
          $$ActivityRemindersTableFilterComposer,
          $$ActivityRemindersTableOrderingComposer,
          $$ActivityRemindersTableAnnotationComposer,
          $$ActivityRemindersTableCreateCompanionBuilder,
          $$ActivityRemindersTableUpdateCompanionBuilder,
          (
            ActivityReminder,
            BaseReferences<
              _$UserDatabase,
              $ActivityRemindersTable,
              ActivityReminder
            >,
          ),
          ActivityReminder,
          PrefetchHooks Function()
        > {
  $$ActivityRemindersTableTableManager(
    _$UserDatabase db,
    $ActivityRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityRemindersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> category = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityRemindersCompanion(
                category: category,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String category,
                Value<int?> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityRemindersCompanion.insert(
                category: category,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ActivityRemindersTable,
      ActivityReminder,
      $$ActivityRemindersTableFilterComposer,
      $$ActivityRemindersTableOrderingComposer,
      $$ActivityRemindersTableAnnotationComposer,
      $$ActivityRemindersTableCreateCompanionBuilder,
      $$ActivityRemindersTableUpdateCompanionBuilder,
      (
        ActivityReminder,
        BaseReferences<
          _$UserDatabase,
          $ActivityRemindersTable,
          ActivityReminder
        >,
      ),
      ActivityReminder,
      PrefetchHooks Function()
    >;
typedef $$AdhanSettingsTableCreateCompanionBuilder =
    AdhanSettingsCompanion Function({Value<int> id, Value<String> voiceId});
typedef $$AdhanSettingsTableUpdateCompanionBuilder =
    AdhanSettingsCompanion Function({Value<int> id, Value<String> voiceId});

class $$AdhanSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $AdhanSettingsTable> {
  $$AdhanSettingsTableFilterComposer({
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

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhanSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $AdhanSettingsTable> {
  $$AdhanSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhanSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $AdhanSettingsTable> {
  $$AdhanSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);
}

class $$AdhanSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AdhanSettingsTable,
          AdhanSetting,
          $$AdhanSettingsTableFilterComposer,
          $$AdhanSettingsTableOrderingComposer,
          $$AdhanSettingsTableAnnotationComposer,
          $$AdhanSettingsTableCreateCompanionBuilder,
          $$AdhanSettingsTableUpdateCompanionBuilder,
          (
            AdhanSetting,
            BaseReferences<_$UserDatabase, $AdhanSettingsTable, AdhanSetting>,
          ),
          AdhanSetting,
          PrefetchHooks Function()
        > {
  $$AdhanSettingsTableTableManager(_$UserDatabase db, $AdhanSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhanSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhanSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdhanSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> voiceId = const Value.absent(),
              }) => AdhanSettingsCompanion(id: id, voiceId: voiceId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> voiceId = const Value.absent(),
              }) => AdhanSettingsCompanion.insert(id: id, voiceId: voiceId),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhanSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AdhanSettingsTable,
      AdhanSetting,
      $$AdhanSettingsTableFilterComposer,
      $$AdhanSettingsTableOrderingComposer,
      $$AdhanSettingsTableAnnotationComposer,
      $$AdhanSettingsTableCreateCompanionBuilder,
      $$AdhanSettingsTableUpdateCompanionBuilder,
      (
        AdhanSetting,
        BaseReferences<_$UserDatabase, $AdhanSettingsTable, AdhanSetting>,
      ),
      AdhanSetting,
      PrefetchHooks Function()
    >;
typedef $$ActivityBookmarksTableCreateCompanionBuilder =
    ActivityBookmarksCompanion Function({
      required String type,
      required int ayahId,
      required DateTime setAt,
      Value<int> rowid,
    });
typedef $$ActivityBookmarksTableUpdateCompanionBuilder =
    ActivityBookmarksCompanion Function({
      Value<String> type,
      Value<int> ayahId,
      Value<DateTime> setAt,
      Value<int> rowid,
    });

class $$ActivityBookmarksTableFilterComposer
    extends Composer<_$UserDatabase, $ActivityBookmarksTable> {
  $$ActivityBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get setAt => $composableBuilder(
    column: $table.setAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityBookmarksTableOrderingComposer
    extends Composer<_$UserDatabase, $ActivityBookmarksTable> {
  $$ActivityBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get setAt => $composableBuilder(
    column: $table.setAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityBookmarksTableAnnotationComposer
    extends Composer<_$UserDatabase, $ActivityBookmarksTable> {
  $$ActivityBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<DateTime> get setAt =>
      $composableBuilder(column: $table.setAt, builder: (column) => column);
}

class $$ActivityBookmarksTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ActivityBookmarksTable,
          ActivityBookmark,
          $$ActivityBookmarksTableFilterComposer,
          $$ActivityBookmarksTableOrderingComposer,
          $$ActivityBookmarksTableAnnotationComposer,
          $$ActivityBookmarksTableCreateCompanionBuilder,
          $$ActivityBookmarksTableUpdateCompanionBuilder,
          (
            ActivityBookmark,
            BaseReferences<
              _$UserDatabase,
              $ActivityBookmarksTable,
              ActivityBookmark
            >,
          ),
          ActivityBookmark,
          PrefetchHooks Function()
        > {
  $$ActivityBookmarksTableTableManager(
    _$UserDatabase db,
    $ActivityBookmarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityBookmarksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> type = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<DateTime> setAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityBookmarksCompanion(
                type: type,
                ayahId: ayahId,
                setAt: setAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String type,
                required int ayahId,
                required DateTime setAt,
                Value<int> rowid = const Value.absent(),
              }) => ActivityBookmarksCompanion.insert(
                type: type,
                ayahId: ayahId,
                setAt: setAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ActivityBookmarksTable,
      ActivityBookmark,
      $$ActivityBookmarksTableFilterComposer,
      $$ActivityBookmarksTableOrderingComposer,
      $$ActivityBookmarksTableAnnotationComposer,
      $$ActivityBookmarksTableCreateCompanionBuilder,
      $$ActivityBookmarksTableUpdateCompanionBuilder,
      (
        ActivityBookmark,
        BaseReferences<
          _$UserDatabase,
          $ActivityBookmarksTable,
          ActivityBookmark
        >,
      ),
      ActivityBookmark,
      PrefetchHooks Function()
    >;
typedef $$CategoryDailyLogTableCreateCompanionBuilder =
    CategoryDailyLogCompanion Function({
      required String category,
      required String dateKey,
      Value<int> rowid,
    });
typedef $$CategoryDailyLogTableUpdateCompanionBuilder =
    CategoryDailyLogCompanion Function({
      Value<String> category,
      Value<String> dateKey,
      Value<int> rowid,
    });

class $$CategoryDailyLogTableFilterComposer
    extends Composer<_$UserDatabase, $CategoryDailyLogTable> {
  $$CategoryDailyLogTableFilterComposer({
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

  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryDailyLogTableOrderingComposer
    extends Composer<_$UserDatabase, $CategoryDailyLogTable> {
  $$CategoryDailyLogTableOrderingComposer({
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

  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryDailyLogTableAnnotationComposer
    extends Composer<_$UserDatabase, $CategoryDailyLogTable> {
  $$CategoryDailyLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);
}

class $$CategoryDailyLogTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $CategoryDailyLogTable,
          CategoryDailyLogData,
          $$CategoryDailyLogTableFilterComposer,
          $$CategoryDailyLogTableOrderingComposer,
          $$CategoryDailyLogTableAnnotationComposer,
          $$CategoryDailyLogTableCreateCompanionBuilder,
          $$CategoryDailyLogTableUpdateCompanionBuilder,
          (
            CategoryDailyLogData,
            BaseReferences<
              _$UserDatabase,
              $CategoryDailyLogTable,
              CategoryDailyLogData
            >,
          ),
          CategoryDailyLogData,
          PrefetchHooks Function()
        > {
  $$CategoryDailyLogTableTableManager(
    _$UserDatabase db,
    $CategoryDailyLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryDailyLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryDailyLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryDailyLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> category = const Value.absent(),
                Value<String> dateKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryDailyLogCompanion(
                category: category,
                dateKey: dateKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String category,
                required String dateKey,
                Value<int> rowid = const Value.absent(),
              }) => CategoryDailyLogCompanion.insert(
                category: category,
                dateKey: dateKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryDailyLogTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $CategoryDailyLogTable,
      CategoryDailyLogData,
      $$CategoryDailyLogTableFilterComposer,
      $$CategoryDailyLogTableOrderingComposer,
      $$CategoryDailyLogTableAnnotationComposer,
      $$CategoryDailyLogTableCreateCompanionBuilder,
      $$CategoryDailyLogTableUpdateCompanionBuilder,
      (
        CategoryDailyLogData,
        BaseReferences<
          _$UserDatabase,
          $CategoryDailyLogTable,
          CategoryDailyLogData
        >,
      ),
      CategoryDailyLogData,
      PrefetchHooks Function()
    >;
typedef $$AdhanNotificationSettingsTableCreateCompanionBuilder =
    AdhanNotificationSettingsCompanion Function({
      required String prayer,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$AdhanNotificationSettingsTableUpdateCompanionBuilder =
    AdhanNotificationSettingsCompanion Function({
      Value<String> prayer,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$AdhanNotificationSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $AdhanNotificationSettingsTable> {
  $$AdhanNotificationSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhanNotificationSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $AdhanNotificationSettingsTable> {
  $$AdhanNotificationSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhanNotificationSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $AdhanNotificationSettingsTable> {
  $$AdhanNotificationSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$AdhanNotificationSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AdhanNotificationSettingsTable,
          AdhanNotificationSetting,
          $$AdhanNotificationSettingsTableFilterComposer,
          $$AdhanNotificationSettingsTableOrderingComposer,
          $$AdhanNotificationSettingsTableAnnotationComposer,
          $$AdhanNotificationSettingsTableCreateCompanionBuilder,
          $$AdhanNotificationSettingsTableUpdateCompanionBuilder,
          (
            AdhanNotificationSetting,
            BaseReferences<
              _$UserDatabase,
              $AdhanNotificationSettingsTable,
              AdhanNotificationSetting
            >,
          ),
          AdhanNotificationSetting,
          PrefetchHooks Function()
        > {
  $$AdhanNotificationSettingsTableTableManager(
    _$UserDatabase db,
    $AdhanNotificationSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhanNotificationSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AdhanNotificationSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdhanNotificationSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> prayer = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhanNotificationSettingsCompanion(
                prayer: prayer,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String prayer,
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhanNotificationSettingsCompanion.insert(
                prayer: prayer,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhanNotificationSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AdhanNotificationSettingsTable,
      AdhanNotificationSetting,
      $$AdhanNotificationSettingsTableFilterComposer,
      $$AdhanNotificationSettingsTableOrderingComposer,
      $$AdhanNotificationSettingsTableAnnotationComposer,
      $$AdhanNotificationSettingsTableCreateCompanionBuilder,
      $$AdhanNotificationSettingsTableUpdateCompanionBuilder,
      (
        AdhanNotificationSetting,
        BaseReferences<
          _$UserDatabase,
          $AdhanNotificationSettingsTable,
          AdhanNotificationSetting
        >,
      ),
      AdhanNotificationSetting,
      PrefetchHooks Function()
    >;
typedef $$MushafColorSettingsTableCreateCompanionBuilder =
    MushafColorSettingsCompanion Function({
      Value<int> id,
      Value<String> paletteId,
      Value<String> nightMode,
    });
typedef $$MushafColorSettingsTableUpdateCompanionBuilder =
    MushafColorSettingsCompanion Function({
      Value<int> id,
      Value<String> paletteId,
      Value<String> nightMode,
    });

class $$MushafColorSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $MushafColorSettingsTable> {
  $$MushafColorSettingsTableFilterComposer({
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

  ColumnFilters<String> get paletteId => $composableBuilder(
    column: $table.paletteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nightMode => $composableBuilder(
    column: $table.nightMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MushafColorSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $MushafColorSettingsTable> {
  $$MushafColorSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get paletteId => $composableBuilder(
    column: $table.paletteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nightMode => $composableBuilder(
    column: $table.nightMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MushafColorSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $MushafColorSettingsTable> {
  $$MushafColorSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get paletteId =>
      $composableBuilder(column: $table.paletteId, builder: (column) => column);

  GeneratedColumn<String> get nightMode =>
      $composableBuilder(column: $table.nightMode, builder: (column) => column);
}

class $$MushafColorSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $MushafColorSettingsTable,
          MushafColorSetting,
          $$MushafColorSettingsTableFilterComposer,
          $$MushafColorSettingsTableOrderingComposer,
          $$MushafColorSettingsTableAnnotationComposer,
          $$MushafColorSettingsTableCreateCompanionBuilder,
          $$MushafColorSettingsTableUpdateCompanionBuilder,
          (
            MushafColorSetting,
            BaseReferences<
              _$UserDatabase,
              $MushafColorSettingsTable,
              MushafColorSetting
            >,
          ),
          MushafColorSetting,
          PrefetchHooks Function()
        > {
  $$MushafColorSettingsTableTableManager(
    _$UserDatabase db,
    $MushafColorSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MushafColorSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MushafColorSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MushafColorSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> paletteId = const Value.absent(),
                Value<String> nightMode = const Value.absent(),
              }) => MushafColorSettingsCompanion(
                id: id,
                paletteId: paletteId,
                nightMode: nightMode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> paletteId = const Value.absent(),
                Value<String> nightMode = const Value.absent(),
              }) => MushafColorSettingsCompanion.insert(
                id: id,
                paletteId: paletteId,
                nightMode: nightMode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MushafColorSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $MushafColorSettingsTable,
      MushafColorSetting,
      $$MushafColorSettingsTableFilterComposer,
      $$MushafColorSettingsTableOrderingComposer,
      $$MushafColorSettingsTableAnnotationComposer,
      $$MushafColorSettingsTableCreateCompanionBuilder,
      $$MushafColorSettingsTableUpdateCompanionBuilder,
      (
        MushafColorSetting,
        BaseReferences<
          _$UserDatabase,
          $MushafColorSettingsTable,
          MushafColorSetting
        >,
      ),
      MushafColorSetting,
      PrefetchHooks Function()
    >;
typedef $$PrayerCheckinSettingsTableCreateCompanionBuilder =
    PrayerCheckinSettingsCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<int> firstDelayMinutes,
    });
typedef $$PrayerCheckinSettingsTableUpdateCompanionBuilder =
    PrayerCheckinSettingsCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<int> firstDelayMinutes,
    });

class $$PrayerCheckinSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $PrayerCheckinSettingsTable> {
  $$PrayerCheckinSettingsTableFilterComposer({
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

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstDelayMinutes => $composableBuilder(
    column: $table.firstDelayMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayerCheckinSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $PrayerCheckinSettingsTable> {
  $$PrayerCheckinSettingsTableOrderingComposer({
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

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstDelayMinutes => $composableBuilder(
    column: $table.firstDelayMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayerCheckinSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $PrayerCheckinSettingsTable> {
  $$PrayerCheckinSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get firstDelayMinutes => $composableBuilder(
    column: $table.firstDelayMinutes,
    builder: (column) => column,
  );
}

class $$PrayerCheckinSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $PrayerCheckinSettingsTable,
          PrayerCheckinSetting,
          $$PrayerCheckinSettingsTableFilterComposer,
          $$PrayerCheckinSettingsTableOrderingComposer,
          $$PrayerCheckinSettingsTableAnnotationComposer,
          $$PrayerCheckinSettingsTableCreateCompanionBuilder,
          $$PrayerCheckinSettingsTableUpdateCompanionBuilder,
          (
            PrayerCheckinSetting,
            BaseReferences<
              _$UserDatabase,
              $PrayerCheckinSettingsTable,
              PrayerCheckinSetting
            >,
          ),
          PrayerCheckinSetting,
          PrefetchHooks Function()
        > {
  $$PrayerCheckinSettingsTableTableManager(
    _$UserDatabase db,
    $PrayerCheckinSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerCheckinSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PrayerCheckinSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PrayerCheckinSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> firstDelayMinutes = const Value.absent(),
              }) => PrayerCheckinSettingsCompanion(
                id: id,
                enabled: enabled,
                firstDelayMinutes: firstDelayMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> firstDelayMinutes = const Value.absent(),
              }) => PrayerCheckinSettingsCompanion.insert(
                id: id,
                enabled: enabled,
                firstDelayMinutes: firstDelayMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerCheckinSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $PrayerCheckinSettingsTable,
      PrayerCheckinSetting,
      $$PrayerCheckinSettingsTableFilterComposer,
      $$PrayerCheckinSettingsTableOrderingComposer,
      $$PrayerCheckinSettingsTableAnnotationComposer,
      $$PrayerCheckinSettingsTableCreateCompanionBuilder,
      $$PrayerCheckinSettingsTableUpdateCompanionBuilder,
      (
        PrayerCheckinSetting,
        BaseReferences<
          _$UserDatabase,
          $PrayerCheckinSettingsTable,
          PrayerCheckinSetting
        >,
      ),
      PrayerCheckinSetting,
      PrefetchHooks Function()
    >;
typedef $$QiyamAyahLogTableCreateCompanionBuilder =
    QiyamAyahLogCompanion Function({
      required String dateKey,
      Value<int> ayahCount,
      Value<int> rowid,
    });
typedef $$QiyamAyahLogTableUpdateCompanionBuilder =
    QiyamAyahLogCompanion Function({
      Value<String> dateKey,
      Value<int> ayahCount,
      Value<int> rowid,
    });

class $$QiyamAyahLogTableFilterComposer
    extends Composer<_$UserDatabase, $QiyamAyahLogTable> {
  $$QiyamAyahLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QiyamAyahLogTableOrderingComposer
    extends Composer<_$UserDatabase, $QiyamAyahLogTable> {
  $$QiyamAyahLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QiyamAyahLogTableAnnotationComposer
    extends Composer<_$UserDatabase, $QiyamAyahLogTable> {
  $$QiyamAyahLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);
}

class $$QiyamAyahLogTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $QiyamAyahLogTable,
          QiyamAyahLogData,
          $$QiyamAyahLogTableFilterComposer,
          $$QiyamAyahLogTableOrderingComposer,
          $$QiyamAyahLogTableAnnotationComposer,
          $$QiyamAyahLogTableCreateCompanionBuilder,
          $$QiyamAyahLogTableUpdateCompanionBuilder,
          (
            QiyamAyahLogData,
            BaseReferences<
              _$UserDatabase,
              $QiyamAyahLogTable,
              QiyamAyahLogData
            >,
          ),
          QiyamAyahLogData,
          PrefetchHooks Function()
        > {
  $$QiyamAyahLogTableTableManager(_$UserDatabase db, $QiyamAyahLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QiyamAyahLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QiyamAyahLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QiyamAyahLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dateKey = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QiyamAyahLogCompanion(
                dateKey: dateKey,
                ayahCount: ayahCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dateKey,
                Value<int> ayahCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QiyamAyahLogCompanion.insert(
                dateKey: dateKey,
                ayahCount: ayahCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QiyamAyahLogTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $QiyamAyahLogTable,
      QiyamAyahLogData,
      $$QiyamAyahLogTableFilterComposer,
      $$QiyamAyahLogTableOrderingComposer,
      $$QiyamAyahLogTableAnnotationComposer,
      $$QiyamAyahLogTableCreateCompanionBuilder,
      $$QiyamAyahLogTableUpdateCompanionBuilder,
      (
        QiyamAyahLogData,
        BaseReferences<_$UserDatabase, $QiyamAyahLogTable, QiyamAyahLogData>,
      ),
      QiyamAyahLogData,
      PrefetchHooks Function()
    >;
typedef $$AyahNotesTableCreateCompanionBuilder =
    AyahNotesCompanion Function({
      Value<int> ayahId,
      required String noteText,
      required DateTime updatedAt,
    });
typedef $$AyahNotesTableUpdateCompanionBuilder =
    AyahNotesCompanion Function({
      Value<int> ayahId,
      Value<String> noteText,
      Value<DateTime> updatedAt,
    });

class $$AyahNotesTableFilterComposer
    extends Composer<_$UserDatabase, $AyahNotesTable> {
  $$AyahNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahNotesTableOrderingComposer
    extends Composer<_$UserDatabase, $AyahNotesTable> {
  $$AyahNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahNotesTableAnnotationComposer
    extends Composer<_$UserDatabase, $AyahNotesTable> {
  $$AyahNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<String> get noteText =>
      $composableBuilder(column: $table.noteText, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AyahNotesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AyahNotesTable,
          AyahNote,
          $$AyahNotesTableFilterComposer,
          $$AyahNotesTableOrderingComposer,
          $$AyahNotesTableAnnotationComposer,
          $$AyahNotesTableCreateCompanionBuilder,
          $$AyahNotesTableUpdateCompanionBuilder,
          (AyahNote, BaseReferences<_$UserDatabase, $AyahNotesTable, AyahNote>),
          AyahNote,
          PrefetchHooks Function()
        > {
  $$AyahNotesTableTableManager(_$UserDatabase db, $AyahNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ayahId = const Value.absent(),
                Value<String> noteText = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AyahNotesCompanion(
                ayahId: ayahId,
                noteText: noteText,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> ayahId = const Value.absent(),
                required String noteText,
                required DateTime updatedAt,
              }) => AyahNotesCompanion.insert(
                ayahId: ayahId,
                noteText: noteText,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyahNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AyahNotesTable,
      AyahNote,
      $$AyahNotesTableFilterComposer,
      $$AyahNotesTableOrderingComposer,
      $$AyahNotesTableAnnotationComposer,
      $$AyahNotesTableCreateCompanionBuilder,
      $$AyahNotesTableUpdateCompanionBuilder,
      (AyahNote, BaseReferences<_$UserDatabase, $AyahNotesTable, AyahNote>),
      AyahNote,
      PrefetchHooks Function()
    >;
typedef $$AppThemeSettingsTableCreateCompanionBuilder =
    AppThemeSettingsCompanion Function({
      Value<int> id,
      Value<String> accentColorId,
    });
typedef $$AppThemeSettingsTableUpdateCompanionBuilder =
    AppThemeSettingsCompanion Function({
      Value<int> id,
      Value<String> accentColorId,
    });

class $$AppThemeSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $AppThemeSettingsTable> {
  $$AppThemeSettingsTableFilterComposer({
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

  ColumnFilters<String> get accentColorId => $composableBuilder(
    column: $table.accentColorId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppThemeSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $AppThemeSettingsTable> {
  $$AppThemeSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get accentColorId => $composableBuilder(
    column: $table.accentColorId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppThemeSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $AppThemeSettingsTable> {
  $$AppThemeSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accentColorId => $composableBuilder(
    column: $table.accentColorId,
    builder: (column) => column,
  );
}

class $$AppThemeSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AppThemeSettingsTable,
          AppThemeSetting,
          $$AppThemeSettingsTableFilterComposer,
          $$AppThemeSettingsTableOrderingComposer,
          $$AppThemeSettingsTableAnnotationComposer,
          $$AppThemeSettingsTableCreateCompanionBuilder,
          $$AppThemeSettingsTableUpdateCompanionBuilder,
          (
            AppThemeSetting,
            BaseReferences<
              _$UserDatabase,
              $AppThemeSettingsTable,
              AppThemeSetting
            >,
          ),
          AppThemeSetting,
          PrefetchHooks Function()
        > {
  $$AppThemeSettingsTableTableManager(
    _$UserDatabase db,
    $AppThemeSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppThemeSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppThemeSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppThemeSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accentColorId = const Value.absent(),
              }) => AppThemeSettingsCompanion(
                id: id,
                accentColorId: accentColorId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accentColorId = const Value.absent(),
              }) => AppThemeSettingsCompanion.insert(
                id: id,
                accentColorId: accentColorId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppThemeSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AppThemeSettingsTable,
      AppThemeSetting,
      $$AppThemeSettingsTableFilterComposer,
      $$AppThemeSettingsTableOrderingComposer,
      $$AppThemeSettingsTableAnnotationComposer,
      $$AppThemeSettingsTableCreateCompanionBuilder,
      $$AppThemeSettingsTableUpdateCompanionBuilder,
      (
        AppThemeSetting,
        BaseReferences<_$UserDatabase, $AppThemeSettingsTable, AppThemeSetting>,
      ),
      AppThemeSetting,
      PrefetchHooks Function()
    >;
typedef $$CustomHabitsTableCreateCompanionBuilder =
    CustomHabitsCompanion Function({
      Value<int> id,
      required String title,
      Value<int> targetDaily,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> remindersEnabled,
      Value<bool> active,
      required DateTime createdAt,
    });
typedef $$CustomHabitsTableUpdateCompanionBuilder =
    CustomHabitsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int> targetDaily,
      Value<int?> reminderHour,
      Value<int> reminderMinute,
      Value<bool> remindersEnabled,
      Value<bool> active,
      Value<DateTime> createdAt,
    });

class $$CustomHabitsTableFilterComposer
    extends Composer<_$UserDatabase, $CustomHabitsTable> {
  $$CustomHabitsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDaily => $composableBuilder(
    column: $table.targetDaily,
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

  ColumnFilters<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomHabitsTableOrderingComposer
    extends Composer<_$UserDatabase, $CustomHabitsTable> {
  $$CustomHabitsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDaily => $composableBuilder(
    column: $table.targetDaily,
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

  ColumnOrderings<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomHabitsTableAnnotationComposer
    extends Composer<_$UserDatabase, $CustomHabitsTable> {
  $$CustomHabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetDaily => $composableBuilder(
    column: $table.targetDaily,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomHabitsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $CustomHabitsTable,
          CustomHabit,
          $$CustomHabitsTableFilterComposer,
          $$CustomHabitsTableOrderingComposer,
          $$CustomHabitsTableAnnotationComposer,
          $$CustomHabitsTableCreateCompanionBuilder,
          $$CustomHabitsTableUpdateCompanionBuilder,
          (
            CustomHabit,
            BaseReferences<_$UserDatabase, $CustomHabitsTable, CustomHabit>,
          ),
          CustomHabit,
          PrefetchHooks Function()
        > {
  $$CustomHabitsTableTableManager(_$UserDatabase db, $CustomHabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomHabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomHabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomHabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> targetDaily = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CustomHabitsCompanion(
                id: id,
                title: title,
                targetDaily: targetDaily,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                remindersEnabled: remindersEnabled,
                active: active,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int> targetDaily = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<bool> active = const Value.absent(),
                required DateTime createdAt,
              }) => CustomHabitsCompanion.insert(
                id: id,
                title: title,
                targetDaily: targetDaily,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                remindersEnabled: remindersEnabled,
                active: active,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomHabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $CustomHabitsTable,
      CustomHabit,
      $$CustomHabitsTableFilterComposer,
      $$CustomHabitsTableOrderingComposer,
      $$CustomHabitsTableAnnotationComposer,
      $$CustomHabitsTableCreateCompanionBuilder,
      $$CustomHabitsTableUpdateCompanionBuilder,
      (
        CustomHabit,
        BaseReferences<_$UserDatabase, $CustomHabitsTable, CustomHabit>,
      ),
      CustomHabit,
      PrefetchHooks Function()
    >;
typedef $$CustomHabitLogsTableCreateCompanionBuilder =
    CustomHabitLogsCompanion Function({
      required int habitId,
      required String dateKey,
      Value<int> count,
      Value<int> rowid,
    });
typedef $$CustomHabitLogsTableUpdateCompanionBuilder =
    CustomHabitLogsCompanion Function({
      Value<int> habitId,
      Value<String> dateKey,
      Value<int> count,
      Value<int> rowid,
    });

class $$CustomHabitLogsTableFilterComposer
    extends Composer<_$UserDatabase, $CustomHabitLogsTable> {
  $$CustomHabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomHabitLogsTableOrderingComposer
    extends Composer<_$UserDatabase, $CustomHabitLogsTable> {
  $$CustomHabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomHabitLogsTableAnnotationComposer
    extends Composer<_$UserDatabase, $CustomHabitLogsTable> {
  $$CustomHabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$CustomHabitLogsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $CustomHabitLogsTable,
          CustomHabitLog,
          $$CustomHabitLogsTableFilterComposer,
          $$CustomHabitLogsTableOrderingComposer,
          $$CustomHabitLogsTableAnnotationComposer,
          $$CustomHabitLogsTableCreateCompanionBuilder,
          $$CustomHabitLogsTableUpdateCompanionBuilder,
          (
            CustomHabitLog,
            BaseReferences<
              _$UserDatabase,
              $CustomHabitLogsTable,
              CustomHabitLog
            >,
          ),
          CustomHabitLog,
          PrefetchHooks Function()
        > {
  $$CustomHabitLogsTableTableManager(
    _$UserDatabase db,
    $CustomHabitLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomHabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomHabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomHabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> habitId = const Value.absent(),
                Value<String> dateKey = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomHabitLogsCompanion(
                habitId: habitId,
                dateKey: dateKey,
                count: count,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int habitId,
                required String dateKey,
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomHabitLogsCompanion.insert(
                habitId: habitId,
                dateKey: dateKey,
                count: count,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomHabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $CustomHabitLogsTable,
      CustomHabitLog,
      $$CustomHabitLogsTableFilterComposer,
      $$CustomHabitLogsTableOrderingComposer,
      $$CustomHabitLogsTableAnnotationComposer,
      $$CustomHabitLogsTableCreateCompanionBuilder,
      $$CustomHabitLogsTableUpdateCompanionBuilder,
      (
        CustomHabitLog,
        BaseReferences<_$UserDatabase, $CustomHabitLogsTable, CustomHabitLog>,
      ),
      CustomHabitLog,
      PrefetchHooks Function()
    >;
typedef $$HifzAyahReviewsTableCreateCompanionBuilder =
    HifzAyahReviewsCompanion Function({
      required int planId,
      required int ayahId,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      required String dueDate,
      Value<DateTime?> lastReviewedAt,
      Value<int> rowid,
    });
typedef $$HifzAyahReviewsTableUpdateCompanionBuilder =
    HifzAyahReviewsCompanion Function({
      Value<int> planId,
      Value<int> ayahId,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<String> dueDate,
      Value<DateTime?> lastReviewedAt,
      Value<int> rowid,
    });

class $$HifzAyahReviewsTableFilterComposer
    extends Composer<_$UserDatabase, $HifzAyahReviewsTable> {
  $$HifzAyahReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HifzAyahReviewsTableOrderingComposer
    extends Composer<_$UserDatabase, $HifzAyahReviewsTable> {
  $$HifzAyahReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HifzAyahReviewsTableAnnotationComposer
    extends Composer<_$UserDatabase, $HifzAyahReviewsTable> {
  $$HifzAyahReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );
}

class $$HifzAyahReviewsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $HifzAyahReviewsTable,
          HifzAyahReview,
          $$HifzAyahReviewsTableFilterComposer,
          $$HifzAyahReviewsTableOrderingComposer,
          $$HifzAyahReviewsTableAnnotationComposer,
          $$HifzAyahReviewsTableCreateCompanionBuilder,
          $$HifzAyahReviewsTableUpdateCompanionBuilder,
          (
            HifzAyahReview,
            BaseReferences<
              _$UserDatabase,
              $HifzAyahReviewsTable,
              HifzAyahReview
            >,
          ),
          HifzAyahReview,
          PrefetchHooks Function()
        > {
  $$HifzAyahReviewsTableTableManager(
    _$UserDatabase db,
    $HifzAyahReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HifzAyahReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HifzAyahReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HifzAyahReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> planId = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HifzAyahReviewsCompanion(
                planId: planId,
                ayahId: ayahId,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueDate: dueDate,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int planId,
                required int ayahId,
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                required String dueDate,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HifzAyahReviewsCompanion.insert(
                planId: planId,
                ayahId: ayahId,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueDate: dueDate,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HifzAyahReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $HifzAyahReviewsTable,
      HifzAyahReview,
      $$HifzAyahReviewsTableFilterComposer,
      $$HifzAyahReviewsTableOrderingComposer,
      $$HifzAyahReviewsTableAnnotationComposer,
      $$HifzAyahReviewsTableCreateCompanionBuilder,
      $$HifzAyahReviewsTableUpdateCompanionBuilder,
      (
        HifzAyahReview,
        BaseReferences<_$UserDatabase, $HifzAyahReviewsTable, HifzAyahReview>,
      ),
      HifzAyahReview,
      PrefetchHooks Function()
    >;
typedef $$ToolUsageStatsTableCreateCompanionBuilder =
    ToolUsageStatsCompanion Function({
      required String toolId,
      Value<int> tapCount,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });
typedef $$ToolUsageStatsTableUpdateCompanionBuilder =
    ToolUsageStatsCompanion Function({
      Value<String> toolId,
      Value<int> tapCount,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });

class $$ToolUsageStatsTableFilterComposer
    extends Composer<_$UserDatabase, $ToolUsageStatsTable> {
  $$ToolUsageStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get toolId => $composableBuilder(
    column: $table.toolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tapCount => $composableBuilder(
    column: $table.tapCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ToolUsageStatsTableOrderingComposer
    extends Composer<_$UserDatabase, $ToolUsageStatsTable> {
  $$ToolUsageStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get toolId => $composableBuilder(
    column: $table.toolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tapCount => $composableBuilder(
    column: $table.tapCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ToolUsageStatsTableAnnotationComposer
    extends Composer<_$UserDatabase, $ToolUsageStatsTable> {
  $$ToolUsageStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get toolId =>
      $composableBuilder(column: $table.toolId, builder: (column) => column);

  GeneratedColumn<int> get tapCount =>
      $composableBuilder(column: $table.tapCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$ToolUsageStatsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ToolUsageStatsTable,
          ToolUsageStat,
          $$ToolUsageStatsTableFilterComposer,
          $$ToolUsageStatsTableOrderingComposer,
          $$ToolUsageStatsTableAnnotationComposer,
          $$ToolUsageStatsTableCreateCompanionBuilder,
          $$ToolUsageStatsTableUpdateCompanionBuilder,
          (
            ToolUsageStat,
            BaseReferences<_$UserDatabase, $ToolUsageStatsTable, ToolUsageStat>,
          ),
          ToolUsageStat,
          PrefetchHooks Function()
        > {
  $$ToolUsageStatsTableTableManager(
    _$UserDatabase db,
    $ToolUsageStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToolUsageStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToolUsageStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToolUsageStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> toolId = const Value.absent(),
                Value<int> tapCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ToolUsageStatsCompanion(
                toolId: toolId,
                tapCount: tapCount,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String toolId,
                Value<int> tapCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ToolUsageStatsCompanion.insert(
                toolId: toolId,
                tapCount: tapCount,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ToolUsageStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ToolUsageStatsTable,
      ToolUsageStat,
      $$ToolUsageStatsTableFilterComposer,
      $$ToolUsageStatsTableOrderingComposer,
      $$ToolUsageStatsTableAnnotationComposer,
      $$ToolUsageStatsTableCreateCompanionBuilder,
      $$ToolUsageStatsTableUpdateCompanionBuilder,
      (
        ToolUsageStat,
        BaseReferences<_$UserDatabase, $ToolUsageStatsTable, ToolUsageStat>,
      ),
      ToolUsageStat,
      PrefetchHooks Function()
    >;
typedef $$ReadingLogTableCreateCompanionBuilder =
    ReadingLogCompanion Function({
      Value<int> id,
      required String dateDay,
      Value<int> pagesRead,
      Value<int> ayahsRead,
      Value<int> minutesSpent,
    });
typedef $$ReadingLogTableUpdateCompanionBuilder =
    ReadingLogCompanion Function({
      Value<int> id,
      Value<String> dateDay,
      Value<int> pagesRead,
      Value<int> ayahsRead,
      Value<int> minutesSpent,
    });

class $$ReadingLogTableFilterComposer
    extends Composer<_$UserDatabase, $ReadingLogTable> {
  $$ReadingLogTableFilterComposer({
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

  ColumnFilters<String> get dateDay => $composableBuilder(
    column: $table.dateDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pagesRead => $composableBuilder(
    column: $table.pagesRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahsRead => $composableBuilder(
    column: $table.ayahsRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesSpent => $composableBuilder(
    column: $table.minutesSpent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingLogTableOrderingComposer
    extends Composer<_$UserDatabase, $ReadingLogTable> {
  $$ReadingLogTableOrderingComposer({
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

  ColumnOrderings<String> get dateDay => $composableBuilder(
    column: $table.dateDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pagesRead => $composableBuilder(
    column: $table.pagesRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahsRead => $composableBuilder(
    column: $table.ayahsRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesSpent => $composableBuilder(
    column: $table.minutesSpent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingLogTableAnnotationComposer
    extends Composer<_$UserDatabase, $ReadingLogTable> {
  $$ReadingLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateDay =>
      $composableBuilder(column: $table.dateDay, builder: (column) => column);

  GeneratedColumn<int> get pagesRead =>
      $composableBuilder(column: $table.pagesRead, builder: (column) => column);

  GeneratedColumn<int> get ayahsRead =>
      $composableBuilder(column: $table.ayahsRead, builder: (column) => column);

  GeneratedColumn<int> get minutesSpent => $composableBuilder(
    column: $table.minutesSpent,
    builder: (column) => column,
  );
}

class $$ReadingLogTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ReadingLogTable,
          ReadingLogData,
          $$ReadingLogTableFilterComposer,
          $$ReadingLogTableOrderingComposer,
          $$ReadingLogTableAnnotationComposer,
          $$ReadingLogTableCreateCompanionBuilder,
          $$ReadingLogTableUpdateCompanionBuilder,
          (
            ReadingLogData,
            BaseReferences<_$UserDatabase, $ReadingLogTable, ReadingLogData>,
          ),
          ReadingLogData,
          PrefetchHooks Function()
        > {
  $$ReadingLogTableTableManager(_$UserDatabase db, $ReadingLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dateDay = const Value.absent(),
                Value<int> pagesRead = const Value.absent(),
                Value<int> ayahsRead = const Value.absent(),
                Value<int> minutesSpent = const Value.absent(),
              }) => ReadingLogCompanion(
                id: id,
                dateDay: dateDay,
                pagesRead: pagesRead,
                ayahsRead: ayahsRead,
                minutesSpent: minutesSpent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dateDay,
                Value<int> pagesRead = const Value.absent(),
                Value<int> ayahsRead = const Value.absent(),
                Value<int> minutesSpent = const Value.absent(),
              }) => ReadingLogCompanion.insert(
                id: id,
                dateDay: dateDay,
                pagesRead: pagesRead,
                ayahsRead: ayahsRead,
                minutesSpent: minutesSpent,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingLogTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ReadingLogTable,
      ReadingLogData,
      $$ReadingLogTableFilterComposer,
      $$ReadingLogTableOrderingComposer,
      $$ReadingLogTableAnnotationComposer,
      $$ReadingLogTableCreateCompanionBuilder,
      $$ReadingLogTableUpdateCompanionBuilder,
      (
        ReadingLogData,
        BaseReferences<_$UserDatabase, $ReadingLogTable, ReadingLogData>,
      ),
      ReadingLogData,
      PrefetchHooks Function()
    >;
typedef $$AudioLogTableCreateCompanionBuilder =
    AudioLogCompanion Function({
      Value<int> id,
      required String dateDay,
      Value<int> seconds,
    });
typedef $$AudioLogTableUpdateCompanionBuilder =
    AudioLogCompanion Function({
      Value<int> id,
      Value<String> dateDay,
      Value<int> seconds,
    });

class $$AudioLogTableFilterComposer
    extends Composer<_$UserDatabase, $AudioLogTable> {
  $$AudioLogTableFilterComposer({
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

  ColumnFilters<String> get dateDay => $composableBuilder(
    column: $table.dateDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AudioLogTableOrderingComposer
    extends Composer<_$UserDatabase, $AudioLogTable> {
  $$AudioLogTableOrderingComposer({
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

  ColumnOrderings<String> get dateDay => $composableBuilder(
    column: $table.dateDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioLogTableAnnotationComposer
    extends Composer<_$UserDatabase, $AudioLogTable> {
  $$AudioLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateDay =>
      $composableBuilder(column: $table.dateDay, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);
}

class $$AudioLogTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AudioLogTable,
          AudioLogData,
          $$AudioLogTableFilterComposer,
          $$AudioLogTableOrderingComposer,
          $$AudioLogTableAnnotationComposer,
          $$AudioLogTableCreateCompanionBuilder,
          $$AudioLogTableUpdateCompanionBuilder,
          (
            AudioLogData,
            BaseReferences<_$UserDatabase, $AudioLogTable, AudioLogData>,
          ),
          AudioLogData,
          PrefetchHooks Function()
        > {
  $$AudioLogTableTableManager(_$UserDatabase db, $AudioLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dateDay = const Value.absent(),
                Value<int> seconds = const Value.absent(),
              }) =>
                  AudioLogCompanion(id: id, dateDay: dateDay, seconds: seconds),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dateDay,
                Value<int> seconds = const Value.absent(),
              }) => AudioLogCompanion.insert(
                id: id,
                dateDay: dateDay,
                seconds: seconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AudioLogTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AudioLogTable,
      AudioLogData,
      $$AudioLogTableFilterComposer,
      $$AudioLogTableOrderingComposer,
      $$AudioLogTableAnnotationComposer,
      $$AudioLogTableCreateCompanionBuilder,
      $$AudioLogTableUpdateCompanionBuilder,
      (
        AudioLogData,
        BaseReferences<_$UserDatabase, $AudioLogTable, AudioLogData>,
      ),
      AudioLogData,
      PrefetchHooks Function()
    >;
typedef $$TasbihLogTableCreateCompanionBuilder =
    TasbihLogCompanion Function({
      Value<int> id,
      required String dateDay,
      required String azkarKey,
      Value<int> count,
      required DateTime completedAt,
    });
typedef $$TasbihLogTableUpdateCompanionBuilder =
    TasbihLogCompanion Function({
      Value<int> id,
      Value<String> dateDay,
      Value<String> azkarKey,
      Value<int> count,
      Value<DateTime> completedAt,
    });

class $$TasbihLogTableFilterComposer
    extends Composer<_$UserDatabase, $TasbihLogTable> {
  $$TasbihLogTableFilterComposer({
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

  ColumnFilters<String> get dateDay => $composableBuilder(
    column: $table.dateDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get azkarKey => $composableBuilder(
    column: $table.azkarKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasbihLogTableOrderingComposer
    extends Composer<_$UserDatabase, $TasbihLogTable> {
  $$TasbihLogTableOrderingComposer({
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

  ColumnOrderings<String> get dateDay => $composableBuilder(
    column: $table.dateDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get azkarKey => $composableBuilder(
    column: $table.azkarKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasbihLogTableAnnotationComposer
    extends Composer<_$UserDatabase, $TasbihLogTable> {
  $$TasbihLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateDay =>
      $composableBuilder(column: $table.dateDay, builder: (column) => column);

  GeneratedColumn<String> get azkarKey =>
      $composableBuilder(column: $table.azkarKey, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$TasbihLogTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $TasbihLogTable,
          TasbihLogData,
          $$TasbihLogTableFilterComposer,
          $$TasbihLogTableOrderingComposer,
          $$TasbihLogTableAnnotationComposer,
          $$TasbihLogTableCreateCompanionBuilder,
          $$TasbihLogTableUpdateCompanionBuilder,
          (
            TasbihLogData,
            BaseReferences<_$UserDatabase, $TasbihLogTable, TasbihLogData>,
          ),
          TasbihLogData,
          PrefetchHooks Function()
        > {
  $$TasbihLogTableTableManager(_$UserDatabase db, $TasbihLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasbihLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasbihLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasbihLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dateDay = const Value.absent(),
                Value<String> azkarKey = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => TasbihLogCompanion(
                id: id,
                dateDay: dateDay,
                azkarKey: azkarKey,
                count: count,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dateDay,
                required String azkarKey,
                Value<int> count = const Value.absent(),
                required DateTime completedAt,
              }) => TasbihLogCompanion.insert(
                id: id,
                dateDay: dateDay,
                azkarKey: azkarKey,
                count: count,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasbihLogTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $TasbihLogTable,
      TasbihLogData,
      $$TasbihLogTableFilterComposer,
      $$TasbihLogTableOrderingComposer,
      $$TasbihLogTableAnnotationComposer,
      $$TasbihLogTableCreateCompanionBuilder,
      $$TasbihLogTableUpdateCompanionBuilder,
      (
        TasbihLogData,
        BaseReferences<_$UserDatabase, $TasbihLogTable, TasbihLogData>,
      ),
      TasbihLogData,
      PrefetchHooks Function()
    >;
typedef $$AyahColorTagsTableCreateCompanionBuilder =
    AyahColorTagsCompanion Function({
      required String type,
      required int ayahId,
      required DateTime taggedAt,
      Value<int> rowid,
    });
typedef $$AyahColorTagsTableUpdateCompanionBuilder =
    AyahColorTagsCompanion Function({
      Value<String> type,
      Value<int> ayahId,
      Value<DateTime> taggedAt,
      Value<int> rowid,
    });

class $$AyahColorTagsTableFilterComposer
    extends Composer<_$UserDatabase, $AyahColorTagsTable> {
  $$AyahColorTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get taggedAt => $composableBuilder(
    column: $table.taggedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahColorTagsTableOrderingComposer
    extends Composer<_$UserDatabase, $AyahColorTagsTable> {
  $$AyahColorTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get taggedAt => $composableBuilder(
    column: $table.taggedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahColorTagsTableAnnotationComposer
    extends Composer<_$UserDatabase, $AyahColorTagsTable> {
  $$AyahColorTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<DateTime> get taggedAt =>
      $composableBuilder(column: $table.taggedAt, builder: (column) => column);
}

class $$AyahColorTagsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AyahColorTagsTable,
          AyahColorTag,
          $$AyahColorTagsTableFilterComposer,
          $$AyahColorTagsTableOrderingComposer,
          $$AyahColorTagsTableAnnotationComposer,
          $$AyahColorTagsTableCreateCompanionBuilder,
          $$AyahColorTagsTableUpdateCompanionBuilder,
          (
            AyahColorTag,
            BaseReferences<_$UserDatabase, $AyahColorTagsTable, AyahColorTag>,
          ),
          AyahColorTag,
          PrefetchHooks Function()
        > {
  $$AyahColorTagsTableTableManager(_$UserDatabase db, $AyahColorTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahColorTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahColorTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahColorTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> type = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<DateTime> taggedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AyahColorTagsCompanion(
                type: type,
                ayahId: ayahId,
                taggedAt: taggedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String type,
                required int ayahId,
                required DateTime taggedAt,
                Value<int> rowid = const Value.absent(),
              }) => AyahColorTagsCompanion.insert(
                type: type,
                ayahId: ayahId,
                taggedAt: taggedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyahColorTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AyahColorTagsTable,
      AyahColorTag,
      $$AyahColorTagsTableFilterComposer,
      $$AyahColorTagsTableOrderingComposer,
      $$AyahColorTagsTableAnnotationComposer,
      $$AyahColorTagsTableCreateCompanionBuilder,
      $$AyahColorTagsTableUpdateCompanionBuilder,
      (
        AyahColorTag,
        BaseReferences<_$UserDatabase, $AyahColorTagsTable, AyahColorTag>,
      ),
      AyahColorTag,
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
  $$HifzPlansTableTableManager get hifzPlans =>
      $$HifzPlansTableTableManager(_db, _db.hifzPlans);
  $$HifzSettingsTableTableManager get hifzSettings =>
      $$HifzSettingsTableTableManager(_db, _db.hifzSettings);
  $$ActivityRemindersTableTableManager get activityReminders =>
      $$ActivityRemindersTableTableManager(_db, _db.activityReminders);
  $$AdhanSettingsTableTableManager get adhanSettings =>
      $$AdhanSettingsTableTableManager(_db, _db.adhanSettings);
  $$ActivityBookmarksTableTableManager get activityBookmarks =>
      $$ActivityBookmarksTableTableManager(_db, _db.activityBookmarks);
  $$CategoryDailyLogTableTableManager get categoryDailyLog =>
      $$CategoryDailyLogTableTableManager(_db, _db.categoryDailyLog);
  $$AdhanNotificationSettingsTableTableManager get adhanNotificationSettings =>
      $$AdhanNotificationSettingsTableTableManager(
        _db,
        _db.adhanNotificationSettings,
      );
  $$MushafColorSettingsTableTableManager get mushafColorSettings =>
      $$MushafColorSettingsTableTableManager(_db, _db.mushafColorSettings);
  $$PrayerCheckinSettingsTableTableManager get prayerCheckinSettings =>
      $$PrayerCheckinSettingsTableTableManager(_db, _db.prayerCheckinSettings);
  $$QiyamAyahLogTableTableManager get qiyamAyahLog =>
      $$QiyamAyahLogTableTableManager(_db, _db.qiyamAyahLog);
  $$AyahNotesTableTableManager get ayahNotes =>
      $$AyahNotesTableTableManager(_db, _db.ayahNotes);
  $$AppThemeSettingsTableTableManager get appThemeSettings =>
      $$AppThemeSettingsTableTableManager(_db, _db.appThemeSettings);
  $$CustomHabitsTableTableManager get customHabits =>
      $$CustomHabitsTableTableManager(_db, _db.customHabits);
  $$CustomHabitLogsTableTableManager get customHabitLogs =>
      $$CustomHabitLogsTableTableManager(_db, _db.customHabitLogs);
  $$HifzAyahReviewsTableTableManager get hifzAyahReviews =>
      $$HifzAyahReviewsTableTableManager(_db, _db.hifzAyahReviews);
  $$ToolUsageStatsTableTableManager get toolUsageStats =>
      $$ToolUsageStatsTableTableManager(_db, _db.toolUsageStats);
  $$ReadingLogTableTableManager get readingLog =>
      $$ReadingLogTableTableManager(_db, _db.readingLog);
  $$AudioLogTableTableManager get audioLog =>
      $$AudioLogTableTableManager(_db, _db.audioLog);
  $$TasbihLogTableTableManager get tasbihLog =>
      $$TasbihLogTableTableManager(_db, _db.tasbihLog);
  $$AyahColorTagsTableTableManager get ayahColorTags =>
      $$AyahColorTagsTableTableManager(_db, _db.ayahColorTags);
}
