import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
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

    // إذا كنا بعد منتصف الليل وقبل الفجر، فإن الصلاة السابقة هي عشاء الأمس
    if (recentPrayer == null) {
      final yesterday = computeDayTimes(
        lat: lat,
        lon: lon,
        date: now.subtract(const Duration(days: 1)),
        methodKey: methodKey,
      );
      final lastYesterday = yesterday.lastWhere((t) => t.moment.isPrayer);
      final off = userPrefs.prayerOffsetFor(lastYesterday.moment.name);
      recentPrayer = PrayerMomentTime(
        lastYesterday.moment,
        lastYesterday.time.add(Duration(minutes: off)),
      );
    }

    final int iqamahMinutes = userPrefs.iqamahMinutesFor(recentPrayer.moment.name);
    final DateTime iqamahTarget = recentPrayer.time.add(Duration(minutes: iqamahMinutes));
    final bool inIqamahWindow = now.isBefore(iqamahTarget);

    PrayerMomentTime? next;
    for (final t in dayTimes.where((t) => t.moment.isPrayer)) {
      final off = userPrefs.prayerOffsetFor(t.moment.name);
      final adjTime = t.time.add(Duration(minutes: off));
      if (adjTime.isAfter(now)) {
        next = PrayerMomentTime(t.moment, adjTime);
        break;
      }
    }
    if (next == null) {
      final tomorrow = computeDayTimes(
        lat: lat,
        lon: lon,
        date: now.add(const Duration(days: 1)),
        methodKey: methodKey,
      );
      final firstTomorrow = tomorrow.firstWhere((t) => t.moment.isPrayer);
      final off = userPrefs.prayerOffsetFor(firstTomorrow.moment.name);
      next = PrayerMomentTime(
        firstTomorrow.moment,
        firstTomorrow.time.add(Duration(minutes: off)),
      );
    }

    final activeMoment = inIqamahWindow ? recentPrayer.moment : next.moment;

    final statusBadge = _computeTimeStatusBadge(now, dayTimes);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        children: [
          Row(
            children: [
              if (showChecklistLink)
                Material(
                  color: isDark
                      ? const Color(0xFF243442)
                      : const Color(0xFF135B4C).withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrayerChecklistScreen(),
                      ),
                    ),
                    child: Tooltip(
                      message: 'الصلوات والعبادات',
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.checklist_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF64B5A5)
                              : const Color(0xFF135B4C),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 28),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059)
                            .withValues(alpha: isDark ? 0.18 : 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        inIqamahWindow ? 'وقت الإقامة' : 'الصلاة القادمة',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFD4AF67)
                              : const Color(0xFF8C6D3F),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      inIqamahWindow
                          ? 'صلاة ${recentPrayer.moment.nameAr} · جاري انتظار الإقامة 🕌'
                          : 'باقي على صلاة ${next.moment.nameAr}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E2833),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 6),

          if (inIqamahWindow) ...[
            _IqamahCountdownWidget(
              adhanTime: recentPrayer.time,
              iqamahTarget: iqamahTarget,
              now: now,
              prayerName: recentPrayer.moment.nameAr,
            ),
          ] else ...[
            _CountdownText(
              target: next.time,
              prayerName: next.moment.nameAr,
              previousTime: recentPrayer.time,
              previousName: recentPrayer.moment.nameAr,
            ),
          ],

          if (statusBadge != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBadge.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusBadge.color.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusBadge.icon, size: 13, color: statusBadge.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      statusBadge.text,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusBadge.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          _MiniDayTimeline(
            dayTimes: dayTimes,
            activeMoment: activeMoment,
            nextMoment: next.moment,
          ),

          if (footer != null) ...[
            const SizedBox(height: 12),
            Divider(
              color: isDark ? const Color(0xFF2C394A) : const Color(0xFFEADBCA),
              height: 1,
            ),
            const SizedBox(height: 10),
            footer!,
          ],
        ],
      ),
    );

    return Card(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 1.5,
      shadowColor: const Color(0xFF135B4C).withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF2A3F4D)
              : const Color(0xFFDCC8A6),
          width: 1.2,
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? const [
                    Color(0xFF1A2836),
                    Color(0xFF15222D),
                    Color(0xFF122624),
                  ]
                : const [
                    Color(0xFFFAF6EC),
                    Color(0xFFF2ECE0),
                    Color(0xFFE7F2EE),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PrayerOrnamentPainter(
                  color: (isDark
                          ? const Color(0xFFD4AF67)
                          : const Color(0xFFC5A059))
                      .withValues(alpha: isDark ? 0.08 : 0.1),
                ),
              ),
            ),
            onTap == null ? content : InkWell(onTap: onTap, child: content),
          ],
        ),
      ),
    );
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

    if (sunrise == null || dhuhr == null || maghrib == null || fajr == null) {
      return null;
    }

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
  const _MiniDayTimeline({
    required this.dayTimes,
    required this.activeMoment,
    this.nextMoment,
  });
  final List<PrayerMomentTime> dayTimes;
  final PrayerMoment activeMoment;
  final PrayerMoment? nextMoment;

  static const _shown = [
    PrayerMoment.fajr,
    PrayerMoment.sunrise,
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

  IconData _iconFor(PrayerMoment m) => switch (m) {
    PrayerMoment.fajr => Icons.auto_awesome,
    PrayerMoment.sunrise => Icons.wb_twilight_outlined,
    PrayerMoment.dhuhr => Icons.wb_sunny_outlined,
    PrayerMoment.asr => Icons.sunny,
    PrayerMoment.maghrib => Icons.wb_twilight_rounded,
    PrayerMoment.isha => Icons.nights_stay_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        for (final moment in _shown)
          Expanded(
            child: Builder(
              builder: (context) {
                final t = dayTimes.where((d) => d.moment == moment).firstOrNull;
                final isNext = moment == nextMoment;
                final isActive = moment == activeMoment && !isNext;

                final Color borderColor;
                final Color contentColor;
                final Gradient? gradient;
                final Color? bgColor;

                if (isNext) {
                  gradient = const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF135B4C), Color(0xFF1D7E6A)],
                  );
                  bgColor = null;
                  borderColor = const Color(0xFFD4AF67);
                  contentColor = Colors.white;
                } else if (isActive) {
                  gradient = null;
                  bgColor = isDark
                      ? const Color(0xFF2C2212)
                      : const Color(0xFFF6EBD4);
                  borderColor = const Color(0xFFC5A059);
                  contentColor = isDark
                      ? const Color(0xFFD4AF67)
                      : const Color(0xFF8C6D3F);
                } else {
                  gradient = null;
                  bgColor = isDark
                      ? const Color(0xFF18222E).withValues(alpha: 0.85)
                      : const Color(0xFFF6F1E6).withValues(alpha: 0.85);
                  borderColor = isDark
                      ? const Color(0xFF2C394A)
                      : const Color(0xFFE3D3B8);
                  contentColor = isDark
                      ? Colors.white70
                      : const Color(0xFF5C5042);
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: borderColor,
                      width: (isNext || isActive) ? 1.3 : 0.9,
                    ),
                    boxShadow: isNext
                        ? [
                            BoxShadow(
                              color: const Color(0xFF135B4C)
                                  .withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(moment),
                        size: 15,
                        color: isNext
                            ? const Color(0xFFF5D78E)
                            : contentColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        moment.nameAr,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 9.5,
                          fontWeight: (isNext || isActive)
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        t == null ? '' : _formatTime(t.time),
                        style: TextStyle(
                          color: contentColor.withValues(alpha: 0.92),
                          fontSize: 9.5,
                          fontWeight: (isNext || isActive)
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _IqamahCountdownWidget extends StatelessWidget {
  const _IqamahCountdownWidget({
    required this.adhanTime,
    required this.iqamahTarget,
    required this.now,
    required this.prayerName,
  });

  final DateTime adhanTime;
  final DateTime iqamahTarget;
  final DateTime now;
  final String prayerName;

  String _formatTime(DateTime t) {
    final h24 = t.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h12:$m';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = iqamahTarget.difference(now);
    final positive = remaining.isNegative ? Duration.zero : remaining;
    final m = positive.inMinutes.toString().padLeft(2, '0');
    final s = (positive.inSeconds % 60).toString().padLeft(2, '0');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countdownColor =
        isDark ? const Color(0xFF55CBAA) : const Color(0xFF0E5D52);

    final totalSec = iqamahTarget.difference(adhanTime).inSeconds;
    final elapsedSec = now.difference(adhanTime).inSeconds;
    final rawProgress = totalSec > 0
        ? (elapsedSec / totalSec).clamp(0.0, 1.0)
        : 1.0;
    final visualProgress = rawProgress.clamp(0.08, 0.96);
    final percentInt = (rawProgress * 100).round().clamp(0, 100);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // العداد الرقمي المباشر لوقت الإقامة المتبقي
          Text(
            '$m:$s',
            style: TextStyle(
              color: countdownColor,
              fontSize: 35,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              height: 1.12,
              shadows: [
                Shadow(
                  color: countdownColor.withValues(alpha: isDark ? 0.25 : 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // شريط التمرير الحيوي لوقت الإقامة (من الأذان إلى وقت الإقامة)
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final fillWidth =
                  (trackWidth * visualProgress).clamp(16.0, trackWidth);
              final thumbOffset =
                  (fillWidth - 10.0).clamp(0.0, trackWidth - 20.0);

              return SizedBox(
                height: 22,
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  clipBehavior: Clip.none,
                  children: [
                    // المسار الخلفي الدافئ
                    Container(
                      height: 10,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF263545)
                            : const Color(0xFFE3D3B8).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF33465A)
                              : const Color(0xFFD5C09D).withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                    ),
                    // الشريط الملوّن المتدرج المفعم بالحيوية
                    Container(
                      height: 10,
                      width: fillWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: AlignmentDirectional.centerStart,
                          end: AlignmentDirectional.centerEnd,
                          colors: [
                            Color(0xFF0E5D52),
                            Color(0xFF1B8A72),
                            Color(0xFFD4AF37),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B8A72)
                                .withValues(alpha: isDark ? 0.45 : 0.32),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // المقبض الدائري المضيء
                    PositionedDirectional(
                      start: thumbOffset,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC5A059),
                            width: 3.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC5A059)
                                  .withValues(alpha: 0.45),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF135B4C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // يمين الشريط: أذان الصلاة
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 13,
                    color: isDark
                        ? const Color(0xFFD4AF67)
                        : const Color(0xFF9B7842),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'أذان $prayerName ${_formatTime(adhanTime)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFD4AF67)
                          : const Color(0xFF8C6D3F),
                    ),
                  ),
                ],
              ),
              // منتصف الشريط: النسبة المئوية لانقضاء وقت الإقامة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2D3A)
                      : const Color(0xFFEDE2CD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'انقضى $percentInt%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFD4AF67)
                        : const Color(0xFF7A5C2E),
                  ),
                ),
              ),
              // يسار الشريط: وقت الإقامة
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الإقامة ${_formatTime(iqamahTarget)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF55CBAA)
                          : const Color(0xFF0E5D52),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFF55CBAA)
                        : const Color(0xFF0E5D52),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownText extends ConsumerWidget {
  const _CountdownText({
    required this.target,
    required this.prayerName,
    this.previousTime,
    this.previousName,
  });

  final DateTime target;
  final String prayerName;
  final DateTime? previousTime;
  final String? previousName;

  String _formatTime(DateTime t) {
    final h24 = t.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h12:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(prayerTickProvider).value ?? DateTime.now();
    final remaining = target.difference(now);
    final positive = remaining.isNegative ? Duration.zero : remaining;
    final h = positive.inHours.toString().padLeft(2, '0');
    final m = (positive.inMinutes % 60).toString().padLeft(2, '0');
    final s = (positive.inSeconds % 60).toString().padLeft(2, '0');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countdownColor =
        isDark ? const Color(0xFF55CBAA) : const Color(0xFF0E5D52);

    final prev = previousTime ?? target.subtract(const Duration(hours: 4));
    final totalSec = target.difference(prev).inSeconds;
    final elapsedSec = now.difference(prev).inSeconds;
    final rawProgress =
        totalSec > 0 ? (elapsedSec / totalSec).clamp(0.0, 1.0) : 0.5;
    // ضمان ظهور جزء ملون حيوي دائماً حتى في أول الدقائق بعد الأذان
    final visualProgress = rawProgress.clamp(0.08, 0.96);
    final percentInt = (rawProgress * 100).round().clamp(0, 100);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // العداد الرقمي المباشر بالأخضر الزمردي مع توهج خفيف
          Text(
            '$h:$m:$s',
            style: TextStyle(
              color: countdownColor,
              fontSize: 35,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              height: 1.12,
              shadows: [
                Shadow(
                  color: countdownColor.withValues(alpha: isDark ? 0.25 : 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // شريط التمرير الحيوي المتدرج من اليمين (الصلاة السابقة) إلى اليسار (الصلاة القادمة)
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final fillWidth =
                  (trackWidth * visualProgress).clamp(16.0, trackWidth);
              final thumbOffset =
                  (fillWidth - 10.0).clamp(0.0, trackWidth - 20.0);

              return SizedBox(
                height: 22,
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  clipBehavior: Clip.none,
                  children: [
                    // المسار الخلفي الدافئ
                    Container(
                      height: 10,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF263545)
                            : const Color(0xFFE3D3B8).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF33465A)
                              : const Color(0xFFD5C09D).withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                    ),
                    // الشريط الملوّن المتدرج المفعم بالحيوية (زمردي -> فيروزي -> ذهبي مضيء)
                    Container(
                      height: 10,
                      width: fillWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: AlignmentDirectional.centerStart,
                          end: AlignmentDirectional.centerEnd,
                          colors: [
                            Color(0xFF0E5D52),
                            Color(0xFF1B8A72),
                            Color(0xFFD4AF37),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B8A72)
                                .withValues(alpha: isDark ? 0.45 : 0.32),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // المقبض الدائري المضيء عند موضع التقدم الحالي
                    PositionedDirectional(
                      start: thumbOffset,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC5A059),
                            width: 3.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC5A059)
                                  .withValues(alpha: 0.45),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF135B4C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // يمين الشريط: الصلاة السابقة التي مضت
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFFD4AF67)
                        : const Color(0xFF9B7842),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    previousName != null
                        ? '$previousName ${_formatTime(prev)}'
                        : '',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFD4AF67)
                          : const Color(0xFF8C6D3F),
                    ),
                  ),
                ],
              ),
              // وسط الشريط: شارة نسبة الوقت المنقضي لإضافة حيوية واضحة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF135B4C)
                      .withValues(alpha: isDark ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF135B4C)
                        .withValues(alpha: isDark ? 0.4 : 0.2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'مضى $percentInt٪',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF64B5A5)
                        : const Color(0xFF135B4C),
                  ),
                ),
              ),
              // يسار الشريط: الصلاة القادمة المستهدفة
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: countdownColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$prayerName ${_formatTime(target)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: countdownColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// رسام نقوش وأقواس هندسية إسلامية في خلفية بطاقة مواقيت الصلاة
class _PrayerOrnamentPainter extends CustomPainter {
  const _PrayerOrnamentPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // أقواس إسلامية علوية ناعمة
    final archPath = Path();
    final w = size.width;
    final h = size.height;

    archPath.moveTo(w * 0.05, h);
    archPath.lineTo(w * 0.05, h * 0.25);
    archPath.quadraticBezierTo(w * 0.05, h * 0.04, w * 0.5, h * 0.02);
    archPath.quadraticBezierTo(w * 0.95, h * 0.04, w * 0.95, h * 0.25);
    archPath.lineTo(w * 0.95, h);
    canvas.drawPath(archPath, paint);

    // زهرة زخرفية ثمانية في مركز البطاقة
    final center = Offset(w * 0.5, h * 0.32);
    const radius = 24.0;
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final petalCenter = Offset(
        center.dx + (radius * 0.5) * math.cos(angle),
        center.dy + (radius * 0.5) * math.sin(angle),
      );
      canvas.drawCircle(petalCenter, radius * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
