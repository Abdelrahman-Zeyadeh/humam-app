import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_database.dart' show Hadith;
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/hadith/hadith_repository.dart' show hadithMatnOnly;
import '../../core/data/quran/quran_database.dart' show Surah;
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart' show QuranRepository;
import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart'
    show UserCategories, UserRepository;
import '../../core/text/time_format.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../azkar/streak_status_row.dart';
import '../mushaf/mushaf_screen.dart';
import '../mushaf/mushaf_settings.dart' show qiyamSessionProvider;
import '../notifications/adhan_notification_service.dart';
import '../notifications/reminder_messages.dart' show qiyamReminderMessages;
import '../prayer/prayer_times_service.dart' show isWithinQiyamWindow;

/// إتمام آخر ٧ أيام لفئة معيّنة — يُعاد جلبه كلّما تغيّرت سلاسل الاستمرار
/// (`categoryStreakVersionProvider`، نفس ما يُنبَّه به عند كل تسجيل جديد).
final _weekCompletionProvider = FutureProvider.family<List<bool>, String>((
  ref,
  category,
) {
  ref.watch(categoryStreakVersionProvider);
  return ref.watch(userPrefsProvider).fixedWeekCompletionFor(category);
});

/// حديث "فضل قيام الليل" — يُجلَب حياً من `hadith.db` المرخّصة بمرجعه
/// (كتاب/رقم)، لا نص ثابت بالكود (راجع توثيق `HadithRepository.
/// hadithByBookAndNumber`). صحيح البخاري ١١٤٥ (ومسلم ١٧٧٢ بنفس المتن):
/// حديث نزول الله تبارك وتعالى بالثلث الأخير من الليل.
final _qiyamVirtueHadithProvider = FutureProvider<Hadith?>((ref) {
  return ref.watch(hadithRepositoryProvider).hadithByBookAndNumber(1, 1145);
});

/// عدد آيات جلسات القيام المتراكم لليوم الحالي — يُعاد جلبه بعد كل إنهاء
/// جلسة (`categoryStreakVersionProvider` يُنبَّه به أيضاً، راجع
/// `MushafScreen._endQiyamSession`).
final _todayQiyamAyahCountProvider = FutureProvider<int>((ref) {
  ref.watch(categoryStreakVersionProvider);
  final dateKey = UserRepository.dateKeyFor(DateTime.now());
  return ref.watch(userPrefsProvider).qiyamAyahCountFor(dateKey);
});

/// حديث "خطة قيام بعدد آيات" — سنن أبي داود (١٣٩٨)، مجلوب حياً من
/// `hadith.db` المرخّصة (`book_id=4` أبو داود)، **لا نص مؤلَّف بالكود**.
/// يغطّي المراتب الثلاث معاً بحديث واحد: "مَنْ قَامَ بِعَشْرِ آيَاتٍ لَمْ
/// يُكْتَبْ مِنَ الْغَافِلِينَ، وَمَنْ قَامَ بِمِائَةِ آيَةٍ كُتِبَ مِنَ
/// الْقَانِتِينَ، وَمَنْ قَامَ بِأَلْفِ آيَةٍ كُتِبَ مِنَ الْمُقَنْطَرِينَ".
final _qiyamGoalHadithProvider = FutureProvider<Hadith?>((ref) {
  return ref.watch(hadithRepositoryProvider).hadithByBookAndNumber(4, 1398);
});

/// وصف زر "خطة بعدد آيات" واحد — الهدف، تسميته العربية، لقب مرتبته
/// (بالحديث نفسه)، لونه، والعبارة الحرفية بنص الحديث المطلوب تمييزها
/// بصرياً لهذا الزر تحديداً (راجع [_HighlightedHadithText]).
typedef _AyahGoal = ({
  int goal,
  String label,
  String rankLabel,
  Color color,
  String highlight,
});

