import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_database.dart' show Hadith;
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/hadith/hadith_repository.dart' show hadithMatnOnly;
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/text/time_format.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../azkar/streak_status_row.dart';
import '../mushaf/mushaf_screen.dart';
import '../mushaf/mushaf_settings.dart' show hifzPickerProvider;
import '../notifications/adhan_notification_service.dart';
import '../notifications/reminder_messages.dart' show hifzReminderMessages;
import 'hifz_range_picker_sheet.dart';
import 'hifz_review_screen.dart';

Color _textSoft(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkSoftOnDark
    : AppColors.inkSoft;

/// حديث واحد يومي (يتغيّر كل يوم) عن فضل/متابعة حفظ القرآن — بطلب صاحب
/// المشروع "لو تخلي ١ بس وكل يوم يظهر حديث مختلف" بدل عرض حديثين ثابتين
/// معاً دوماً. ثلاثة أحاديث حقيقية فقط أدرجتها **مسبقاً** نسخة `hadith.db`
/// الاحتياطية الثابتة (`essential_hadith_fallback.dart`، مرخّصة Unlicense
/// وموثَّقة بمرجعها كتاب/رقم) بموضوع حفظ/مراجعة القرآن تحديداً — لا نص
/// مؤلَّف بالكود ولا رقم حديث غير موثَّق مسبقاً بالمصدر. `hadithByBookAndNumber`
/// يقرأ من قاعدة الكتاب الفعلية لو نُزِّل لاحقاً، ومن هذه النسخة الاحتياطية
/// قبل التنزيل — كلا الحالتين نفس النص الموثَّق.
const _kHifzVirtueHadiths = [
  (
    bookId: 1,
    number: 4937,
    narrator: 'عَنْ عَائِشَةَ رضي الله عنها',
    source: 'رواه البخاري (٤٩٣٧)',
  ),
  (
    bookId: 1,
    number: 5033,
    narrator: 'عَنْ أَبِي مُوسَى رضي الله عنه',
    source: 'رواه البخاري (٥٠٣٣)',
  ),
  (
    bookId: 2,
    number: 1844,
    narrator: 'عَنْ أَبِي مُوسَى رضي الله عنه',
    source: 'رواه مسلم (١٨٤٤)',
  ),
];

/// يختار حديث اليوم بثبات طول اليوم (يوم السنة % عدد الأحاديث) — لا حديث
/// عشوائي بكل إعادة بناء، ويتبدّل تلقائياً غداً. يرجع الحديث مع نسبته
/// ومرجعه معاً (بدل حديث فقط) فلا تحتاج البطاقة تعيد مطابقة الحديث بمصدره.
final _hifzVirtueHadithProvider =
    FutureProvider<({Hadith? hadith, String narrator, String source})>((
      ref,
    ) async {
      final dayOfYear = DateTime.now()
          .difference(DateTime(DateTime.now().year))
          .inDays;
      final pick = _kHifzVirtueHadiths[dayOfYear % _kHifzVirtueHadiths.length];
      final hadith = await ref
          .watch(hadithRepositoryProvider)
          .hadithByBookAndNumber(pick.bookId, pick.number);
      return (hadith: hadith, narrator: pick.narrator, source: pick.source);
    });

/// اسم السورة ووصف النطاق لخطة حفظ — يُبنى من طرفَي النطاق (`from`/`to`
/// كـ`ayah_id` عام) لا من الخطة نفسها مباشرة، حتى يبقى مفتاح الكاش قيمياً
/// (record) لا هوية كائن `HifzPlan` (تُبنى نسخة جديدة منه بكل `preload`/
/// تحديث، فهوية الكائن وحدها كانت ستُبطل الكاش كل مرة بلا داع).
final _hifzRangeLabelProvider =
    FutureProvider.family<String, (int from, int to)>((ref, range) async {
      final quran = ref.watch(quranRepositoryProvider);
      final fromAyah = await quran.ayahById(range.$1);
      final toAyah = await quran.ayahById(range.$2);
      final surah = await quran.surahById(fromAyah.surah);
      return '${surah.nameAr} — من آية ${fromAyah.ayah} إلى آية ${toAyah.ayah}';
    });

/// عدد آيات المراجعة المستحقّة اليوم لخطة معيّنة — راجع `HifzReviewScreen`/
/// `UserRepository.dueHifzAyahCountForPlan`. `hifzVersionProvider` يُجبر
/// إعادة الجلب بعد أي تقدّم جديد بالخطة (`bump()` يُستدعى بكل تابع حفظ).
final _dueReviewCountProvider = FutureProvider.family<int, int>((ref, planId) {
  ref.watch(hifzVersionProvider);
  return ref.read(hifzPrefsProvider).dueReviewCount(planId);
});

enum _StartChoice { surah, mushaf }

/// قسم الحفظ: قائمة خطط حفظ **متعددة** (لا خطة واحدة نشطة فقط) — بطلب
/// صاحب المشروع الصريح: "خليه بقدر اعمل من غير ما احذف القديمة واحفظ
/// القديمة ومعلوماتها والتاريخ تبعها". كل خطة نطاق آيات مستقل وتقدّم
/// مستقل (`HifzPlan.id`)، وتبقى بالقائمة حتى يحذفها المستخدم صراحة —
/// بدء خطة جديدة لا يمسّ أي خطة سابقة إطلاقاً. التذكير اليومي يبقى إعداداً
/// عاماً واحداً (`HifzSettings` صف وحيد بقاعدة البيانات) يخصّ كل الخطط
/// معاً لا خطة بعينها.
class HifzScreen extends ConsumerWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hifzVersionProvider); // يجبر إعادة البناء بعد bump()
    final hifzPrefs = ref.watch(hifzPrefsProvider);
    final plans = hifzPrefs.plans;

    return Scaffold(
      // هيدر بتدرّج كحلي مطابق للوحة التصميم المعتمدة (`Plans.dc.html`) —
      // بقي `AppBar` عادياً بلا لمس هيكل الجسم (`body`)، فقط زُيِّن بصرياً.
      appBar: const GradientAppBar(
        title: 'قسم الحفظ',
        colors: [AppColors.purple, AppColors.navy],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _HifzVirtueCard(),
          const SizedBox(height: 16),
          const StreakStatusRow(category: UserCategories.hifz),
          const SizedBox(height: 16),
          if (plans.isEmpty)
            _EmptyState(onStart: () => _startNewPlan(context, ref))
          else ...[
            for (final plan in plans) ...[
              _PlanCard(
                plan: plan,
                onContinue: () => _continue(context, ref, plan),
                onDelete: () => _confirmDelete(context, ref, plan),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('خطة حفظ جديدة'),
              onPressed: () => _startNewPlan(context, ref),
            ),
          ],
          const Divider(height: 44),
          // **لا `const` هون عمداً** — راجع توثيق [_ReminderSection] لسبب
          // حقيقي مُصلَح: كانت `const` تمنع فليتر إعادة البناء كلياً.
          _ReminderSection(),
        ],
      ),
    );
  }

  Future<void> _startNewPlan(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_StartChoice>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const _StartChoiceSheet(),
    );
    if (choice == null || !context.mounted) return;

    final hifzPrefs = ref.read(hifzPrefsProvider);
    if (choice == _StartChoice.surah) {
      final range = await HifzRangePickerSheet.show(context);
      if (range == null) return;
      await hifzPrefs.start(fromAyahId: range.from, toAyahId: range.to);
    } else {
      // `activate()` هون **قبل** الفتح مباشرة — لا بـ`initState` بـ
      // `MushafScreen` (كانت تُسبّب نفس كراش Riverpod "Tried to modify a
      // provider while the widget tree was building" الموثَّق بـ
      // `MushafScreen.initState`، رغم عدم الإبلاغ عنه هون تحديداً — نفس
      // النمط بالضبط).
      ref.read(hifzPickerProvider.notifier).activate();
      final range = await Navigator.of(context).push<HifzRange>(
        MaterialPageRoute(
          builder: (_) => const MushafScreen(pickingHifzRange: true),
        ),
      );
      if (range == null) return;
      await hifzPrefs.start(fromAyahId: range.from, toAyahId: range.to);
    }
    ref.read(hifzVersionProvider.notifier).bump();
  }

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref,
    HifzPlan plan,
  ) async {
    final page =
        (await ref.read(quranRepositoryProvider).ayahById(plan.currentAyahId))
            .page;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MushafScreen(
          initialPage: page,
          hifzPracticeMode: true,
          hifzPlanId: plan.id,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HifzPlan plan,
  ) async {
    // حذف حقيقي بلا تراجع (لا شاشة "أرشيف" تسترجعه) — تأكيد أولاً بطلب
    // صريح، كما يليق بإجراء صعب التراجع.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف خطة الحفظ؟'),
        content: const Text(
          'سيُحذف تقدّم هذه الخطة نهائياً ولا يمكن التراجع عن الحذف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(hifzPrefsProvider).cancel(plan.id);
    ref.read(hifzVersionProvider.notifier).bump();
  }
}

/// "فضل حفظ القرآن ومراجعته" — حديث واحد يتبدّل يومياً (راجع توثيق
/// `_hifzVirtueHadithProvider`/`_kHifzVirtueHadiths` أعلى الملف)، مجلوب
/// حياً من `hadith.db` المرخّصة، لا نص مؤلَّف بالكود.
class _HifzVirtueCard extends ConsumerWidget {
  const _HifzVirtueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final pick = ref.watch(_hifzVirtueHadithProvider).value;
    final hadith = pick?.hadith;
    if (hadith == null) return const SizedBox.shrink();

    return Card(
      color: AppColors.purple.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.purple,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'فضل حفظ القرآن ومراجعته',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // سند مختصَر بطلب صاحب المشروع "اختصر السند اجعله فقط الراوي عن
            // رسول الله ﷺ والحديث" — نسبة كل حديث موثَّقة يدوياً بـ
            // `_kHifzVirtueHadiths`، المتن نفسه مجلوب حياً بلا تعديل، فقط
            // سلسلة "حَدَّثَنَا..." تُحذَف من العرض (راجع [hadithMatnOnly]).
            Text(
              '${pick!.narrator}، عَنِ النَّبِيِّ صلى الله عليه وسلم:\n${hadithMatnOnly(hadith.content)}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.85),
                fontSize: 13.5,
                height: 1.7,
              ),
            ),
            Text(
              pick.source,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 48, color: themeAccent(context)),
          const SizedBox(height: 16),
          const Text(
            'لا خطط حفظ بعد',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'اختر نطاق آيات تريد حفظه — من سورة مباشرة، أو حدّده بنفسك من المصحف. تقدر تبدأ أكثر من خطة بنفس الوقت لاحقاً.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('ابدأ خطة حفظ'),
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _StartChoiceSheet extends StatelessWidget {
  const _StartChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'خطة حفظ جديدة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('اختر من سورة'),
              onPressed: () => Navigator.of(context).pop(_StartChoice.surah),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('حدّد من المصحف'),
              onPressed: () => Navigator.of(context).pop(_StartChoice.mushaf),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.plan,
    required this.onContinue,
    required this.onDelete,
  });
  final HifzPlan plan;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final labelAsync = ref.watch(
      _hifzRangeLabelProvider((plan.fromAyahId, plan.toAyahId)),
    );

    // بطاقة موحَّدة بحلقة تقدّم دائرية — بطلب صاحب المشروع "لو تحسّن شكلها"،
    // بنفس لغة التصميم المعتمدة (راجع `_ActivePlanView` بـ`khatma_screen.dart`
    // — نفس المبدأ بالضبط).
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: plan.progress.clamp(0.0, 1.0),
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.purple.withValues(
                          alpha: 0.14,
                        ),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.purple,
                        ),
                      ),
                    ),
                    Text(
                      '${(plan.progress * 100).round()}٪',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelAsync.when(
                      loading: () => const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => const Text(
                        'تعذّر تحميل بيانات النطاق',
                        style: TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 13,
                        ),
                      ),
                      data: (label) => Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'بدأت بتاريخ ${_formatDate(plan.createdAt)}',
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('تابع الحفظ'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'حذف الخطة',
                color: _textSoft(context),
                onPressed: onDelete,
              ),
            ],
          ),
          _DueReviewRow(planId: plan.id),
        ],
      ),
    );
  }
}

