import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_providers.dart';
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
import 'widgets/ayah_goal_plan.dart';
import 'widgets/qiyam_section_card.dart';
import 'widgets/qiyam_virtue_card.dart';
import 'widgets/qiyam_week_tracker.dart';

/// عدد آيات جلسات القيام المتراكم لليوم الحالي — يُعاد جلبه بعد كل إنهاء
/// جلسة (`categoryStreakVersionProvider` يُنبَّه به أيضاً، راجع
/// `MushafScreen._endQiyamSession`).
final _todayQiyamAyahCountProvider = FutureProvider<int>((ref) {
  ref.watch(categoryStreakVersionProvider);
  final dateKey = UserRepository.dateKeyFor(DateTime.now());
  return ref.watch(userPrefsProvider).qiyamAyahCountFor(dateKey);
});

/// شاشة قيام الليل: تسجيل يدوي (لا طريقة لرصد قيامك تلقائياً) بسلسلة
/// استمرار مستقلة (`UserCategories.qiyam`، معروضة أيضاً بالداشبورد)، +
/// تذكير يومي اختياري بساعة يحدّدها المستخدم (`AdhanNotificationService.
/// scheduleQiyamReminder` — تكرار يومي حقيقي على مستوى النظام، لا إعادة
/// جدولة يدوية كإشعارات الأذان).
///
/// الشاشة نفسها مجرّد تنسيق (composition): كل قسم (بطاقة الفضل/تتبّع
/// الأسبوع/خطة الآيات) استُخرج لملفه الخاص بمجلد `widgets/` (كان ~٩٦٣
/// سطراً بملف واحد)، بلا أي تغيير سلوكي.
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
            child: QiyamVirtueCard(),
          ),
          // نفس صف الحالة المستخدَم بكل خانات الأذكار الأخرى ("زي الثانيات")
          // — سلسلة الاستمرار + هل تمّت اليوم أم لا، بنفس التصميم حرفياً.
          const StreakStatusRow(category: UserCategories.qiyam),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: QiyamWeekTracker(category: UserCategories.qiyam),
          ),
          // بطاقة التسجيل الليلي: "ابدأ قيام" + "سجّل قيامك الليلة"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: QiyamSectionCard(
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
            child: QiyamSectionCard(
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
                  const AyahGoalButtons(),
                ],
              ),
            ),
          ),

          // بطاقة "تذكير يومي"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: QiyamSectionCard(
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
