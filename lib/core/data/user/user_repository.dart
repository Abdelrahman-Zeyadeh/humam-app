import 'package:drift/drift.dart';

import 'user_database.dart';

class KhatmaPlan {
  const KhatmaPlan({required this.startDate, required this.targetDays});
  final DateTime startDate;
  final int targetDays;

  int get dailyPages => (604 / targetDays).ceil();

  DateTime get expectedEndDate => startDate.add(Duration(days: targetDays));

  int get daysElapsed {
    final d = DateTime.now().difference(startDate).inDays + 1;
    return d.clamp(1, targetDays);
  }

  /// الصفحة المتوقّع الوصول إليها اليوم لو الالتزام تام بالورد اليومي.
  int get expectedPageByNow => (daysElapsed * dailyPages).clamp(1, 604);
}

/// مفاتيح فئات سلاسل الاستمرار المستقلة (`CategoryStreaks.category`) —
/// ثابتة هون بدل تكرار النصوص الحرفية عبر الملفات. **`dailyWird` استثناء
/// عمداً**: لا صف له بـ`CategoryStreaks` أصلاً، يبقى مخزَّناً بعمود
/// `ReadingProgress.streakDays`/`streakLastDay` القديم (`streakDays`/
/// `bumpStreakIfNewDay` أسفله) — كان موجوداً قبل تقسيم الفئات ولا داعي
/// لهجرته لتفادي فقد سلسلة المستخدم الحالية.
class UserCategories {
  UserCategories._();
  static const morningAzkar = 'morning_azkar';
  static const eveningAzkar = 'evening_azkar';
  static const dailyWird = 'daily_wird';
  static const hifz = 'hifz';
  static const nightAzkar = 'night_azkar';
  static const qiyam = 'qiyam';
}

/// واجهة واحدة فوق `user.db` تحلّ محل خمس فئات `*_prefs.dart` كانت تغلّف
/// `SharedPreferences` مباشرة. تحتفظ بنسخة كاملة بالذاكرة (`_bookmarks`،
/// `_lastPage`...) تُحمَّل مرة واحدة بـ [preload] عند إقلاع التطبيق —
/// نفس نمط `await SharedPreferences.getInstance()` قبل `runApp` — حتى
/// تبقى القراءات **متزامنة** لكل الشاشات المستهلِكة (`user_prefs.dart`
/// وأخواتها) بلا إعادة كتابتها كلها بـ `FutureProvider`/`AsyncValue`. كل
/// كتابة تُحدِّث الذاكرة فوراً ثم تُخزَّن بـdrift بالخلفية.
class UserRepository {
  UserRepository(this._db);
  final UserDatabase _db;

  Set<int> _bookmarks = {};
  int? _lastPage;
  int _streakDays = 0;
  String? _streakLastDay;
  KhatmaPlan? _activeKhatma;
  String _reciterId = 'husary';
  double _speed = 1.0;
  double? _lat;
  double? _lon;
  String? _cityName;
  String _calcMethod = 'ummAlQura';
  int _tasbihCount = 0;
  final Map<String, int> _categoryStreakDays = {};
  final Map<String, String?> _categoryStreakLastDay = {};
  bool _qiyamEnabled = false;
  int? _qiyamHour;
  int _qiyamMinute = 0;
  Set<int> _azkarFavoriteCategoryIds = {};

  bool _preloaded = false;

  /// يُستدعى مرة واحدة بـ`main()` بعد الهجرة (`prefs_migration.dart`)
  /// وقبل `runApp` — يملأ كل الحقول أعلاه من `user.db` دفعة واحدة.
  Future<void> preload() async {
    if (_preloaded) return;
    _preloaded = true;

    final bookmarkRows = await _db.select(_db.bookmarks).get();
    _bookmarks = bookmarkRows.map((r) => r.ayahId).toSet();

    final progress = await (_db.select(_db.readingProgress)..where((t) => t.id.equals(1))).getSingleOrNull();
    _lastPage = progress?.lastPage;
    _streakDays = progress?.streakDays ?? 0;
    _streakLastDay = progress?.streakLastDay;

    final khatma =
        await (_db.select(_db.khatmaPlans)..where((t) => t.active.equals(true))).getSingleOrNull();
    _activeKhatma =
        khatma == null ? null : KhatmaPlan(startDate: khatma.startDate, targetDays: khatma.targetDays);

    final audio = await (_db.select(_db.audioSettings)..where((t) => t.id.equals(1))).getSingleOrNull();
    _reciterId = audio?.reciterId ?? 'husary';
    _speed = audio?.speed ?? 1.0;

    final location =
        await (_db.select(_db.locationSettings)..where((t) => t.id.equals(1))).getSingleOrNull();
    _lat = location?.lat;
    _lon = location?.lon;
    _cityName = location?.cityName;
    _calcMethod = location?.calcMethod ?? 'ummAlQura';

    final tasbih = await (_db.select(_db.tasbihCounter)..where((t) => t.id.equals(1))).getSingleOrNull();
    _tasbihCount = tasbih?.count ?? 0;

    final streakRows = await _db.select(_db.categoryStreaks).get();
    for (final row in streakRows) {
      _categoryStreakDays[row.category] = row.streakDays;
      _categoryStreakLastDay[row.category] = row.streakLastDay;
    }

    final qiyam = await (_db.select(_db.qiyamSettings)..where((t) => t.id.equals(1))).getSingleOrNull();
    _qiyamEnabled = qiyam?.enabled ?? false;
    _qiyamHour = qiyam?.reminderHour;
    _qiyamMinute = qiyam?.reminderMinute ?? 0;

    final favoriteRows = await _db.select(_db.azkarFavorites).get();
    _azkarFavoriteCategoryIds = favoriteRows.map((r) => r.categoryId).toSet();
  }

