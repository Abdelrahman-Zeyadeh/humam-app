// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hadith_database.dart';

// ignore_for_file: type=lint
class $HadithBooksTable extends HadithBooks
    with TableInfo<$HadithBooksTable, HadithBook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HadithBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, nameAr];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadith_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<HadithBook> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HadithBook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HadithBook(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
    );
  }

  @override
  $HadithBooksTable createAlias(String alias) {
    return $HadithBooksTable(attachedDatabase, alias);
  }
}

class HadithBook extends DataClass implements Insertable<HadithBook> {
  final int id;
  final String key;
  final String nameAr;
  const HadithBook({required this.id, required this.key, required this.nameAr});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['name_ar'] = Variable<String>(nameAr);
    return map;
  }

  HadithBooksCompanion toCompanion(bool nullToAbsent) {
    return HadithBooksCompanion(
      id: Value(id),
      key: Value(key),
      nameAr: Value(nameAr),
    );
  }

  factory HadithBook.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HadithBook(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'nameAr': serializer.toJson<String>(nameAr),
    };
  }

  HadithBook copyWith({int? id, String? key, String? nameAr}) => HadithBook(
    id: id ?? this.id,
    key: key ?? this.key,
    nameAr: nameAr ?? this.nameAr,
  );
  HadithBook copyWithCompanion(HadithBooksCompanion data) {
    return HadithBook(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HadithBook(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('nameAr: $nameAr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, nameAr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HadithBook &&
          other.id == this.id &&
          other.key == this.key &&
          other.nameAr == this.nameAr);
}

class HadithBooksCompanion extends UpdateCompanion<HadithBook> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> nameAr;
  const HadithBooksCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.nameAr = const Value.absent(),
  });
  HadithBooksCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String nameAr,
  }) : key = Value(key),
       nameAr = Value(nameAr);
  static Insertable<HadithBook> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? nameAr,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (nameAr != null) 'name_ar': nameAr,
    });
  }

  HadithBooksCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? nameAr,
  }) {
    return HadithBooksCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      nameAr: nameAr ?? this.nameAr,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HadithBooksCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('nameAr: $nameAr')
          ..write(')'))
        .toString();
  }
}

