package com.humam.humam_app

/**
 * يطابق `kAppAccentColors` بـ `lib/core/theme/app_accent_colors.dart` —
 * كل ودجت شاشة رئيسية (Humam/PrayerBar/Dhikr/AyahDhikr) يقرأ `accent_id`
 * من SharedPreferences (يُدفَع من Flutter عبر `updateHumamHomeWidget`)
 * ويختار خلفية التدرّج المطابقة بدل الكحلي الثابت — راجع تعليق
 * `humam_widget_background.xml` لتفاصيل القيم. **حدّث هالخريطة لو أُضيف
 * لون تمييز جديد بـ`app_accent_colors.dart`** (drawable مطابق يلزم أيضاً).
 */
object WidgetAccentColors {
  fun backgroundRes(accentId: String?): Int =
      when (accentId) {
        "emerald" -> R.drawable.humam_widget_bg_emerald
        "amber" -> R.drawable.humam_widget_bg_amber
        "parchment" -> R.drawable.humam_widget_bg_parchment
        "blue" -> R.drawable.humam_widget_bg_blue
        "teal" -> R.drawable.humam_widget_bg_teal
        "purple" -> R.drawable.humam_widget_bg_purple
        "obsidian" -> R.drawable.humam_widget_bg_obsidian
        else -> R.drawable.humam_widget_background // "gold" الافتراضي + أي قيمة غير معروفة
      }
}