  // --- علامات مرجعية وآخر صفحة وسلسلة الأيام ---

  Set<int> get bookmarkedAyahIds => _bookmarks;

  bool isBookmarked(int ayahId) => _bookmarks.contains(ayahId);

  Future<void> toggleBookmark(int ayahId) async {
    final existing = await (_db.select(_db.bookmarks)..where((t) => t.ayahId.equals(ayahId))).getSingleOrNull();
    if (existing != null) {
      await (_db.delete(_db.bookmarks)..where((t) => t.ayahId.equals(ayahId))).go();
      _bookmarks = {..._bookmarks}..remove(ayahId);
    } else {
      await _db.into(_db.bookmarks).insert(BookmarksCompanion.insert(ayahId: ayahId, createdAt: DateTime.now()));
      _bookmarks = {..._bookmarks, ayahId};
    }
  }

  int? get lastReadPage => _lastPage;

  Future<void> setLastReadPage(int page) async {
    _lastPage = page;
    await _db.into(_db.readingProgress).insertOnConflictUpdate(
          ReadingProgressCompanion(id: const Value(1), lastPage: Value(page)),
        );
  }

  int get streakDays => _streakDays;

  /// يُستدعى عند كل تغيير صفحة بالمصحف — يزيد السلسلة يوماً واحداً بأول
  /// زيارة كل يوم تقويمي، ويصفّرها لو انقطع يوم كامل أو أكثر بين آخر
  /// زيارة واليوم — لا حساب دقيق بالساعات، فقط تاريخ التقويم المحلي.
  Future<void> bumpStreakIfNewDay() async {
    final today = _dateKey(DateTime.now());
    if (_streakLastDay == today) return;

    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final continued = _streakLastDay == yesterday;
    final newCount = continued ? _streakDays + 1 : 1;

    _streakDays = newCount;
    _streakLastDay = today;
    await _db.into(_db.readingProgress).insertOnConflictUpdate(
          ReadingProgressCompanion(id: const Value(1), streakDays: Value(newCount), streakLastDay: Value(today)),
        );
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  // --- سلاسل استمرار مستقلة لكل نشاط (راجع [UserCategories]) ---

  int streakDaysFor(String category) => _categoryStreakDays[category] ?? 0;

  /// هل سُجِّل هذا النشاط اليوم فعلاً؟ (مفيد لتعطيل زر "سجّل اليوم" بعد
  /// أول تسجيل — قيام الليل مثلاً لا يُعاد تسجيله مرتين بنفس اليوم).
  bool completedTodayFor(String category) => _categoryStreakLastDay[category] == _dateKey(DateTime.now());

  /// نفس منطق [bumpStreakIfNewDay] بالضبط لكن معمَّم لأي فئة — يُستدعى
  /// عند اكتمال نشاط اليوم (كل أذكار الصباح مثلاً) أو تسجيل يدوي (قيام
  /// الليل). لا شيء لو استُدعي مرتين بنفس اليوم.
  Future<void> bumpCategoryStreakIfNewDay(String category) async {
    final today = _dateKey(DateTime.now());
    final lastDay = _categoryStreakLastDay[category];
    if (lastDay == today) return;

    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final continued = lastDay == yesterday;
    final newCount = continued ? streakDaysFor(category) + 1 : 1;

    _categoryStreakDays[category] = newCount;
    _categoryStreakLastDay[category] = today;
    await _db.into(_db.categoryStreaks).insertOnConflictUpdate(
          CategoryStreaksCompanion(
            category: Value(category),
            streakDays: Value(newCount),
            streakLastDay: Value(today),
          ),
        );
  }

  // --- تذكير قيام الليل ---

  bool get qiyamEnabled => _qiyamEnabled;
  int? get qiyamHour => _qiyamHour;
  int get qiyamMinute => _qiyamMinute;

  Future<void> setQiyamReminder({required bool enabled, int? hour, int? minute}) async {
    _qiyamEnabled = enabled;
    if (hour != null) _qiyamHour = hour;
    if (minute != null) _qiyamMinute = minute;
    await _db.into(_db.qiyamSettings).insertOnConflictUpdate(
          QiyamSettingsCompanion(
            id: const Value(1),
            enabled: Value(enabled),
            reminderHour: _qiyamHour == null ? const Value.absent() : Value(_qiyamHour),
            reminderMinute: Value(_qiyamMinute),
          ),
        );
  }

  // --- أقسام مفضَّلة من مكتبة حصن المسلم ---

  Set<int> get azkarFavoriteCategoryIds => _azkarFavoriteCategoryIds;

  bool isAzkarFavorite(int categoryId) => _azkarFavoriteCategoryIds.contains(categoryId);

  Future<void> toggleAzkarFavorite(int categoryId) async {
    if (_azkarFavoriteCategoryIds.contains(categoryId)) {
      await (_db.delete(_db.azkarFavorites)..where((t) => t.categoryId.equals(categoryId))).go();
      _azkarFavoriteCategoryIds = {..._azkarFavoriteCategoryIds}..remove(categoryId);
    } else {
      await _db.into(_db.azkarFavorites).insert(
            AzkarFavoritesCompanion.insert(categoryId: categoryId, createdAt: DateTime.now()),
          );
      _azkarFavoriteCategoryIds = {..._azkarFavoriteCategoryIds, categoryId};
    }
  }

  // --- خطة الختمة ---

  KhatmaPlan? get activePlan => _activeKhatma;

  Future<void> startKhatma(int targetDays) async {
    final plan = KhatmaPlan(startDate: DateTime.now(), targetDays: targetDays);
    _activeKhatma = plan;
    await _db.transaction(() async {
      await (_db.update(_db.khatmaPlans)..where((t) => t.active.equals(true)))
          .write(const KhatmaPlansCompanion(active: Value(false)));
      await _db
          .into(_db.khatmaPlans)
          .insert(KhatmaPlansCompanion.insert(startDate: plan.startDate, targetDays: targetDays));
    });
  }

  Future<void> cancelKhatma() async {
    _activeKhatma = null;
    await (_db.update(_db.khatmaPlans)..where((t) => t.active.equals(true)))
        .write(const KhatmaPlansCompanion(active: Value(false)));
  }

  // --- إعدادات الصوت ---

  String get reciterId => _reciterId;

  Future<void> setReciterId(String id) async {
    _reciterId = id;
    await _db.into(_db.audioSettings).insertOnConflictUpdate(
          AudioSettingsCompanion(id: const Value(1), reciterId: Value(id)),
        );
  }

  double get speed => _speed;

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _db.into(_db.audioSettings).insertOnConflictUpdate(
          AudioSettingsCompanion(id: const Value(1), speed: Value(speed)),
        );
  }

