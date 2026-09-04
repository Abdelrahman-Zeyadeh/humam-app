import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart' show Ayah;
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/user_providers.dart';
import '../azkar/azkar_full_repository.dart' show azkarLibraryProvider;
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
    required this.audioMinutesThisWeek,
  });

  final String? continueReadingSurah;
  final Ayah ayahOfDay;
  final String ayahOfDaySurah;
  final String dhikrOfDay;

  /// دقائق الاستماع للتلاوة خلال آخر ٧ أيام (راجع `UserRepository.getAudioMinutes`).
  final int audioMinutesThisWeek;
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

  // آية/ذكر "الفترة": يتغيّران كل ١٠ دقائق لا يبقيان ثابتَين طول اليوم —
  // `_dashboardRotationBucketProvider` يدفع إعادة الحساب فقط لما تتغيّر
  // الفترة فعلاً (لا كل ثانية). لا عشوائية حقيقية مخزَّنة ولا نص مؤلَّف: فهرس
  // حتمي يقرأ من قاعدة البيانات/المصدر المرخّص دائماً — لكن يمرّ عبر [_scatter]
  // (تبعثر Knuth الضربي) قبل التحويل لفهرس، فلا يبقى تسلسلياً (`+1` بالآية
  // كل فترة، غالباً بنفس السورة) كما كان سابقاً؛ نفس `bucket` يُنتج نفس
  // الآية دائماً (حتمي)، لكن الفترات المتتالية تقفز بلا نمط ظاهر.
  const totalAyahs = 6236;
  final bucket = ref.watch(_dashboardRotationBucketProvider).value ?? _rotationBucketFor(DateTime.now());
  final ayahId = (_scatter(bucket, salt: 0x9E3779B1) % totalAyahs) + 1;
  final ayah = await quran.ayahById(ayahId);
  final ayahSurah = await quran.surahById(ayah.surah);

  // فقط أذكار قصيرة مكرَّرة (تسبيح/تهليل/استغفار/تحميد) — لا أدعية طويلة.
  // معيار بنيوي من البيانات نفسها لا تصنيف مكتوب يدوياً: العدّ (`count`)
  // بمصدر أذكار حصن المسلم مرتفع تحديداً للصيغ المكرَّرة القصيرة (تسبيح
  // ١٠٠ مرة مثلاً)، بخلاف الأدعية الطويلة (`count: 1` غالباً). تحقّقتُ من
  // القيم الفعلية بـ`assets/azkar/azkar.json` قبل اختيار الحدَّين.
  //
  // **مصدران معاً** — بطلب صاحب المشروع "شو الاذكار اللي مخليها تنعرض؟
  // ضيف تسبيح تحميد لا تهليل": أذكار الصباح/المساء (٣٤ ذكراً، `azkar.json`)
  // وحدها لا تضمّ صيغ التسبيح المفردة الكلاسيكية (سبحان الله/الحمد لله/الله
  // أكبر ٣٣-٣٤ مرة — موجودة فقط بقسم "أذكار النوم" بمكتبة حصن المسلم
  // الكاملة، `azkar_categories.json`، تحقّقتُ مباشرة من الملف). فأضفنا كل
  // المكتبة (١٣١ قسماً) بنفس معيار القِصَر/التكرار العالي، فيتّسع التنوّع
  // كثيراً بدل الاقتصار على ٣٤ عنصراً فقط.
  final azkarList = await ref.watch(azkarListProvider.future);
  final azkarLibrary = await ref.watch(azkarLibraryProvider.future);
  final tasbihStyle = <String>[
    for (final d in azkarList)
      if (d.count >= 3 && d.content.length <= 130) d.content,
    for (final cat in azkarLibrary)
      for (final it in cat.items)
        if (it.count >= 10 && it.text.length <= 60) it.text,
  ];
  final dhikrPool = tasbihStyle.isNotEmpty
      ? tasbihStyle
      : [for (final d in azkarList) d.content];
  final dhikrOfDay = dhikrPool.isEmpty ? '' : dhikrPool[_scatter(bucket, salt: 0x85EBCA6B) % dhikrPool.length];

  final audioMinutesThisWeek = await ref.watch(userRepositoryProvider).getAudioMinutes(7);

  return HomeDashboardData(
    continueReadingSurah: continueReadingSurah,
    ayahOfDay: ayah,
    ayahOfDaySurah: ayahSurah.nameArPlain,
    dhikrOfDay: dhikrOfDay,
    audioMinutesThisWeek: audioMinutesThisWeek,
  );
});

const _kRotationMinutes = 10; // ~١٤٤ فترة/يوم

int _rotationBucketFor(DateTime t) => t.difference(DateTime(t.year)).inMinutes ~/ _kRotationMinutes;

/// نبضة تدفع إعادة حساب آية/ذكر "الفترة" — تتحقّق كل دقيقة (كافية لالتقاط
/// تغيّر فترة الـ١٠ دقائق بسرعة معقولة)، لكن القيمة المُصدَرة (`bucket`) لا
/// تتغيّر فعلياً إلا كل ١٠ دقائق (`.distinct()`)، فلا نعيد استعلام قاعدة
/// البيانات إلا لما تتغيّر الفترة فعلاً.
final _dashboardRotationBucketProvider = StreamProvider.autoDispose<int>((ref) async* {
  yield _rotationBucketFor(DateTime.now());
  yield* Stream<int>.periodic(const Duration(minutes: 1), (_) => _rotationBucketFor(DateTime.now())).distinct();
});

/// تبعثر حتمي بسيط (Knuth's multiplicative hashing) — نفس `bucket` يُنتج
/// نفس القيمة دائماً (لا حالة عشوائية مخزَّنة، لا تعتمد على وقت التشغيل)،
/// لكن قيم `bucket` المتتالية (كل ١٠ دقائق) تُنتج فهارس متباعدة بلا نمط
/// "+1" ظاهر. `salt` مختلف بين استخدامَي الآية والذكر كي لا يدورا معاً
/// بنفس النمط بالضبط بأي لحظة.
int _scatter(int bucket, {required int salt}) {
  final h = (bucket + salt) * 2654435761;
  return h & 0x7FFFFFFF;
}
