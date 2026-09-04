import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// أفاتار مبسَّط (أيقونة + لون) لعضو مجموعة صحبة — قائمة محدودة مختارة
/// (نفس فلسفة `app_accent_colors.dart`: خيارات جاهزة لا لون/أيقونة حرّة)
/// بدل صورة شخصية حقيقية، لتفادي تعقيد رفع/تخزين صور لكل عضو بكل مجموعة.
class GroupAvatarPreset {
  const GroupAvatarPreset({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

const List<GroupAvatarPreset> kGroupAvatarPresets = [
  GroupAvatarPreset(icon: Icons.mosque_rounded, color: Color(0xFF1B8A72)),
  GroupAvatarPreset(icon: Icons.menu_book_rounded, color: AppColors.goldDeep),
  GroupAvatarPreset(icon: Icons.nights_stay_rounded, color: Color(0xFF2C5E8A)),
  GroupAvatarPreset(icon: Icons.favorite_rounded, color: Color(0xFFB5495B)),
  GroupAvatarPreset(icon: Icons.star_rounded, color: Color(0xFF7E429B)),
  GroupAvatarPreset(icon: Icons.eco_rounded, color: Color(0xFF3E8E5B)),
  GroupAvatarPreset(icon: Icons.wb_sunny_rounded, color: Color(0xFFD98324)),
  GroupAvatarPreset(icon: Icons.fingerprint_rounded, color: Color(0xFF00796B)),
];

/// `index` مصدره حقل غير موثوق جاء أصلاً من Firestore (أو قيمة قديمة قبل
/// هذه الميزة) — `clamp` يحمي من خروج الفهرس عن حدود القائمة بدل رمي
/// استثناء، ويرجع أول عنصر افتراضياً (بدل الأخير) ليطابق سلوك `avatarIndex:
/// 0` السابق للأعضاء الحاليين بلا اختيار صريح.
GroupAvatarPreset groupAvatarByIndex(int index) =>
    kGroupAvatarPresets[index.clamp(0, kGroupAvatarPresets.length - 1)];