class $HadithsTable extends Hadiths with TableInfo<$HadithsTable, Hadith> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HadithsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hadithNumberMeta = const VerificationMeta(
    'hadithNumber',
  );
  @override
  late final GeneratedColumn<int> hadithNumber = GeneratedColumn<int>(
    'hadith_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textSearchMeta = const VerificationMeta(
    'textSearch',
  );
  @override
  late final GeneratedColumn<String> textSearch = GeneratedColumn<String>(
    'text_search',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    hadithNumber,
    content,
    textSearch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadiths';
  @override
  VerificationContext validateIntegrity(
    Insertable<Hadith> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('hadith_number')) {
      context.handle(
        _hadithNumberMeta,
        hadithNumber.isAcceptableOrUnknown(
          data['hadith_number']!,
          _hadithNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hadithNumberMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('text_search')) {
      context.handle(
        _textSearchMeta,
        textSearch.isAcceptableOrUnknown(data['text_search']!, _textSearchMeta),
      );
    } else if (isInserting) {
      context.missing(_textSearchMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Hadith map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hadith(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      hadithNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hadith_number'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      textSearch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_search'],
      )!,
    );
  }

  @override
  $HadithsTable createAlias(String alias) {
    return $HadithsTable(attachedDatabase, alias);
  }
}

class Hadith extends DataClass implements Insertable<Hadith> {
  final int id;
  final int bookId;
  final int hadithNumber;
  final String content;
  final String textSearch;
  const Hadith({
    required this.id,
    required this.bookId,
    required this.hadithNumber,
    required this.content,
    required this.textSearch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['hadith_number'] = Variable<int>(hadithNumber);
    map['text'] = Variable<String>(content);
    map['text_search'] = Variable<String>(textSearch);
    return map;
  }

  HadithsCompanion toCompanion(bool nullToAbsent) {
    return HadithsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      hadithNumber: Value(hadithNumber),
      content: Value(content),
      textSearch: Value(textSearch),
    );
  }

  factory Hadith.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Hadith(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      hadithNumber: serializer.fromJson<int>(json['hadithNumber']),
      content: serializer.fromJson<String>(json['content']),
      textSearch: serializer.fromJson<String>(json['textSearch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'hadithNumber': serializer.toJson<int>(hadithNumber),
      'content': serializer.toJson<String>(content),
      'textSearch': serializer.toJson<String>(textSearch),
    };
  }

  Hadith copyWith({
    int? id,
    int? bookId,
    int? hadithNumber,
    String? content,
    String? textSearch,
  }) => Hadith(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    hadithNumber: hadithNumber ?? this.hadithNumber,
    content: content ?? this.content,
    textSearch: textSearch ?? this.textSearch,
  );
  Hadith copyWithCompanion(HadithsCompanion data) {
    return Hadith(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      hadithNumber: data.hadithNumber.present
          ? data.hadithNumber.value
          : this.hadithNumber,
      content: data.content.present ? data.content.value : this.content,
      textSearch: data.textSearch.present
          ? data.textSearch.value
          : this.textSearch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Hadith(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('hadithNumber: $hadithNumber, ')
          ..write('content: $content, ')
          ..write('textSearch: $textSearch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, hadithNumber, content, textSearch);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Hadith &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.hadithNumber == this.hadithNumber &&
          other.content == this.content &&
          other.textSearch == this.textSearch);
}

class HadithsCompanion extends UpdateCompanion<Hadith> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<int> hadithNumber;
  final Value<String> content;
  final Value<String> textSearch;
  const HadithsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.hadithNumber = const Value.absent(),
    this.content = const Value.absent(),
    this.textSearch = const Value.absent(),
  });
  HadithsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required int hadithNumber,
    required String content,
    required String textSearch,
  }) : bookId = Value(bookId),
       hadithNumber = Value(hadithNumber),
       content = Value(content),
       textSearch = Value(textSearch);
  static Insertable<Hadith> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<int>? hadithNumber,
    Expression<String>? content,
    Expression<String>? textSearch,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (hadithNumber != null) 'hadith_number': hadithNumber,
      if (content != null) 'text': content,
      if (textSearch != null) 'text_search': textSearch,
    });
  }

  HadithsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<int>? hadithNumber,
    Value<String>? content,
    Value<String>? textSearch,
  }) {
    return HadithsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      hadithNumber: hadithNumber ?? this.hadithNumber,
      content: content ?? this.content,
      textSearch: textSearch ?? this.textSearch,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (hadithNumber.present) {
      map['hadith_number'] = Variable<int>(hadithNumber.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (textSearch.present) {
      map['text_search'] = Variable<String>(textSearch.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HadithsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('hadithNumber: $hadithNumber, ')
          ..write('content: $content, ')
          ..write('textSearch: $textSearch')
          ..write(')'))
        .toString();
  }
}

abstract class _$HadithDatabase extends GeneratedDatabase {
  _$HadithDatabase(QueryExecutor e) : super(e);
  $HadithDatabaseManager get managers => $HadithDatabaseManager(this);
  late final $HadithBooksTable hadithBooks = $HadithBooksTable(this);
  late final $HadithsTable hadiths = $HadithsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [hadithBooks, hadiths];
}

typedef $$HadithBooksTableCreateCompanionBuilder =
    HadithBooksCompanion Function({
      Value<int> id,
      required String key,
      required String nameAr,
    });
typedef $$HadithBooksTableUpdateCompanionBuilder =
    HadithBooksCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> nameAr,
    });

