// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tafsir_edition_database.dart';

// ignore_for_file: type=lint
class $TafsirTextsTable extends TafsirTexts
    with TableInfo<$TafsirTextsTable, TafsirText> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TafsirTextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ayahId, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'texts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TafsirText> instance, {
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
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ayahId};
  @override
  TafsirText map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TafsirText(
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $TafsirTextsTable createAlias(String alias) {
    return $TafsirTextsTable(attachedDatabase, alias);
  }
}

class TafsirText extends DataClass implements Insertable<TafsirText> {
  final int ayahId;
  final String body;
  const TafsirText({required this.ayahId, required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ayah_id'] = Variable<int>(ayahId);
    map['body'] = Variable<String>(body);
    return map;
  }

  TafsirTextsCompanion toCompanion(bool nullToAbsent) {
    return TafsirTextsCompanion(ayahId: Value(ayahId), body: Value(body));
  }

  factory TafsirText.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TafsirText(
      ayahId: serializer.fromJson<int>(json['ayahId']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ayahId': serializer.toJson<int>(ayahId),
      'body': serializer.toJson<String>(body),
    };
  }

  TafsirText copyWith({int? ayahId, String? body}) =>
      TafsirText(ayahId: ayahId ?? this.ayahId, body: body ?? this.body);
  TafsirText copyWithCompanion(TafsirTextsCompanion data) {
    return TafsirText(
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TafsirText(')
          ..write('ayahId: $ayahId, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ayahId, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TafsirText &&
          other.ayahId == this.ayahId &&
          other.body == this.body);
}

class TafsirTextsCompanion extends UpdateCompanion<TafsirText> {
  final Value<int> ayahId;
  final Value<String> body;
  const TafsirTextsCompanion({
    this.ayahId = const Value.absent(),
    this.body = const Value.absent(),
  });
  TafsirTextsCompanion.insert({
    this.ayahId = const Value.absent(),
    required String body,
  }) : body = Value(body);
  static Insertable<TafsirText> custom({
    Expression<int>? ayahId,
    Expression<String>? body,
  }) {
    return RawValuesInsertable({
      if (ayahId != null) 'ayah_id': ayahId,
      if (body != null) 'body': body,
    });
  }

  TafsirTextsCompanion copyWith({Value<int>? ayahId, Value<String>? body}) {
    return TafsirTextsCompanion(
      ayahId: ayahId ?? this.ayahId,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TafsirTextsCompanion(')
          ..write('ayahId: $ayahId, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}

abstract class _$TafsirEditionDatabase extends GeneratedDatabase {
  _$TafsirEditionDatabase(QueryExecutor e) : super(e);
  $TafsirEditionDatabaseManager get managers =>
      $TafsirEditionDatabaseManager(this);
  late final $TafsirTextsTable tafsirTexts = $TafsirTextsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tafsirTexts];
}

typedef $$TafsirTextsTableCreateCompanionBuilder =
    TafsirTextsCompanion Function({Value<int> ayahId, required String body});
typedef $$TafsirTextsTableUpdateCompanionBuilder =
    TafsirTextsCompanion Function({Value<int> ayahId, Value<String> body});

class $$TafsirTextsTableFilterComposer
    extends Composer<_$TafsirEditionDatabase, $TafsirTextsTable> {
  $$TafsirTextsTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TafsirTextsTableOrderingComposer
    extends Composer<_$TafsirEditionDatabase, $TafsirTextsTable> {
  $$TafsirTextsTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TafsirTextsTableAnnotationComposer
    extends Composer<_$TafsirEditionDatabase, $TafsirTextsTable> {
  $$TafsirTextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$TafsirTextsTableTableManager
    extends
        RootTableManager<
          _$TafsirEditionDatabase,
          $TafsirTextsTable,
          TafsirText,
          $$TafsirTextsTableFilterComposer,
          $$TafsirTextsTableOrderingComposer,
          $$TafsirTextsTableAnnotationComposer,
          $$TafsirTextsTableCreateCompanionBuilder,
          $$TafsirTextsTableUpdateCompanionBuilder,
          (
            TafsirText,
            BaseReferences<
              _$TafsirEditionDatabase,
              $TafsirTextsTable,
              TafsirText
            >,
          ),
          TafsirText,
          PrefetchHooks Function()
        > {
  $$TafsirTextsTableTableManager(
    _$TafsirEditionDatabase db,
    $TafsirTextsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TafsirTextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TafsirTextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TafsirTextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ayahId = const Value.absent(),
                Value<String> body = const Value.absent(),
              }) => TafsirTextsCompanion(ayahId: ayahId, body: body),
          createCompanionCallback:
              ({
                Value<int> ayahId = const Value.absent(),
                required String body,
              }) => TafsirTextsCompanion.insert(ayahId: ayahId, body: body),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TafsirTextsTableProcessedTableManager =
    ProcessedTableManager<
      _$TafsirEditionDatabase,
      $TafsirTextsTable,
      TafsirText,
      $$TafsirTextsTableFilterComposer,
      $$TafsirTextsTableOrderingComposer,
      $$TafsirTextsTableAnnotationComposer,
      $$TafsirTextsTableCreateCompanionBuilder,
      $$TafsirTextsTableUpdateCompanionBuilder,
      (
        TafsirText,
        BaseReferences<_$TafsirEditionDatabase, $TafsirTextsTable, TafsirText>,
      ),
      TafsirText,
      PrefetchHooks Function()
    >;

class $TafsirEditionDatabaseManager {
  final _$TafsirEditionDatabase _db;
  $TafsirEditionDatabaseManager(this._db);
  $$TafsirTextsTableTableManager get tafsirTexts =>
      $$TafsirTextsTableTableManager(_db, _db.tafsirTexts);
}
