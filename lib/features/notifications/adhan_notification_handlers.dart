/// معالجات ردّ فعل أزرار الإشعارات (متابعة "هل صليت؟" + أذكار بعد الصلاة)
/// — مفكّكة كـpart من [AdhanNotificationService] الرئيسي للحفاظ على
/// وصول المُعرّفات الخاصة (_k*) بين الملفين بلا نسخ مكرّر.
part of 'adhan_notification_service.dart';
/// معالج رد فعل زرّي إشعار متابعة "هل صليت؟" — **دالة top-level مستقلة**
/// (لا داخل الصنف) بموسم `@pragma('vm:entry-point')` لأنها **قد تُستدعى
/// بمعزل (isolate) خلفي منفصل كلياً** لو ضغط المستخدم الزرّ والتطبيق مغلَق
/// تماماً (قيد فعلي بمكتبة `flutter_local_notifications`، راجع "⚠️ قيود
/// معروفة، غير مُختبرة بجهاز فعلي" أعلى الملف — هذا القيد لم يُختبر بإغلاق
/// فعلي كامل للتطبيق بعد). لا وصول لحاوية Riverpod هون، فالكتابة تفتح
/// اتصال `UserDatabase` مستقل قصير العمر بدل المرور بـ`UserRepository`
/// المحمَّل مسبقاً بالتطبيق الرئيسي.
@pragma('vm:entry-point')
void onPrayerCheckinNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  final payload = response.payload;
  if (payload == null) return;

  // نفس الدالة الوحيدة مسجَّلة لكل أنواع إشعارات هذا الملف (متابعة "هل
  // صليت؟" وتنبيه أذكار بعد الصلاة معاً) — التمييز ببادئة الحمولة (payload)
  // بدل دالتين منفصلتين، لأن `flutter_local_notifications` يسمح بمعالج
  // واحد فقط مسجَّل بـ`initialize()`.
  if (payload.startsWith(_kPostPrayerAzkarPayloadPrefix)) {
    final openReading =
        actionId == _kPostPrayerAzkarReadAction ||
        actionId == null ||
        actionId.isEmpty;
    unawaited(
      _handlePostPrayerAzkarResponse(
        openReading: openReading,
        notificationId: response.id,
      ),
    );
    return;
  }

  // إذا ضغط المستخدم على زر "صليت" أو ضغط على جسم الإشعار مباشرة (actionId == null)
  final isYes =
      (actionId == _kCheckinYesAction || actionId == null || actionId.isEmpty);
  unawaited(
    _handlePrayerCheckinResponse(
      payload,
      prayed: isYes,
      notificationId: response.id,
    ),
  );
}

/// معالج رد فعل تنبيه "أذكار بعد الصلاة" — نفس قيد ردّ المتابعة أعلاه (قد
/// يُستدعى بمعزل خلفي كلياً). "اقرأ الآن" (أو ضغط جسم الإشعار مباشرة) يفتح
/// شاشة الأذكار بعد الصلاة فوراً لو التطبيق حيّ ([postPrayerAzkarOpenCallback]
/// مسجَّلة من `RootShell`)، وإلا يُحفَظ علم [kPendingOpenPostPrayerAzkarKey]
/// يُستهلَك عند الإقلاع القادم. "×" يغلق الإشعار بلا فتح ولا تسجيل أي شيء.
Future<void> _handlePostPrayerAzkarResponse({
  required bool openReading,
  int? notificationId,
}) async {
  if (notificationId != null) {
    try {
      await FlutterLocalNotificationsPlugin().cancel(id: notificationId);
    } catch (_) {}
  }
  if (!openReading) return;

  final callback = postPrayerAzkarOpenCallback;
  if (callback != null) {
    callback();
    return;
  }
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(kPendingOpenPostPrayerAzkarKey, true);
  } catch (_) {}
}

