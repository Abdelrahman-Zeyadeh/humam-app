// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quran_database.dart';

// ignore_for_file: type=lint
class $SurahsTable extends Surahs with TableInfo<$SurahsTable, Surah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _nameArPlainMeta = const VerificationMeta(
    'nameArPlain',
  );
  @override
  late final GeneratedColumn<String> nameArPlain = GeneratedColumn<String>(
    'name_ar_plain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revelationPlaceMeta = const VerificationMeta(
    'revelationPlace',
  );
  @override
  late final GeneratedColumn<String> revelationPlace = GeneratedColumn<String>(
    'revelation_place',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revelationOrderMeta = const VerificationMeta(
    'revelationOrder',
  );
  @override
  late final GeneratedColumn<int> revelationOrder = GeneratedColumn<int>(
    'revelation_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bismillahPreMeta = const VerificationMeta(
    'bismillahPre',
  );
  @override
  late final GeneratedColumn<int> bismillahPre = GeneratedColumn<int>(
    'bismillah_pre',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameAr,
    nameArPlain,
    nameEn,
    revelationPlace,
    revelationOrder,
    ayahCount,
    startPage,
    bismillahPre,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Surah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_ar_plain')) {
      context.handle(
        _nameArPlainMeta,
        nameArPlain.isAcceptableOrUnknown(
          data['name_ar_plain']!,
          _nameArPlainMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameArPlainMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('revelation_place')) {
      context.handle(
        _revelationPlaceMeta,
        revelationPlace.isAcceptableOrUnknown(
          data['revelation_place']!,
          _revelationPlaceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_revelationPlaceMeta);
    }
    if (data.containsKey('revelation_order')) {
      context.handle(
        _revelationOrderMeta,
        revelationOrder.isAcceptableOrUnknown(
          data['revelation_order']!,
          _revelationOrderMeta,
        ),
      );
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    } else if (isInserting) {
      context.missing(_startPageMeta);
    }
    if (data.containsKey('bismillah_pre')) {
      context.handle(
        _bismillahPreMeta,
        bismillahPre.isAcceptableOrUnknown(
          data['bismillah_pre']!,
          _bismillahPreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bismillahPreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Surah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surah(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameArPlain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar_plain'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      revelationPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revelation_place'],
      )!,
      revelationOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revelation_order'],
      ),
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      )!,
      bismillahPre: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bismillah_pre'],
      )!,
    );
  }

  @override
  $SurahsTable createAlias(String alias) {
    return $SurahsTable(attachedDatabase, alias);
  }
}

class Surah extends DataClass implements Insertable<Surah> {
  final int id;
  final String nameAr;
  final String nameArPlain;
  final String nameEn;
  final String revelationPlace;
  final int? revelationOrder;
  final int ayahCount;
  final int startPage;
  final int bismillahPre;
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameArPlain,
    required this.nameEn,
    required this.revelationPlace,
    this.revelationOrder,
    required this.ayahCount,
    required this.startPage,
    required this.bismillahPre,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_ar_plain'] = Variable<String>(nameArPlain);
    map['name_en'] = Variable<String>(nameEn);
    map['revelation_place'] = Variable<String>(revelationPlace);
    if (!nullToAbsent || revelationOrder != null) {
      map['revelation_order'] = Variable<int>(revelationOrder);
    }
    map['ayah_count'] = Variable<int>(ayahCount);
    map['start_page'] = Variable<int>(startPage);
    map['bismillah_pre'] = Variable<int>(bismillahPre);
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      nameArPlain: Value(nameArPlain),
      nameEn: Value(nameEn),
      revelationPlace: Value(revelationPlace),
      revelationOrder: revelationOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(revelationOrder),
      ayahCount: Value(ayahCount),
      startPage: Value(startPage),
      bismillahPre: Value(bismillahPre),
    );
  }

  factory Surah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surah(
      id: serializer.fromJson<int>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameArPlain: serializer.fromJson<String>(json['nameArPlain']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      revelationPlace: serializer.fromJson<String>(json['revelationPlace']),
      revelationOrder: serializer.fromJson<int?>(json['revelationOrder']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      startPage: serializer.fromJson<int>(json['startPage']),
      bismillahPre: serializer.fromJson<int>(json['bismillahPre']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameArPlain': serializer.toJson<String>(nameArPlain),
      'nameEn': serializer.toJson<String>(nameEn),
      'revelationPlace': serializer.toJson<String>(revelationPlace),
      'revelationOrder': serializer.toJson<int?>(revelationOrder),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'startPage': serializer.toJson<int>(startPage),
      'bismillahPre': serializer.toJson<int>(bismillahPre),
    };
  }

  Surah copyWith({
    int? id,
    String? nameAr,
    String? nameArPlain,
    String? nameEn,
    String? revelationPlace,
    Value<int?> revelationOrder = const Value.absent(),
    int? ayahCount,
    int? startPage,
    int? bismillahPre,
  }) => Surah(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    nameArPlain: nameArPlain ?? this.nameArPlain,
    nameEn: nameEn ?? this.nameEn,
    revelationPlace: revelationPlace ?? this.revelationPlace,
    revelationOrder: revelationOrder.present
        ? revelationOrder.value
        : this.revelationOrder,
    ayahCount: ayahCount ?? this.ayahCount,
    startPage: startPage ?? this.startPage,
    bismillahPre: bismillahPre ?? this.bismillahPre,
  );
  Surah copyWithCompanion(SurahsCompanion data) {
    return Surah(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameArPlain: data.nameArPlain.present
          ? data.nameArPlain.value
          : this.nameArPlain,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      revelationPlace: data.revelationPlace.present
          ? data.revelationPlace.value
          : this.revelationPlace,
      revelationOrder: data.revelationOrder.present
          ? data.revelationOrder.value
          : this.revelationOrder,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      bismillahPre: data.bismillahPre.present
          ? data.bismillahPre.value
          : this.bismillahPre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surah(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameArPlain: $nameArPlain, ')
          ..write('nameEn: $nameEn, ')
          ..write('revelationPlace: $revelationPlace, ')
          ..write('revelationOrder: $revelationOrder, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('startPage: $startPage, ')
          ..write('bismillahPre: $bismillahPre')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nameAr,
    nameArPlain,
    nameEn,
    revelationPlace,
    revelationOrder,
    ayahCount,
    startPage,
    bismillahPre,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surah &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.nameArPlain == this.nameArPlain &&
          other.nameEn == this.nameEn &&
          other.revelationPlace == this.revelationPlace &&
          other.revelationOrder == this.revelationOrder &&
          other.ayahCount == this.ayahCount &&
          other.startPage == this.startPage &&
          other.bismillahPre == this.bismillahPre);
}

class SurahsCompanion extends UpdateCompanion<Surah> {
  final Value<int> id;
  final Value<String> nameAr;
  final Value<String> nameArPlain;
  final Value<String> nameEn;
  final Value<String> revelationPlace;
  final Value<int?> revelationOrder;
  final Value<int> ayahCount;
  final Value<int> startPage;
  final Value<int> bismillahPre;
  const SurahsCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameArPlain = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.revelationPlace = const Value.absent(),
    this.revelationOrder = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.startPage = const Value.absent(),
    this.bismillahPre = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    required String nameArPlain,
    required String nameEn,
    required String revelationPlace,
    this.revelationOrder = const Value.absent(),
    required int ayahCount,
    required int startPage,
    required int bismillahPre,
  }) : nameAr = Value(nameAr),
       nameArPlain = Value(nameArPlain),
       nameEn = Value(nameEn),
       revelationPlace = Value(revelationPlace),
       ayahCount = Value(ayahCount),
       startPage = Value(startPage),
       bismillahPre = Value(bismillahPre);
  static Insertable<Surah> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? nameArPlain,
    Expression<String>? nameEn,
    Expression<String>? revelationPlace,
    Expression<int>? revelationOrder,
    Expression<int>? ayahCount,
    Expression<int>? startPage,
    Expression<int>? bismillahPre,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameArPlain != null) 'name_ar_plain': nameArPlain,
      if (nameEn != null) 'name_en': nameEn,
      if (revelationPlace != null) 'revelation_place': revelationPlace,
      if (revelationOrder != null) 'revelation_order': revelationOrder,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (startPage != null) 'start_page': startPage,
      if (bismillahPre != null) 'bismillah_pre': bismillahPre,
    });
  }

  SurahsCompanion copyWith({
    Value<int>? id,
    Value<String>? nameAr,
    Value<String>? nameArPlain,
    Value<String>? nameEn,
    Value<String>? revelationPlace,
    Value<int?>? revelationOrder,
    Value<int>? ayahCount,
    Value<int>? startPage,
    Value<int>? bismillahPre,
  }) {
    return SurahsCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameArPlain: nameArPlain ?? this.nameArPlain,
      nameEn: nameEn ?? this.nameEn,
      revelationPlace: revelationPlace ?? this.revelationPlace,
      revelationOrder: revelationOrder ?? this.revelationOrder,
      ayahCount: ayahCount ?? this.ayahCount,
      startPage: startPage ?? this.startPage,
      bismillahPre: bismillahPre ?? this.bismillahPre,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameArPlain.present) {
      map['name_ar_plain'] = Variable<String>(nameArPlain.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (revelationPlace.present) {
      map['revelation_place'] = Variable<String>(revelationPlace.value);
    }
    if (revelationOrder.present) {
      map['revelation_order'] = Variable<int>(revelationOrder.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (bismillahPre.present) {
      map['bismillah_pre'] = Variable<int>(bismillahPre.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameArPlain: $nameArPlain, ')
          ..write('nameEn: $nameEn, ')
          ..write('revelationPlace: $revelationPlace, ')
          ..write('revelationOrder: $revelationOrder, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('startPage: $startPage, ')
          ..write('bismillahPre: $bismillahPre')
          ..write(')'))
        .toString();
  }
}

class $AyahsTable extends Ayahs with TableInfo<$AyahsTable, Ayah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juzMeta = const VerificationMeta('juz');
  @override
  late final GeneratedColumn<int> juz = GeneratedColumn<int>(
    'juz',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hizbMeta = const VerificationMeta('hizb');
  @override
  late final GeneratedColumn<int> hizb = GeneratedColumn<int>(
    'hizb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rubMeta = const VerificationMeta('rub');
  @override
  late final GeneratedColumn<int> rub = GeneratedColumn<int>(
    'rub',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manzilMeta = const VerificationMeta('manzil');
  @override
  late final GeneratedColumn<int> manzil = GeneratedColumn<int>(
    'manzil',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sajdaTypeMeta = const VerificationMeta(
    'sajdaType',
  );
  @override
  late final GeneratedColumn<String> sajdaType = GeneratedColumn<String>(
    'sajda_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textUthmaniMeta = const VerificationMeta(
    'textUthmani',
  );
  @override
  late final GeneratedColumn<String> textUthmani = GeneratedColumn<String>(
    'text_uthmani',
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
    surah,
    ayah,
    page,
    juz,
    hizb,
    rub,
    manzil,
    sajdaType,
    textUthmani,
    textSearch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ayah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('juz')) {
      context.handle(
        _juzMeta,
        juz.isAcceptableOrUnknown(data['juz']!, _juzMeta),
      );
    } else if (isInserting) {
      context.missing(_juzMeta);
    }
    if (data.containsKey('hizb')) {
      context.handle(
        _hizbMeta,
        hizb.isAcceptableOrUnknown(data['hizb']!, _hizbMeta),
      );
    }
    if (data.containsKey('rub')) {
      context.handle(
        _rubMeta,
        rub.isAcceptableOrUnknown(data['rub']!, _rubMeta),
      );
    }
    if (data.containsKey('manzil')) {
      context.handle(
        _manzilMeta,
        manzil.isAcceptableOrUnknown(data['manzil']!, _manzilMeta),
      );
    } else if (isInserting) {
      context.missing(_manzilMeta);
    }
    if (data.containsKey('sajda_type')) {
      context.handle(
        _sajdaTypeMeta,
        sajdaType.isAcceptableOrUnknown(data['sajda_type']!, _sajdaTypeMeta),
      );
    }
    if (data.containsKey('text_uthmani')) {
      context.handle(
        _textUthmaniMeta,
        textUthmani.isAcceptableOrUnknown(
          data['text_uthmani']!,
          _textUthmaniMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textUthmaniMeta);
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
  Ayah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ayah(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      juz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}juz'],
      )!,
      hizb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hizb'],
      ),
      rub: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rub'],
      ),
      manzil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manzil'],
      )!,
      sajdaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sajda_type'],
      ),
      textUthmani: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_uthmani'],
      )!,
      textSearch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_search'],
      )!,
    );
  }

  @override
  $AyahsTable createAlias(String alias) {
    return $AyahsTable(attachedDatabase, alias);
  }
}

