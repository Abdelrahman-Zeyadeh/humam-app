import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/hijri/hijri_date.dart';
import '../../core/theme/app_colors.dart';
import 'prayer_screen.dart' show PrayerChecklistScreen;
import 'prayer_times_service.dart';

/// نبضة كل ثانية لعدّاد الصلاة القادمة — مشتركة بين شاشة الصلاة والداشبورد.
final prayerTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// بطاقة الصلاة القادمة والإقامة — تعرض اليوم والتاريخ الهجري والعد التنازلي
/// المباشر وخلفيات متناسقة مع ثيم التطبيق النشط والحي مع أوقات الكراهة والإستحباب.
class PrayerCountdownCard extends ConsumerWidget {
  const PrayerCountdownCard({
    super.key,
    required this.lat,
    required this.lon,
    required this.methodKey,
    this.onTap,
    this.footer,
    this.showChecklistLink = true,
  });

  final double lat;
  final double lon;
  final String methodKey;

  /// إظهار زر "سجّل صلواتك وعباداتك" — الطريق الأوضح لشاشة
  /// `PrayerChecklistScreen` (راجع توثيق موقع الاستخدام أسفل).
  final bool showChecklistLink;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accentColorVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final accent = themeAccent(context);
    final now = ref.watch(prayerTickProvider).value ?? DateTime.now();

    final dayTimes = computeDayTimes(
      lat: lat,
      lon: lon,
      date: now,
      methodKey: methodKey,
    );

    PrayerMomentTime? recentPrayer;
    for (final t in dayTimes.where((t) => t.moment.isPrayer)) {
      final off = userPrefs.prayerOffsetFor(t.moment.name);
      final adjTime = t.time.add(Duration(minutes: off));
      if (!adjTime.isAfter(now)) {
        recentPrayer = PrayerMomentTime(t.moment, adjTime);
      }
    }

    int iqamahMinutes = 15;
    bool inIqamahWindow = false;
    DateTime? iqamahTarget;

    if (recentPrayer != null) {
      iqamahMinutes = userPrefs.iqamahMinutesFor(recentPrayer.moment.name);
      iqamahTarget = recentPrayer.time.add(Duration(minutes: iqamahMinutes));
      if (now.isBefore(iqamahTarget)) {
        inIqamahWindow = true;
      }
    }

    var next = nextPrayer(dayTimes, now);
    if (next == null) {
      final tomorrow = computeDayTimes(
        lat: lat,
        lon: lon,
        date: now.add(const Duration(days: 1)),
        methodKey: methodKey,
      );
      next = tomorrow.firstWhere((t) => t.moment.isPrayer);
    }

    final activeMoment = inIqamahWindow ? recentPrayer!.moment : next.moment;
    final gradientColors = _dynamicGradientColors(activeMoment, context);