  // --- الموقع لمواقيت الصلاة/القبلة ---

  double? get lat => _lat;
  double? get lon => _lon;
  String? get cityName => _cityName;
  bool get hasLocation => _lat != null && _lon != null;

  Future<void> setLocation({required double lat, required double lon, required String cityName}) async {
    _lat = lat;
    _lon = lon;
    _cityName = cityName;
    await _db.into(_db.locationSettings).insertOnConflictUpdate(
          LocationSettingsCompanion(id: const Value(1), lat: Value(lat), lon: Value(lon), cityName: Value(cityName)),
        );
  }

  String get calculationMethod => _calcMethod;

  Future<void> setCalculationMethod(String key) async {
    _calcMethod = key;
    await _db.into(_db.locationSettings).insertOnConflictUpdate(
          LocationSettingsCompanion(id: const Value(1), calcMethod: Value(key)),
        );
  }

  // --- المسبحة ---

  int get tasbihCount => _tasbihCount;

  Future<void> setTasbihCount(int value) async {
    _tasbihCount = value;
    await _db.into(_db.tasbihCounter).insertOnConflictUpdate(
          TasbihCounterCompanion(id: const Value(1), count: Value(value)),
        );
  }

  // --- هجرة لمرة واحدة من SharedPreferences (راجع prefs_migration.dart) ---

  /// يكتب قيماً خاماً مباشرة إلى drift بلا لمس الذاكرة المؤقتة (تُحمَّل
  /// أصلاً بـ[preload] بعد الهجرة مباشرة) وبلا منطق الأعمال المعتاد
  /// (مثلاً بتاريخ بدء ختمة أصلي محفوظ لا `DateTime.now()`). يُستخدم
  /// **فقط** أثناء الهجرة لمرة واحدة.
  Future<void> restoreMigratedData({
    int? lastPage,
    int? streakDays,
    String? streakLastDay,
    DateTime? khatmaStartDate,
    int? khatmaTargetDays,
  }) async {
    await _db.transaction(() async {
      if (lastPage != null || streakDays != null || streakLastDay != null) {
        await _db.into(_db.readingProgress).insertOnConflictUpdate(
              ReadingProgressCompanion(
                id: const Value(1),
                lastPage: lastPage == null ? const Value.absent() : Value(lastPage),
                streakDays: streakDays == null ? const Value.absent() : Value(streakDays),
                streakLastDay: streakLastDay == null ? const Value.absent() : Value(streakLastDay),
              ),
            );
      }
      if (khatmaStartDate != null && khatmaTargetDays != null) {
        await _db.into(_db.khatmaPlans).insert(
              KhatmaPlansCompanion.insert(startDate: khatmaStartDate, targetDays: khatmaTargetDays),
            );
      }
    });
  }
}
