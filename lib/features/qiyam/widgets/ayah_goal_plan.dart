import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/hadith/hadith_database.dart' show Hadith;
import '../../../core/data/hadith/hadith_providers.dart';
import '../../../core/data/hadith/hadith_repository.dart' show hadithMatnOnly;
import '../../../core/data/quran/quran_database.dart' show Surah;
import '../../../core/data/quran/quran_providers.dart';
import '../../../core/data/quran/quran_repository.dart' show QuranRepository;
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../mushaf/mushaf_screen.dart';
import '../../mushaf/mushaf_settings.dart' show qiyamSessionProvider;

/// وصف زر "خطة بعدد آيات" واحد — الهدف، تسميته العربية، لقب مرتبته
/// (بالحديث نفسه)، لونه، والعبارة الحرفية بنص الحديث المطلوب تمييزها
/// بصرياً لهذا الزر تحديداً (راجع [HighlightedHadithText]).
typedef AyahGoal = ({
  int goal,
  String label,
  String rankLabel,
  Color color,
  String highlight,
});

const List<AyahGoal> kAyahGoals = [
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

/// حديث "خطة قيام بعدد آيات" — سنن أبي داود (١٣٩٨)، مجلوب حياً من
/// `hadith.db` المرخّصة (`book_id=4` أبو داود)، **لا نص مؤلَّف بالكود**.
/// يغطّي المراتب الثلاث معاً بحديث واحد: "مَنْ قَامَ بِعَشْرِ آيَاتٍ لَمْ
/// يُكْتَبْ مِنَ الْغَافِلِينَ، وَمَنْ قَامَ بِمِائَةِ آيَةٍ كُتِبَ مِنَ
/// الْقَانِتِينَ، وَمَنْ قَامَ بِأَلْفِ آيَةٍ كُتِبَ مِنَ الْمُقَنْطَرِينَ".
final _qiyamGoalHadithProvider = FutureProvider<Hadith?>((ref) {
  return ref.watch(hadithRepositoryProvider).hadithByBookAndNumber(4, 1398);
});

/// أزرار "خطة قيام بعدد آيات" الثلاثة (١٠/١٠٠/١٠٠٠ آية فقط — بلا عدد حرّ
/// مخصَّص، بطلب صاحب المشروع صراحة) — بإلهام من موقع قانتين
/// (qaniteen.com). كل زر يفتح [_QiyamGoalSheet] بحديث الفضل الكامل (سنن
/// أبي داود ١٣٩٨) وخيار بدء القراءة فعلياً بمجموعة سور مقترحة تصل لهذا
/// العدد (راجع [pickRandomSurahGroup] أعلى الملف).
class AyahGoalButtons extends StatelessWidget {
  const AyahGoalButtons({super.key});

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
          for (var i = 0; i < kAyahGoals.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Material(
                color: isDark
                    ? kAyahGoals[i].color.withValues(alpha: 0.14)
                    : kAyahGoals[i].color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _QiyamGoalSheet(goal: kAyahGoals[i]),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kAyahGoals[i].color.withValues(alpha: 0.4),
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
                          color: kAyahGoals[i].color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kAyahGoals[i].label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: kAyahGoals[i].color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kAyahGoals[i].rankLabel,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: kAyahGoals[i].color.withValues(alpha: 0.85),
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
  final AyahGoal goal;

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
