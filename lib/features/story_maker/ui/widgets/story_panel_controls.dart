import 'package:flutter/material.dart';

import '../../../../core/data/quran/quran_database.dart';

/// عنوان صغير لكل مجموعة تحكّم بلوح الخيارات — يفصل بصرياً بين "النمط
/// والمقاس"/"الخلفية"/"حجم الخط"/"عناصر إضافية" بدل ما تكون كتلة واحدة
/// متلاصقة (كانت شكوى صريحة: "شكله كثير معجوق"). استُخرجت من
/// `ayah_story_maker_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class PanelLabel extends StatelessWidget {
  const PanelLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// قائمة منسدلة مضغوطة لاختيار رقم آية ضمن سورة — تُستخدَم مرّتين
/// (طرف "من" و"إلى") بلوح اختيار نطاق الآيات. `minIndex` يقصّ الخيارات
/// الأقل من طرف "من" عند استخدامها لطرف "إلى". استُخرجت من
/// `ayah_story_maker_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class AyahNumberDropdown extends StatelessWidget {
  const AyahNumberDropdown({
    super.key,
    required this.label,
    required this.ayahs,
    required this.value,
    required this.onChanged,
    this.minIndex = 0,
  });

  final String label;
  final List<Ayah> ayahs;
  final int value;
  final int minIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11.5),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        for (var i = minIndex; i < ayahs.length; i++)
          DropdownMenuItem(value: i, child: Text('آية ${ayahs[i].ayah}', style: const TextStyle(fontSize: 13))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
