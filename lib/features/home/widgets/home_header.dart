import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/data/user/dashboard_prefs.dart';
import '../../../core/data/user/khatma_prefs.dart';
import '../../../core/data/user/location_prefs.dart';
import '../../hijri/hijri_calendar_screen.dart';
import '../../khatma/khatma_screen.dart';
import '../../notifications/notification_history_service.dart';
import '../../notifications/notifications_screen.dart';
import '../../prayer/prayer_times_service.dart';
import '../../search/unified_search_screen.dart';
import '../../settings/settings_screen.dart';
import '../dashboard_customize_sheet.dart';
import 'home_contextual_dhikr.dart';

enum _HeaderMenuAction { toggleMinimal, customize }

/// شريط الترحيب والبطاقات العلوية المدمجة بالألوان الملكية (أبيض + أخضر زمردي + ذهبي عاجي)
/// بتصميم مطابق للصورة المرجعية: التاريخ الهجري بالذهبي والأخضر، وبطاقتي الأذكار والختمة
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.hijri});
  final String hijri;

  String _arabicNumber(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? d[i] : c;
    }).join();
  }

  String _monthNameAr(int m) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final locationPrefs = ref.watch(locationPrefsProvider);
    List<PrayerMomentTime>? dayTimes;
    if (locationPrefs.hasLocation) {
      dayTimes = computeDayTimes(
        lat: locationPrefs.lat!,
        lon: locationPrefs.lon!,
        date: now,
        methodKey: locationPrefs.calculationMethod,
      );
    }

    final slot = dayTimes != null
        ? slotForDayTimes(dayTimes, now)
        : (now.hour < 5
            ? DaySlot.beforeFajr
            : now.hour < 12
                ? DaySlot.morning
                : now.hour < 16
                    ? DaySlot.midday
                    : now.hour < 20
                        ? DaySlot.evening
                        : DaySlot.night);

    final khatmaPrefs = ref.watch(khatmaPrefsProvider);
    final hasActiveKhatma = khatmaPrefs.activePlans.isNotEmpty;
    final activeKhatma = hasActiveKhatma ? khatmaPrefs.activePlans.first : null;

    final cal = HijriCalendar.fromDate(now);
    HijriCalendar.language = 'ar';
    const weekdays = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    final weekdayName = weekdays[now.weekday - 1];
    final hijriDay = cal.hDay;
    final hijriMonthName = cal.getLongMonthName();
    final gregorianDateStr = '${_arabicNumber(now.day)} ${_monthNameAr(now.month)} ${_arabicNumber(now.year)}';

    // Dhikr card info based on current slot
    final String dhikrSubtitle;
    final String dhikrTitle;
    final IconData dhikrIcon;
    switch (slot) {
      case DaySlot.beforeFajr:
        dhikrSubtitle = 'وقت السحر';
        dhikrTitle = 'قيام الليل';
        dhikrIcon = Icons.nightlight_round;
        break;
      case DaySlot.morning:
        dhikrSubtitle = 'ابدأ يومك بالذكر';
        dhikrTitle = 'أذكار الصباح';
        dhikrIcon = Icons.wb_sunny_rounded;
        break;
      case DaySlot.midday:
        dhikrSubtitle = 'صلاة الأوابين';
        dhikrTitle = 'صلاة الضحى';
        dhikrIcon = Icons.light_mode_rounded;
        break;
      case DaySlot.evening:
        dhikrSubtitle = 'حصّن نفسك';
        dhikrTitle = 'أذكار المساء';
        dhikrIcon = Icons.wb_twilight_rounded;
        break;
      case DaySlot.night:
      case DaySlot.unknown:
        dhikrSubtitle = 'قبل أن تنام';
        dhikrTitle = 'أذكار النوم';
        dhikrIcon = Icons.bedtime_rounded;
        break;
    }

    // Dynamic Time-of-Day Atmosphere & Greeting
    final String timeGreeting;
    final String timeSubGreeting;
    final IconData timeIcon;
    final Color timeAccentColor;
    switch (slot) {
      case DaySlot.beforeFajr:
        timeGreeting = 'طاب سحرك بالذكر';
        timeSubGreeting = 'وقت السحر والاستغفار المبارك';
        timeIcon = Icons.nights_stay_rounded;
        timeAccentColor = const Color(0xFF818CF8);
        break;
      case DaySlot.morning:
        timeGreeting = 'أصبحنا وأصبح الملك لله';
        timeSubGreeting = 'ابدأ يومك بنور الذكر والقرآن';
        timeIcon = Icons.wb_sunny_rounded;
        timeAccentColor = const Color(0xFFF59E0B);
        break;
      case DaySlot.midday:
        timeGreeting = 'طابت أوقاتك بالطاعة';
        timeSubGreeting = 'لا تنسَ صلاة الضحى والاستغفار';
        timeIcon = Icons.light_mode_rounded;
        timeAccentColor = const Color(0xFF0D9488);
        break;
      case DaySlot.evening:
        timeGreeting = 'أمسينا وأمسى الملك لله';
        timeSubGreeting = 'حصن نفسك وأهلك بأذكار المساء';
        timeIcon = Icons.wb_twilight_rounded;
        timeAccentColor = const Color(0xFFF97316);
        break;
      case DaySlot.night:
      case DaySlot.unknown:
        timeGreeting = 'ليلة هانئة بالسكينة';
        timeSubGreeting = 'اختم يومك بالوتر وأذكار النوم';
        timeIcon = Icons.bedtime_rounded;
        timeAccentColor = const Color(0xFFA78BFA);
        break;
    }

    final isMinimal = ref.watch(dashboardMinimalModeProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header Row: Title & Action Buttons
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(timeIcon, size: 17, color: timeAccentColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            timeGreeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E2833),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeSubGreeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // زر الإعدادات الأخضر الزمردي
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF135B4C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // زر الإشعارات
              Consumer(
                builder: (context, ref, _) {
                  final unreadCount = ref.watch(unreadNotificationsCountProvider);
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2632) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C394A) : const Color(0xFFEADBCA),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: isDark ? Colors.white70 : const Color(0xFF4A3E31),
                            size: 19,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE55353),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // زر البحث
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UnifiedSearchScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2632) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C394A) : const Color(0xFFEADBCA),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF4A3E31),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // القائمة الإضافية
              PopupMenuButton<_HeaderMenuAction>(
                tooltip: 'خيارات',
                onSelected: (action) {
                  switch (action) {
                    case _HeaderMenuAction.toggleMinimal:
                      ref.read(dashboardMinimalModeProvider.notifier).toggle();
                      break;
                    case _HeaderMenuAction.customize:
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const DashboardCustomizeSheet(),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _HeaderMenuAction.toggleMinimal,
                    child: Row(
                      children: [
                        Icon(
                          isMinimal ? Icons.view_agenda_rounded : Icons.tune_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(isMinimal ? 'العودة للواجهة الكاملة' : 'الوضع البسيط'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _HeaderMenuAction.customize,
                    child: Row(
                      children: [
                        Icon(Icons.dashboard_customize_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('تخصيص الواجهة'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 32,
                  height: 36,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white60 : const Color(0xFF6A5D4E),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Row of Two Cards (Hijri Date Card + Dhikr & Khatma Stack)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // البطاقة اليمنى: التاريخ الهجري الملكي بتدرج عاجي ذهبي دافئ
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: isDark
                            ? const [Color(0xFF1E2632), Color(0xFF252E3C)]
                            : const [Color(0xFFFFFDF8), Color(0xFFF5ECDA)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334254) : const Color(0xFFE0C89F),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC5A059).withValues(alpha: isDark ? 0.1 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HijriCalendarScreen()),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // الزخرفة الهندسية والأقواس الإسلامية في الخلفية
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _IslamicOrnamentPainter(
                                  color: (isDark
                                          ? const Color(0xFFD4AF67)
                                          : const Color(0xFFC5A059))
                                      .withValues(alpha: isDark ? 0.11 : 0.14),
                                  showArch: true,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(
                                        Icons.ios_share_rounded,
                                        size: 15,
                                        color: Color(0xFFC5A059),
                                      ),
                                      Text(
                                        weekdayName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFC5A059),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _arabicNumber(hijriDay),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      color: isDark ? const Color(0xFF55CBAA) : const Color(0xFF135B4C),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hijriMonthName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF64B5A5) : const Color(0xFF135B4C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    gregorianDateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6D3F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // البطاقة اليسرى: كرتان متراكبان (أذكار الوقت الحالي + الختمة)
                Expanded(
                  child: Column(
                    children: [
                      // الكرت العلوي: أذكار الوقت الحالي بتدرج زمردي فاتح ومنعش
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: isDark
                                  ? const [Color(0xFF162925), Color(0xFF1D2834)]
                                  : const [Color(0xFFF1F9F6), Color(0xFFE2F1EC)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF26473F) : const Color(0xFFC2DFD7),
                              width: 1.1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => navigateToDhikrDirectly(context, ref, slot),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [Color(0xFF135B4C), Color(0xFF1E7E6A)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        dhikrIcon,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dhikrSubtitle,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : const Color(0xFF5A6D68),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            dhikrTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? const Color(0xFF64B5A5) : const Color(0xFF0E4D40),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // الكرت السفلي: الختمات بتدرج ذهبي رملي دافئ
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: isDark
                                  ? const [Color(0xFF282218), Color(0xFF1E2632)]
                                  : const [Color(0xFFFCF8EE), Color(0xFFF3E8D0)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF423623) : const Color(0xFFE4CFA6),
                              width: 1.1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const KhatmaScreen()),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [Color(0xFFC5A059), Color(0xFFA68038)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.menu_book_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ختماتي',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : const Color(0xFF7A6A52),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            hasActiveKhatma
                                                ? 'صفحة ${_arabicNumber(activeKhatma!.currentPage)} من ٦٠٤'
                                                : 'ابدأ ختمة جديدة',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6D3F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// رسام الزخارف والنقوش الإسلامية الهندسية والأقواس لبطاقات الداشبورد
class _IslamicOrnamentPainter extends CustomPainter {
  const _IslamicOrnamentPainter({
    required this.color,
    this.showArch = true,
  });

  final Color color;
  final bool showArch;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (showArch) {
      // قوس إسلامي علوي (Moorish / Pointed Arch)
      final archPath = Path();
      final w = size.width;
      final h = size.height;

      archPath.moveTo(w * 0.1, h * 0.95);
      archPath.lineTo(w * 0.1, h * 0.42);
      archPath.quadraticBezierTo(w * 0.1, h * 0.08, w * 0.5, h * 0.04);
      archPath.quadraticBezierTo(w * 0.9, h * 0.08, w * 0.9, h * 0.42);
      archPath.lineTo(w * 0.9, h * 0.95);

      canvas.drawPath(archPath, paint);

      // قوس داخلي ناعم موازي
      final innerArch = Path();
      innerArch.moveTo(w * 0.18, h * 0.95);
      innerArch.lineTo(w * 0.18, h * 0.44);
      innerArch.quadraticBezierTo(w * 0.18, h * 0.16, w * 0.5, h * 0.12);
      innerArch.quadraticBezierTo(w * 0.82, h * 0.16, w * 0.82, h * 0.44);
      innerArch.lineTo(w * 0.82, h * 0.95);

      final dashedPaint = Paint()
        ..color = color.withValues(alpha: color.a * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(innerArch, dashedPaint);
    }

    // زهرة زخرفية إسلامية مركزية (Islamic 8-pointed rosette)
    final center = Offset(size.width * 0.5, size.height * 0.48);
    const radius = 26.0;
    final flowerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final petalCenter = Offset(
        center.dx + (radius * 0.5) * math.cos(angle),
        center.dy + (radius * 0.5) * math.sin(angle),
      );
      canvas.drawCircle(petalCenter, radius * 0.45, flowerPaint);
    }
    canvas.drawCircle(center, radius * 0.25, flowerPaint);
  }

  @override
  bool shouldRepaint(covariant _IslamicOrnamentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showArch != showArch;
}
