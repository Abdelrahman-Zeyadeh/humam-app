import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';

/// نتيجة اختيار نطاق حفظ: طرفا النطاق كـ`ayah_id` عام (١-٦٢٣٦)، جاهزَين
/// لتمريرهما مباشرة لـ`UserRepository.startHifzPlan`.
typedef HifzRange = ({int from, int to});

/// ورقة سفلية باختيارين متتاليين: سورة (بنمط `MushafSurahIndexSheet`)، ثم
/// "من آية" و"إلى آية" ضمن حدود تلك السورة فقط — نطاق ضمن سورة واحدة بهذه
/// الجولة (راجع ملاحظة النطاق بخطة التنفيذ).
class HifzRangePickerSheet extends ConsumerStatefulWidget {
  const HifzRangePickerSheet({super.key});

  static Future<HifzRange?> show(BuildContext context) {
    return showModalBottomSheet<HifzRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const HifzRangePickerSheet(),
    );
  }

  @override
  ConsumerState<HifzRangePickerSheet> createState() => _HifzRangePickerSheetState();
}

class _HifzRangePickerSheetState extends ConsumerState<HifzRangePickerSheet> {
  Surah? _surah;
  int _from = 1;
  int _to = 1;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(
              _surah == null ? 'اختر السورة' : 'من آية إلى آية — ${_surah!.nameAr}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
            ),
            const Divider(height: 24),
            Expanded(child: _surah == null ? _SurahList(onPicked: _onSurahPicked) : _RangePicker(
              surah: _surah!,
              from: _from,
              to: _to,
              onChanged: (from, to) => setState(() {
                _from = from;
                _to = to;
              }),
              onBack: () => setState(() => _surah = null),
              onConfirm: _confirm,
            )),
          ],
        ),
      ),
    );
  }

  void _onSurahPicked(Surah surah) {
    setState(() {
      _surah = surah;
      _from = 1;
      _to = surah.ayahCount;
    });
  }

  Future<void> _confirm() async {
    final surah = _surah;
    if (surah == null) return;
    final ayahs = await ref.read(quranRepositoryProvider).ayahsForSurah(surah.id);
    if (ayahs.isEmpty || !mounted) return;
    final fromId = ayahs[(_from - 1).clamp(0, ayahs.length - 1)].id;
    final toId = ayahs[(_to - 1).clamp(0, ayahs.length - 1)].id;
    Navigator.of(context).pop((from: fromId, to: toId));
  }
}

class _SurahList extends ConsumerWidget {
  const _SurahList({required this.onPicked});
  final ValueChanged<Surah> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(_allSurahsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return surahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('تعذّر تحميل فهرس السور')),
      data: (surahs) => ListView.separated(
        itemCount: surahs.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) {
          final s = surahs[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: themeAccent(context).withValues(alpha: 0.15),
              foregroundColor: themeAccent(context),
              child: Text('${s.id}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            title: Text(s.nameAr, style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
            subtitle: Text('${s.ayahCount} آية', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            onTap: () => onPicked(s),
          );
        },
      ),
    );
  }
}

class _RangePicker extends StatelessWidget {
  const _RangePicker({
    required this.surah,
    required this.from,
    required this.to,
    required this.onChanged,
    required this.onBack,
    required this.onConfirm,
  });
  final Surah surah;
  final int from;
  final int to;
  final void Function(int from, int to) onChanged;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'من آية',
                  value: from,
                  min: 1,
                  max: surah.ayahCount,
                  onChanged: (v) => onChanged(v > to ? to : v, to),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NumberField(
                  label: 'إلى آية',
                  value: to,
                  min: 1,
                  max: surah.ayahCount,
                  onChanged: (v) => onChanged(from, v < from ? from : v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${to - from + 1} آية مختارة', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(onPressed: onBack, child: const Text('سورة أخرى')),
              const Spacer(),
              FilledButton(onPressed: onConfirm, child: const Text('بدء خطة الحفظ')),
            ],
          ),
        ],
      ),
    );
  }
}

/// حقل رقم بعدّاد +/- **وكتابة مباشرة أيضاً** (بطلب صاحب المشروع: "تحديد
/// الآيات من خلال الكتابة مش بس من العداد") — `TextField` بينهما بدل نص
/// ثابت. الكتابة تُطبَّق عند فقد التركيز أو ضغط "تم"، وتُحصر ضمن [min]/[max]
/// كما العدّاد تماماً.
class _NumberField extends StatefulWidget {
  const _NumberField({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);

  void _onFocusChange() {
    // فقد التركيز = تطبيق ما كُتب (تنقّل بالضغط على حقل آخر بلا "تم" بلوحة
    // المفاتيح) — لا تجاهل صامت لما كتبه المستخدم.
    if (!_focusNode.hasFocus) _submit(_controller.text);
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // مزامنة من مصدر خارجي (زر +/- بهذا الحقل أو تغيّر الحقل الآخر يقلّم
    // هذا) — فقط لو الحقل غير مركَّز حالياً، حتى لا "يقفز" النص أثناء الكتابة.
    if (!_focusNode.hasFocus) {
      final text = '${widget.value}';
      if (_controller.text != text) _controller.text = text;
    }
  }

  void _submit(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) {
      _controller.text = '${widget.value}';
      return;
    }
    final clamped = parsed.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
    if (clamped != parsed) _controller.text = '$clamped';
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Text(widget.label, style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: widget.value > widget.min ? () => widget.onChanged(widget.value - 1) : null),
            SizedBox(
              width: 56,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                onSubmitted: _submit,
              ),
            ),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: widget.value < widget.max ? () => widget.onChanged(widget.value + 1) : null),
          ],
        ),
      ],
    );
  }
}

final _allSurahsProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).allSurahs();
});