class Ayah extends DataClass implements Insertable<Ayah> {
  final int id;
  final int surah;
  final int ayah;
  final int page;
  final int juz;
  final int? hizb;
  final int? rub;
  final int manzil;
  final String? sajdaType;
  final String textUthmani;
  final String textSearch;
  const Ayah({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.page,
    required this.juz,
    this.hizb,
    this.rub,
    required this.manzil,
    this.sajdaType,
    required this.textUthmani,
    required this.textSearch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['page'] = Variable<int>(page);
    map['juz'] = Variable<int>(juz);
    if (!nullToAbsent || hizb != null) {
      map['hizb'] = Variable<int>(hizb);
    }
    if (!nullToAbsent || rub != null) {
      map['rub'] = Variable<int>(rub);
    }
    map['manzil'] = Variable<int>(manzil);
    if (!nullToAbsent || sajdaType != null) {
      map['sajda_type'] = Variable<String>(sajdaType);
    }
    map['text_uthmani'] = Variable<String>(textUthmani);
    map['text_search'] = Variable<String>(textSearch);
    return map;
  }

  AyahsCompanion toCompanion(bool nullToAbsent) {
    return AyahsCompanion(
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      page: Value(page),
      juz: Value(juz),
      hizb: hizb == null && nullToAbsent ? const Value.absent() : Value(hizb),
      rub: rub == null && nullToAbsent ? const Value.absent() : Value(rub),
      manzil: Value(manzil),
      sajdaType: sajdaType == null && nullToAbsent
          ? const Value.absent()
          : Value(sajdaType),
      textUthmani: Value(textUthmani),
      textSearch: Value(textSearch),
    );
  }

  factory Ayah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ayah(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      page: serializer.fromJson<int>(json['page']),
      juz: serializer.fromJson<int>(json['juz']),
      hizb: serializer.fromJson<int?>(json['hizb']),
      rub: serializer.fromJson<int?>(json['rub']),
      manzil: serializer.fromJson<int>(json['manzil']),
      sajdaType: serializer.fromJson<String?>(json['sajdaType']),
      textUthmani: serializer.fromJson<String>(json['textUthmani']),
      textSearch: serializer.fromJson<String>(json['textSearch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'page': serializer.toJson<int>(page),
      'juz': serializer.toJson<int>(juz),
      'hizb': serializer.toJson<int?>(hizb),
      'rub': serializer.toJson<int?>(rub),
      'manzil': serializer.toJson<int>(manzil),
      'sajdaType': serializer.toJson<String?>(sajdaType),
      'textUthmani': serializer.toJson<String>(textUthmani),
      'textSearch': serializer.toJson<String>(textSearch),
    };
  }

  Ayah copyWith({
    int? id,
    int? surah,
    int? ayah,
    int? page,
    int? juz,
    Value<int?> hizb = const Value.absent(),
    Value<int?> rub = const Value.absent(),
    int? manzil,
    Value<String?> sajdaType = const Value.absent(),
    String? textUthmani,
    String? textSearch,
  }) => Ayah(
    id: id ?? this.id,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    page: page ?? this.page,
    juz: juz ?? this.juz,
    hizb: hizb.present ? hizb.value : this.hizb,
    rub: rub.present ? rub.value : this.rub,
    manzil: manzil ?? this.manzil,
    sajdaType: sajdaType.present ? sajdaType.value : this.sajdaType,
    textUthmani: textUthmani ?? this.textUthmani,
    textSearch: textSearch ?? this.textSearch,
  );
  Ayah copyWithCompanion(AyahsCompanion data) {
    return Ayah(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      page: data.page.present ? data.page.value : this.page,
      juz: data.juz.present ? data.juz.value : this.juz,
      hizb: data.hizb.present ? data.hizb.value : this.hizb,
      rub: data.rub.present ? data.rub.value : this.rub,
      manzil: data.manzil.present ? data.manzil.value : this.manzil,
      sajdaType: data.sajdaType.present ? data.sajdaType.value : this.sajdaType,
      textUthmani: data.textUthmani.present
          ? data.textUthmani.value
          : this.textUthmani,
      textSearch: data.textSearch.present
          ? data.textSearch.value
          : this.textSearch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ayah(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('juz: $juz, ')
          ..write('hizb: $hizb, ')
          ..write('rub: $rub, ')
          ..write('manzil: $manzil, ')
          ..write('sajdaType: $sajdaType, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textSearch: $textSearch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    surah,
    ayah,
    page,
    juz,
    hizb,
    rub,
    manzil,
    sajdaType,
    textUthmani,
    textSearch,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ayah &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.page == this.page &&
          other.juz == this.juz &&
          other.hizb == this.hizb &&
          other.rub == this.rub &&
          other.manzil == this.manzil &&
          other.sajdaType == this.sajdaType &&
          other.textUthmani == this.textUthmani &&
          other.textSearch == this.textSearch);
}

class AyahsCompanion extends UpdateCompanion<Ayah> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> page;
  final Value<int> juz;
  final Value<int?> hizb;
  final Value<int?> rub;
  final Value<int> manzil;
  final Value<String?> sajdaType;
  final Value<String> textUthmani;
  final Value<String> textSearch;
  const AyahsCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.page = const Value.absent(),
    this.juz = const Value.absent(),
    this.hizb = const Value.absent(),
    this.rub = const Value.absent(),
    this.manzil = const Value.absent(),
    this.sajdaType = const Value.absent(),
    this.textUthmani = const Value.absent(),
    this.textSearch = const Value.absent(),
  });
  AyahsCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    required int page,
    required int juz,
    this.hizb = const Value.absent(),
    this.rub = const Value.absent(),
    required int manzil,
    this.sajdaType = const Value.absent(),
    required String textUthmani,
    required String textSearch,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       page = Value(page),
       juz = Value(juz),
       manzil = Value(manzil),
       textUthmani = Value(textUthmani),
       textSearch = Value(textSearch);
  static Insertable<Ayah> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? page,
    Expression<int>? juz,
    Expression<int>? hizb,
    Expression<int>? rub,
    Expression<int>? manzil,
    Expression<String>? sajdaType,
    Expression<String>? textUthmani,
    Expression<String>? textSearch,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (page != null) 'page': page,
      if (juz != null) 'juz': juz,
      if (hizb != null) 'hizb': hizb,
      if (rub != null) 'rub': rub,
      if (manzil != null) 'manzil': manzil,
      if (sajdaType != null) 'sajda_type': sajdaType,
      if (textUthmani != null) 'text_uthmani': textUthmani,
      if (textSearch != null) 'text_search': textSearch,
    });
  }

  AyahsCompanion copyWith({
    Value<int>? id,
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? page,
    Value<int>? juz,
    Value<int?>? hizb,
    Value<int?>? rub,
    Value<int>? manzil,
    Value<String?>? sajdaType,
    Value<String>? textUthmani,
    Value<String>? textSearch,
  }) {
    return AyahsCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      page: page ?? this.page,
      juz: juz ?? this.juz,
      hizb: hizb ?? this.hizb,
      rub: rub ?? this.rub,
      manzil: manzil ?? this.manzil,
      sajdaType: sajdaType ?? this.sajdaType,
      textUthmani: textUthmani ?? this.textUthmani,
      textSearch: textSearch ?? this.textSearch,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (juz.present) {
      map['juz'] = Variable<int>(juz.value);
    }
    if (hizb.present) {
      map['hizb'] = Variable<int>(hizb.value);
    }
    if (rub.present) {
      map['rub'] = Variable<int>(rub.value);
    }
    if (manzil.present) {
      map['manzil'] = Variable<int>(manzil.value);
    }
    if (sajdaType.present) {
      map['sajda_type'] = Variable<String>(sajdaType.value);
    }
    if (textUthmani.present) {
      map['text_uthmani'] = Variable<String>(textUthmani.value);
    }
    if (textSearch.present) {
      map['text_search'] = Variable<String>(textSearch.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahsCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('juz: $juz, ')
          ..write('hizb: $hizb, ')
          ..write('rub: $rub, ')
          ..write('manzil: $manzil, ')
          ..write('sajdaType: $sajdaType, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textSearch: $textSearch')
          ..write(')'))
        .toString();
  }
}

