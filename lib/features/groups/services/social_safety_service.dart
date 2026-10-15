import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/faith_group.dart';

/// أسباب الإبلاغ عن عضو في مجموعات الصحبة
enum ReportReason {
  spam('رسائل مزعجة أو متكررة (Spam)'),
  inappropriateContent('محتوى غير لائق أو مسيء'),
  cheating('غش أو تلاعب في الأرقام والإنجازات'),
  suspiciousActivity('نشاط مريب أو غير مألوف');

  final String title;
  const ReportReason(this.title);
}

/// بلاغ عن مستخدم
class UserReport {
  final String reporterId;
  final String reportedUserId;
  final String reportedUserName;
  final String groupId;
  final ReportReason reason;
  final String details;
  final DateTime timestamp;

  const UserReport({
    required this.reporterId,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.groupId,
    required this.reason,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'groupId': groupId,
      'reason': reason.name,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// فاحص منطقية التقدم والإنجازات اليومية والجماعية
///
/// يفحص القيم غير المنطقية (مثل قراءة أكثر من ٦٠٤ صفحات في جلسة واحدة أو صلاة أكثر من ٥ صلوات مفروضة)
/// ويمنع التلاعب بالأرقام قبل رفعها للوحة التنافس.
class ProgressValidator {
  static const int maxDailyPrayers = 5;
  static const int maxQuranPages = 604;
  static const int maxDailySunnah = 20;
  static const int maxSingleChallengeIncrement = 604;
  static const int maxGenericCounter = 100000;

  /// التحقق من صحة تقدم الأعمال اليومية
  static ({bool isValid, String? error}) validateDailyProgress(DailyDeedsProgress progress) {
    if (progress.prayersCompleted < 0 || progress.prayersCompleted > maxDailyPrayers) {
      return (
        isValid: false,
        error: 'عدد الصلوات المفروضة يجب ألا يتجاوز $maxDailyPrayers صلوات في اليوم.',
      );
    }
    if (progress.quranPages < 0 || progress.quranPages > maxQuranPages) {
      return (
        isValid: false,
        error: 'عدد صفحات القرآن لا يمكن أن يتجاوز $maxQuranPages صفحة (المصحف كاملاً).',
      );
    }
    if (progress.sunnahCount < 0 || progress.sunnahCount > maxDailySunnah) {
      return (
        isValid: false,
        error: 'عدد ركعات السنن والنوافل غير منطقي (الحد الأقصى $maxDailySunnah).',
      );
    }
    if (progress.tasbihCount < 0 || progress.tasbihCount > maxGenericCounter) {
      return (
        isValid: false,
        error: 'عدد التسبيحات يتجاوز الحد المعقول للتسجيل اليومي.',
      );
    }
    return (isValid: true, error: null);
  }

  /// التحقق من صحة الإضافة إلى التحدي الجماعي
  static ({bool isValid, String? error}) validateChallengeContribution({
    required String unit,
    required int addValue,
  }) {
    if (addValue <= 0) {
      return (isValid: false, error: 'يجب إدخال قيمة موجبة أكبر من صفر.');
    }

    final isPages = unit.contains('صفح') || unit.contains('ورق');
    if (isPages && addValue > maxSingleChallengeIncrement) {
      return (
        isValid: false,
        error: 'القيمة المدخلة ($addValue صفحة) تتجاوز صفحات المصحف الشريف كاملة ($maxQuranPages صفحة).',
      );
    }

    if (addValue > maxGenericCounter) {
      return (
        isValid: false,
        error: 'القيمة المدخلة كبيرة جداً وغير منطقية للمشاركة الواحدة.',
      );
    }

    return (isValid: true, error: null);
  }
}

/// خدمة الأمان الاجتماعي: الإبلاغ، الحظر، وضبط التنافس
///
/// NOTE: Server-side enforcement (Cloud Functions / Firestore security rules & automated banning)
/// is a remaining backend task. Current moderation, rate-limiting, and block filtering
/// are enforced locally and on the client side.
class SocialSafetyService {
  static final SocialSafetyService instance = SocialSafetyService._();
  SocialSafetyService._();

  static const String _kBlockedUsersKey = 'faith_groups_blocked_users';
  static const String _kLocalReportsKey = 'faith_groups_local_reports';

  /// إرسال بلاغ عن عضو
  Future<void> submitReport(UserReport report) async {
    // 1. محاولة الإرسال السحابي إلى مجموعة reports في Firestore
    try {
      await FirebaseFirestore.instance.collection('reports').add(report.toMap());
    } catch (e) {
      debugPrint('SocialSafetyService.submitReport cloud error (fallback to local): $e');
    }

    // 2. تسجيل محلي احتياطي
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentReports = prefs.getStringList(_kLocalReportsKey) ?? [];
      currentReports.add(jsonEncode({
        'reportedUserId': report.reportedUserId,
        'reportedUserName': report.reportedUserName,
        'reason': report.reason.name,
        'details': report.details,
        'time': report.timestamp.toIso8601String(),
      }));
      await prefs.setStringList(_kLocalReportsKey, currentReports);
    } catch (_) {}
  }

  /// حظر مستخدم محلياً
  Future<void> blockUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBlockedUsersKey) ?? [];
    if (!list.contains(userId)) {
      list.add(userId);
      await prefs.setStringList(_kBlockedUsersKey, list);
    }
  }

  /// إلغاء حظر مستخدم
  Future<void> unblockUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBlockedUsersKey) ?? [];
    list.remove(userId);
    await prefs.setStringList(_kBlockedUsersKey, list);
  }

  /// الحصول على قائمة المستخدمين المحظورين
  Future<Set<String>> getBlockedUserIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBlockedUsersKey) ?? [];
    return list.toSet();
  }
}

/// موفر إدارة المستخدمين المحظورين
class BlockedUsersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final ids = await SocialSafetyService.instance.getBlockedUserIds();
    state = ids;
  }

  Future<void> blockUser(String userId) async {
    await SocialSafetyService.instance.blockUser(userId);
    state = {...state, userId};
  }

  Future<void> unblockUser(String userId) async {
    await SocialSafetyService.instance.unblockUser(userId);
    state = state.where((id) => id != userId).toSet();
  }

  bool isBlocked(String userId) => state.contains(userId);
}

final blockedUsersProvider = NotifierProvider<BlockedUsersNotifier, Set<String>>(
  BlockedUsersNotifier.new,
);
