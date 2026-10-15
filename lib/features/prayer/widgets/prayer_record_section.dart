import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../azkar/post_prayer_azkar_screen.dart';
import '../prayer_analytics_screen.dart';
import '../prayer_times_service.dart';

/// مفتاح تاريخ بصيغة YYYY-MM-DD مطابق لما تقرأه PrayerAnalyticsScreen
String _formatDateKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// اختصارات أيام الأسبوع العربية المتطابقة مع التصميم
String _dayAbbr(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'إث',
    DateTime.tuesday => 'ثل',
    DateTime.wednesday => 'أر',
    DateTime.thursday => 'خم',
    DateTime.friday => 'جم',
    DateTime.saturday => 'سب',
    DateTime.sunday => 'أحد',
    _ => '',
  };
}

/// فئة صلاة في شريط التسجيل
class _PrayerRecordItem {
  const _PrayerRecordItem({
    required this.key,
    required this.category,
    required this.label,
  });

  final String key;
  final String category;
  final String label;
}

const _kPrayers = [
  _PrayerRecordItem(
    key: 'fajr',
    category: UserCategories.fajr,
    label: 'الفجر',
  ),
  _PrayerRecordItem(
    key: 'dhuhr',
    category: UserCategories.dhuhr,
    label: 'الظهر',
  ),
  _PrayerRecordItem(
    key: 'asr',
    category: UserCategories.asr,
    label: 'العصر',
  ),
  _PrayerRecordItem(
    key: 'maghrib',
    category: UserCategories.maghrib,
    label: 'المغرب',
  ),
  _PrayerRecordItem(
    key: 'isha',
    category: UserCategories.isha,
    label: 'العشاء',
  ),
];

/// قسم "سجل صلواتك" و"الالتزام الأسبوعي" في شاشة الصلاة
/// مطابق لتصميم منار وفذكر وصورة المستخدم
class PrayerRecordSection extends ConsumerStatefulWidget {
  const PrayerRecordSection({super.key});

  @override
  ConsumerState<PrayerRecordSection> createState() => _PrayerRecordSectionState();
}

