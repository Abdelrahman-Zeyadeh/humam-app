import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart' show Ayah;
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/user_providers.dart';
import '../azkar/azkar_repository.dart' show azkarListProvider;

/// بيانات الداشبورد المجموعة بطلب واحد — تُبنى من قراءات `quran.db`
/// (async، على isolate drift) بخلاف بقية بيانات الداشبورد (آخر صفحة،
/// السلسلة، الختمة، الموقع) وهي متزامنة أصلاً عبر `UserRepository`
/// المحمَّل مسبقاً. راجع "قاعدة: الرئيسية تُبنى بلا استعلامات متسلسلة
/// بـ initState" ببرومبت-تطوير-همام.md §المرحلة٤ — هذا `FutureProvider`
/// واحد يجمع كل استعلامات drift بدل عدة FutureBuilder متتالية.
class HomeDashboardData {
  const HomeDashboardData({
    required this.continueReadingSurah,
    required this.ayahOfDay,
    required this.ayahOfDaySurah,
    required this.dhikrOfDay,
  });

  final String? continueReadingSurah;
  final Ayah ayahOfDay;
  final String ayahOfDaySurah;
  final String dhikrOfDay;
}

final homeDashboardDataProvider = FutureProvider.autoDispose<HomeDashboardData>((ref) async {
  final quran = ref.watch(quranRepositoryProvider);
  final lastPage = ref.watch(userRepositoryProvider).lastReadPage;

  String? continueReadingSurah;
  if (lastPage != null) {
    final ayahsOnPage = await quran.ayahsForPage(lastPage);
    if (ayahsOnPage.isNotEmpty) {
      final surah = await quran.surahById(ayahsOnPage.first.surah);
      // `nameArPlain` لا `nameAr`: الاسم يشمل كلمة "سورة" أصلاً بقاعدة
      // البيانات (`سورة الكهف` لا `الكهف` فقط) — استخدام `nameAr` هون كان
      // ينتج ازدواج "سورة سورة الكهف" لأن الواجهة كانت تضيف "سورة" ثانية
      // بالنص الثابت. راجع أيضاً نفس القرار بـ`mushaf_page_widget.dart`
      // (تجنّب تشكيل Cairo الخاطئ).
      continueReadingSurah = surah.nameArPlain;
    }
  }

  // آية/ذكر "الفترة": يتغيّران كل ٤ ساعات (٦ فترات باليوم) لا يبقيان ثابتَين
  // طول اليوم — `_dashboardRotationBucketProvider` يدفع إعادة الحساب فقط
  // لما تتغيّر الفترة فعلاً (لا كل ثانية). ما زالت لا عشوائية حقيقية ولا
  // نص مؤلَّف: مجرّد فهرس حتمي يقرأ من قاعدة البيانات/المصدر المرخّص دائماً.
  const totalAyahs = 6236;
  final bucket = ref.watch(_dashboardRotationBucketProvider).value ?? _rotationBucketFor(DateTime.now());
  final ayahId = (bucket % totalAyahs) + 1;
  final ayah = await quran.ayahById(ayahId);
  final ayahSurah = await quran.surahById(ayah.surah);

  // فقط أذكار قصيرة مكرَّرة (تسبيح/تهليل/استغفار/تحميد) — لا أدعية طويلة.
  // معيار بنيوي من البيانات نفسها لا تصنيف مكتوب يدوياً: العدّ (`count`)
  // بمصدر أذكار حصن المسلم مرتفع تحديداً للصيغ المكرَّرة القصيرة (تسبيح
  // ١٠٠ مرة مثلاً)، بخلاف الأدعية الطويلة (`count: 1` غالباً). تحقّقتُ من
  // القيم الفعلية بـ`assets/azkar/azkar.json` قبل اختيار الحدَّين.
  final azkarList = await ref.watch(azkarListProvider.future);
  final tasbihStyle = azkarList.where((d) => d.count >= 3 && d.content.length <= 130).toList();
  final dhikrPool = tasbihStyle.isNotEmpty ? tasbihStyle : azkarList;
  final dhikrOfDay = dhikrPool.isEmpty ? '' : dhikrPool[bucket % dhikrPool.length].content;

  return HomeDashboardData(
    continueReadingSurah: continueReadingSurah,
    ayahOfDay: ayah,
    ayahOfDaySurah: ayahSurah.nameArPlain,
    dhikrOfDay: dhikrOfDay,
  );
});

const _kRotationHours = 4; // ٦ فترات/يوم

int _rotationBucketFor(DateTime t) => t.difference(DateTime(t.year)).inDays * (24 ~/ _kRotationHours) + (t.hour ~/ _kRotationHours);

/// نبضة تدفع إعادة حساب آية/ذكر "الفترة" — تتحقّق كل ٥ دقائق، لكن القيمة
/// المُصدَرة (`bucket`) لا تتغيّر فعلياً إلا كل ٤ ساعات (`.distinct()`)، فلا
/// نعيد استعلام قاعدة البيانات إلا لما تتغيّر الفترة فعلاً.
final _dashboardRotationBucketProvider = StreamProvider.autoDispose<int>((ref) async* {
  yield _rotationBucketFor(DateTime.now());
  yield* Stream<int>.periodic(const Duration(minutes: 5), (_) => _rotationBucketFor(DateTime.now())).distinct();
});