    final statusBadge = _computeTimeStatusBadge(now, dayTimes);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                todayHijriWithDayArabic(now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (inIqamahWindow &&
              recentPrayer != null &&
              iqamahTarget != null) ...[
            Text(
              'صلاة ${recentPrayer.moment.nameAr} · جاري انتظار الإقامة 🕌',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            _IqamahCountdownWidget(
              adhanTime: recentPrayer.time,
              iqamahTarget: iqamahTarget,
              now: now,
            ),
          ] else ...[
            Text(
              'الصلاة القادمة · صلاة ${next.moment.nameAr}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            _CountdownText(
              target: next.time.add(
                Duration(minutes: userPrefs.prayerOffsetFor(next.moment.name)),
              ),
              prayerName: next.moment.nameAr,
            ),
          ],

          if (statusBadge != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBadge.color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusBadge.color.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusBadge.icon, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      statusBadge.text,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          _MiniDayTimeline(dayTimes: dayTimes, activeMoment: activeMoment),

          // بطلب صاحب المشروع: مدخل واضح لشاشة "الصلوات والعبادات" —
          // كانت الطريقة الوحيدة مربّعاً صغيراً وسط شبكة سلاسل الاستمرار
          // بالرئيسية ("مختفية وضايعة")، صار زرّاً صريحاً هون ضمن بطاقة
          // الصلاة الرئيسية نفسها.
          if (showChecklistLink) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrayerChecklistScreen(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.checklist_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'سجّل صلواتك وعباداتك',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_left,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (footer != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
            const SizedBox(height: 10),
            footer!,
          ],
        ],
      ),
    );

    return Card(
      color: accent,
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: gradientColors,
          ),
        ),
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }

  List<Color> _dynamicGradientColors(
    PrayerMoment moment,
    BuildContext context,
  ) {
    final accent = themeAccent(context);
    final hsv = HSVColor.fromColor(accent);
    final darkColor = hsv
        .withValue((hsv.value * 0.55).clamp(0.1, 1.0))
        .toColor();
    return [accent.withValues(alpha: 0.92), darkColor];
  }

  ({String text, Color color, IconData icon})? _computeTimeStatusBadge(
    DateTime now,
    List<PrayerMomentTime> dayTimes,
  ) {
    final sunrise = dayTimes
        .where((t) => t.moment == PrayerMoment.sunrise)
        .firstOrNull
        ?.time;
    final dhuhr = dayTimes
        .where((t) => t.moment == PrayerMoment.dhuhr)
        .firstOrNull
        ?.time;
    final asr = dayTimes
        .where((t) => t.moment == PrayerMoment.asr)
        .firstOrNull
        ?.time;
    final maghrib = dayTimes
        .where((t) => t.moment == PrayerMoment.maghrib)
        .firstOrNull
        ?.time;
    final fajr = dayTimes
        .where((t) => t.moment == PrayerMoment.fajr)
        .firstOrNull
        ?.time;

    if (sunrise == null || dhuhr == null || maghrib == null || fajr == null)
      return null;

    if (now.isAfter(sunrise) &&
        now.isBefore(sunrise.add(const Duration(minutes: 15)))) {
      return (
        text: 'وقت نهي وكراهة (عند الشروق)',
        color: const Color(0xFFEF4444),
        icon: Icons.remove_circle_outline,
      );
    }
    final istiwaaStart = dhuhr.subtract(const Duration(minutes: 15));
    if (now.isAfter(istiwaaStart) && now.isBefore(dhuhr)) {
      return (
        text: 'وقت نهي وكراهة (قبل الظهر - وقت الاستواء)',
        color: const Color(0xFFEF4444),
        icon: Icons.remove_circle_outline,
      );
    }
    final ghurubStart = asr != null
        ? asr.add(const Duration(minutes: 35))
        : maghrib.subtract(const Duration(minutes: 25));
    if (now.isAfter(ghurubStart) && now.isBefore(maghrib)) {
      return (
        text: 'وقت نهي وكراهة (عند صفار وغروب الشمس)',
        color: const Color(0xFFEF4444),
        icon: Icons.remove_circle_outline,
      );
    }

    final ishraqEnd = sunrise.add(const Duration(minutes: 20));
    if (now.isAfter(sunrise.add(const Duration(minutes: 15))) &&
        now.isBefore(ishraqEnd)) {
      return (
        text: 'وقت مستحب: صلاة الإشراق ✨',
        color: const Color(0xFF10B981),
        icon: Icons.auto_awesome,
      );
    }
    if (now.isAfter(ishraqEnd) &&
        now.isBefore(dhuhr.subtract(const Duration(minutes: 15)))) {
      return (
        text: 'وقت مستحب: صلاة الضحى (صلاة الأوابين) ☀️',
        color: const Color(0xFF10B981),
        icon: Icons.wb_sunny_outlined,
      );
    }

    final nextFajr = fajr.add(const Duration(days: 1));
    final nightDuration = nextFajr.difference(maghrib);
    final lastThird = nextFajr.subtract(
      Duration(minutes: (nightDuration.inMinutes / 3).round()),
    );
    if (now.isAfter(lastThird) || now.isBefore(fajr)) {
      return (
        text: 'وقت مستحب: الثلث الأخير من الليل وقيام الليل 🌙',
        color: const Color(0xFFF59E0B),
        icon: Icons.nightlight_outlined,
      );
    }

    return null;
  }
}

/// شريط مصغّر لمواقيت اليوم الخمسة — يبرز الصلاة الحالية/القادمة بحبّة
/// بيضاء، مطابق لـ"mini day timeline" بلوحة التصميم المعتمدة. لا يستبدل
/// أي منطق حساب موجود، فقط عرض إضافي أسفل بطاقة العدّ التنازلي.
class _MiniDayTimeline extends StatelessWidget {
  const _MiniDayTimeline({required this.dayTimes, required this.activeMoment});
  final List<PrayerMomentTime> dayTimes;
  final PrayerMoment activeMoment;

  static const _shown = [
    PrayerMoment.fajr,
    PrayerMoment.dhuhr,
    PrayerMoment.asr,
    PrayerMoment.maghrib,
    PrayerMoment.isha,
  ];

  String _formatTime(DateTime t) {
    final h24 = t.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h12:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final moment in _shown)
            Expanded(
              child: Builder(
                builder: (context) {
                  final t = dayTimes
                      .where((d) => d.moment == moment)
                      .firstOrNull;
                  final active = moment == activeMoment;
                  final name = Text(
                    moment.nameAr,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  );
                  return Column(
                    children: [
                      active
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                moment.nameAr,
                                style: TextStyle(
                                  color: themeAccent(context),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : name,
                      const SizedBox(height: 2),
                      Text(
                        t == null ? '' : _formatTime(t.time),
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _IqamahCountdownWidget extends StatelessWidget {
  const _IqamahCountdownWidget({
    required this.adhanTime,
    required this.iqamahTarget,
    required this.now,
  });

  final DateTime adhanTime;
  final DateTime iqamahTarget;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final remaining = iqamahTarget.difference(now);
    final positive = remaining.isNegative ? Duration.zero : remaining;
    final m = positive.inMinutes.toString().padLeft(2, '0');
    final s = (positive.inSeconds % 60).toString().padLeft(2, '0');

    final totalSec = iqamahTarget.difference(adhanTime).inSeconds;
    final elapsedSec = now.difference(adhanTime).inSeconds;
    final progress = totalSec > 0
        ? (elapsedSec / totalSec).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Text(
            'متبقي على رفع الإقامة: $m:$s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _CountdownText extends ConsumerWidget {
  const _CountdownText({required this.target, required this.prayerName});

  final DateTime target;
  final String prayerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(prayerTickProvider).value ?? DateTime.now();
    final remaining = target.difference(now);
    final positive = remaining.isNegative ? Duration.zero : remaining;
    final h = positive.inHours.toString().padLeft(2, '0');
    final m = (positive.inMinutes % 60).toString().padLeft(2, '0');
    final s = (positive.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        'المتبقي للصلاة: $h:$m:$s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