class $$HadithBooksTableFilterComposer
    extends Composer<_$HadithDatabase, $HadithBooksTable> {
  $$HadithBooksTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HadithBooksTableOrderingComposer
    extends Composer<_$HadithDatabase, $HadithBooksTable> {
  $$HadithBooksTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HadithBooksTableAnnotationComposer
    extends Composer<_$HadithDatabase, $HadithBooksTable> {
  $$HadithBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);
}

class $$HadithBooksTableTableManager
    extends
        RootTableManager<
          _$HadithDatabase,
          $HadithBooksTable,
          HadithBook,
          $$HadithBooksTableFilterComposer,
          $$HadithBooksTableOrderingComposer,
          $$HadithBooksTableAnnotationComposer,
          $$HadithBooksTableCreateCompanionBuilder,
          $$HadithBooksTableUpdateCompanionBuilder,
          (
            HadithBook,
            BaseReferences<_$HadithDatabase, $HadithBooksTable, HadithBook>,
          ),
          HadithBook,
          PrefetchHooks Function()
        > {
  $$HadithBooksTableTableManager(_$HadithDatabase db, $HadithBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HadithBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HadithBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HadithBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
              }) => HadithBooksCompanion(id: id, key: key, nameAr: nameAr),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String nameAr,
              }) =>
                  HadithBooksCompanion.insert(id: id, key: key, nameAr: nameAr),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HadithBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$HadithDatabase,
      $HadithBooksTable,
      HadithBook,
      $$HadithBooksTableFilterComposer,
      $$HadithBooksTableOrderingComposer,
      $$HadithBooksTableAnnotationComposer,
      $$HadithBooksTableCreateCompanionBuilder,
      $$HadithBooksTableUpdateCompanionBuilder,
      (
        HadithBook,
        BaseReferences<_$HadithDatabase, $HadithBooksTable, HadithBook>,
      ),
      HadithBook,
      PrefetchHooks Function()
    >;
typedef $$HadithsTableCreateCompanionBuilder =
    HadithsCompanion Function({
      Value<int> id,
      required int bookId,
      required int hadithNumber,
      required String content,
      required String textSearch,
    });
typedef $$HadithsTableUpdateCompanionBuilder =
    HadithsCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<int> hadithNumber,
      Value<String> content,
      Value<String> textSearch,
    });

class $$HadithsTableFilterComposer
    extends Composer<_$HadithDatabase, $HadithsTable> {
  $$HadithsTableFilterComposer({
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

  ColumnFilters<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hadithNumber => $composableBuilder(
    column: $table.hadithNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HadithsTableOrderingComposer
    extends Composer<_$HadithDatabase, $HadithsTable> {
  $$HadithsTableOrderingComposer({
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

  ColumnOrderings<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hadithNumber => $composableBuilder(
    column: $table.hadithNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HadithsTableAnnotationComposer
    extends Composer<_$HadithDatabase, $HadithsTable> {
  $$HadithsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get hadithNumber => $composableBuilder(
    column: $table.hadithNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => column,
  );
}

class $$HadithsTableTableManager
    extends
        RootTableManager<
          _$HadithDatabase,
          $HadithsTable,
          Hadith,
          $$HadithsTableFilterComposer,
          $$HadithsTableOrderingComposer,
          $$HadithsTableAnnotationComposer,
          $$HadithsTableCreateCompanionBuilder,
          $$HadithsTableUpdateCompanionBuilder,
          (Hadith, BaseReferences<_$HadithDatabase, $HadithsTable, Hadith>),
          Hadith,
          PrefetchHooks Function()
        > {
  $$HadithsTableTableManager(_$HadithDatabase db, $HadithsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HadithsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HadithsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HadithsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> hadithNumber = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> textSearch = const Value.absent(),
              }) => HadithsCompanion(
                id: id,
                bookId: bookId,
                hadithNumber: hadithNumber,
                content: content,
                textSearch: textSearch,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required int hadithNumber,
                required String content,
                required String textSearch,
              }) => HadithsCompanion.insert(
                id: id,
                bookId: bookId,
                hadithNumber: hadithNumber,
                content: content,
                textSearch: textSearch,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HadithsTableProcessedTableManager =
    ProcessedTableManager<
      _$HadithDatabase,
      $HadithsTable,
      Hadith,
      $$HadithsTableFilterComposer,
      $$HadithsTableOrderingComposer,
      $$HadithsTableAnnotationComposer,
      $$HadithsTableCreateCompanionBuilder,
      $$HadithsTableUpdateCompanionBuilder,
      (Hadith, BaseReferences<_$HadithDatabase, $HadithsTable, Hadith>),
      Hadith,
      PrefetchHooks Function()
    >;

class $HadithDatabaseManager {
  final _$HadithDatabase _db;
  $HadithDatabaseManager(this._db);
  $$HadithBooksTableTableManager get hadithBooks =>
      $$HadithBooksTableTableManager(_db, _db.hadithBooks);
  $$HadithsTableTableManager get hadiths =>
      $$HadithsTableTableManager(_db, _db.hadiths);
}
