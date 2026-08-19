/// رابط استضافة خطوط صفحات المصحف غير المضمَّنة (٥١-٦٠٤) — GitHub
/// Releases بمستودع `humam-app-assets`، الإصدار v1، تحقّق ٢٠٢٦-٠٨-١٩ من
/// أن `p51.ttf` و`p604.ttf` ينزّلان بنجاح (HTTP 200) بالحجم الصحيح.
///
/// شكل الرابط النهائي لكل صفحة: `$kFontsBaseUrl/p{page}.ttf`
const String kFontsBaseUrl =
    'https://github.com/Abdelrahman-Zeyadeh/humam-app-assets/releases/download/v1';

bool get isFontsBaseUrlConfigured => kFontsBaseUrl != 'PLACEHOLDER_NOT_CONFIGURED';

String fontDownloadUrl(int page) => '$kFontsBaseUrl/p$page.ttf';
