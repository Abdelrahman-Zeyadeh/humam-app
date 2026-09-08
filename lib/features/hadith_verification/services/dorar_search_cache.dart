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

  /// المفتاح يشمل رقم الصفحة (`page`) — قبل هذا كان الكاش يغطّي الصفحة
  /// الأولى فقط بغض النظر عن الصفحة الفعلية المطلوبة، فزر "تحميل المزيد"
  /// (صفحات ٢+) كان يعيد جلب WebView كامل في كل مرة حتى لتكرار نفس
  /// الاستعلام بالضبط. الصفحة الأولى تبقى بلا لاحقة (`p1` ضمنية) حفاظاً
  /// على توافق مفاتيح الكاش المخزَّنة مسبقاً بأجهزة المستخدمين.
  String _key(String query, int page) {
    final base = '$_keyPrefix${query.trim().toLowerCase()}';
    return page <= 1 ? base : '${base}_p$page';
  }

  /// يرجّع النتائج المحفوظة لو موجودة ولسّا ضمن مدة الصلاحية، وإلا `null`
  /// (يشمل عدم وجود أي كاش أصلاً). `page` افتراضياً ١ (سلوك البحث
  /// الأساسي)، ويُمرَّر رقم أكبر لصفحات "تحميل المزيد".
  List<DorarHadithResult>? get(String query, {int page = 1}) {
    final raw = _prefs.getString(_key(query, page));
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

  static const _historyKey = 'dorar_recent_search_history';

  List<String> getRecentQueries() {
    return _prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> saveQueryToHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final current = getRecentQueries().toList();
    current.remove(q);
    current.insert(0, q);
    if (current.length > 15) {
      current.removeRange(15, current.length);
    }
    await _prefs.setStringList(_historyKey, current);
  }

  Future<void> removeFromHistory(String query) async {
    final current = getRecentQueries().toList();
    current.remove(query);
    await _prefs.setStringList(_historyKey, current);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  /// `page` بنفس معنى [get] — سجل البحث الأخير (`saveQueryToHistory`) لا
  /// يُحدَّث إلا لصفحات البحث الأساسية (١) لتفادي ازدحام السجل بنفس
  /// الاستعلام مكرَّراً لكل صفحة "تحميل المزيد".
  Future<void> set(String query, List<DorarHadithResult> results, {int page = 1}) async {
    final payload = jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    });
    await _prefs.setString(_key(query, page), payload);
    if (page <= 1) await saveQueryToHistory(query);
  }
}
