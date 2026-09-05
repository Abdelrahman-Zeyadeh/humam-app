import 'package:flutter/material.dart';

/// ألوان مشتركة بين مكوّنات نافذة "مشاركة الآية" (الشيت الرئيسي، المعاينات،
/// ونوافذ الاختيار) — مجمّعة هنا حتى تبقى متطابقة تماماً أينما استُخدمت بدل
/// تكرار قيم الألوان الصريحة (Hex) في كل ملف على حِدة.
class AyahShareColors {
  AyahShareColors._();

  static const primaryGreen = Color(0xFF437A4D);
  static const parchmentBg = Color(0xFFF9F6EE);
  static const parchmentCard = Color(0xFFFAF7F0);
  static const borderTan = Color(0xFFE2D8C3);
  static const goldMushaf = Color(0xFFC5A059);
}
