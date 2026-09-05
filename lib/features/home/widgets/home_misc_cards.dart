import 'package:flutter/material.dart';

import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../hifz/hifz_screen.dart';
import '../../khatma/khatma_screen.dart' show KhatmaScreen;
import '../home_style_helpers.dart';

/// دعوة لبدء خطة ختمة/حفظ — تظهر فقط لو ما عند المستخدم خطة نشطة من
/// النوع المعني بعد (سدّ فجوة الاكتشاف: بطاقتَي الختمة/الحفظ لا تظهران
/// إلا بعد بدء خطة أصلاً، فبلا هاي الدعوة ما فيه أي إشارة بالداشبورد
/// توجّه مستخدم جديد لبدء واحدة). استُخرجت من `home_screen.dart` أثناء
/// تفكيك الملف بلا أي تغيير سلوكي.
class StartPlanPrompt extends StatelessWidget {
  const StartPlanPrompt({super.key, required this.showKhatma, required this.showHifz});
  final bool showKhatma;
  final bool showHifz;

  @override
  Widget build(BuildContext context) {
    final bothMissing = showKhatma && showHifz;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TintedIconBadge(
                icon: Icons.rocket_launch_outlined,
                color: AppColors.gold,
                iconColor: AppColors.goldDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bothMissing
                      ? 'ابدأ رحلتك مع القرآن اليوم'
                      : showKhatma
                      ? 'ما بدأت خطة ختمة بعد'
                      : 'ما بدأت خطة حفظ بعد',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: homeTextStrong(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bothMissing
                ? 'خطة ختمة أو خطة حفظ بتساعدك تلتزم بوردك اليومي بانتظام'
                : showKhatma
                ? 'حدّد وتيرتك اليومية وتابع تقدّمك صفحة بصفحة'
                : 'حدّد ما تحفظه وتابع مراجعتك بجدول ذكي',
            style: TextStyle(fontSize: 11, color: homeTextSoft(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showKhatma)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KhatmaScreen()),
                    ),
                    child: const Text(
                      'ابدأ خطة ختمة',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ),
              if (showKhatma && showHifz) const SizedBox(width: 8),
              if (showHifz)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HifzScreen()),
                    ),
                    child: const Text(
                      'ابدأ خطة حفظ',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شكل هيكلي (skeleton) بديل مؤقت لبطاقة قيد التحميل — استُخرجت من
/// `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: homeCardBorder(context),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

/// شارة صغيرة "دقائق التلاوة هذا الأسبوع" — راجع
/// `UserRepository.getAudioMinutes`/`audio_log` (`quran_audio_controller.dart`
/// يسجّل ثواني الاستماع الفعلية). تظهر فقط لو استمع المستخدم فعلياً هذا
/// الأسبوع (>٠ دقيقة) — بلا بطاقة فارغة لمستخدم جديد. استُخرجت من
/// `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class ListeningMinutesChip extends StatelessWidget {
  const ListeningMinutesChip({super.key, required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.headphones_outlined,
            color: AppColors.tealDeep,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'دقائق التلاوة هذا الأسبوع: $minutes دقيقة',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: homeTextStrong(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// زرّا الإجراء أسفل الرئيسية ("تقرير أسبوعي"/"تخصيص الواجهة") — حبّة
/// (pill) مستديرة بالكامل بارتفاع ٤٨ وأيقونة برُقعة دائرية، مطابقة
/// لأسلوب لوحة التصميم المعتمدة، بدل `OutlinedButton` مستطيل الحواف.
/// استُخرجت من `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class PillActionButton extends StatelessWidget {
  const PillActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final badgeColor = accent ? themeAccent(context) : homeTextStrong(context);
    return Material(
      color: homeCardSurface(context),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: homeCardBorder(context)),
            boxShadow: homeCardShadow(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: badgeColor),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: homeTextStrong(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