const List<_AyahGoal> _kAyahGoals = [
  (
    goal: 10,
    label: '١٠ آيات',
    rankLabel: 'لَمْ يُكْتَبْ مِنَ الْغَافِلِينَ',
    color: AppColors.teal,
    highlight: 'لَمْ يُكْتَبْ مِنَ الْغَافِلِينَ',
  ),
  (
    goal: 100,
    label: '١٠٠ آية',
    rankLabel: 'كُتِبَ مِنَ الْقَانِتِينَ',
    // `AppColors.goldDeep` حرفياً هون (لا `themeAccent(context)`) — `const`
    // على مستوى الملف بلا `BuildContext` متاح. `goldDeep` لا `gold` لأن هذا
    // اللون يُستخدَم كنص/أيقونة مباشرة فوق خلفيات فاتحة بأكتر من مكان
    // بهالشاشة (راجع توثيق `AppColors.goldDeep`).
    color: AppColors.goldDeep,
    highlight: 'كُتِبَ مِنَ الْقَانِتِينَ',
  ),
  (
    goal: 1000,
    label: '١٠٠٠ آية',
    rankLabel: 'كُتِبَ مِنَ الْمُقَنْطَرِينَ',
    color: Color(0xFF8E5B45),
    highlight: 'كُتِبَ مِنَ الْمُقَنْطَرِينَ',
  ),
];

/// يختار مجموعة سور عشوائية (مختلفة كل استدعاء — `Random()` جديد بلا بذرة
/// ثابتة، بطلب صاحب المشروع "سور مختلفة كل مرة وليست ثابتة") يصل مجموع
/// آياتها للهدف المطلوب أو يتجاوزه بقليل. المجمَّع المرشَّح مُقيَّد بحد
/// أقصى لعدد آيات السورة حسب الهدف (لا معنى لاختيار البقرة ٢٨٦ آية لهدف
/// ١٠ آيات مثلاً).
Future<List<Surah>> pickRandomSurahGroup(
  QuranRepository quran,
  int goal,
) async {
  final maxAyahCount = switch (goal) {
    10 => 20,
    100 => 60,
    _ => 200,
  };
  final all = await quran.allSurahs();
  final pool = all.where((s) => s.ayahCount <= maxAyahCount).toList()
    ..shuffle(Random());
  final selected = <Surah>[];
  var total = 0;
  for (final s in pool) {
    if (total >= goal) break;
    selected.add(s);
    total += s.ayahCount;
  }
  // احتياط نادر: لو المجمَّع المقيَّد بأكمله ما وصل الهدف (ممكن نظرياً لهدف
  // ١٠٠٠)، أكمل بسور أكبر (مخلوطة أيضاً) حتى الوصول.
  if (total < goal) {
    final remaining = all.where((s) => !selected.contains(s)).toList()
      ..shuffle(Random());
    for (final s in remaining) {
      if (total >= goal) break;
      selected.add(s);
      total += s.ayahCount;
    }
  }
  return selected;
}

/// شاشة قيام الليل: تسجيل يدوي (لا طريقة لرصد قيامك تلقائياً) بسلسلة
/// استمرار مستقلة (`UserCategories.qiyam`، معروضة أيضاً بالداشبورد)، +
/// تذكير يومي اختياري بساعة يحدّدها المستخدم (`AdhanNotificationService.
/// scheduleQiyamReminder` — تكرار يومي حقيقي على مستوى النظام، لا إعادة
/// جدولة يدوية كإشعارات الأذان).
class QiyamScreen extends ConsumerWidget {
  const QiyamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // **باج حقيقي مُصلَح هون**: الشاشة كانت لا تراقب `categoryStreakVersionProvider`
    // إطلاقاً رغم أن `_toggleEnabled`/`_pickTime` يبمّانه بعد كل تفعيل/تعطيل
    // — يعني `SwitchListTile` أسفل (`prefs.qiyamEnabled`) لم يكن يُعاد بناؤه
    // أبداً بعد الضغط، فيبدو المفتاح "لا يستجيب"/يرجع لحالته القديمة بصرياً
    // رغم أن القيمة فعلياً اتخزّنت بقاعدة البيانات. بلاغ صاحب المشروع "بقدرش
    // افعل التذكير" كان بالضبط بهذا السبب.
    ref.watch(categoryStreakVersionProvider);
    final prefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final loggedToday = prefs.completedTodayFor(UserCategories.qiyam);
    // بطلب صاحب المشروع: "قسم... القيام خليه كل اشي بوقته" ثم "خليه
    // المدة تبعته من العشا الى الفجر" — يُفتح التسجيل بدخول وقت العشاء
    // ويُغلق مجدداً بدخول وقت الفجر (لا يبقى مفتوحاً طوال اليوم التالي).
    final loc = ref.watch(locationPrefsProvider);
    final locked = !isWithinQiyamWindow(
      lat: loc.lat,
      lon: loc.lon,
      methodKey: loc.calculationMethod,
    );

