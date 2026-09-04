import 'package:drift/drift.dart';

/// جدول ملف تفسير مُنزَّل مستقل — يطابق تصميم-النظام.md §٢.٣ حرفياً
/// (`texts(ayah_id, body)`) لا `Tafsirs` بـ`quran_tables.dart` (تلك مصمَّمة
/// لتحوي عدّة تفاسير بجدول واحد عبر عمود `edition`، هون كل ملف تفسير واحد
/// بالتعريف فلا حاجة له). راجع `tools/split_tafsir_editions.py`.
class TafsirTexts extends Table {
  // بلا هذا التصريح، اسم جدول SQL الفعلي الذي يولّده drift افتراضياً من
  // اسم الصنف هو `tafsir_texts` لا `texts` — بينما `tools/split_tafsir_
  // editions.py` ينشئ الجدول باسم `texts` حرفياً (مطابقة تصميم-النظام.md
  // §٢.٣). **عطل حقيقي رُصد باختبار الوحدة**: بلا هذا السطر، الاستعلام
  // يفشل بصمت لجدول غير موجود ويرجع `null` دائماً (لا استثناء واضح) —
  // راجع `test/quran_repository_test.dart`.
  @override
  String get tableName => 'texts';

  IntColumn get ayahId => integer().named('ayah_id')();
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {ayahId};
}