class $PageLinesTable extends PageLines
    with TableInfo<$PageLinesTable, PageLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineNoMeta = const VerificationMeta('lineNo');
  @override
  late final GeneratedColumn<int> lineNo = GeneratedColumn<int>(
    'line_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTypeMeta = const VerificationMeta(
    'lineType',
  );
  @override
  late final GeneratedColumn<String> lineType = GeneratedColumn<String>(
    'line_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCenteredMeta = const VerificationMeta(
    'isCentered',
  );
  @override
  late final GeneratedColumn<int> isCentered = GeneratedColumn<int>(
    'is_centered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstWordIdMeta = const VerificationMeta(
    'firstWordId',
  );
  @override
  late final GeneratedColumn<int> firstWordId = GeneratedColumn<int>(
    'first_word_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastWordIdMeta = const VerificationMeta(
    'lastWordId',
  );
  @override
  late final GeneratedColumn<int> lastWordId = GeneratedColumn<int>(
    'last_word_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surahRefMeta = const VerificationMeta(
    'surahRef',
  );
  @override
  late final GeneratedColumn<int> surahRef = GeneratedColumn<int>(
    'surah_ref',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    page,
    lineNo,
    lineType,
    isCentered,
    firstWordId,
    lastWordId,
    surahRef,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line_no')) {
      context.handle(
        _lineNoMeta,
        lineNo.isAcceptableOrUnknown(data['line_no']!, _lineNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNoMeta);
    }
    if (data.containsKey('line_type')) {
      context.handle(
        _lineTypeMeta,
        lineType.isAcceptableOrUnknown(data['line_type']!, _lineTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTypeMeta);
    }
    if (data.containsKey('is_centered')) {
      context.handle(
        _isCenteredMeta,
        isCentered.isAcceptableOrUnknown(data['is_centered']!, _isCenteredMeta),
      );
    } else if (isInserting) {
      context.missing(_isCenteredMeta);
    }
    if (data.containsKey('first_word_id')) {
      context.handle(
        _firstWordIdMeta,
        firstWordId.isAcceptableOrUnknown(
          data['first_word_id']!,
          _firstWordIdMeta,
        ),
      );
    }
    if (data.containsKey('last_word_id')) {
      context.handle(
        _lastWordIdMeta,
        lastWordId.isAcceptableOrUnknown(
          data['last_word_id']!,
          _lastWordIdMeta,
        ),
      );
    }
    if (data.containsKey('surah_ref')) {
      context.handle(
        _surahRefMeta,
        surahRef.isAcceptableOrUnknown(data['surah_ref']!, _surahRefMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page, lineNo};
  @override
  PageLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageLine(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      lineNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_no'],
      )!,
      lineType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_type'],
      )!,
      isCentered: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_centered'],
      )!,
      firstWordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_word_id'],
      ),
      lastWordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_word_id'],
      ),
      surahRef: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_ref'],
      ),
    );
  }

  @override
  $PageLinesTable createAlias(String alias) {
    return $PageLinesTable(attachedDatabase, alias);
  }
}

