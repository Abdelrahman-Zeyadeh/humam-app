import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart' show sharedPreferencesProvider;

/// تصنيفات الإشعارات المعروضة بالواجهة
enum NotificationCategory {
  all('الكل'),
  prayer('الصلاة'),
  azkar('الأذكار'),
  quran('القرآن'),
  occasions('المناسبات');

  const NotificationCategory(this.label);
  final String label;

  static NotificationCategory fromString(String key) {
    switch (key.toLowerCase()) {
      case 'prayer':
      case 'salah':
        return NotificationCategory.prayer;
      case 'azkar':
      case 'dhikr':
        return NotificationCategory.azkar;
      case 'quran':
      case 'khatma':
      case 'hifz':
        return NotificationCategory.quran;
      case 'occasions':
      case 'hadith':
      case 'event':
        return NotificationCategory.occasions;
      default:
        return NotificationCategory.all;
    }
  }
}

/// سجل الإشعار الفردي
class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  final String id;
  final String title;
  final String body;
  final String category; // 'prayer' | 'azkar' | 'quran' | 'occasions'
  final DateTime timestamp;
  final bool isRead;
  final String? payload;

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    DateTime? timestamp,
    bool? isRead,
    String? payload,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'payload': payload,
  };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: (json['category'] as String?) ?? 'azkar',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isRead: (json['isRead'] as bool?) ?? false,
      payload: json['payload'] as String?,
    );
  }
}

const _kNotificationHistoryStorageKey = 'app_notification_history_log_v1';

/// قائمة الإشعارات النموذجية الأولية مطابقة لصور التطبيق والتصميم الفعلي
List<AppNotificationItem> _defaultSampleNotifications() {
  final now = DateTime.now();
  return [
    AppNotificationItem(
      id: 'notif_sample_1',
      title: 'أذكار المساء',
      body: 'اختم يومك بذكر الله — حرز ليلتك ومنامك',
      category: 'azkar',
      timestamp: DateTime(now.year, now.month, now.day, 17, 30),
      isRead: false,
    ),
    AppNotificationItem(
      id: 'notif_sample_2',
      title: 'أذكار الصباح',
      body: 'ابدأ يومك بذكر الله — حصنك ونورك',
      category: 'azkar',
      timestamp: DateTime(now.year, now.month, now.day, 6, 15),
      isRead: false,
    ),
    AppNotificationItem(
      id: 'notif_sample_3',
      title: 'أذكار المساء',
      body: 'اختم يومك بذكر الله — حرز ليلتك ومنامك',
      category: 'azkar',
      timestamp: now.subtract(const Duration(days: 1)),
      isRead: false,
    ),
    AppNotificationItem(
      id: 'notif_sample_4',
      title: 'تذكير ختمتك الأسبوعي',
      body: 'لم تبدأ ختمتك بعد — كل صفحة تُقرّبك من الله',
      category: 'quran',
      timestamp: now.subtract(const Duration(days: 1, hours: 4)),
      isRead: false,
    ),
    AppNotificationItem(
      id: 'notif_sample_5',
      title: 'أذكار الصباح',
      body: 'ابدأ يومك بذكر الله — حصنك ونورك',
      category: 'azkar',
      timestamp: now.subtract(const Duration(days: 1, hours: 10)),
      isRead: true,
    ),
    AppNotificationItem(
      id: 'notif_sample_6',
      title: 'أذكار المساء',
      body: 'اختم يومك بذكر الله — حرز ليلتك ومنامك',
      category: 'azkar',
      timestamp: now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotificationItem(
      id: 'notif_sample_7',
      title: 'صلاة العصر',
      body: 'حان الآن موعد صلاة العصر حسب توقيتك المحلي',
      category: 'prayer',
      timestamp: now.subtract(const Duration(days: 2, hours: 3)),
      isRead: true,
    ),
    AppNotificationItem(
      id: 'notif_sample_8',
      title: 'حديث اليوم',
      body: 'قال رسول الله ﷺ: «من سلك طريقاً يلتمس فيه علماً سهّل الله له به طريقاً إلى الجنة»',
      category: 'occasions',
      timestamp: now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];
}

class NotificationHistoryNotifier extends Notifier<List<AppNotificationItem>> {
  @override
  List<AppNotificationItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_kNotificationHistoryStorageKey);
    if (raw == null || raw.isEmpty) {
      final initial = _defaultSampleNotifications();
      prefs.setString(
        _kNotificationHistoryStorageKey,
        jsonEncode(initial.map((e) => e.toJson()).toList()),
      );
      return initial;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AppNotificationItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading notification history: $e');
      return _defaultSampleNotifications();
    }
  }

  Future<void> _save(List<AppNotificationItem> items) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_kNotificationHistoryStorageKey, raw);
  }

  /// تسجيل إشعار جديد مرسل
  Future<void> recordNotification({
    required String title,
    required String body,
    required String category,
    DateTime? timestamp,
    String? payload,
  }) async {
    final item = AppNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      category: category,
      timestamp: timestamp ?? DateTime.now(),
      isRead: false,
      payload: payload,
    );
    final updated = [item, ...state];
    state = updated;
    await _save(updated);
  }

  /// تمييز الكل كمقروء
  Future<void> markAllAsRead() async {
    final updated = state.map((item) => item.copyWith(isRead: true)).toList();
    state = updated;
    await _save(updated);
  }

  /// تمييز إشعار محدد كمقروء
  Future<void> markAsRead(String id) async {
    final updated = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    state = updated;
    await _save(updated);
  }

  /// حذف جميع الإشعارات
  Future<void> clearAll() async {
    state = const [];
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kNotificationHistoryStorageKey);
  }

  /// إعادة التحميل والتحديث
  void refresh() {
    ref.invalidateSelf();
  }
}

final notificationHistoryProvider =
    NotifierProvider<NotificationHistoryNotifier, List<AppNotificationItem>>(
      NotificationHistoryNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationHistoryProvider);
  return items.where((e) => !e.isRead).length;
});
