/// نمط ملفات القارئ: `perAyah` = ملف منفصل لكل آية (يسمح بالتظليل المتزامن
/// وتكرار آية/مقطع بدقة)، `perSurahOnly` = ملف واحد للسورة كاملة (لا يوجد
/// مصدر تقسيم بالآية موثّق لهذا القارئ بعد — لا تظليل متزامن ولا تكرار
/// مقطع، فقط تشغيل/إيقاف وسرعة وتكرار السورة كاملة).
enum ReciterAudioMode { perAyah, perSurahOnly }

class Reciter {
  const Reciter({required this.id, required this.nameAr, required this.mode});
  final String id;
  final String nameAr;
  final ReciterAudioMode mode;
}

/// القرّاء الأربعة المعتمدون بالتطبيق. المصادر تحقّقنا من صحّتها يدوياً
/// (طلبات HTTP فعلية أعادت ملفات صوت حقيقية) قبل الاعتماد — راجع
/// tools/raw/README.md، قسم "الصوت".
const List<Reciter> kReciters = [
  Reciter(id: 'husary', nameAr: 'الحصري', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'minshawy', nameAr: 'المنشاوي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'qasim', nameAr: 'عبدالمحسن القاسم', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'baleela', nameAr: 'بندر بليلة', mode: ReciterAudioMode.perSurahOnly),
];

const String kDefaultReciterId = 'husary';

Reciter reciterById(String id) => kReciters.firstWhere(
      (r) => r.id == id,
      orElse: () => kReciters.first,
    );

/// مجلد everyayah.com للقرّاء ذوي التقسيم بالآية (`perAyah` فقط).
String _everyAyahFolder(String reciterId) => switch (reciterId) {
      'husary' => 'Husary_128kbps',
      'minshawy' => 'Minshawy_Murattal_128kbps',
      'qasim' => 'Muhsin_Al_Qasim_192kbps',
      _ => throw ArgumentError('لا يوجد تقسيم بالآية لهذا القارئ: $reciterId'),
    };

/// رابط ملف آية واحدة. أسماء ملفات everyayah.com: `SSSAAA.mp3` (سورة ثم
/// آية، كل منهما ٣ خانات بأصفار بادئة).
String ayahAudioUrl(String reciterId, int surah, int ayah) {
  final folder = _everyAyahFolder(reciterId);
  final s = surah.toString().padLeft(3, '0');
  final a = ayah.toString().padLeft(3, '0');
  return 'https://everyayah.com/data/$folder/$s$a.mp3';
}

/// رابط ملف سورة كاملة واحد — القارئ الوحيد المعتمد له حالياً هو بندر
/// بليلة (لا تقسيم بالآية متوفّر له من مصدر موثّق). أسماء ملفات
/// mp3quran.net لسوره: `SSS.mp3` (٣ خانات بأصفار بادئة).
String surahAudioUrl(String reciterId, int surah) {
  final s = surah.toString().padLeft(3, '0');
  if (reciterId == 'baleela') return 'https://server6.mp3quran.net/balilah/$s.mp3';
  throw ArgumentError('استخدم قائمة ملفات آيات بدل ملف سورة واحد لهذا القارئ: $reciterId');
}
