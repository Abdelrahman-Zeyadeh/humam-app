/// رابط استضافة خطوط صفحات المصحف غير المضمَّنة (٥١-٦٠٤) — GitHub
/// Releases بمستودع `humam-app-assets`، الإصدار v1، تحقّق ٢٠٢٦-٠٨-١٩ من
/// أن `p51.ttf` و`p604.ttf` ينزّلان بنجاح (HTTP 200) بالحجم الصحيح.
///
/// شكل الرابط النهائي لكل صفحة: `$kFontsBaseUrl/p{page}.ttf`
///
/// **متغيّر لا `const`** عمداً (خلاف بقية ثوابت هذا الملف) — يسمح لاختبارات
/// `font_download_service.dart` (`FontDownloadController`) بإعادة توجيهه
/// مؤقّتاً لخادم محلي حقيقي بالاختبار (`HttpServer` على `127.0.0.1`) بدل
/// GitHub الفعلي، ثم استعادة القيمة الأصلية بعد كل اختبار. القيمة
/// الافتراضية بالتشغيل الحقيقي هي نفسها تماماً — لا فرق سلوكي بالتطبيق.
String kFontsBaseUrl =
    'https://github.com/Abdelrahman-Zeyadeh/humam-app-assets/releases/download/v1';

String fontDownloadUrl(int page) => '$kFontsBaseUrl/p$page.ttf';

/// رابط استضافة خطوط صفحات مصحف QCF V1 (طبعة 1405هـ) — من مستودع
/// `fadihittih/quran-center-mushaf-assets` (رابط Raw GitHub مباشر).
/// أسماء الملفات تبدأ من `QCF_P001.TTF` حتى `QCF_P604.TTF`.
String kFontsV1BaseUrl =
    'https://raw.githubusercontent.com/fadihittih/quran-center-mushaf-assets/main/fonts';

String fontV1DownloadUrl(int page) {
  final pad = page.toString().padLeft(3, '0');
  return '$kFontsV1BaseUrl/QCF_P$pad.TTF';
}

/// رابط استضافة كتب الأحاديث غير المضمَّنة (كل شيء عدا الأربعين النووية/
/// القدسية — راجع `hadith_book_catalog.dart`). GitHub Releases، مستودع
/// `humam-app-assets`، وسم `hadith-v1` — تحقّق ٢٠٢٦-٠٨-٢٢ من نجاح تنزيل
/// السبعة كلها (HTTP 200) عبر GitHub API مباشرة.
const String kHadithBooksBaseUrl =
    'https://github.com/Abdelrahman-Zeyadeh/humam-app-assets/releases/download/hadith-v1';

String hadithBookDownloadUrl(String bookKey) => '$kHadithBooksBaseUrl/$bookKey.db';

/// رابط استضافة كل إصدارات التفسير/الإعراب/معاني الكلمات (لا شيء مضمَّن
/// — راجع `tafsir_edition_catalog.dart`). GitHub Releases، مستودع
/// `humam-app-assets`، وسم `Tafsir-v1` (نفس وسم ملفات JSON الخام
/// الأصلية — صاحب المشروع رفع ملفات `.db` على نفس الإصدار بدل وسم
/// منفصل). **تحقّق ٢٠٢٦-٠٩-٠١ مباشر عبر GitHub API: كل الـ١٤ ملفاً
/// بالكتالوج مرفوعون فعلياً وأحجامهم مطابقة تماماً** (الميسر/السعدي/
/// ابن كثير/الجلالين + المختصر/عثيمين/أضواء البيان/البغوي/الطبري/
/// القرطبي/إعراب×٣/معاني الكلمات) — لا شيء ناقص أو يرجع ٤٠٤ حالياً،
/// خلاف ما وثّقته مذكّرة سابقة (كانت ٤ من ١٤ فقط، رُفعت البقية بجلسة
/// غير موثَّقة لاحقة). لو رجعت لهالموضوع لاحقاً وشكّيت بحالة أي ملف،
/// تحقّق عبر GitHub API مباشرة (`/releases/tags/Tafsir-v1`) لا افتراضاً.
const String kTafsirEditionsBaseUrl =
    'https://github.com/Abdelrahman-Zeyadeh/humam-app-assets/releases/download/Tafsir-v1';

String tafsirEditionDownloadUrl(String editionKey) => '$kTafsirEditionsBaseUrl/tafsir_$editionKey.db';

/// رابط استضافة صور صفحات المصحف المصورة (طبعات سكان مجمع الملك فهد
/// الرسمية — راجع خطة `golden-cuddling-tiger.md` للسياق الكامل). ثلاث
/// نسخ بمعرّفات `normal`/`jawamie`/`premium` (راجع `RasterMushafEdition`
/// بـ`mushaf_settings.dart`)، كل نسخة ٦٠٤ صفحة WebP.
///
/// **إصدار GitHub منفصل لكل نسخة** (`mushaf-images-<edition>-v1`) — لا
/// وسم واحد مشترك للثلاث نسخ معاً: GitHub Releases يحدّ كل إصدار بـ١٠٠٠
/// أصل كحد أقصى، و٣×٦٠٤=١٨١٢ أصل يتجاوز الحد بوسم واحد (اكتُشف عملياً
/// أثناء الرفع اليدوي ٢٠٢٦-٠٩-٠٤). أسماء الملفات داخل كل إصدار مسبوقة
/// باسم النسخة رغم استقلال الإصدار (`<edition>_%03d.webp`، مثلاً
/// `normal_001.webp`) — هيك رُفعت فعلياً يدوياً، أبسط من إعادة تسمية
/// ٦٠٤×٣ ملف محلياً بلا أي فائدة عملية إضافية.
///
/// **لم تُرفع الإصدارات بعد** — تحويل ملفات PDF المصدرية لصور فعلية
/// (`tools/build_mushaf_page_images.py`) عمل منفصل قيد التنفيذ بالتوازي.
/// الرابط جاهز بنفس نمط `kFontsBaseUrl`/`kTafsirEditionsBaseUrl` تحسّباً؛
/// لا تفترض نجاح التنزيل الفعلي قبل تحقّق مباشر من رفع الوسوم.
///
/// تجاوز اختياري (افتراضياً `null`) — يسمح لاختبار
/// `mushaf_image_download_test.dart` بإعادة توجيه كل النسخ مؤقّتاً لخادم
/// محلي حقيقي بالاختبار بدل GitHub الفعلي، بلا حاجة لمحاكاة ٣ وسوم
/// منفصلة (الاختبار لا يهمّه أي وسم، فقط "أي رابط أساسي تُطلَب منه
/// `/{page:03d}.webp`" — نفس نمط `kFontsBaseUrl` القديم، بس هون كتجاوز
/// منفصل لأن الرابط الفعلي بالإنتاج يعتمد على `editionId` (دالة لا قيمة
/// ثابتة واحدة).
String? kMushafImagesBaseUrlOverride;

String mushafImagePageUrl(String editionId, int page) {
  final pad = page.toString().padLeft(3, '0');
  final base = kMushafImagesBaseUrlOverride ??
      'https://github.com/Abdelrahman-Zeyadeh/humam-app-assets/releases/download/mushaf-images-$editionId-v1';
  return '$base/$pad.webp';
}