    return Scaffold(
      // هيدر بتدرّج كحلي مطابق لأسلوب لوحة التصميم المعتمدة — `AppBar`
      // عادي بلا لمس هيكل الجسم، فقط زُيِّن بصرياً.
      appBar: const GradientAppBar(
        title: 'قيام الليل',
        colors: [AppColors.navy, AppColors.navyDeep],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _QiyamVirtueCard(),
          ),
          // نفس صف الحالة المستخدَم بكل خانات الأذكار الأخرى ("زي الثانيات")
          // — سلسلة الاستمرار + هل تمّت اليوم أم لا، بنفس التصميم حرفياً.
          const StreakStatusRow(category: UserCategories.qiyam),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _WeekTracker(category: UserCategories.qiyam),
          ),
          // بطاقة التسجيل الليلي: "ابدأ قيام" + "سجّل قيامك الليلة"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _QiyamSectionCard(
              accent: AppColors.gold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // "ابدأ قيام" — يفتح المصحف بوضع تتبّع (`qiyamSessionMode`)
                  // يعدّ آيات هذه الجلسة، وينهيها بزر بشريط علوي داخل المصحف
                  // نفسه (`MushafScreen._endQiyamSession`) — بطلب صاحب المشروع
                  // "تتبع كم اية تمت قراءتها بجلسة قيام الليل".
                  OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('ابدأ قيام (تتبّع عدد الآيات)'),
                    onPressed: () {
                      // `start()` هون **قبل** الفتح مباشرة — لا بـ`initState`
                      // بـ`MushafScreen` (كانت تُسبّب "Tried to modify a
                      // provider while the widget tree was building" فعلياً،
                      // راجع توثيق `MushafScreen.initState`/`dispose`).
                      ref.read(qiyamSessionProvider.notifier).start();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const MushafScreen(qiyamSessionMode: true),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Consumer(
                    builder: (context, ref, _) {
                      final countAsync = ref.watch(
                        _todayQiyamAyahCountProvider,
                      );
                      final count = countAsync.value ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'قرأت $count آية بجلسات القيام الليلة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  AppPrimaryButton(
                    icon: loggedToday
                        ? Icons.check_circle
                        : (locked ? Icons.lock_outline : Icons.bedtime_outlined),
                    label: loggedToday
                        ? 'سجّلت قيامك الليلة'
                        : (locked
                              ? 'وقت القيام غير متاح الآن'
                              : 'سجّل قيامك الليلة'),
                    onPressed: loggedToday || locked
                        ? null
                        : () async {
                            await prefs.bumpCategoryStreakIfNewDay(
                              UserCategories.qiyam,
                            );
                            ref
                                .read(categoryStreakVersionProvider.notifier)
                                .bump();
                          },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    locked
                        ? 'وقت القيام من دخول العشاء حتى دخول الفجر.'
                        : 'التسجيل اليدوي متاح أيضاً بلا فتح المصحف — فقط اضغط الزر بعد ما تصلّي.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.55),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // بطاقة "خطة قيام بعدد آيات"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _QiyamSectionCard(
              accent: AppColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: themeAccent(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'خطة قيام بعدد آيات',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر عدد آيات هدفك — تشوف فضله بالحديث، وتقدر تبدأ فوراً بمجموعة سور مقترحة تصل له.',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _AyahGoalButtons(),
                ],
              ),
            ),
          ),