Future<void> _handlePrayerCheckinResponse(
  String payload, {
  required bool prayed,
  int? notificationId,
}) async {
  final parts = payload.split('|');
  if (parts.length != 3) return;
  final dateKey = parts[0];
  final rawCategory = parts[1];
  final category = rawCategory.startsWith('prayer_')
      ? rawCategory
      : 'prayer_$rawCategory'; // يطابق UserCategories.fajr/dhuhr/asr/maghrib/isha
  final slotIndex = int.tryParse(parts[2]);
  if (slotIndex == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  try {
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: onPrayerCheckinNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onPrayerCheckinNotificationResponse,
    );
  } catch (e) {
    debugPrint('تعذّر تهيئة الإشعارات بمعزل خلفي: $e');
  }

  // إخفاء وحذف الإشعار فوراً من شريط الإشعارات عند الضغط
  if (notificationId != null) {
    try {
      await plugin.cancel(id: notificationId);
    } catch (_) {}
  }
  if (slotIndex == 99) {
    try {
      await plugin.cancel(id: 9998);
    } catch (_) {}
  }

  // "صليت" فقط يكتب شيئاً — "لسا" يلغي التكرار بلا تسجيل
  //
  // **ملاحظة**: كان هون سابقاً إشعار فوري ثابت "أذكار ما بعد الصلاة" يُطلَق
  // مباشرة عند الضغط على "صليت" تحديداً. حُذف بالكامل — الميزة الآن مستقلة
  // كلياً (`postPrayerAzkarEnabled`/`_schedulePostPrayerAzkarOne`، مجدولة
  // مسبقاً بمدة قابلة للتخصيص من دخول وقت الصلاة نفسه)، بغضّ النظر عن ردّ
  // "هل صليت؟" من عدمه — راجع توثيق `UserRepository.postPrayerAzkarEnabled`.
  if (prayed) {
    final db = UserDatabase();
    try {
      await _bumpCategoryStreakIfNewDay(db, category, dateKey);
      if (UserRepository.currentInstance != null) {
        await UserRepository.currentInstance!.reloadCategoryStreaks();
      }
    } catch (e) {
      debugPrint('تعذّر تسجيل "صليت" من الإشعار: $e');
    } finally {
      await db.close();
    }
  }

  // ألغِ بقية إشعارات هذه الصلاة/اليوم
  if (slotIndex != 99) {
    for (var i = 0; i < _kCheckinMaxRepeatsPerSlot; i++) {
      try {
        await plugin.cancel(id: _kCheckinIdBase + slotIndex * 10 + i);
      } catch (_) {}
    }
  }
}

/// نسخة طبق الأصل من منطق `UserRepository.bumpCategoryStreakIfNewDay` —
/// **معاد كتابتها هون عمداً** لا مستدعاة مباشرة، لأن هذا الرد قد يصل بمعزل
/// خلفي منفصل كلياً بلا وصول لمثيل `UserRepository` المحمَّل مسبقاً بالتطبيق
/// الرئيسي (راجع توثيق [onPrayerCheckinNotificationResponse]). `dateKey`
/// يصل جاهزاً من وقت جدولة الإشعار نفسه (لا `DateTime.now()` هون) — قد
/// يُضغَط الزرّ بعد منتصف الليل لصلاة كان وقتها أمس.
Future<void> _bumpCategoryStreakIfNewDay(
  UserDatabase db,
  String category,
  String dateKey,
) async {
  final alreadyLogged =
      await (db.select(db.categoryDailyLog)..where(
            (t) => t.category.equals(category) & t.dateKey.equals(dateKey),
          ))
          .getSingleOrNull();
  if (alreadyLogged != null) return;

  final row = await (db.select(
    db.categoryStreaks,
  )..where((t) => t.category.equals(category))).getSingleOrNull();
  final yesterday = _yesterdayOf(dateKey);
  final continued = row?.streakLastDay == yesterday;
  final newCount = continued ? (row?.streakDays ?? 0) + 1 : 1;

  await db
      .into(db.categoryStreaks)
      .insertOnConflictUpdate(
        CategoryStreaksCompanion(
          category: Value(category),
          streakDays: Value(newCount),
          streakLastDay: Value(dateKey),
        ),
      );
  await db
      .into(db.categoryDailyLog)
      .insertOnConflictUpdate(
        CategoryDailyLogCompanion(
          category: Value(category),
          dateKey: Value(dateKey),
        ),
      );
}

/// نفس تنسيق `UserRepository._dateKey` حرفياً (بلا حشو أصفار) — يحسب مفتاح
/// اليوم السابق من نص `dateKey` مباشرة بدل `DateTime.now()`.
String _yesterdayOf(String dateKey) {
  final parts = dateKey.split('-');
  final d = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final y = d.subtract(const Duration(days: 1));
  return '${y.year}-${y.month}-${y.day}';
}
