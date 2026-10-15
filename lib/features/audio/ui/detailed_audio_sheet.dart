import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/quran/quran_database.dart';
import '../../../core/data/quran/quran_providers.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../audio_downloads_screen.dart';
import '../quran_audio_controller.dart';
import '../reciters.dart';
import 'reciter_avatar.dart';

/// نافذة خيارات التلاوة السريعة عند الضغط على آية
class AyahAudioQuickSheet extends ConsumerWidget {
  const AyahAudioQuickSheet({
    super.key,
    required this.ayah,
    required this.surah,
  });

  final Ayah ayah;
  final Surah surah;

  static Future<void> show(BuildContext context, {required Ayah ayah, required Surah surah}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AyahAudioQuickSheet(ayah: ayah, surah: surah),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس النافذة
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'خيارات التلاوة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.nameAr} · آية ${ayah.ayah}',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: themeAccent(context), size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // خيار: الاستماع لهذه الآية فقط
            _AudioOptionTile(
              title: 'الاستماع لهذه الآية فقط',
              icon: Icons.play_arrow_rounded,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(quranAudioControllerProvider.notifier).playAyah(surah.id, ayah.ayah);
              },
            ),
            const SizedBox(height: 8),

            // خيار: بدء الاستماع من هذه الآية
            _AudioOptionTile(
              title: 'بدء الاستماع من هذه الآية',
              icon: Icons.fast_forward_rounded,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(quranAudioControllerProvider.notifier).playRange(
                  surahId: surah.id,
                  fromAyah: ayah.ayah,
                  toAyah: surah.ayahCount,
                );
              },
            ),
            const SizedBox(height: 14),

            // زر: المزيد من خيارات الاستماع (المقطع، القارئ، التكرار، السرعة)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2C3542) : const Color(0xFF374151),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                DetailedAudioRangeSheet.show(context, initialSurah: surah, initialAyah: ayah);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.chevron_left, size: 20),
                  Text(
                    'المزيد من خيارات الاستماع',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioOptionTile extends StatelessWidget {
  const _AudioOptionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              Icon(icon, size: 20, color: themeAccent(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// نافذة خيارات التلاوة المتقدمة (تحديد المقطع، اختيار القارئ مع بحث، التكرار، السرعة)
class DetailedAudioRangeSheet extends ConsumerStatefulWidget {
  const DetailedAudioRangeSheet({
    super.key,
    required this.initialSurah,
    required this.initialAyah,
  });

  final Surah initialSurah;
  final Ayah initialAyah;

  static Future<void> show(
    BuildContext context, {
    required Surah initialSurah,
    required Ayah initialAyah,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DetailedAudioRangeSheet(
        initialSurah: initialSurah,
        initialAyah: initialAyah,
      ),
    );
  }

  @override
  ConsumerState<DetailedAudioRangeSheet> createState() => _DetailedAudioRangeSheetState();
}

class _DetailedAudioRangeSheetState extends ConsumerState<DetailedAudioRangeSheet> {
  late final int _surahId = widget.initialSurah.id;
  late int _fromAyah = widget.initialAyah.ayah;
  late int _toAyah = widget.initialSurah.ayahCount;
  int _rangeRepeat = 1;
  int _ayahRepeat = 1;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    final audio = ref.read(quranAudioControllerProvider);
    _speed = audio.speed;
  }

  void _showReciterSearchPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReciterSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(quranAudioControllerProvider);
    final reciter = reciterById(audio.reciterId);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahsAsync = ref.watch(allSurahsProvider);
    final surahs = surahsAsync.value ?? const [];
    final currentSurah = surahs.where((s) => s.id == _surahId).firstOrNull ?? widget.initialSurah;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رأس النافذة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'حدد المقطع والخيارات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),

              // قسم 1: حدد المقطع
              _SectionBox(
                title: 'حدد المقطع',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownSelector<int>(
                            label: 'إلى الآية',
                            value: _toAyah,
                            items: List.generate(
                              currentSurah.ayahCount,
                              (i) => DropdownMenuItem(value: i + 1, child: Text('آية ${i + 1}')),
                            ),
                            onChanged: (v) {
                              if (v != null) setState(() => _toAyah = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DropdownSelector<int>(
                            label: 'من الآية',
                            value: _fromAyah,
                            items: List.generate(
                              currentSurah.ayahCount,
                              (i) => DropdownMenuItem(value: i + 1, child: Text('آية ${i + 1}')),
                            ),
                            onChanged: (v) {
                              if (v != null) setState(() => _fromAyah = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // قسم 2: اختر القارئ
              _SectionBox(
                title: 'اختر القارئ',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ReciterAvatar(reciter: reciter, radius: 20),
                      title: Text(
                        reciter.nameAr,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: const Text('اضغط للبحث واختيار قارئ آخر', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.search, size: 20),
                      onTap: _showReciterSearchPicker,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.download_for_offline_outlined, size: 20),
                      title: const Text('الذهاب لصفحة التحميل والتلاوات بدون إنترنت', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_left, size: 18),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AudioDownloadsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // قسم 3: خيارات التلاوة والتكرار
              _SectionBox(
                title: 'خيارات التلاوة',
                child: Column(
                  children: [
                    _CounterRow(
                      title: 'تكرار المقطع',
                      count: _rangeRepeat,
                      onChanged: (c) => setState(() => _rangeRepeat = c),
                    ),
                    const Divider(height: 12),
                    _CounterRow(
                      title: 'تكرار الآية',
                      count: _ayahRepeat,
                      onChanged: (c) => setState(() => _ayahRepeat = c),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // قسم 4: سرعة التلاوة
              _SectionBox(
                title: 'سرعة التلاوة',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [1.0, 1.25, 1.5, 1.75].map((s) {
                    final isSelected = (_speed - s).abs() < 0.05;
                    return ChoiceChip(
                      label: Text('${s}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      selected: isSelected,
                      selectedColor: themeAccent(context),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : onSurface),
                      onSelected: (_) {
                        setState(() => _speed = s);
                        ref.read(quranAudioControllerProvider.notifier).setSpeed(s);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // زر التشغيل الرئيسي
              AppPrimaryButton(
                icon: Icons.play_arrow_rounded,
                label: 'تشغيل التلاوة',
                onPressed: () {
                  Navigator.of(context).pop();
                  final from = _fromAyah <= _toAyah ? _fromAyah : _toAyah;
                  final to = _fromAyah <= _toAyah ? _toAyah : _fromAyah;
                  ref.read(quranAudioControllerProvider.notifier).playRange(
                    surahId: _surahId,
                    fromAyah: from,
                    toAyah: to,
                    rangeRepeat: _rangeRepeat,
                    ayahRepeat: _ayahRepeat,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.7),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.title,
    required this.count,
    required this.onChanged,
  });

  final String title;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => onChanged(count + 1),
              visualDensity: VisualDensity.compact,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.remove, size: 16),
              onPressed: count > 1 ? () => onChanged(count - 1) : null,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
        ),
      ],
    );
  }
}

class _DropdownSelector<T> extends StatelessWidget {
  const _DropdownSelector({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// نافذة بحث واختيار القارئ السريعة
class _ReciterSearchSheet extends ConsumerStatefulWidget {
  const _ReciterSearchSheet();

  @override
  ConsumerState<_ReciterSearchSheet> createState() => _ReciterSearchSheetState();
}

class _ReciterSearchSheetState extends ConsumerState<_ReciterSearchSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(quranAudioControllerProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = kReciters
        .where((r) => r.nameAr.toLowerCase().contains(_query.toLowerCase().trim()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'اختيار القارئ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (q) => setState(() => _query = q),
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم القارئ (مثلاً: المنشاوي، الحصري...)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = filtered[index];
                final isSelected = r.id == audio.reciterId;

                return ListTile(
                  leading: ReciterAvatar(reciter: r, radius: 20),
                  title: Text(
                    r.nameAr,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? themeAccent(context) : onSurface,
                    ),
                  ),
                  subtitle: r.mode == ReciterAudioMode.perSurahOnly
                      ? const Text('تشغيل السورة كاملة فقط', style: TextStyle(fontSize: 11))
                      : null,
                  trailing: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                    color: isSelected ? themeAccent(context) : onSurface.withValues(alpha: 0.3),
                    size: 22,
                  ),
                  onTap: () {
                    ref.read(quranAudioControllerProvider.notifier).setReciter(r.id);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
