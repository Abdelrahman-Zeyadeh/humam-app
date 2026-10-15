import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_accent_colors.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../azkar/azkar_full_repository.dart';
import '../../azkar/azkar_library_category_screen.dart';
import '../../azkar/azkar_repository.dart' show AzkarPeriod;
import '../../azkar/azkar_screen.dart';
import '../../prayer/prayer_location_controller.dart';
import '../../prayer/prayer_times_service.dart';
import '../../qiyam/qiyam_screen.dart';
import '../../shell/root_shell.dart';
import '../home_style_helpers.dart';

enum _DaySlot { beforeFajr, morning, midday, evening, night, unknown }

_DaySlot _slotFor(List<PrayerMomentTime> dayTimes, DateTime now) {
  DateTime timeOf(PrayerMoment m) =>
      dayTimes.firstWhere((t) => t.moment == m).time;
  if (now.isBefore(timeOf(PrayerMoment.fajr))) return _DaySlot.beforeFajr;
  if (now.isBefore(timeOf(PrayerMoment.dhuhr))) return _DaySlot.morning;
  if (now.isBefore(timeOf(PrayerMoment.asr))) return _DaySlot.midday;
  if (now.isBefore(timeOf(PrayerMoment.maghrib))) return _DaySlot.evening;
  return _DaySlot.night;
}

/// بطاقة "بلا موقع بعد" — **بنفس هوية `PrayerCountdownCard` اللونية
/// تماماً** (تدرّج `accent.primaryLight/primaryDark` + نص أبيض/ذهبي فاتح)
/// عمداً لا بطاقة بيضاء عادية. قبل هالتعديل كانت بيضاء (`homeCardSurface`)
/// بينما البطاقة الحقيقية بعد تحديد الموقع كحلي/بلون التمييز — يعني
/// المستخدم يشوف "ومضة بيضاء" ثم تنقلب أزرق فجأة أول ما يحدَّد الموقع.
/// هلق الانتقال بلا قفزة لونية محسوسة، بس المحتوى يتبدّل. استُخرجت من
/// `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class NoLocationPrayerCard extends ConsumerWidget {
  const NoLocationPrayerCard({super.key, this.footer});
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accentColorVersionProvider);
    final accent = appAccentColorById(
      ref.read(userPrefsProvider).accentColorId,
    );

    return Card(
      color: accent.primaryDark,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeAccent(context).withValues(alpha: 0.35)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [accent.primaryLight, accent.primaryDark],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    ref.read(locationControllerProvider.notifier).useGps(),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.goldSoft,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مواقيت الصلاة بحسب موقعك',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'اضغط لتحديد موقعك تلقائياً وعرض أوقات الأذان والقبلة',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.my_location,
                      color: AppColors.goldSoft,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 10),
                Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                const SizedBox(height: 8),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// البطاقة القيادية بأعلى الرئيسية بحسب "فترة اليوم" الحالية (قبل الفجر/
/// الصباح/الظهيرة/المساء/الليل) — تحدّد الفترة من مواقيت الصلاة الفعلية
/// إن توفّرت، وإلا تعرض دعوة لتحديد الموقع. استُخرجت من `home_screen.dart`
/// أثناء تفكيك الملف بلا أي تغيير سلوكي.
class LeadingCard extends ConsumerWidget {
  const LeadingCard({super.key, required this.dayTimes, required this.now});
  final List<PrayerMomentTime>? dayTimes;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dayTimes == null) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.goldDeep,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'حدّد موقعك لحساب مواقيت الصلاة وأذكار الفترة',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: homeTextStrong(context)),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(locationControllerProvider.notifier).useGps(),
              child: const Text('تحديد', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final slot = _slotFor(dayTimes!, now);

    return switch (slot) {
      _DaySlot.beforeFajr || _DaySlot.night => _NightQiyamCard(
        title: slot == _DaySlot.beforeFajr ? 'سحر مبارك' : 'أذكار النوم والوتر',
        subtitle: slot == _DaySlot.beforeFajr
            ? 'وقت السحر والتهجد والاستغفار'
            : 'أوتر قبل أن تنام واقرأ أذكارك',
      ),
      _DaySlot.morning => const _AzkarLeadingCard(
        title: 'أذكار الصباح',
        subtitle: 'أصبحنا وأصبح الملك لله — ابدأ يومك بالذكر',
        period: AzkarPeriod.morning,
        icon: Icons.wb_sunny_outlined,
      ),
      _DaySlot.midday => const _MiddayLeadingCard(),
      _DaySlot.evening => const _AzkarLeadingCard(
        title: 'أذكار المساء',
        subtitle: 'أمسينا وأمسى الملك لله — حصّن نفسك',
        period: AzkarPeriod.evening,
        icon: Icons.wb_twilight,
      ),
      _DaySlot.unknown => const _AzkarLeadingCard(
        title: 'أذكار اليوم',
        subtitle: '«ألا بذكر الله تطمئن القلوب»',
        period: AzkarPeriod.morning,
        icon: Icons.brightness_2_outlined,
      ),
    };
  }
}

class _NightQiyamCard extends ConsumerWidget {
  const _NightQiyamCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () async {
        if (title.contains('النوم')) {
          final cached = ref.read(sleepAzkarProvider).value;
          if (cached != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AzkarLibraryCategoryScreen(category: cached),
              ),
            );
          } else {
            final cat = await ref.read(sleepAzkarProvider.future);
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AzkarLibraryCategoryScreen(category: cat),
                ),
              );
            }
          }
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QiyamScreen()),
          );
        }
      },
      child: Row(
        children: [
          const TintedIconBadge(
            icon: Icons.dark_mode_outlined,
            color: AppColors.navy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: homeTextStrong(context),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: homeTextSoft(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: homeTextSoft(context), size: 18),
        ],
      ),
    );
  }
}

class _AzkarLeadingCard extends ConsumerWidget {
  const _AzkarLeadingCard({
    required this.title,
    required this.subtitle,
    required this.period,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final AzkarPeriod period;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AzkarScreen(period: period)),
      ),
      child: Row(
        children: [
          TintedIconBadge(icon: icon, color: AppColors.teal, iconColor: AppColors.tealDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: homeTextStrong(context),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: homeTextSoft(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: homeTextSoft(context), size: 18),
        ],
      ),
    );
  }
}

class _MiddayLeadingCard extends ConsumerWidget {
  const _MiddayLeadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
      child: Row(
        children: [
          const TintedIconBadge(
            icon: Icons.fingerprint,
            color: AppColors.gold,
            iconColor: AppColors.goldDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المسبحة الإلكترونية',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: homeTextStrong(context),
                  ),
                ),
                Text(
                  '«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ» — رطّب لسانك بذكر الله',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: homeTextSoft(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: homeTextSoft(context), size: 18),
        ],
      ),
    );
  }
}