class PageLine extends DataClass implements Insertable<PageLine> {
  final int page;
  final int lineNo;
  final String lineType;
  final int isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahRef;
  const PageLine({
    required this.page,
    required this.lineNo,
    required this.lineType,
    required this.isCentered,
    this.firstWordId,
    this.lastWordId,
    this.surahRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['line_no'] = Variable<int>(lineNo);
    map['line_type'] = Variable<String>(lineType);
    map['is_centered'] = Variable<int>(isCentered);
    if (!nullToAbsent || firstWordId != null) {
      map['first_word_id'] = Variable<int>(firstWordId);
    }
    if (!nullToAbsent || lastWordId != null) {
      map['last_word_id'] = Variable<int>(lastWordId);
    }
    if (!nullToAbsent || surahRef != null) {
      map['surah_ref'] = Variable<int>(surahRef);
    }
    return map;
  }

  PageLinesCompanion toCompanion(bool nullToAbsent) {
    return PageLinesCompanion(
      page: Value(page),
      lineNo: Value(lineNo),
      lineType: Value(lineType),
      isCentered: Value(isCentered),
      firstWordId: firstWordId == null && nullToAbsent
          ? const Value.absent()
          : Value(firstWordId),
      lastWordId: lastWordId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWordId),
      surahRef: surahRef == null && nullToAbsent
          ? const Value.absent()
          : Value(surahRef),
    );
  }

