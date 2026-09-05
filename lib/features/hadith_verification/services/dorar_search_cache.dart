import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/user/user_prefs.dart' show sharedPreferencesProvider;
import '../models/dorar_hadith_result.dart';

/// كاش محلي لنتائج بحث دُرر السنية المتكررة — الجلب الفعلي بطيء نسبياً
/// (يحتاج تحميل صفحة كاملة بـ`WebView` حقيقي، راجع `DorarWebViewFetcher`)،
/// فتكرار نفس الاستعلام (بحث المستخدم لنفس الحديث أكثر من مرة، أو نفس
/// الاستعلام من "التحقق من صحة" بشاشات أخرى) يعيد استخدام النتيجة المحفوظة
/// بدل WebView جديد كل مرة. صلاحية محدودة ([_kTtl]) لا كاش دائم — محتوى
/// الدرر نادراً ما يتغيّر لكنه ليس ثابتاً كلياً.
final dorarSearchCacheProvider = Provider<DorarSearchCache>((ref) {
  return DorarSearchCache(ref.read(sharedPreferencesProvider));
});

class DorarSearchCache {
  DorarSearchCache(this._prefs);
  final SharedPreferences _prefs;

  static const _keyPrefix = 'dorar_search_cache_';
  static const _kTtl = Duration(days: 3);

  String _key(String query) => '$_keyPrefix${query.trim().toLowerCase()}';

  /// يرجّع النتائج المحفوظة لو موجودة ولسّا ضمن مدة الصلاحية، وإلا `null`
  /// (يشمل عدم وجود أي كاش أصلاً).
  List<DorarHadithResult>? get(String query) {
    final raw = _prefs.getString(_key(query));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > _kTtl) {
        return null;
      }
      final list = decoded['results'] as List<dynamic>;
      return list
          .map((e) => DorarHadithResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // تنسيق كاش قديم/تالف — تجاهله بأمان بدل رمي خطأ يُسقِط البحث.
      return null;
    }
  }

  Future<void> set(String query, List<DorarHadithResult> results) async {
    final payload = jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    });
    await _prefs.setString(_key(query), payload);
  }
}
