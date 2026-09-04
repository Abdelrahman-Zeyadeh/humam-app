import 'package:flutter/foundation.dart' show visibleForTesting;

import 'tafsir_edition_database.dart';
import 'tafsir_edition_files.dart';

/// يحلّ أي طلب تفسير غير مضمَّن (بمفتاح الإصدار) إلى اتصال drift الصحيح —
/// اتصال مفتوح على ملف تفسير مُنزَّل (يُفتح مرّة واحدة ويُخزَّن مؤقتاً).
/// نفس نمط `HadithDbRegistry` بالضبط، لكن **بلا اتصال مضمَّن هون** —
/// الجلالين (الإصدار المضمَّن الوحيد) يبقى يُقرأ من `QuranDatabase` نفسها
/// عبر `QuranRepository.tafsirForAyah` مباشرة، لا عبر هالصنف إطلاقاً.
class TafsirEditionRegistry {
  TafsirEditionRegistry() : _opened = {}, _isTesting = false;

  /// للاختبارات فقط — يمرّر خريطة اتصالات جاهزة مباشرة بدل البحث عن ملفات
  /// مُنزَّلة فعلياً عبر `path_provider`. راجع `HadithDbRegistry.forTesting`.
  @visibleForTesting
  TafsirEditionRegistry.forTesting(Map<String, TafsirEditionDatabase> opened)
    : _opened = opened,
      _isTesting = true;

  final Map<String, TafsirEditionDatabase> _opened;
  final bool _isTesting;

  /// `null` لو الإصدار غير منزَّل بعد. لا يُستدعى بـ`jalalayn` إطلاقاً —
  /// ذاك يُقرأ من `quran.db` مباشرة (راجع توثيق الصنف أعلاه).
  Future<TafsirEditionDatabase?> dbForEdition(String editionKey) async {
    final cached = _opened[editionKey];
    if (cached != null) return cached;
    final file = await tafsirEditionLocalFile(editionKey);
    if (!await file.exists()) return null;
    final db = TafsirEditionDatabase(file);
    _opened[editionKey] = db;
    return db;
  }

  /// يفتح اتصالات أي إصدار مُنزَّل على القرص لم يُلمَس هالجلسة بعد —
  /// حالياً غير مُستخدَم (لا بحث نصي عابر للتفاسير بعد، خلافاً للأحاديث)،
  /// موجود جاهزاً لو أُضيف مستقبلاً. راجع `HadithDbRegistry.activeDatabases`.
  Future<List<TafsirEditionDatabase>> get activeDatabases async {
    if (!_isTesting) {
      for (final key in await scanDownloadedTafsirEditionKeys()) {
        await dbForEdition(key);
      }
    }
    return _opened.values.toList();
  }

  Future<void> closeAll() async {
    for (final db in _opened.values) {
      await db.close();
    }
    _opened.clear();
  }
}
