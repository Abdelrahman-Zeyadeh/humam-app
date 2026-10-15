import 'package:flutter/material.dart';

/// هوية هُمَام البصرية المعتمدة. لا تُغيَّر هذه القيم بلا قرار واعٍ —
/// راجع "تصميم-النظام.md" و"تصميم هُمَام الأولي" (الكانفاس المعتمد) قبل أي تعديل.
abstract final class AppColors {
  // الألوان الأساسية
  static const navy = Color(0xFF0B2545);
  static const navyDeep = Color(0xFF071A33);
  static const blue = Color(0xFF164B7A);
  static const gold = Color(0xFFC9A24B);
  static const goldSoft = Color(0xFFE7D2A0);

  /// نسخة أغمق وأقل تشبّعاً من [gold]، لاستخدامها حصراً كلون **نص أو
  /// أيقونة** فوق خلفيات فاتحة (بطاقات بيضاء/كريمية) — [gold]/[goldSoft]
  /// المباشرين تباينهما هناك ~2.2:1 فقط (دون حد WCAG الأدنى 4.5:1 للنص
  /// العادي). `goldDeep` بتباين ~4.6:1 يحافظ على نفس عائلة اللون بإحساس
  /// أهدأ. [gold]/[goldSoft] يبقيان كما هما لكل استخدامات الخلفية/الزخرفة.
  static const goldDeep = Color(0xFF8C6D3F);

  // الخلفيات
  static const paper = Color(0xFFF6EEDA); // خلفية صفحة المصحف الورقية
  static const cream = Color(0xFFF8F5EE); // خلفية شاشات التطبيق العامة بنمط منار (أبيض على بيج)

  // النصوص
  static const ink = Color(0xFF1C2B3A);
  static const inkSoft = Color(0xFF5B6B7C);

  // لمسات محدودة
  static const teal = Color(0xFF2F8F82);
  static const purple = Color(0xFF6E5B95);

  /// نسخة أغمق من [teal] لاستخدامها كنص/أيقونة فوق خلفيات فاتحة — نفس
  /// سبب وجود [goldDeep]: [teal] المباشر على أبيض/كريمي تباينه ~3.9:1
  /// فقط (دون حد WCAG 4.5:1 للنص العادي). نفس قيمة `primaryLight` لباقة
  /// الفيروزي بـ`app_accent_colors.dart` — تباين ~7.5:1، بلا لون جديد كلياً.
  static const tealDeep = Color(0xFF005B52);

  /// أزرق معلوماتي محايد — لعناصر "معلومة/مشاركة/إحصائية" لا علاقة إلها
  /// بلون التمييز (accent) ولا بعائلة الذهبي. كان مكرَّراً كـ`Color(0xFF386892)`
  /// حرفياً بـ٥ ملفات منفصلة (`about_screen`, `account_data_section`,
  /// `more_placeholder_screen` مرتين، `achievements_screen`) بلا أي ثابت
  /// مشترك بينها — خطر واضح لانحراف اللون لو تغيّر بمكان ونُسي غيره.
  static const infoBlue = Color(0xFF386892);

  static const line = Color(0xFFEBE4D6); // خط إطار ناعم بيج/رملي هادئ

  // الوضع الليلي — دافئة لا سوداء صريحة، بنفس الهوية
  static const paperDark = Color(0xFF221D16); // خلفية صفحة المصحف الليلية
  static const surfaceDark = Color(0xFF0F1E33); // أفتح قليلاً من navyDeep لبطاقات/أشرطة
  static const inkOnDark = Color(0xFFEDE6D8);
  static const inkSoftOnDark = Color(0xFFAFA391);
  static const lineDark = Color(0x22EDE6D8); // inkOnDark بشفافية 13%
}

/// لون تمييز التطبيق **الحالي** — بديل `AppColors.gold` المباشر بكل
/// الودجتات القابلة للتخصيص (أيقونات/شارات/حدود ملوَّنة)، بطلب صاحب
/// المشروع "لون التطبيق لا كامل مش بس الايقونات" (كانت الجولة الأولى مقصورة
/// على `ThemeData.colorScheme.secondary` القياسي — أزرار/مفاتيح/تبويب سفلي
/// فقط، لا هذه الاستخدامات المباشرة الـ٩٠+ بـ٣٠ ملفاً). يقرأ نفس
/// `colorScheme.secondary` المربوط أصلاً بـ`AppTheme.light/dark` حسب اللون
/// المختار بالإعدادات (`app_accent_colors.dart`) — أي `Theme.of(context)`
/// هون يعيد بناء أي ودجت يستخدمه تلقائياً عند تغيّر الثيم (خلافاً لقراءة
/// `AppColors.gold` الثابتة القديمة).
Color themeAccent(BuildContext context) => Theme.of(context).colorScheme.secondary;