/// شارة/زر "مراجعة اليوم" — يظهر فقط لو فيه آيات مستحقّة فعلاً (راجع
/// `_dueReviewCountProvider`/`HifzReviewScreen`). لا شيء لو صفر (لا داعي
/// لزر معطَّل دائم الظهور).
class _DueReviewRow extends ConsumerWidget {
  const _DueReviewRow({required this.planId});
  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(_dueReviewCountProvider(planId)).value ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.psychology_outlined, size: 18),
        label: Text(
          due > 0
              ? 'مراجعة وتثبيت اليوم ($due آية مستحقة)'
              : 'مراجعة وتثبيت الحفظ',
        ),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HifzReviewScreen(planId: planId)),
          );
          ref.invalidate(_dueReviewCountProvider(planId));
        },
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// تذكير يومي عام لكل خطط الحفظ معاً — صف إعدادات وحيد بقاعدة البيانات
/// (`HifzSettings`)، لا تذكير مستقل لكل خطة على حدة.
///
/// **باج حقيقي مُصلَح هون:** كانت تُستخدَم كـ`const _ReminderSection()` بموقع
/// الاستدعاء (`HifzScreen.build`) — بلا معاملات، فهي قيمة `const` قانونية
/// كاملة الهوية (نفس الكائن حرفياً بكل استدعاء نصّي). Flutter يقارن
/// `child.widget == newWidget` **قبل** استدعاء `update()`/`build()` عند إعادة
/// بناء الأب (`Element.updateChild`)؛ لو متطابقان (وهما كذلك بلا معاملات) يعيد
/// نفس العنصر بلا استدعاء `build()` أبداً — أي هذا الودجت **لا يُعاد بناؤه
/// إطلاقاً** حتى لو أُعيد بناء `HifzScreen` نفسها بسبب `hifzVersionProvider`.
/// النتيجة: `hifzPrefs.reminderEnabled`/`.reminderHour` المعروضتان بالمفتاح
/// أسفل تبقيان بقيمة أول بناء للأبد، فيبدو تفعيل التذكير "ما بيصير" رغم أنه
/// فعلياً يُكتب بقاعدة البيانات ويُجدوَل بنجاح. الحل المزدوج: (١) إزالة
/// `const` بموقع الاستدعاء، (٢) مراقبة `hifzVersionProvider` هون مباشرة
/// (دفاعي إضافي — يجعل هذا الودجت يعيد بناء نفسه بفضل Riverpod حتى لو أُعيد
/// لفّه بـ`const` بالخطأ لاحقاً). بلاغ صاحب المشروع "الحفظ... بقدرش افعله"
/// كان بالضبط بهذا السبب.
class _ReminderSection extends ConsumerWidget {
  // ignore: prefer_const_constructors_in_immutables
  // عمداً بلا `const` — راجع توثيق الفئة أعلاه (باج إعادة البناء).
  const _ReminderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hifzVersionProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hifzPrefs = ref.watch(hifzPrefsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تذكير يومي',
          style: TextStyle(
            color: onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'إشعار يتكرر كل يوم بالساعة اللي تختارها لتذكيرك بمتابعة الحفظ — يخص كل خططك معاً.',
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.6),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('تفعيل التذكير'),
          value: hifzPrefs.reminderEnabled,
          onChanged: (v) => _toggleEnabled(context, ref, v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time),
          title: Text(
            hifzPrefs.reminderHour != null
                ? formatTimeOfDay(
                    hifzPrefs.reminderHour!,
                    hifzPrefs.reminderMinute,
                  )
                : 'اختر الساعة',
          ),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _pickTime(context, ref),
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final hifzPrefs = ref.read(hifzPrefsProvider);
    final initial = TimeOfDay(
      hour: hifzPrefs.reminderHour ?? 20,
      minute: hifzPrefs.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: initial,
    );
    if (picked == null || !context.mounted) return;
    await hifzPrefs.setReminder(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    ref.read(hifzVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyReminderState(context, ref);
  }

  Future<void> _toggleEnabled(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final hifzPrefs = ref.read(hifzPrefsProvider);
    if (value && hifzPrefs.reminderHour == null) {
      // ما في ساعة مختارة بعد — نفتح منتقي الوقت مباشرة، وهو يفعّل ضمنياً
      // (`setReminder(enabled: true, ...)`) عند الاختيار.
      await _pickTime(context, ref);
      return;
    }
    await hifzPrefs.setReminder(enabled: value);
    ref.read(hifzVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyReminderState(context, ref);
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `qiyam_screen.dart._applyReminderState`.
  Future<void> _applyReminderState(BuildContext context, WidgetRef ref) async {
    final hifzPrefs = ref.read(hifzPrefsProvider);
    try {
      if (hifzPrefs.reminderEnabled && hifzPrefs.reminderHour != null) {
        await AdhanNotificationService.instance.requestPermissions();
        final messages = await hifzReminderMessages(
          ref.read(hadithRepositoryProvider),
        );
        await AdhanNotificationService.instance.scheduleHifzReminder(
          hour: hifzPrefs.reminderHour!,
          minute: hifzPrefs.reminderMinute,
          messages: messages,
        );
      } else {
        await AdhanNotificationService.instance.cancelHifzReminder();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط تذكير الحفظ على هذا الجهاز: $e')),
      );
    }
  }
}