          // بطاقة "تذكير يومي"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _QiyamSectionCard(
              accent: AppColors.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: themeAccent(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'تذكير يومي',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إشعار يتكرر كل يوم بالساعة اللي تختارها لتذكيرك بالقيام.',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تفعيل التذكير'),
                    value: prefs.qiyamEnabled,
                    onChanged: (v) => _toggleEnabled(context, ref, v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      prefs.qiyamHour != null
                          ? formatTimeOfDay(prefs.qiyamHour!, prefs.qiyamMinute)
                          : 'اختر الساعة',
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _pickTime(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(userPrefsProvider);
    final initial = TimeOfDay(
      hour: prefs.qiyamHour ?? 2,
      minute: prefs.qiyamMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: initial,
    );
    if (picked == null || !context.mounted) return;
    await prefs.setQiyamReminder(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyReminderState(context, ref);
  }

  Future<void> _toggleEnabled(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final prefs = ref.read(userPrefsProvider);
    if (value && prefs.qiyamHour == null) {
      // ما في ساعة مختارة بعد — نفتح منتقي الوقت مباشرة، وهو يفعّل ضمنياً
      // (`setQiyamReminder(enabled: true, ...)`) عند الاختيار.
      await _pickTime(context, ref);
      return;
    }
    await prefs.setQiyamReminder(enabled: value);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyReminderState(context, ref);
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `prayer_screen.dart._toggleNotifications` (الخدمة آمنة على أندرويد/
  /// iOS فقط، ترمي على منصّات أخرى بلا إعدادات مخصَّصة).
  Future<void> _applyReminderState(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(userPrefsProvider);
    try {
      if (prefs.qiyamEnabled && prefs.qiyamHour != null) {
        await AdhanNotificationService.instance.requestPermissions();
        final messages = await qiyamReminderMessages(
          ref.read(hadithRepositoryProvider),
        );
        await AdhanNotificationService.instance.scheduleQiyamReminder(
          hour: prefs.qiyamHour!,
          minute: prefs.qiyamMinute,
          messages: messages,
        );
      } else {
        await AdhanNotificationService.instance.cancelQiyamReminder();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر ضبط تذكير قيام الليل على هذا الجهاز: $e'),
        ),
      );
    }
  }
}

/// بطاقة قسم موحّدة لجسم شاشة قيام الليل (تسجيل/خطة الآيات/التذكير) —
/// خلفية سطح مرفوعة قليلاً بحواف مدوّرة وظل خفيف، بنفس روح باقي بطاقات
/// التطبيق، بدل نص خام مفصول بـ`Divider`.
class _QiyamSectionCard extends StatelessWidget {
  const _QiyamSectionCard({required this.child, this.accent});
  final Widget child;

  /// شريط علوي ملوّن مميِّز لهوية هذا القسم تحديداً — بلا هذا اللون، كل
  /// البطاقات الثلاث كانت متطابقة الشكل تماماً (بطلب صاحب المشروع "تصميم
  /// بصري أعمق").
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accent != null) Container(height: 4, color: accent),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

/// "فضل قيام الليل" — حديث حقيقي مجلوب حياً من `hadith.db` المرخّصة (راجع
/// `_qiyamVirtueHadithProvider` أعلى الملف)، لا نص مؤلَّف بالكود.
class _QiyamVirtueCard extends ConsumerWidget {
  const _QiyamVirtueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hadithAsync = ref.watch(_qiyamVirtueHadithProvider);
    final hadith = hadithAsync.value;
    if (hadith == null) return const SizedBox.shrink();

    return Card(
      color: themeAccent(context).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: themeAccent(context),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'فضل قيام الليل',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // سند مختصَر بطلب صاحب المشروع "اختصر السند اجعله فقط الراوي
            // عن رسول الله ﷺ والحديث" — راوي هذا الحديث (أبو هريرة رضي
            // الله عنه) موثَّق حرفياً بنص الحديث الكامل بـ`hadith.db` (راجع
            // توثيق [hadithMatnOnly])، المتن نفسه مجلوب حياً بلا تعديل.
            Text(
              'عَنْ أَبِي هُرَيْرَةَ رضى الله عنه، أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم:\n${hadithMatnOnly(hadith.content)}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.85),
                fontSize: 13.5,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'رواه البخاري (١١٤٥) ومسلم (١٧٧٢)',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// أزرار "خطة قيام بعدد آيات" الثلاثة (١٠/١٠٠/١٠٠٠ آية فقط — بلا عدد حرّ
/// مخصَّص، بطلب صاحب المشروع صراحة) — بإلهام من موقع قانتين
/// (qaniteen.com). كل زر يفتح [_QiyamGoalSheet] بحديث الفضل الكامل (سنن
/// أبي داود ١٣٩٨) وخيار بدء القراءة فعلياً بمجموعة سور مقترحة تصل لهذا
/// العدد (راجع [pickRandomSurahGroup] أعلى الملف).
class _AyahGoalButtons extends StatelessWidget {
  const _AyahGoalButtons();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // بطاقات ملوّنة رأسية بدل أزرار `OutlinedButton` رفيعة متطابقة الشكل
    // (بطلب صاحب المشروع "تصميم بصري أعمق") — كل هدف بمساحة أكبر، أيقونة
    // مرتبة له، وشارة الهدف الرقمي بخلفية ملوّنة.
    final goalIcons = [
      Icons.looks_one_rounded,
      Icons.looks_two_rounded,
      Icons.workspace_premium_rounded,
    ];
    // `IntrinsicHeight` **إلزامي** هون — بدونه، `CrossAxisAlignment.stretch`
    // بصف داخل `ListView` (ارتفاع الأب غير محدود) يرمي استثناء تخطيط حقيقي
    // (`RenderFlex` يطلب ارتفاعاً لا نهائياً) فتختفي الشاشة بالكامل — هذا
    // بالضبط ما بلّغه صاحب المشروع "قيام الليل ما في صفحة عندي".
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _kAyahGoals.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Material(
                color: isDark
                    ? _kAyahGoals[i].color.withValues(alpha: 0.14)
                    : _kAyahGoals[i].color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _QiyamGoalSheet(goal: _kAyahGoals[i]),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _kAyahGoals[i].color.withValues(alpha: 0.4),
                      ),
                    ),
                    // العبارة الحرفية من الحديث (`rankLabel`) صارت ظاهرة على
                    // البطاقة مباشرة، لا داخل الشيت فقط — بطلب صاحب المشروع
                    // (مثلاً "١٠ آيات" + "لَمْ يُكْتَبْ مِنَ الْغَافِلِينَ").
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          goalIcons[i % goalIcons.length],
                          size: 26,
                          color: _kAyahGoals[i].color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _kAyahGoals[i].label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: _kAyahGoals[i].color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _kAyahGoals[i].rankLabel,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: _kAyahGoals[i].color.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// شيت هدف واحد ("١٠/١٠٠/١٠٠٠ آية"): يعرض حديث سنن أبي داود ١٣٩٨ الحقيقي
/// كاملاً (مجلوباً حياً، راجع `_qiyamGoalHadithProvider`) مع تمييز العبارة
/// الخاصة بهذا الهدف تحديداً، ثم يقترح مجموعة سور عشوائية (تختلف كل ضغطة
/// "مجموعة تانية" — [pickRandomSurahGroup]) وزر "ابدأ القراءة" يفتح المصحف
/// مباشرة على أول آية بأول سورة بالمجموعة بوضع تتبّع القيام.
class _QiyamGoalSheet extends ConsumerStatefulWidget {
  const _QiyamGoalSheet({required this.goal});
  final _AyahGoal goal;

  @override
  ConsumerState<_QiyamGoalSheet> createState() => _QiyamGoalSheetState();
}

class _QiyamGoalSheetState extends ConsumerState<_QiyamGoalSheet> {
  List<Surah>? _group;
  bool _loading = false;

  Future<void> _pickGroup() async {
    setState(() => _loading = true);
    final quran = ref.read(quranRepositoryProvider);
    final group = await pickRandomSurahGroup(quran, widget.goal.goal);
    if (!mounted) return;
    setState(() {
      _group = group;
      _loading = false;
    });
  }

  void _start() {
    final group = _group;
    if (group == null || group.isEmpty) return;
    // `start()` هون **قبل** الفتح مباشرة — نفس نمط زر "ابدأ قيام" (لا
    // `initState` بـ`MushafScreen`، راجع توثيقه لسبب هذا القيد).
    ref.read(qiyamSessionProvider.notifier).start();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MushafScreen(
          initialPage: group.first.startPage,
          qiyamSessionMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hadithAsync = ref.watch(_qiyamGoalHadithProvider);
    final hadith = hadithAsync.value;
    final group = _group;
    final total = group == null
        ? 0
        : group.fold<int>(0, (sum, s) => sum + s.ayahCount);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: widget.goal.color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.goal.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hadith != null)
              // سند مختصَر بطلب صاحب المشروع "اختصر السند اجعله فقط الراوي
              // عن رسول الله ﷺ والحديث" — راوي هذا الحديث (عبد الله بن عمرو
              // بن العاص رضي الله عنهما) موثَّق حرفياً بنص الحديث الكامل
              // بـ`hadith.db` (راجع توثيق [hadithMatnOnly]).
              _HighlightedHadithText(
                text:
                    'عَنْ عَبْدِ اللَّهِ بْنِ عَمْرِو بْنِ الْعَاصِ رضي الله عنهما، قَالَ: قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم:\n${hadithMatnOnly(hadith.content)}',
                highlight: widget.goal.highlight,
                onSurface: onSurface,
                color: widget.goal.color,
              )
            else if (hadithAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            const SizedBox(height: 4),
            Text(
              'رواه أبو داود (١٣٩٨)',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const Divider(height: 28),
            if (group == null) ...[
              Text(
                'اختر مجموعة سور قصيرة تصل لعدد آيات هذا الهدف تقريباً — تُختار عشوائياً وتختلف كل مرة.',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.65),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                icon: Icons.shuffle,
                label: 'اقترح مجموعة سور',
                loading: _loading,
                onPressed: _loading ? null : _pickGroup,
              ),
            ] else ...[
              Text(
                'المجموعة المقترحة ($total آية):',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in group)
                    Chip(
                      label: Text(
                        '${s.nameAr} (${s.ayahCount})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: widget.goal.color.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shuffle),
                      label: const Text('مجموعة تانية'),
                      onPressed: _loading ? null : _pickGroup,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppPrimaryButton(
                      icon: Icons.play_arrow,
                      label: 'ابدأ القراءة',
                      color: widget.goal.color,
                      onPressed: _start,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// نص حديث كامل مع تمييز بصري (تسمين + خلفية خفيفة بلون [color]) لعبارة
/// [highlight] المطابقة لهدف معيّن ضمن حديث واحد يغطّي عدّة مراتب (سنن أبي
/// داود ١٣٩٨) — النص الكامل يبقى ظاهراً دوماً (أمانة نقل الحديث كما ورد)،
/// فقط الجزء ذو الصلة يُبرَز.
class _HighlightedHadithText extends StatelessWidget {
  const _HighlightedHadithText({
    required this.text,
    required this.highlight,
    required this.onSurface,
    required this.color,
  });
  final String text;
  final String highlight;
  final Color onSurface;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      color: onSurface.withValues(alpha: 0.85),
      fontSize: 13.5,
      height: 1.8,
    );
    final idx = text.indexOf(highlight);
    if (idx == -1) {
      return Text(text, textDirection: TextDirection.rtl, style: baseStyle);
    }
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + highlight.length),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
          TextSpan(text: text.substring(idx + highlight.length)),
        ],
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

/// صف "أيام الأسبوع" — أيام الأسبوع السبعة الثابتة (السبت..الجمعة)
class _WeekTracker extends ConsumerWidget {
  const _WeekTracker({required this.category});
  final String category;

  static const _dayNames = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']; // السبت..الجمعة

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final weekAsync = ref.watch(_weekCompletionProvider(category));
    final now = DateTime.now();
    final todayIndex = (now.weekday % 7 + 1) % 7;

    return weekAsync.when(
      loading: () => const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (done) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (i < done.length && done[i])
                        ? themeAccent(context)
                        : Colors.transparent,
                    border: Border.all(
                      color: (i < done.length && done[i])
                          ? themeAccent(context)
                          : (i > todayIndex
                                ? onSurface.withValues(alpha: 0.1)
                                : onSurface.withValues(alpha: 0.25)),
                    ),
                  ),
                  child: (i < done.length && done[i])
                      ? const Icon(Icons.check, size: 18, color: AppColors.navy)
                      : Text(
                          _dayNames[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == todayIndex
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == todayIndex
                                ? themeAccent(context)
                                : onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  i == todayIndex ? 'اليوم' : '',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: themeAccent(context),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
