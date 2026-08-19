/// رابط استضافة خطوط صفحات المصحف غير المضمَّنة (٥١-٦٠٤). **قيمة مؤقتة
/// غير فعلية بعد** — راجع "مدير تنزيل الخطوط" بـ tools/raw/README.md
/// لخطوات الاستضافة (GitHub Releases مُوصى به: مجاني، رابط ثابت، بلا
/// حدّ سرعة عملياً لحجمنا). حدّث هذا الثابت فقط بالرابط الحقيقي بعد رفع
/// ملفات `p51.ttf` … `p604.ttf` (بنفس التسمية حرفياً) كـ release assets.
///
/// شكل الرابط النهائي لكل صفحة: `$kFontsBaseUrl/p{page}.ttf`
/// مثال GitHub Releases: `https://github.com/OWNER/REPO/releases/download/TAG`
const String kFontsBaseUrl = 'PLACEHOLDER_NOT_CONFIGURED';

bool get isFontsBaseUrlConfigured => kFontsBaseUrl != 'PLACEHOLDER_NOT_CONFIGURED';

String fontDownloadUrl(int page) => '$kFontsBaseUrl/p$page.ttf';
