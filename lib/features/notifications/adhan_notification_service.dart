import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../prayer/prayer_times_service.dart';

const _kChannelId = 'adhan_ch_default';
const _kChannelName = 'أذان مواقيت الصلاة';
const _kNotifIdBase = 9000;
const _kMaxScheduledPerCall = 20; // يومان × ٥ صلوات + هامش

const _kQiyamChannelId = 'qiyam_reminder_ch';
const _kQiyamChannelName = 'تذكير قيام الليل';
const _kQiyamNotifId = 9100; // بعيد عن مدى إشعارات الأذان (٩٠٠٠-٩٠١٩) عمداً

/// إشعارات دخول وقت الصلاة — محلية بالكامل (`flutter_local_notifications`
/// + حساب `computeDayTimes` نفسه المستخدَم بشاشة الصلاة)، بلا خادم وبلا
/// اعتماد شبكي. **تملك أيضاً تذكير قيام الليل** (`scheduleQiyamReminder`
/// أسفله) — نفس نسخة `FlutterLocalNotificationsPlugin` المهيَّأة هون
/// (تهيئة واحدة فقط بكل التطبيق) بدل مثيل ثانٍ منفصل، بقناة إشعار خاصة.
///
/// ⚠️ **لا صوت أذان مخصَّص بعد** — تستخدم صوت الإشعار الافتراضي للنظام.
/// بحثت عن مصدر أذان مرخَّص بوضوح لإعادة التوزيع التجاري (نفس معيار كل
/// مصادر المشروع الأخرى: ملف LICENSE صريح لا وصف README فقط) ولم أجد
/// واحداً موثوقاً بما يكفي — مستودعات GitHub المتوفرة بلا ملف ترخيص فعلي،
/// وملف Freesound الوحيد المرخّص CC0 صراحة مستخرَج من فيديو يوتيوب
/// (مصدر أصلي غير واضح الحقوق رغم تصريح الرافع). **حاجز نشر إضافي** —
/// نفس فئة قيد ترخيص خط QCF بـتصميم-النظام.md §٨، لا تفصيل مؤجَّل.
///
/// ⚠️ **قيود أخرى معروفة، غير مُختبرة بجهاز فعلي:**
/// - الجدولة تغطي يومين فقط (اليوم والغد) وتُعاد عند كل إقلاع أو تغيير
///   موقع/طريقة حساب — لو لم يُفتح التطبيق يومين متتاليين تتوقف الإشعارات
///   حتى يُفتح من جديد. لا آلية إعادة جدولة بالخلفية دون فتح التطبيق.
/// - `SCHEDULE_EXACT_ALARM` قد يحتاج تفعيلاً يدوياً من المستخدم بأندرويد
///   12+ ("التنبيهات والتذكيرات") — الخدمة تتراجع تلقائياً لجدولة غير
///   دقيقة (`inexactAllowWhileIdle`) لو رُفض، بلا فشل صامت كامل.
/// - إعادة الجدولة بعد إعادة تشغيل الجهاز (`ScheduledNotificationBootReceiver`
///   بـ`AndroidManifest.xml`) لم تُختبر بإعادة تشغيل فعلية.
class AdhanNotificationService {
  AdhanNotificationService._();
  static final instance = AdhanNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // فشل صامت — تبقى المنطقة الزمنية الافتراضية لحزمة timezone، ما
      // يعني إشعارات بوقت خاطئ لا انهياراً. راجع القيود بالأعلى.
      debugPrint('تعذّر تحديد المنطقة الزمنية المحلية للإشعارات: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(settings: const InitializationSettings(android: androidInit, iOS: iosInit));

    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: 'تنبيه عند دخول وقت كل صلاة',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const qiyamChannel = AndroidNotificationChannel(
      _kQiyamChannelId,
      _kQiyamChannelName,
      description: 'تذكير يومي بالساعة التي يختارها المستخدم لقيام الليل',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(qiyamChannel);

    _initialized = true;
  }

  /// يطلب أذونات النظام اللازمة — لا يفشل التطبيق ولا يرمي استثناءً لو
  /// رُفضت، فقط لا تصل الإشعارات (أو تصل بجدولة غير دقيقة).
  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('طلب إذن إشعارات الأذان فشل/تعذّر: $e');
    }
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('طلب إذن إشعارات الأذان (iOS) فشل/تعذّر: $e');
    }
  }

  /// يلغي كل إشعارات الأذان المجدولة حالياً — يُستخدم مباشرة عند تعطيل
  /// الإشعارات كلياً، وداخلياً أول كل [rescheduleUpcoming].
  Future<void> cancelAll() async {
    for (var i = 0; i < _kMaxScheduledPerCall; i++) {
      await _plugin.cancel(id: _kNotifIdBase + i);
    }
  }

  /// يلغي كل الإشعارات المجدولة القديمة، ويعيد جدولة ما تبقّى من صلوات
  /// اليوم وكل صلوات الغد. يُستدعى عند إقلاع التطبيق وعند تغيير الموقع
  /// أو طريقة الحساب (راجع `prayer_location_controller.dart`).
  Future<void> rescheduleUpcoming({
    required double lat,
    required double lon,
    required String methodKey,
    required bool Function(PrayerMoment) isEnabled,
  }) async {
    if (!_initialized) await initialize();
    await cancelAll();

    final now = DateTime.now();
    var id = _kNotifIdBase;
    for (final dayOffset in [0, 1]) {
      final date = now.add(Duration(days: dayOffset));
      final times = computeDayTimes(lat: lat, lon: lon, date: date, methodKey: methodKey);
      for (final t in times) {
        if (!t.moment.isPrayer) continue;
        if (!t.time.isAfter(now)) continue;
        if (!isEnabled(t.moment)) continue;
        await _scheduleOne(id++, t.moment, t.time);
      }
    }
  }

  /// تذكير قيام الليل — يتكرر يومياً بنفس الساعة/الدقيقة تلقائياً على
  /// مستوى النظام (`matchDateTimeComponents: DateTimeComponents.time`)،
  /// خلافاً لإشعارات الأذان أعلاه (تحتاج إعادة جدولة يدوية كل يومين). لا
  /// علاقة بحساب مواقيت الصلاة — وقت اختياري بحت يحدّده المستخدم بشاشة
  /// قيام الليل (`qiyam_screen.dart`).
  Future<void> scheduleQiyamReminder({required int hour, required int minute}) async {
    if (!_initialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kQiyamChannelId,
        _kQiyamChannelName,
        channelDescription: 'تذكير يومي بالساعة التي يختارها المستخدم لقيام الليل',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id: _kQiyamNotifId,
          title: 'وقت قيام الليل',
          body: 'حان وقت التذكير الذي اخترته لقيام الليل',
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.time,
        );

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('جدولة دقيقة لتذكير قيام الليل فشلت، تراجع لجدولة تقريبية: $e');
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelQiyamReminder() => _plugin.cancel(id: _kQiyamNotifId);

  Future<void> _scheduleOne(int id, PrayerMoment moment, DateTime time) async {
    final scheduled = tz.TZDateTime.from(time, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: 'تنبيه عند دخول وقت كل صلاة',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'حان وقت صلاة ${moment.nameAr}',
        body: 'حيّ على الصلاة، حيّ على الفلاح',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // غالباً رفض `SCHEDULE_EXACT_ALARM` (بحاجة موافقة يدوية بأندرويد
      // 12+) — نتراجع لجدولة غير دقيقة بدل ما تُفقد الإشعارات بالكامل.
      debugPrint('جدولة دقيقة لإشعار ${moment.nameAr} فشلت، تراجع لجدولة تقريبية: $e');
      await _plugin.zonedSchedule(
        id: id,
        title: 'حان وقت صلاة ${moment.nameAr}',
        body: 'حيّ على الصلاة، حيّ على الفلاح',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