  factory PageLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageLine(
      page: serializer.fromJson<int>(json['page']),
      lineNo: serializer.fromJson<int>(json['lineNo']),
      lineType: serializer.fromJson<String>(json['lineType']),
      isCentered: serializer.fromJson<int>(json['isCentered']),
      firstWordId: serializer.fromJson<int?>(json['firstWordId']),
      lastWordId: serializer.fromJson<int?>(json['lastWordId']),
      surahRef: serializer.fromJson<int?>(json['surahRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'lineNo': serializer.toJson<int>(lineNo),
      'lineType': serializer.toJson<String>(lineType),
      'isCentered': serializer.toJson<int>(isCentered),
      'firstWordId': serializer.toJson<int?>(firstWordId),
      'lastWordId': serializer.toJson<int?>(lastWordId),
      'surahRef': serializer.toJson<int?>(surahRef),
    };
  }

  PageLine copyWith({
    int? page,
    int? lineNo,
    String? lineType,
    int? isCentered,
    Value<int?> firstWordId = const Value.absent(),
    Value<int?> lastWordId = const Value.absent(),
    Value<int?> surahRef = const Value.absent(),
  }) => PageLine(
    page: page ?? this.page,
    lineNo: lineNo ?? this.lineNo,
    lineType: lineType ?? this.lineType,
    isCentered: isCentered ?? this.isCentered,
    firstWordId: firstWordId.present ? firstWordId.value : this.firstWordId,
    lastWordId: lastWordId.present ? lastWordId.value : this.lastWordId,
    surahRef: surahRef.present ? surahRef.value : this.surahRef,
  );
  PageLine copyWithCompanion(PageLinesCompanion data) {
    return PageLine(
      page: data.page.present ? data.page.value : this.page,
      lineNo: data.lineNo.present ? data.lineNo.value : this.lineNo,
      lineType: data.lineType.present ? data.lineType.value : this.lineType,
      isCentered: data.isCentered.present
          ? data.isCentered.value
          : this.isCentered,
      firstWordId: data.firstWordId.present
          ? data.firstWordId.value
          : this.firstWordId,
      lastWordId: data.lastWordId.present
          ? data.lastWordId.value
          : this.lastWordId,
      surahRef: data.surahRef.present ? data.surahRef.value : this.surahRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageLine(')
          ..write('page: $page, ')
          ..write('lineNo: $lineNo, ')
          ..write('lineType: $lineType, ')
          ..write('isCentered: $isCentered, ')
          ..write('firstWordId: $firstWordId, ')
          ..write('lastWordId: $lastWordId, ')
          ..write('surahRef: $surahRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    page,
    lineNo,
    lineType,
    isCentered,
    firstWordId,
    lastWordId,
    surahRef,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageLine &&
          other.page == this.page &&
          other.lineNo == this.lineNo &&
          other.lineType == this.lineType &&
          other.isCentered == this.isCentered &&
          other.firstWordId == this.firstWordId &&
          other.lastWordId == this.lastWordId &&
          other.surahRef == this.surahRef);
}

class PageLinesCompanion extends UpdateCompanion<PageLine> {
  final Value<int> page;
  final Value<int> lineNo;
  final Value<String> lineType;
  final Value<int> isCentered;
  final Value<int?> firstWordId;
  final Value<int?> lastWordId;
  final Value<int?> surahRef;
  final Value<int> rowid;
  const PageLinesCompanion({
    this.page = const Value.absent(),
    this.lineNo = const Value.absent(),
    this.lineType = const Value.absent(),
    this.isCentered = const Value.absent(),
    this.firstWordId = const Value.absent(),
    this.lastWordId = const Value.absent(),
    this.surahRef = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageLinesCompanion.insert({
    required int page,
    required int lineNo,
    required String lineType,
    required int isCentered,
    this.firstWordId = const Value.absent(),
    this.lastWordId = const Value.absent(),
    this.surahRef = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : page = Value(page),
       lineNo = Value(lineNo),
       lineType = Value(lineType),
       isCentered = Value(isCentered);
  static Insertable<PageLine> custom({
    Expression<int>? page,
    Expression<int>? lineNo,
    Expression<String>? lineType,
    Expression<int>? isCentered,
    Expression<int>? firstWordId,
    Expression<int>? lastWordId,
    Expression<int>? surahRef,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (lineNo != null) 'line_no': lineNo,
      if (lineType != null) 'line_type': lineType,
      if (isCentered != null) 'is_centered': isCentered,
      if (firstWordId != null) 'first_word_id': firstWordId,
      if (lastWordId != null) 'last_word_id': lastWordId,
      if (surahRef != null) 'surah_ref': surahRef,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageLinesCompanion copyWith({
    Value<int>? page,
    Value<int>? lineNo,
    Value<String>? lineType,
    Value<int>? isCentered,
    Value<int?>? firstWordId,
    Value<int?>? lastWordId,
    Value<int?>? surahRef,
    Value<int>? rowid,
  }) {
    return PageLinesCompanion(
      page: page ?? this.page,
      lineNo: lineNo ?? this.lineNo,
      lineType: lineType ?? this.lineType,
      isCentered: isCentered ?? this.isCentered,
      firstWordId: firstWordId ?? this.firstWordId,
      lastWordId: lastWordId ?? this.lastWordId,
      surahRef: surahRef ?? this.surahRef,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (lineNo.present) {
      map['line_no'] = Variable<int>(lineNo.value);
    }
    if (lineType.present) {
      map['line_type'] = Variable<String>(lineType.value);
    }
    if (isCentered.present) {
      map['is_centered'] = Variable<int>(isCentered.value);
    }
    if (firstWordId.present) {
      map['first_word_id'] = Variable<int>(firstWordId.value);
    }
    if (lastWordId.present) {
      map['last_word_id'] = Variable<int>(lastWordId.value);
    }
    if (surahRef.present) {
      map['surah_ref'] = Variable<int>(surahRef.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageLinesCompanion(')
          ..write('page: $page, ')
          ..write('lineNo: $lineNo, ')
          ..write('lineType: $lineType, ')
          ..write('isCentered: $isCentered, ')
          ..write('firstWordId: $firstWordId, ')
          ..write('lastWordId: $lastWordId, ')
          ..write('surahRef: $surahRef, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineNoMeta = const VerificationMeta('lineNo');
  @override
  late final GeneratedColumn<int> lineNo = GeneratedColumn<int>(
    'line_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _glyphMeta = const VerificationMeta('glyph');
  @override
  late final GeneratedColumn<String> glyph = GeneratedColumn<String>(
    'glyph',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charTypeMeta = const VerificationMeta(
    'charType',
  );
  @override
  late final GeneratedColumn<String> charType = GeneratedColumn<String>(
    'char_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ayahId,
    position,
    page,
    lineNo,
    glyph,
    charType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
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
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line_no')) {
      context.handle(
        _lineNoMeta,
        lineNo.isAcceptableOrUnknown(data['line_no']!, _lineNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNoMeta);
    }
    if (data.containsKey('glyph')) {
      context.handle(
        _glyphMeta,
        glyph.isAcceptableOrUnknown(data['glyph']!, _glyphMeta),
      );
    } else if (isInserting) {
      context.missing(_glyphMeta);
    }
    if (data.containsKey('char_type')) {
      context.handle(
        _charTypeMeta,
        charType.isAcceptableOrUnknown(data['char_type']!, _charTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_charTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      lineNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_no'],
      )!,
      glyph: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glyph'],
      )!,
      charType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}char_type'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;
  final int ayahId;
  final int position;
  final int page;
  final int lineNo;
  final String glyph;
  final String charType;
  const Word({
    required this.id,
    required this.ayahId,
    required this.position,
    required this.page,
    required this.lineNo,
    required this.glyph,
    required this.charType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['position'] = Variable<int>(position);
    map['page'] = Variable<int>(page);
    map['line_no'] = Variable<int>(lineNo);
    map['glyph'] = Variable<String>(glyph);
    map['char_type'] = Variable<String>(charType);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      position: Value(position),
      page: Value(page),
      lineNo: Value(lineNo),
      glyph: Value(glyph),
      charType: Value(charType),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      position: serializer.fromJson<int>(json['position']),
      page: serializer.fromJson<int>(json['page']),
      lineNo: serializer.fromJson<int>(json['lineNo']),
      glyph: serializer.fromJson<String>(json['glyph']),
      charType: serializer.fromJson<String>(json['charType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'position': serializer.toJson<int>(position),
      'page': serializer.toJson<int>(page),
      'lineNo': serializer.toJson<int>(lineNo),
      'glyph': serializer.toJson<String>(glyph),
      'charType': serializer.toJson<String>(charType),
    };
  }

  Word copyWith({
    int? id,
    int? ayahId,
    int? position,
    int? page,
    int? lineNo,
    String? glyph,
    String? charType,
  }) => Word(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    position: position ?? this.position,
    page: page ?? this.page,
    lineNo: lineNo ?? this.lineNo,
    glyph: glyph ?? this.glyph,
    charType: charType ?? this.charType,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      position: data.position.present ? data.position.value : this.position,
      page: data.page.present ? data.page.value : this.page,
      lineNo: data.lineNo.present ? data.lineNo.value : this.lineNo,
      glyph: data.glyph.present ? data.glyph.value : this.glyph,
      charType: data.charType.present ? data.charType.value : this.charType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('position: $position, ')
          ..write('page: $page, ')
          ..write('lineNo: $lineNo, ')
          ..write('glyph: $glyph, ')
          ..write('charType: $charType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ayahId, position, page, lineNo, glyph, charType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.position == this.position &&
          other.page == this.page &&
          other.lineNo == this.lineNo &&
          other.glyph == this.glyph &&
          other.charType == this.charType);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<int> position;
  final Value<int> page;
  final Value<int> lineNo;
  final Value<String> glyph;
  final Value<String> charType;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.position = const Value.absent(),
    this.page = const Value.absent(),
    this.lineNo = const Value.absent(),
    this.glyph = const Value.absent(),
    this.charType = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required int position,
    required int page,
    required int lineNo,
    required String glyph,
    required String charType,
  }) : ayahId = Value(ayahId),
       position = Value(position),
       page = Value(page),
       lineNo = Value(lineNo),
       glyph = Value(glyph),
       charType = Value(charType);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<int>? position,
    Expression<int>? page,
    Expression<int>? lineNo,
    Expression<String>? glyph,
    Expression<String>? charType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (position != null) 'position': position,
      if (page != null) 'page': page,
      if (lineNo != null) 'line_no': lineNo,
      if (glyph != null) 'glyph': glyph,
      if (charType != null) 'char_type': charType,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<int>? position,
    Value<int>? page,
    Value<int>? lineNo,
    Value<String>? glyph,
    Value<String>? charType,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      position: position ?? this.position,
      page: page ?? this.page,
      lineNo: lineNo ?? this.lineNo,
      glyph: glyph ?? this.glyph,
      charType: charType ?? this.charType,
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
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (lineNo.present) {
      map['line_no'] = Variable<int>(lineNo.value);
    }
    if (glyph.present) {
      map['glyph'] = Variable<String>(glyph.value);
    }
    if (charType.present) {
      map['char_type'] = Variable<String>(charType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('position: $position, ')
          ..write('page: $page, ')
          ..write('lineNo: $lineNo, ')
          ..write('glyph: $glyph, ')
          ..write('charType: $charType')
          ..write(')'))
        .toString();
  }
}

class $TafsirsTable extends Tafsirs with TableInfo<$TafsirsTable, Tafsir> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TafsirsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _editionMeta = const VerificationMeta(
    'edition',
  );
  @override
  late final GeneratedColumn<String> edition = GeneratedColumn<String>(
    'edition',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [id, ayahId, edition, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tafsirs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tafsir> instance, {
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
    if (data.containsKey('edition')) {
      context.handle(
        _editionMeta,
        edition.isAcceptableOrUnknown(data['edition']!, _editionMeta),
      );
    } else if (isInserting) {
      context.missing(_editionMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tafsir map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tafsir(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      edition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $TafsirsTable createAlias(String alias) {
    return $TafsirsTable(attachedDatabase, alias);
  }
}

class Tafsir extends DataClass implements Insertable<Tafsir> {
  final int id;
  final int ayahId;
  final String edition;
  final String content;
  const Tafsir({
    required this.id,
    required this.ayahId,
    required this.edition,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['edition'] = Variable<String>(edition);
    map['text'] = Variable<String>(content);
    return map;
  }

  TafsirsCompanion toCompanion(bool nullToAbsent) {
    return TafsirsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      edition: Value(edition),
      content: Value(content),
    );
  }

  factory Tafsir.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tafsir(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      edition: serializer.fromJson<String>(json['edition']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'edition': serializer.toJson<String>(edition),
      'content': serializer.toJson<String>(content),
    };
  }

  Tafsir copyWith({int? id, int? ayahId, String? edition, String? content}) =>
      Tafsir(
        id: id ?? this.id,
        ayahId: ayahId ?? this.ayahId,
        edition: edition ?? this.edition,
        content: content ?? this.content,
      );
  Tafsir copyWithCompanion(TafsirsCompanion data) {
    return Tafsir(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      edition: data.edition.present ? data.edition.value : this.edition,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tafsir(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('edition: $edition, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ayahId, edition, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tafsir &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.edition == this.edition &&
          other.content == this.content);
}

class TafsirsCompanion extends UpdateCompanion<Tafsir> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<String> edition;
  final Value<String> content;
  const TafsirsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.edition = const Value.absent(),
    this.content = const Value.absent(),
  });
  TafsirsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required String edition,
    required String content,
  }) : ayahId = Value(ayahId),
       edition = Value(edition),
       content = Value(content);
  static Insertable<Tafsir> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<String>? edition,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (edition != null) 'edition': edition,
      if (content != null) 'text': content,
    });
  }

  TafsirsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<String>? edition,
    Value<String>? content,
  }) {
    return TafsirsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      edition: edition ?? this.edition,
      content: content ?? this.content,
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
    if (edition.present) {
      map['edition'] = Variable<String>(edition.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TafsirsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('edition: $edition, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $TranslationsTable extends Translations
    with TableInfo<$TranslationsTable, Translation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _editionMeta = const VerificationMeta(
    'edition',
  );
  @override
  late final GeneratedColumn<String> edition = GeneratedColumn<String>(
    'edition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [id, ayahId, edition, lang, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Translation> instance, {
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
    if (data.containsKey('edition')) {
      context.handle(
        _editionMeta,
        edition.isAcceptableOrUnknown(data['edition']!, _editionMeta),
      );
    } else if (isInserting) {
      context.missing(_editionMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Translation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Translation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      edition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $TranslationsTable createAlias(String alias) {
    return $TranslationsTable(attachedDatabase, alias);
  }
}

class Translation extends DataClass implements Insertable<Translation> {
  final int id;
  final int ayahId;
  final String edition;
  final String lang;
  final String content;
  const Translation({
    required this.id,
    required this.ayahId,
    required this.edition,
    required this.lang,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['edition'] = Variable<String>(edition);
    map['lang'] = Variable<String>(lang);
    map['text'] = Variable<String>(content);
    return map;
  }

  TranslationsCompanion toCompanion(bool nullToAbsent) {
    return TranslationsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      edition: Value(edition),
      lang: Value(lang),
      content: Value(content),
    );
  }

  factory Translation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Translation(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      edition: serializer.fromJson<String>(json['edition']),
      lang: serializer.fromJson<String>(json['lang']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'edition': serializer.toJson<String>(edition),
      'lang': serializer.toJson<String>(lang),
      'content': serializer.toJson<String>(content),
    };
  }

  Translation copyWith({
    int? id,
    int? ayahId,
    String? edition,
    String? lang,
    String? content,
  }) => Translation(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    edition: edition ?? this.edition,
    lang: lang ?? this.lang,
    content: content ?? this.content,
  );
  Translation copyWithCompanion(TranslationsCompanion data) {
    return Translation(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      edition: data.edition.present ? data.edition.value : this.edition,
      lang: data.lang.present ? data.lang.value : this.lang,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Translation(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('edition: $edition, ')
          ..write('lang: $lang, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ayahId, edition, lang, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Translation &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.edition == this.edition &&
          other.lang == this.lang &&
          other.content == this.content);
}

class TranslationsCompanion extends UpdateCompanion<Translation> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<String> edition;
  final Value<String> lang;
  final Value<String> content;
  const TranslationsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.edition = const Value.absent(),
    this.lang = const Value.absent(),
    this.content = const Value.absent(),
  });
  TranslationsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required String edition,
    required String lang,
    required String content,
  }) : ayahId = Value(ayahId),
       edition = Value(edition),
       lang = Value(lang),
       content = Value(content);
  static Insertable<Translation> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<String>? edition,
    Expression<String>? lang,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (edition != null) 'edition': edition,
      if (lang != null) 'lang': lang,
      if (content != null) 'text': content,
    });
  }

  TranslationsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<String>? edition,
    Value<String>? lang,
    Value<String>? content,
  }) {
    return TranslationsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      edition: edition ?? this.edition,
      lang: lang ?? this.lang,
      content: content ?? this.content,
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
    if (edition.present) {
      map['edition'] = Variable<String>(edition.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('edition: $edition, ')
          ..write('lang: $lang, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

abstract class _$QuranDatabase extends GeneratedDatabase {
  _$QuranDatabase(QueryExecutor e) : super(e);
  $QuranDatabaseManager get managers => $QuranDatabaseManager(this);
  late final $SurahsTable surahs = $SurahsTable(this);
  late final $AyahsTable ayahs = $AyahsTable(this);
  late final $PageLinesTable pageLines = $PageLinesTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $TafsirsTable tafsirs = $TafsirsTable(this);
  late final $TranslationsTable translations = $TranslationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surahs,
    ayahs,
    pageLines,
    words,
    tafsirs,
    translations,
  ];
}

typedef $$SurahsTableCreateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> id,
      required String nameAr,
      required String nameArPlain,
      required String nameEn,
      required String revelationPlace,
      Value<int?> revelationOrder,
      required int ayahCount,
      required int startPage,
      required int bismillahPre,
    });
typedef $$SurahsTableUpdateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> id,
      Value<String> nameAr,
      Value<String> nameArPlain,
      Value<String> nameEn,
      Value<String> revelationPlace,
      Value<int?> revelationOrder,
      Value<int> ayahCount,
      Value<int> startPage,
      Value<int> bismillahPre,
    });

class $$SurahsTableFilterComposer
    extends Composer<_$QuranDatabase, $SurahsTable> {
  $$SurahsTableFilterComposer({
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

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameArPlain => $composableBuilder(
    column: $table.nameArPlain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revelationPlace => $composableBuilder(
    column: $table.revelationPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revelationOrder => $composableBuilder(
    column: $table.revelationOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bismillahPre => $composableBuilder(
    column: $table.bismillahPre,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SurahsTableOrderingComposer
    extends Composer<_$QuranDatabase, $SurahsTable> {
  $$SurahsTableOrderingComposer({
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

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameArPlain => $composableBuilder(
    column: $table.nameArPlain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revelationPlace => $composableBuilder(
    column: $table.revelationPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revelationOrder => $composableBuilder(
    column: $table.revelationOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bismillahPre => $composableBuilder(
    column: $table.bismillahPre,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurahsTableAnnotationComposer
    extends Composer<_$QuranDatabase, $SurahsTable> {
  $$SurahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameArPlain => $composableBuilder(
    column: $table.nameArPlain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get revelationPlace => $composableBuilder(
    column: $table.revelationPlace,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revelationOrder => $composableBuilder(
    column: $table.revelationOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get bismillahPre => $composableBuilder(
    column: $table.bismillahPre,
    builder: (column) => column,
  );
}

class $$SurahsTableTableManager
    extends
        RootTableManager<
          _$QuranDatabase,
          $SurahsTable,
          Surah,
          $$SurahsTableFilterComposer,
          $$SurahsTableOrderingComposer,
          $$SurahsTableAnnotationComposer,
          $$SurahsTableCreateCompanionBuilder,
          $$SurahsTableUpdateCompanionBuilder,
          (Surah, BaseReferences<_$QuranDatabase, $SurahsTable, Surah>),
          Surah,
          PrefetchHooks Function()
        > {
  $$SurahsTableTableManager(_$QuranDatabase db, $SurahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameArPlain = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> revelationPlace = const Value.absent(),
                Value<int?> revelationOrder = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int> bismillahPre = const Value.absent(),
              }) => SurahsCompanion(
                id: id,
                nameAr: nameAr,
                nameArPlain: nameArPlain,
                nameEn: nameEn,
                revelationPlace: revelationPlace,
                revelationOrder: revelationOrder,
                ayahCount: ayahCount,
                startPage: startPage,
                bismillahPre: bismillahPre,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nameAr,
                required String nameArPlain,
                required String nameEn,
                required String revelationPlace,
                Value<int?> revelationOrder = const Value.absent(),
                required int ayahCount,
                required int startPage,
                required int bismillahPre,
              }) => SurahsCompanion.insert(
                id: id,
                nameAr: nameAr,
                nameArPlain: nameArPlain,
                nameEn: nameEn,
                revelationPlace: revelationPlace,
                revelationOrder: revelationOrder,
                ayahCount: ayahCount,
                startPage: startPage,
                bismillahPre: bismillahPre,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SurahsTableProcessedTableManager =
    ProcessedTableManager<
      _$QuranDatabase,
      $SurahsTable,
      Surah,
      $$SurahsTableFilterComposer,
      $$SurahsTableOrderingComposer,
      $$SurahsTableAnnotationComposer,
      $$SurahsTableCreateCompanionBuilder,
      $$SurahsTableUpdateCompanionBuilder,
      (Surah, BaseReferences<_$QuranDatabase, $SurahsTable, Surah>),
      Surah,
      PrefetchHooks Function()
    >;
typedef $$AyahsTableCreateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      required int surah,
      required int ayah,
      required int page,
      required int juz,
      Value<int?> hizb,
      Value<int?> rub,
      required int manzil,
      Value<String?> sajdaType,
      required String textUthmani,
      required String textSearch,
    });
typedef $$AyahsTableUpdateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      Value<int> surah,
      Value<int> ayah,
      Value<int> page,
      Value<int> juz,
      Value<int?> hizb,
      Value<int?> rub,
      Value<int> manzil,
      Value<String?> sajdaType,
      Value<String> textUthmani,
      Value<String> textSearch,
    });

class $$AyahsTableFilterComposer
    extends Composer<_$QuranDatabase, $AyahsTable> {
  $$AyahsTableFilterComposer({
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

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hizb => $composableBuilder(
    column: $table.hizb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rub => $composableBuilder(
    column: $table.rub,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get manzil => $composableBuilder(
    column: $table.manzil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sajdaType => $composableBuilder(
    column: $table.sajdaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahsTableOrderingComposer
    extends Composer<_$QuranDatabase, $AyahsTable> {
  $$AyahsTableOrderingComposer({
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

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hizb => $composableBuilder(
    column: $table.hizb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rub => $composableBuilder(
    column: $table.rub,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get manzil => $composableBuilder(
    column: $table.manzil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sajdaType => $composableBuilder(
    column: $table.sajdaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahsTableAnnotationComposer
    extends Composer<_$QuranDatabase, $AyahsTable> {
  $$AyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get juz =>
      $composableBuilder(column: $table.juz, builder: (column) => column);

  GeneratedColumn<int> get hizb =>
      $composableBuilder(column: $table.hizb, builder: (column) => column);

  GeneratedColumn<int> get rub =>
      $composableBuilder(column: $table.rub, builder: (column) => column);

  GeneratedColumn<int> get manzil =>
      $composableBuilder(column: $table.manzil, builder: (column) => column);

  GeneratedColumn<String> get sajdaType =>
      $composableBuilder(column: $table.sajdaType, builder: (column) => column);

  GeneratedColumn<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => column,
  );
}

class $$AyahsTableTableManager
    extends
        RootTableManager<
          _$QuranDatabase,
          $AyahsTable,
          Ayah,
          $$AyahsTableFilterComposer,
          $$AyahsTableOrderingComposer,
          $$AyahsTableAnnotationComposer,
          $$AyahsTableCreateCompanionBuilder,
          $$AyahsTableUpdateCompanionBuilder,
          (Ayah, BaseReferences<_$QuranDatabase, $AyahsTable, Ayah>),
          Ayah,
          PrefetchHooks Function()
        > {
  $$AyahsTableTableManager(_$QuranDatabase db, $AyahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> juz = const Value.absent(),
                Value<int?> hizb = const Value.absent(),
                Value<int?> rub = const Value.absent(),
                Value<int> manzil = const Value.absent(),
                Value<String?> sajdaType = const Value.absent(),
                Value<String> textUthmani = const Value.absent(),
                Value<String> textSearch = const Value.absent(),
              }) => AyahsCompanion(
                id: id,
                surah: surah,
                ayah: ayah,
                page: page,
                juz: juz,
                hizb: hizb,
                rub: rub,
                manzil: manzil,
                sajdaType: sajdaType,
                textUthmani: textUthmani,
                textSearch: textSearch,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surah,
                required int ayah,
                required int page,
                required int juz,
                Value<int?> hizb = const Value.absent(),
                Value<int?> rub = const Value.absent(),
                required int manzil,
                Value<String?> sajdaType = const Value.absent(),
                required String textUthmani,
                required String textSearch,
              }) => AyahsCompanion.insert(
                id: id,
                surah: surah,
                ayah: ayah,
                page: page,
                juz: juz,
                hizb: hizb,
                rub: rub,
                manzil: manzil,
                sajdaType: sajdaType,
                textUthmani: textUthmani,
                textSearch: textSearch,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyahsTableProcessedTableManager =
    ProcessedTableManager<
      _$QuranDatabase,
      $AyahsTable,
      Ayah,
      $$AyahsTableFilterComposer,
      $$AyahsTableOrderingComposer,
      $$AyahsTableAnnotationComposer,
      $$AyahsTableCreateCompanionBuilder,
      $$AyahsTableUpdateCompanionBuilder,
      (Ayah, BaseReferences<_$QuranDatabase, $AyahsTable, Ayah>),
      Ayah,
      PrefetchHooks Function()
    >;
typedef $$PageLinesTableCreateCompanionBuilder =
    PageLinesCompanion Function({
      required int page,
      required int lineNo,
      required String lineType,
      required int isCentered,
      Value<int?> firstWordId,
      Value<int?> lastWordId,
      Value<int?> surahRef,
      Value<int> rowid,
    });
typedef $$PageLinesTableUpdateCompanionBuilder =
    PageLinesCompanion Function({
      Value<int> page,
      Value<int> lineNo,
      Value<String> lineType,
      Value<int> isCentered,
      Value<int?> firstWordId,
      Value<int?> lastWordId,
      Value<int?> surahRef,
      Value<int> rowid,
    });

class $$PageLinesTableFilterComposer
    extends Composer<_$QuranDatabase, $PageLinesTable> {
  $$PageLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineType => $composableBuilder(
    column: $table.lineType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isCentered => $composableBuilder(
    column: $table.isCentered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstWordId => $composableBuilder(
    column: $table.firstWordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastWordId => $composableBuilder(
    column: $table.lastWordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surahRef => $composableBuilder(
    column: $table.surahRef,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PageLinesTableOrderingComposer
    extends Composer<_$QuranDatabase, $PageLinesTable> {
  $$PageLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineType => $composableBuilder(
    column: $table.lineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isCentered => $composableBuilder(
    column: $table.isCentered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstWordId => $composableBuilder(
    column: $table.firstWordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastWordId => $composableBuilder(
    column: $table.lastWordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surahRef => $composableBuilder(
    column: $table.surahRef,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PageLinesTableAnnotationComposer
    extends Composer<_$QuranDatabase, $PageLinesTable> {
  $$PageLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get lineNo =>
      $composableBuilder(column: $table.lineNo, builder: (column) => column);

  GeneratedColumn<String> get lineType =>
      $composableBuilder(column: $table.lineType, builder: (column) => column);

  GeneratedColumn<int> get isCentered => $composableBuilder(
    column: $table.isCentered,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstWordId => $composableBuilder(
    column: $table.firstWordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastWordId => $composableBuilder(
    column: $table.lastWordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get surahRef =>
      $composableBuilder(column: $table.surahRef, builder: (column) => column);
}

class $$PageLinesTableTableManager
    extends
        RootTableManager<
          _$QuranDatabase,
          $PageLinesTable,
          PageLine,
          $$PageLinesTableFilterComposer,
          $$PageLinesTableOrderingComposer,
          $$PageLinesTableAnnotationComposer,
          $$PageLinesTableCreateCompanionBuilder,
          $$PageLinesTableUpdateCompanionBuilder,
          (
            PageLine,
            BaseReferences<_$QuranDatabase, $PageLinesTable, PageLine>,
          ),
          PageLine,
          PrefetchHooks Function()
        > {
  $$PageLinesTableTableManager(_$QuranDatabase db, $PageLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> lineNo = const Value.absent(),
                Value<String> lineType = const Value.absent(),
                Value<int> isCentered = const Value.absent(),
                Value<int?> firstWordId = const Value.absent(),
                Value<int?> lastWordId = const Value.absent(),
                Value<int?> surahRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageLinesCompanion(
                page: page,
                lineNo: lineNo,
                lineType: lineType,
                isCentered: isCentered,
                firstWordId: firstWordId,
                lastWordId: lastWordId,
                surahRef: surahRef,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int page,
                required int lineNo,
                required String lineType,
                required int isCentered,
                Value<int?> firstWordId = const Value.absent(),
                Value<int?> lastWordId = const Value.absent(),
                Value<int?> surahRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageLinesCompanion.insert(
                page: page,
                lineNo: lineNo,
                lineType: lineType,
                isCentered: isCentered,
                firstWordId: firstWordId,
                lastWordId: lastWordId,
                surahRef: surahRef,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PageLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$QuranDatabase,
      $PageLinesTable,
      PageLine,
      $$PageLinesTableFilterComposer,
      $$PageLinesTableOrderingComposer,
      $$PageLinesTableAnnotationComposer,
      $$PageLinesTableCreateCompanionBuilder,
      $$PageLinesTableUpdateCompanionBuilder,
      (PageLine, BaseReferences<_$QuranDatabase, $PageLinesTable, PageLine>),
      PageLine,
      PrefetchHooks Function()
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required int ayahId,
      required int position,
      required int page,
      required int lineNo,
      required String glyph,
      required String charType,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<int> position,
      Value<int> page,
      Value<int> lineNo,
      Value<String> glyph,
      Value<String> charType,
    });

class $$WordsTableFilterComposer
    extends Composer<_$QuranDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get charType => $composableBuilder(
    column: $table.charType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableOrderingComposer
    extends Composer<_$QuranDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get charType => $composableBuilder(
    column: $table.charType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$QuranDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
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

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get lineNo =>
      $composableBuilder(column: $table.lineNo, builder: (column) => column);

  GeneratedColumn<String> get glyph =>
      $composableBuilder(column: $table.glyph, builder: (column) => column);

  GeneratedColumn<String> get charType =>
      $composableBuilder(column: $table.charType, builder: (column) => column);
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$QuranDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, BaseReferences<_$QuranDatabase, $WordsTable, Word>),
          Word,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$QuranDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> lineNo = const Value.absent(),
                Value<String> glyph = const Value.absent(),
                Value<String> charType = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                ayahId: ayahId,
                position: position,
                page: page,
                lineNo: lineNo,
                glyph: glyph,
                charType: charType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                required int position,
                required int page,
                required int lineNo,
                required String glyph,
                required String charType,
              }) => WordsCompanion.insert(
                id: id,
                ayahId: ayahId,
                position: position,
                page: page,
                lineNo: lineNo,
                glyph: glyph,
                charType: charType,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$QuranDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, BaseReferences<_$QuranDatabase, $WordsTable, Word>),
      Word,
      PrefetchHooks Function()
    >;
typedef $$TafsirsTableCreateCompanionBuilder =
    TafsirsCompanion Function({
      Value<int> id,
      required int ayahId,
      required String edition,
      required String content,
    });
typedef $$TafsirsTableUpdateCompanionBuilder =
    TafsirsCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<String> edition,
      Value<String> content,
    });

class $$TafsirsTableFilterComposer
    extends Composer<_$QuranDatabase, $TafsirsTable> {
  $$TafsirsTableFilterComposer({
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

  ColumnFilters<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TafsirsTableOrderingComposer
    extends Composer<_$QuranDatabase, $TafsirsTable> {
  $$TafsirsTableOrderingComposer({
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

  ColumnOrderings<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TafsirsTableAnnotationComposer
    extends Composer<_$QuranDatabase, $TafsirsTable> {
  $$TafsirsTableAnnotationComposer({
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

  GeneratedColumn<String> get edition =>
      $composableBuilder(column: $table.edition, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$TafsirsTableTableManager
    extends
        RootTableManager<
          _$QuranDatabase,
          $TafsirsTable,
          Tafsir,
          $$TafsirsTableFilterComposer,
          $$TafsirsTableOrderingComposer,
          $$TafsirsTableAnnotationComposer,
          $$TafsirsTableCreateCompanionBuilder,
          $$TafsirsTableUpdateCompanionBuilder,
          (Tafsir, BaseReferences<_$QuranDatabase, $TafsirsTable, Tafsir>),
          Tafsir,
          PrefetchHooks Function()
        > {
  $$TafsirsTableTableManager(_$QuranDatabase db, $TafsirsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TafsirsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TafsirsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TafsirsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<String> edition = const Value.absent(),
                Value<String> content = const Value.absent(),
              }) => TafsirsCompanion(
                id: id,
                ayahId: ayahId,
                edition: edition,
                content: content,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                required String edition,
                required String content,
              }) => TafsirsCompanion.insert(
                id: id,
                ayahId: ayahId,
                edition: edition,
                content: content,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TafsirsTableProcessedTableManager =
    ProcessedTableManager<
      _$QuranDatabase,
      $TafsirsTable,
      Tafsir,
      $$TafsirsTableFilterComposer,
      $$TafsirsTableOrderingComposer,
      $$TafsirsTableAnnotationComposer,
      $$TafsirsTableCreateCompanionBuilder,
      $$TafsirsTableUpdateCompanionBuilder,
      (Tafsir, BaseReferences<_$QuranDatabase, $TafsirsTable, Tafsir>),
      Tafsir,
      PrefetchHooks Function()
    >;
typedef $$TranslationsTableCreateCompanionBuilder =
    TranslationsCompanion Function({
      Value<int> id,
      required int ayahId,
      required String edition,
      required String lang,
      required String content,
    });
typedef $$TranslationsTableUpdateCompanionBuilder =
    TranslationsCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<String> edition,
      Value<String> lang,
      Value<String> content,
    });

class $$TranslationsTableFilterComposer
    extends Composer<_$QuranDatabase, $TranslationsTable> {
  $$TranslationsTableFilterComposer({
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

  ColumnFilters<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranslationsTableOrderingComposer
    extends Composer<_$QuranDatabase, $TranslationsTable> {
  $$TranslationsTableOrderingComposer({
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

  ColumnOrderings<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslationsTableAnnotationComposer
    extends Composer<_$QuranDatabase, $TranslationsTable> {
  $$TranslationsTableAnnotationComposer({
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

  GeneratedColumn<String> get edition =>
      $composableBuilder(column: $table.edition, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$TranslationsTableTableManager
    extends
        RootTableManager<
          _$QuranDatabase,
          $TranslationsTable,
          Translation,
          $$TranslationsTableFilterComposer,
          $$TranslationsTableOrderingComposer,
          $$TranslationsTableAnnotationComposer,
          $$TranslationsTableCreateCompanionBuilder,
          $$TranslationsTableUpdateCompanionBuilder,
          (
            Translation,
            BaseReferences<_$QuranDatabase, $TranslationsTable, Translation>,
          ),
          Translation,
          PrefetchHooks Function()
        > {
  $$TranslationsTableTableManager(_$QuranDatabase db, $TranslationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<String> edition = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> content = const Value.absent(),
              }) => TranslationsCompanion(
                id: id,
                ayahId: ayahId,
                edition: edition,
                lang: lang,
                content: content,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                required String edition,
                required String lang,
                required String content,
              }) => TranslationsCompanion.insert(
                id: id,
                ayahId: ayahId,
                edition: edition,
                lang: lang,
                content: content,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranslationsTableProcessedTableManager =
    ProcessedTableManager<
      _$QuranDatabase,
      $TranslationsTable,
      Translation,
      $$TranslationsTableFilterComposer,
      $$TranslationsTableOrderingComposer,
      $$TranslationsTableAnnotationComposer,
      $$TranslationsTableCreateCompanionBuilder,
      $$TranslationsTableUpdateCompanionBuilder,
      (
        Translation,
        BaseReferences<_$QuranDatabase, $TranslationsTable, Translation>,
      ),
      Translation,
      PrefetchHooks Function()
    >;

class $QuranDatabaseManager {
  final _$QuranDatabase _db;
  $QuranDatabaseManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db, _db.ayahs);
  $$PageLinesTableTableManager get pageLines =>
      $$PageLinesTableTableManager(_db, _db.pageLines);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$TafsirsTableTableManager get tafsirs =>
      $$TafsirsTableTableManager(_db, _db.tafsirs);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db, _db.translations);
}
