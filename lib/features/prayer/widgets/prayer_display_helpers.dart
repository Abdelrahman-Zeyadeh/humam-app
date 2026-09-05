import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/adhan_notification_prefs.dart';
import '../prayer_times_service.dart';

/// دوال عرض صغيرة مشتركة بين شاشة الصلاة الرئيسية وورقة تفاصيل الصلاة
/// (`prayer_detail_sheet.dart`) — أُخرجت هون بدل تكرارها أو تضخيم ملف
/// واحد بمنطق عرض بحت لا علاقة له بالتنسيق (orchestration).

/// أيقونة كل وقت/صلاة — تُستخدم بقائمة أوقات اليوم وبرأس ورقة التفاصيل.
IconData prayerMomentIcon(PrayerMoment m) => switch (m) {
  PrayerMoment.fajr => Icons.nights_stay_outlined,
  PrayerMoment.sunrise => Icons.wb_twilight_outlined,
  PrayerMoment.dhuhr => Icons.wb_sunny_outlined,
  PrayerMoment.asr => Icons.wb_sunny,
  PrayerMoment.maghrib => Icons.wb_twilight,
  PrayerMoment.isha => Icons.dark_mode_outlined,
};

/// صياغة الوقت بنظام ١٢ ساعة مع صباحاً/مساءً بالعربي (ص/م).
String formatPrayerTime12h(DateTime t) {
  final h24 = t.hour;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final period = h24 < 12 ? 'ص' : 'م';
  final m = t.minute.toString().padLeft(2, '0');
  return '$h12:$m $period';
}

/// أيقونة نمط التنبيه الحالي لصلاة معيّنة (أذان/نغمة/صامت/إيقاف) — تُستخدم
/// بزر التفاصيل بجانب كل صلاة في القائمة الرئيسية.
IconData prayerNotificationModeIcon(WidgetRef ref, PrayerMoment moment) {
  final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
  final mode = notifPrefs.notificationModeFor(moment);
  return switch (mode) {
    'adhan' => Icons.volume_up_outlined,
    'tone' => Icons.notifications_active_outlined,
    'silent' => Icons.notifications_paused_outlined,
    _ => Icons.notifications_off_outlined,
  };
}