class _PrayerRecordSectionState extends ConsumerState<PrayerRecordSection> {
  // تخزين محلي لبيانات الصلوات المسجلة لليوم
  Map<String, String> _todayPrayerStatus = {};
  // تخزين محلي لبيانات السنن الرواتب لليوم
  Map<String, bool> _todaySunnahStatus = {};
  // تخزين محلي لعدد الصلوات لكل يوم من آخر 7 أيام
  List<int> _weeklyCounts = List.filled(7, 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  static String _sunnahLabelFor(String prayerKey) {
    return switch (prayerKey) {
      'fajr' => 'سنة الفجر (ركعتان قبل الفريضة)',
      'dhuhr' => 'سنة الظهر (٤ قبلية + ٢ بعدية)',
      'asr' => 'سنة العصر (٤ ركعات مستحبة)',
      'maghrib' => 'سنة المغرب (ركعتان بعد الفريضة)',
      'isha' => 'سنة العشاء (ركعتان) والوتر',
      _ => 'السنّة الراتبة',
    };
  }

  static String _sunnahShortName(String prayerKey) {
    return switch (prayerKey) {
      'fajr' => 'سنة الفجر (٢)',
      'dhuhr' => 'سنة الظهر (٤+٢)',
      'asr' => 'سنة العصر (٤)',
      'maghrib' => 'سنة المغرب (٢)',
      'isha' => 'العشاء والوتر',
      _ => 'السنّة',
    };
  }

  static String _sunnahCategoryFor(String prayerKey) {
    return switch (prayerKey) {
      'fajr' => UserCategories.sunnahFajrQabliyah,
      'dhuhr' => UserCategories.sunnahDhuhrBadiyah,
      'asr' => UserCategories.sunnahAsrQabliyah,
      'maghrib' => UserCategories.sunnahMaghribBadiyah,
      'isha' => UserCategories.sunnahIshaBadiyah,
      _ => UserCategories.sunnahDuha,
    };
  }

  Future<void> _toggleSunnah(String prayerKey) async {
    final now = DateTime.now();
    final loc = ref.read(locationPrefsProvider);
    final effectiveLat = loc.lat ?? kDefaultFallbackLat;
    final effectiveLon = loc.lon ?? kDefaultFallbackLon;
    final dayTimes = computeDayTimes(
      lat: effectiveLat,
      lon: effectiveLon,
      date: now,
      methodKey: loc.calculationMethod,
    );
    final pTime = dayTimes.firstWhere((t) => t.moment.name == prayerKey).time;
    final current = _todaySunnahStatus[prayerKey] ?? false;

    // لا يمكن تسجيل السنة قبل دخول وقت صلاتها
    if (now.isBefore(pTime) && !current) {
      if (mounted) {
        final prayerLabel = _kPrayers.firstWhere((p) => p.key == prayerKey).label;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.lock_clock_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('لم يحن وقت ${_sunnahLabelFor(prayerKey)} بعد — تفتح مع أذان صلاة $prayerLabel'),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final todayKey = _formatDateKey(now);
    final sp = await SharedPreferences.getInstance();
    final next = !current;
    if (next) {
      await sp.setBool('prayer_sunnah_${prayerKey}_$todayKey', true);
      final cat = _sunnahCategoryFor(prayerKey);
      await ref.read(userPrefsProvider).bumpCategoryStreakIfNewDay(cat);
    } else {
      await sp.remove('prayer_sunnah_${prayerKey}_$todayKey');
    }
    ref.read(categoryStreakVersionProvider.notifier).bump();
    await _loadHistory();
    if (mounted && next) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('تقبّل الله طاعتك 🤲 — تمّ تسجيل ${_sunnahLabelFor(prayerKey)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadHistory() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = _formatDateKey(now);

      // 1. قراءة صلوات وسنن اليوم
      final Map<String, String> todayMap = {};
      final Map<String, bool> sunnahMap = {};
      for (final p in _kPrayers) {
        final val = sp.getString('prayer_perf_${p.key}_$todayKey');
        if (val != null) {
          todayMap[p.key] = val;
        }
        sunnahMap[p.key] = sp.getBool('prayer_sunnah_${p.key}_$todayKey') ?? false;
      }

      // 2. قراءة آخر 7 أيام (منذ 6 أيام حتى اليوم)
      final List<int> counts = [];
      for (int i = 0; i < 7; i++) {
        final dt = now.subtract(Duration(days: 6 - i));
        final dateKey = _formatDateKey(dt);
        int dayCount = 0;
        for (final p in _kPrayers) {
          if (sp.getString('prayer_perf_${p.key}_$dateKey') != null) {
            dayCount++;
          }
        }
        counts.add(dayCount);
      }

      if (mounted) {
        setState(() {
          _todayPrayerStatus = todayMap;
          _todaySunnahStatus = sunnahMap;
          _weeklyCounts = counts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePrayer(_PrayerRecordItem item) async {
    _showPrayerOptionsSheet(item);
  }

  Future<void> _showPrayerOptionsSheet(_PrayerRecordItem item) async {
    final now = DateTime.now();
    final todayKey = _formatDateKey(now);
    final currentStatus = _todayPrayerStatus[item.key];
    String? tempSelected = currentStatus;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E232B) : const Color(0xFFFAF7F2),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isSunnahDone = _todaySunnahStatus[item.key] ?? false;
            final loc = ref.read(locationPrefsProvider);
            final effectiveLat = loc.lat ?? kDefaultFallbackLat;
            final effectiveLon = loc.lon ?? kDefaultFallbackLon;
            final dayTimes = computeDayTimes(
              lat: effectiveLat,
              lon: effectiveLon,
              date: DateTime.now(),
              methodKey: loc.calculationMethod,
            );
            final pTime = dayTimes.firstWhere((t) => t.moment.name == item.key).time;
            final isSunnahLocked = DateTime.now().isBefore(pTime);

            final options = [
              (
                key: 'masjid',
                title: 'في المسجد',
                sub: 'حضرت المسجد',
                icon: Icons.mosque_rounded,
                iconColor: const Color(0xFF2E7D32),
                iconBg: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9),
              ),
              (
                key: 'jamaah',
                title: 'جماعة',
                sub: 'جماعة في المنزل أو العمل',
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF00796B),
                iconBg: isDark ? const Color(0xFF173835) : const Color(0xFFE0F2F1),
              ),
              (
                key: 'on_time',
                title: 'في الوقت',
                sub: 'خلال وقت الصلاة',
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFFB8860B),
                iconBg: isDark ? const Color(0xFF38321A) : const Color(0xFFFFF8E1),
              ),
              (
                key: 'qadaa',
                title: 'قضاء',
                sub: 'صلّيت قضاءً بعد الفوات',
                icon: Icons.history_rounded,
                iconColor: const Color(0xFFD35400),
                iconBg: isDark ? const Color(0xFF3B281B) : const Color(0xFFFBEFE3),
              ),
              (
                key: 'missed',
                title: 'فائتة',
                sub: 'سجّلها بصدق وانطلق إلى الأمام',
                icon: Icons.cancel_outlined,
                iconColor: const Color(0xFFC0392B),
                iconBg: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFDEDEC),
              ),
            ];

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شريط السحب العلوي
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : const Color(0xFFD6CEBF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // عنوان الصلاة وأيقونة الساعة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF2E2721),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'كيف أدّيت هذه الصلاة؟',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : const Color(0xFF8C8276),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF3ECE0),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF9E8462),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // قائمة الخيارات الخمسة المصممة كبطاقات أنيقة مع راديو
                    for (final opt in options) ...[
                      () {
                        final isSelected = tempSelected == opt.key;
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              tempSelected = isSelected ? null : opt.key;
                            });
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252B34) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF8C6D46)
                                    : (isDark ? Colors.white12 : const Color(0xFFEFEBE4)),
                                width: isSelected ? 1.6 : 1.0,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                // دائرة الاختيار (Radio circle)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF8C6D46)
                                          : (isDark ? Colors.white38 : const Color(0xFFC4BCB0)),
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? const Color(0xFF8C6D46)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(Icons.check, size: 14, color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),

                                // نصوص الخيار: الاسم والشرح
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        opt.title,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF2E2721),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.sub,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white54 : const Color(0xFF8C8276),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // أيقونة الحالة
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: opt.iconBg,
                                  ),
                                  child: Icon(opt.icon, color: opt.iconColor, size: 20),
                                ),
                              ],
                            ),
                          ),
                        );
                      }(),
                    ],
                    const SizedBox(height: 8),

                    // بطاقة السنة الراتبة المصاحبة مع سويتش
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252B34) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFEFEBE4),
                        ),
                      ),
                      child: Row(
                        children: [
                          // سويتش التفعيل
                          if (isSunnahLocked && !isSunnahDone)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'مقفل',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Switch(
                              value: isSunnahDone,
                              activeThumbColor: const Color(0xFF7E6038),
                              activeTrackColor: const Color(0xFF7E6038).withValues(alpha: 0.4),
                              onChanged: (_) async {
                                await _toggleSunnah(item.key);
                                setSheetState(() {});
                              },
                            ),
                          const SizedBox(width: 12),

                          // نصوص السنة
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'السنة الراتبة (${_sunnahLabelFor(item.key)})',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF2E2721),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSunnahDone
                                      ? 'صلّيت السنة مع الفرض ✓'
                                      : (isSunnahLocked
                                          ? 'تفتح مع دخول وقت صلاة ${item.label}'
                                          : 'صلّيت السنة مع الفرض'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white54 : const Color(0xFF8C8276),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // أيقونة النجمة
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF9E8462),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // زر "تم" العريض المماثل للصورة
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (tempSelected == null && currentStatus != null) {
                            Navigator.pop(ctx, 'delete');
                          } else {
                            Navigator.pop(ctx, tempSelected);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E6038),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'تم',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      final sp = await SharedPreferences.getInstance();
      if (selected == 'delete') {
        await sp.remove('prayer_perf_${item.key}_$todayKey');
      } else {
        await sp.setString('prayer_perf_${item.key}_$todayKey', selected);
        if (currentStatus == null && selected != 'missed') {
          final userPrefs = ref.read(userPrefsProvider);
          await userPrefs.bumpCategoryStreakIfNewDay(item.category);
        }
      }
      ref.read(categoryStreakVersionProvider.notifier).bump();
      await _loadHistory();

      if (selected != 'delete' && selected != 'missed' && mounted) {
        final accent = themeAccent(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('تقبّل الله صلاتك 🤲 — يمكنك قراءة أذكار ما بعد الصلاة الآن'),
            action: SnackBarAction(
              label: 'الأذكار',
              textColor: accent,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostPrayerAzkarScreen()),
                );
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (selected == 'missed' && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('عسى الله أن يعفو عنك 🤲 — بادر بقضائها في أقرب فرصة'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final cardBg = isDark ? const Color(0xFF1E2420) : Colors.white;
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFEDE8E1);

    final todayLoggedCount = _todayPrayerStatus.values.where((v) => v != 'missed').length;
    final now = DateTime.now();
    final loc = ref.watch(locationPrefsProvider);
    final effectiveLat = loc.lat ?? kDefaultFallbackLat;
    final effectiveLon = loc.lon ?? kDefaultFallbackLon;
    final List<PrayerMomentTime> dayTimes = computeDayTimes(
      lat: effectiveLat,
      lon: effectiveLon,
      date: now,
      methodKey: loc.calculationMethod,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. عنوان "سجل صلواتك" مع رابط الإحصاءات
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.assignment_turned_in_outlined, size: 18, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  'سجل صلواتك',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrayerAnalyticsScreen()),
                ).then((_) => _loadHistory());
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الإحصاءات',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_left, color: accent, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // بطاقة تسجيل الصلوات الخمس
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // الصف العلوي: صلّيت X من 5 + اضغط للتسجيل
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'صلّيت $todayLoggedCount من 5',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'اضغط للتسجيل',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // صف الأزرار الخمسة الدائرية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final item in _kPrayers)
                    () {
                      DateTime? prayerTime;
                      for (final t in dayTimes) {
                        if (t.moment.name == item.key) {
                          prayerTime = t.time;
                          break;
                        }
                      }
                      final bool isLocked = prayerTime != null &&
                          now.isBefore(prayerTime) &&
                          _todayPrayerStatus[item.key] == null;
                      return _buildPrayerCircleButton(
                        item: item,
                        status: _todayPrayerStatus[item.key],
                        accent: accent,
                        onSurface: onSurface,
                        isDark: isDark,
                        isLocked: isLocked,
                      );
                    }(),
                ],
              ),
              const SizedBox(height: 14),

              // شريط متابعة السنن الرواتب السريع
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161C18) : const Color(0xFFFAF8F3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 6),
                            Text(
                              'السنن الرواتب',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFE5C378) : const Color(0xFF8C6A1A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_todaySunnahStatus.values.where((v) => v).length} من 5 مكتملة',
                          style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final p in _kPrayers) ...[
                            () {
                              final isSunnahDone = _todaySunnahStatus[p.key] ?? false;
                              DateTime? prayerTime;
                              for (final t in dayTimes) {
                                if (t.moment.name == p.key) {
                                  prayerTime = t.time;
                                  break;
                                }
                              }
                              final bool isSunnahLocked = prayerTime != null &&
                                  now.isBefore(prayerTime) &&
                                  !isSunnahDone;

                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Opacity(
                                  opacity: isSunnahLocked ? 0.5 : 1.0,
                                  child: FilterChip(
                                    avatar: Icon(
                                      isSunnahDone
                                          ? Icons.check_circle_rounded
                                          : (isSunnahLocked
                                              ? Icons.lock_outline_rounded
                                              : Icons.circle_outlined),
                                      size: 13,
                                      color: isSunnahDone
                                          ? Colors.black
                                          : (isSunnahLocked ? onSurface.withValues(alpha: 0.45) : const Color(0xFFD4AF37)),
                                    ),
                                    label: Text(_sunnahShortName(p.key)),
                                    selected: isSunnahDone,
                                    selectedColor: const Color(0xFFD4AF37),
                                    labelStyle: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSunnahDone
                                          ? Colors.black
                                          : (isSunnahLocked ? onSurface.withValues(alpha: 0.5) : onSurface),
                                    ),
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(
                                      color: isSunnahDone
                                          ? const Color(0xFFD4AF37)
                                          : (isSunnahLocked
                                              ? onSurface.withValues(alpha: 0.1)
                                              : onSurface.withValues(alpha: 0.15)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onSelected: (_) => _toggleSunnah(p.key),
                                  ),
                                ),
                              );
                            }(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // زر الوصول السريع لأذكار بعد الصلاة
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PostPrayerAzkarScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 16, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'أذكار ما بعد الصلاة المفروضة',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. عنوان "الالتزام الأسبوعي" مع الزخرفة ورابط الإحصاءات
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerAnalyticsScreen()),
            ).then((_) => _loadHistory());
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.bar_chart_rounded, size: 18, color: accent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الالتزام الأسبوعي',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'عرض الإحصاءات',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_left, color: accent, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // بطاقة الرسم البياني الأسبوعي (قابلة للضغط لفتح الإحصاءات)
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerAnalyticsScreen()),
            ).then((_) => _loadHistory());
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Column(
            children: [
              // الصف العلوي: النقاط الخمس وشارة X/5 اليوم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 5 نقاط تعبّر عن صلوات اليوم
                  Row(
                    children: [
                      for (int dot = 0; dot < 5; dot++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dot < todayLoggedCount
                                ? accent
                                : (isDark
                                    ? Colors.white24
                                    : const Color(0xFFDDD6CE)),
                          ),
                        ),
                    ],
                  ),
                  // شارة X/5 اليوم
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$todayLoggedCount/5 اليوم',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // الرسم البياني لـ 7 أيام
              _isLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < 7; i++)
                          _buildWeeklyBar(
                            count: _weeklyCounts[i],
                            dayDt: now.subtract(Duration(days: 6 - i)),
                            isToday: i == 6,
                            accent: accent,
                            onSurface: onSurface,
                            isDark: isDark,
                          ),
                      ],
                    ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildPrayerCircleButton({
    required _PrayerRecordItem item,
    required String? status,
    required Color accent,
    required Color onSurface,
    required bool isDark,
    bool isLocked = false,
  }) {
    final isDone = status != null;
    final color = switch (status) {
      'masjid' => PrayerStatusColors.masjid,
      'jamaah' => PrayerStatusColors.jamaah,
      'on_time' => PrayerStatusColors.onTime,
      'qadaa' => PrayerStatusColors.qadaa,
      'missed' => const Color(0xFFC0392B),
      _ => accent,
    };
    final icon = isLocked
        ? Icons.lock_outline_rounded
        : switch (status) {
            'masjid' => Icons.mosque_outlined,
            'jamaah' => Icons.groups_outlined,
            'on_time' => Icons.check,
            'qadaa' => Icons.history_toggle_off,
            'missed' => Icons.close_rounded,
            _ => Icons.add,
          };

    return InkWell(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لم يدخل وقت صلاة ${item.label} بعد'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _togglePrayer(item);
      },
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Opacity(
          opacity: isLocked ? 0.45 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? color
                      : (isLocked
                          ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04))
                          : accent.withValues(alpha: isDark ? 0.08 : 0.04)),
                  border: isDone
                      ? null
                      : Border.all(
                          color: isLocked
                              ? (isDark ? Colors.white24 : Colors.black12)
                              : accent.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                  boxShadow: isDone
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isDone
                        ? Colors.white
                        : onSurface.withValues(alpha: isLocked ? 0.35 : 0.5),
                    size: isLocked ? 19 : 22,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                  color: isDone
                      ? onSurface
                      : onSurface.withValues(alpha: isLocked ? 0.4 : 0.65),
                ),
              ),
              if (_todaySunnahStatus[item.key] == true) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'سنة ✓',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyBar({
    required int count,
    required DateTime dayDt,
    required bool isToday,
    required Color accent,
    required Color onSurface,
    required bool isDark,
  }) {
    const totalBarHeight = 65.0;
    final fillRatio = (count / 5.0).clamp(0.0, 1.0);
    final fillHeight = totalBarHeight * fillRatio;
    final barTrackColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFF4EEE6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // العدد فوق العمود
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
            color: count > 0 ? onSurface : onSurface.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 6),

        // العمود المفرغ والممتلئ
        Container(
          width: 26,
          height: totalBarHeight,
          decoration: BoxDecoration(
            color: barTrackColor,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: 26,
            height: fillHeight,
            decoration: BoxDecoration(
              color: isToday ? accent : accent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // اختصار اسم اليوم أسفل العمود
        Text(
          _dayAbbr(dayDt.weekday),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday ? accent : onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
