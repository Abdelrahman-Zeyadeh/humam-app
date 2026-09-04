import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'duroos_lectures_screen.dart';
import 'duroos_models.dart';

export 'duroos_models.dart' show DuroosSource, kDuroosSources;

/// ألوان بطاقة كل مصدر بالشبكة — تدور على مجموعة ثابتة من ألوان هوية
/// التطبيق (ذهبي/كحلي/فيروزي/بنفسجي) حسب ترتيب المصدر، لإعطاء كل عالِم/
/// موضوع هوية بصرية مميزة بدل تكرار نفس التصميم المحايد لكل الصفوف —
/// بطلب صاحب المشروع "القوائم كثير بدائية".
const List<Color> _kSourceAccents = [
  AppColors.goldDeep,
  AppColors.tealDeep,
  AppColors.blue,
  AppColors.purple,
  Color(0xFFE67E22),
  Color(0xFF2E7D32),
  AppColors.navy,
  Color(0xFF8D6E63),
];

/// قائمة العلماء/المواضيع — كل بطاقة تفتح `DuroosLecturesScreen` بمحتوى
/// حقيقي (محاضرات فعلية بعناوينها الصحيحة قابلة للتشغيل مباشرة)، لا
/// رابطاً خارجياً يفتح متصفحاً. راجع `duroos_models.dart` للمصادر
/// وسبب هذا القرار.
///
/// **شبكة بطاقات "غلاف" بدل قائمة صفوف مسطّحة** — كل بطاقة برأس ملوّن
/// مميّز (تدرّج + أيقونة كبيرة) واسم/وصف أسفله، بطلب صاحب المشروع "القوائم
/// كثير بدائية" (كانت `ListView.separated` بصفوف نصية متطابقة الشكل).
///
/// **بلا `Scaffold`/`AppBar` خاصّين بها عمداً** — تُستخدَم كتبويب داخل
/// `RadioAndDuroosScreen` (راجع `radio_and_duroos_screen.dart`)، هي
/// المزوِّد الوحيد للـ`Scaffold`/`AppBar` الآن. لا نقطة دخول تانية
/// تستخدمها مباشرة (تحقّق `grep` وقت هذا التعديل).
/// رأس البطاقة الاحتياطي (تدرّج ملوّن + أيقونة كبيرة) — يُستخدَم لمصادر
/// بلا صورة شخصية بعد بـ[DuroosSource.imageAsset]، وأيضاً كـ`errorBuilder`
/// لو تعذّر تحميل الصورة المضمَّنة لأي سبب.
class _SourceIconHeader extends StatelessWidget {
  const _SourceIconHeader({
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  final IconData icon;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.35 : 0.22),
            accent.withValues(alpha: isDark ? 0.16 : 0.08),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 40, color: accent),
    );
  }
}

class DuroosScreen extends StatelessWidget {
  const DuroosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: kDuroosSources.length,
      itemBuilder: (context, index) {
        final source = kDuroosSources[index];
        final accent = _kSourceAccents[index % _kSourceAccents.length];

        return Material(
          color: isDark ? const Color(0xFF1B232E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DuroosLecturesScreen(source: source, title: source.title),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (isDark ? AppColors.lineDark : AppColors.line)
                      .withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رأس البطاقة: صورة شخصية حقيقية للشيخ/العالِم لو متوفرة
                  // (`source.imageAsset` — راجع توثيقها بـ`duroos_models.dart`)،
                  // وإلا أيقونة ملوّنة احتياطية بنفس الأسلوب القديم — بطلب
                  // صاحب المشروع "هات صور لكل شيخ وعالم... وضعها بمكانها".
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: source.imageAsset != null
                          ? Image.asset(
                              source.imageAsset!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              // بعض صور المصادر مصدرها بدقة كبيرة جداً (تصل
                              // لأكتر من 1000px عرض) بينما البطاقة بالشبكة
                              // صغيرة — بلا `cacheWidth` كان يفكّ كل صورة
                              // بدقتها الكاملة بالذاكرة (RGBA غير مضغوط) في
                              // كل مرة تُبنى الشبكة، وهذا بيسبب تهنيج ملموس
                              // (jank) عند فتح/تمرير تبويب الدروس. تحديد
                              // عرض فكّ معقول (~3x بطاقة الشبكة بشاشة عادية)
                              // يخفّض الذاكرة والوقت بلا فرق مرئي بالجودة.
                              cacheWidth: 480,
                              errorBuilder: (_, __, ___) => _SourceIconHeader(
                                icon: source.icon,
                                accent: accent,
                                isDark: isDark,
                              ),
                            )
                          : _SourceIconHeader(
                              icon: source.icon,
                              accent: accent,
                              isDark: isDark,
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            height: 1.3,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 13,
                              color: accent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'استماع مباشر',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
