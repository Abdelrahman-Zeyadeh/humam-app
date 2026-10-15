/// نمط ملفات القارئ: `perAyah` = ملف منفصل لكل آية (يسمح بالتظليل المتزامن
/// وتكرار آية/مقطع بدقة)، `perSurahOnly` = ملف واحد للسورة كاملة (لا يوجد
/// مصدر تقسيم بالآية موثّق لهذا القارئ بعد — لا تظليل متزامن ولا تكرار
/// مقطع، فقط تشغيل/إيقاف وسرعة وتكرار السورة كاملة).
enum ReciterAudioMode { perAyah, perSurahOnly }

class Reciter {
  const Reciter({
    required this.id,
    required this.nameAr,
    required this.mode,
    String? imageAsset,
  }) : _imageAsset = imageAsset;

  final String id;
  final String nameAr;
  final ReciterAudioMode mode;
  final String? _imageAsset;

  String get imageAsset => _imageAsset ?? 'assets/images/reciters/$id.jpg';
}

/// القرّاء المعتمدون بالتطبيق من مصادر موثوقة (everyayah.com / mp3quran.net)
const List<Reciter> kReciters = [
  Reciter(id: 'husary', nameAr: 'محمود خليل الحصري (مرتل)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'husary_mujawwad', nameAr: 'محمود خليل الحصري (مجود)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'husary_muallim', nameAr: 'محمود خليل الحصري (المصحف المعلم)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'minshawy', nameAr: 'محمد صديق المنشاوي (مرتل)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'minshawy_mujawwad', nameAr: 'محمد صديق المنشاوي (مجود)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'minshawy_teacher', nameAr: 'محمد صديق المنشاوي (المصحف المعلم)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'abdulbasit_murattal', nameAr: 'عبد الباسط عبد الصمد (مرتل)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'abdulbasit_mujawwad', nameAr: 'عبد الباسط عبد الصمد (مجود)', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'tablawi', nameAr: 'محمد محمود الطبلاوي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'mustafa_ismail', nameAr: 'مصطفى إسماعيل', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'banna', nameAr: 'محمود علي البنا', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'alafasy', nameAr: 'مشاري العفاسي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'dossari', nameAr: 'ياسر الدوسري', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'muaiqly', nameAr: 'ماهر المعيقلي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'qatami', nameAr: 'ناصر القطامي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'ajamy', nameAr: 'أحمد بن علي العجمي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'ghamadi', nameAr: 'سعد الغامدي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'fares_abbad', nameAr: 'فارس عباد', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'shuraym', nameAr: 'سعود الشريم', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'sudais', nameAr: 'عبد الرحمن السديس', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'juhaynee', nameAr: 'عبد الله عواد الجهني', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'hudhaify', nameAr: 'علي الحذيفي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'qasim', nameAr: 'عبد المحسن القاسم', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'jaber', nameAr: 'علي جابر', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'ayyoub', nameAr: 'محمد أيوب', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'basfar', nameAr: 'عبد الله بصفر', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'shatri', nameAr: 'أبو بكر الشاطري', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'rifai', nameAr: 'هاني الرفاعي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'budair', nameAr: 'صلاح البدير', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'tunaiji', nameAr: 'خليفة الطنيجي', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'matroud', nameAr: 'عبد الله مطرود', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'akhdar', nameAr: 'إبراهيم الأخضر', mode: ReciterAudioMode.perAyah),
  Reciter(id: 'baleela', nameAr: 'بندر بليلة (إمام المسجد الحرام)', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'barhaji', nameAr: 'محمد برهجي (تلاوة حجازية خاشعة)', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'talib_hamid', nameAr: 'أحمد بن طالب بن حميد (إمام المسجد النبوي)', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'qarafi', nameAr: 'عبد الله القرافي (المسجد النبوي)', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'badr_turki', nameAr: 'بدر التركي (الحرم المكي)', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'buaijan', nameAr: 'عبد الله البعيجان (إمام المسجد النبوي)', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'abkar', nameAr: 'إدريس أبكر', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'hazza', nameAr: 'هزاع البلوشي', mode: ReciterAudioMode.perSurahOnly),
  Reciter(id: 'saeedan', nameAr: 'وليد بن راشد السعيدان', mode: ReciterAudioMode.perSurahOnly),
];

const String kDefaultReciterId = 'husary';

Reciter reciterById(String id) =>
    kReciters.firstWhere((r) => r.id == id, orElse: () => kReciters.first);

/// مجلد everyayah.com للقرّاء ذوي التقسيم بالآية (`perAyah` فقط).
String _everyAyahFolder(String reciterId) => switch (reciterId) {
  'husary' => 'Husary_128kbps',
  'husary_mujawwad' => 'Husary_128kbps_Mujawwad',
  'husary_muallim' => 'Husary_Muallim_128kbps',
  'minshawy' => 'Minshawy_Murattal_128kbps',
  'minshawy_mujawwad' => 'Minshawy_Mujawwad_192kbps',
  'minshawy_teacher' => 'Minshawy_Teacher_128kbps',
  'abdulbasit_murattal' => 'Abdul_Basit_Murattal_192kbps',
  'abdulbasit_mujawwad' => 'Abdul_Basit_Mujawwad_128kbps',
  'tablawi' => 'Mohammad_al_Tablaway_128kbps',
  'mustafa_ismail' => 'Mustafa_Ismail_48kbps',
  'banna' => 'Mahmoud_Ali_Al_Banna_32kbps',
  'alafasy' => 'Alafasy_128kbps',
  'dossari' => 'Yasser_Ad-Dussary_128kbps',
  'muaiqly' => 'MaherAlMuaiqly128kbps',
  'qatami' => 'Nasser_Alqatami_128kbps',
  'ajamy' => 'Ahmed_ibn_Ali_al-Ajamy_64kbps_QuranExplorer.Com',
  'ghamadi' => 'Ghamadi_40kbps',
  'fares_abbad' => 'Fares_Abbad_64kbps',
  'shuraym' => 'Saood_ash-Shuraym_128kbps',
  'sudais' => 'Abdurrahmaan_As-Sudais_192kbps',
  'juhaynee' => 'Abdullaah_3awwaad_Al-Juhaynee_128kbps',
  'hudhaify' => 'Hudhaify_128kbps',
  'qasim' => 'Muhsin_Al_Qasim_192kbps',
  'jaber' => 'Ali_Jaber_64kbps',
  'ayyoub' => 'Muhammad_Ayyoub_128kbps',
  'basfar' => 'Abdullah_Basfar_192kbps',
  'shatri' => 'Abu_Bakr_Ash-Shaatree_128kbps',
  'rifai' => 'Hani_Rifai_192kbps',
  'budair' => 'Salah_Al_Budair_128kbps',
  'tunaiji' => 'Khalefa_Al_Tunaiji_64kbps',
  'matroud' => 'Abdullah_Matroud_128kbps',
  'akhdar' => 'Ibrahim_Akhdar_32kbps',
  _ => throw ArgumentError('لا يوجد تقسيم بالآية لهذا القارئ: $reciterId'),
};

/// رابط ملف آية واحدة. أسماء ملفات everyayah.com: `SSSAAA.mp3`.
String ayahAudioUrl(String reciterId, int surah, int ayah) {
  final folder = _everyAyahFolder(reciterId);
  final s = surah.toString().padLeft(3, '0');
  final a = ayah.toString().padLeft(3, '0');
  return 'https://everyayah.com/data/$folder/$s$a.mp3';
}

/// مسار السيرفر السحابي لقراء السورة الكاملة (Mp3Quran)
String _surahAudioBaseUrl(String reciterId) => switch (reciterId) {
  'qarafi' => 'https://server16.mp3quran.net/a_alqrafi/Rewayat-Hafs-A-n-Assem',
  'barhaji' => 'https://server16.mp3quran.net/M_Burhaji/Rewayat-Hafs-A-n-Assem',
  'talib_hamid' => 'https://server16.mp3quran.net/a_binhameed/Rewayat-Hafs-A-n-Assem',
  'baleela' => 'https://server6.mp3quran.net/balilah',
  'badr_turki' => 'https://server10.mp3quran.net/bader/Rewayat-Hafs-A-n-Assem',
  'buaijan' => 'https://server8.mp3quran.net/buajan',
  'abkar' => 'https://server6.mp3quran.net/abkr',
  'hazza' => 'https://server11.mp3quran.net/hazza',
  'saeedan' => 'https://archive.org/download/Walid-Alsaeedan-1438',
  _ => throw ArgumentError(
    'استخدم قائمة ملفات آيات بدل ملف سورة واحد لهذا القارئ: $reciterId',
  ),
};

/// رابط ملف سورة كاملة واحد — راجع [_surahAudioBaseUrl].
String surahAudioUrl(String reciterId, int surah) {
  final s = surah.toString().padLeft(3, '0');
  return '${_surahAudioBaseUrl(reciterId)}/$s.mp3';
}
