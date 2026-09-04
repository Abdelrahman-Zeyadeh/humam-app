import 'package:hijri/hijri_calendar.dart';

/// التاريخ الهجري لليوم، محسوب محلياً بالكامل (خوارزمية جدولية أم القرى
/// عبر حزمة `hijri`، BSD-2-Clause) — بلا استدعاء شبكة إطلاقاً.
String todayHijriArabic([DateTime? date]) {
  final cal = date == null ? HijriCalendar.now() : HijriCalendar.fromDate(date);
  HijriCalendar.language = 'ar';
  final day = cal.hDay.toString().padLeft(2, '0');
  return '$day ${cal.getLongMonthName()} ${cal.hYear}هـ';
}

/// اليوم والتاريخ الهجري كاملين بالعربية (مثال: "السبت 09 ربيع الأول 1448هـ")
String todayHijriWithDayArabic([DateTime? date]) {
  final dt = date ?? DateTime.now();
  const weekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  final weekday = weekdays[dt.weekday - 1];
  return '$weekday ${todayHijriArabic(dt)}';
}
