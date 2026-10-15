import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/mushaf_palettes.dart';
import '../../mushaf/font_download_screen.dart';
import '../../mushaf/font_download_service.dart';
import '../../mushaf/mushaf_page_provider.dart';
import '../../mushaf/mushaf_settings.dart';
import 'settings_section_helpers.dart';

const Map<ThemeMode, String> _kThemeLabels = {
  ThemeMode.system: 'حسب النظام',
  ThemeMode.light: 'فاتح',
  ThemeMode.dark: 'داكن',
};

/// قسم "المظهر والألوان" — وضع المظهر، لون تمييز التطبيق، ألوان صفحة
/// المصحف، طبعة خط المصحف، وحجم خط الصفحة. استُخرج من `settings_screen.dart`
/// أثناء تفكيكه بلا أي تغيير سلوكي.
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('المظهر والألوان'),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubHeader('وضع المظهر (فاتح/داكن)'),
                SegmentedButton<ThemeMode>(
                  segments: [
                    for (final mode in ThemeMode.values)
                      ButtonSegment(
                        value: mode,
                        label: Text(_kThemeLabels[mode]!),
                      ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).set(s.first),
                ),
                if (themeMode != ThemeMode.light) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'الوضع الليلي الصافي (AMOLED Black)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'خلفية سوداء نقية بالكامل لتوفير البطارية وإراحة العين تماماً',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: ref.watch(amoledDarkModeProvider),
                    onChanged: (val) =>
                        ref.read(amoledDarkModeProvider.notifier).set(val),
                  ),
                ],
                const SizedBox(height: 16),
                const SubHeader('لون خلفية ونصوص صفحة المصحف'),
                const _MushafColorSection(),
                const SizedBox(height: 16),
                const SubHeader('حجم نصوص التطبيق العامة'),
                const _GlobalTextScaleSelector(),
                const SizedBox(height: 16),
                const SubHeader('طبعة خط المصحف'),
                const _MushafFontEditionSection(),
                const SizedBox(height: 16),
                const SubHeader('حجم خط صفحة المصحف والتخطيط'),
                const _TextSizeSlider(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlobalTextScaleSelector extends ConsumerWidget {
  const _GlobalTextScaleSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appTextScaleProvider);
    return SegmentedButton<AppTextScale>(
      segments: [
        for (final scale in AppTextScale.values)
          ButtonSegment(
            value: scale,
            label: Text(
              scale.label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
      selected: {current},
      onSelectionChanged: (s) =>
          ref.read(appTextScaleProvider.notifier).set(s.first),
    );
  }
}


/// شبكة لوحات ألوان صفحة المصحف — لوحات جاهزة (راجع `mushaf_palettes.dart`)
/// لا منتقي ألوان حرّ، بطلب صاحب المشروع "شو الأفضل" لقسم "ألوان" (توصية:
/// تصاميم متحفّظة تحافظ على الهوية البصرية بدل أي تركيبة تكسرها). كل بطاقة
/// معاينة صغيرة بلونَي الخلفية/النص الفعليين للوحة بوضع العرض الحالي
/// (فاتح/داكن)، فتحاكي شكل صفحة المصحف الحقيقي قبل الاختيار.
class _MushafColorSection extends ConsumerWidget {
  const _MushafColorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mushafPaletteVersionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = ref.read(userPrefsProvider).mushafPaletteId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final palette in kMushafPalettes)
              _PaletteSwatch(
                palette: palette,
                isDark: isDark,
                isSelected: palette.id == selected,
                onTap: () async {
                  await ref
                      .read(userPrefsProvider)
                      .setMushafPaletteId(palette.id);
                  ref.read(mushafPaletteVersionProvider.notifier).bump();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        const _MushafNightModeSection(),
      ],
    );
  }
}

/// إعداد "المصحف الليلي" — قلب ألوان صفحة المصحف كاملة (راجع
/// `mushaf_page_widget.dart`)، بثلاث حالات: تلقائي (يتبع وضع الثيم العام
/// المظلم)، مفعَّل دائماً، معطَّل دائماً.
class _MushafNightModeSection extends ConsumerWidget {
  const _MushafNightModeSection();

  static const _options = [
    (value: 'auto', label: 'تلقائي', icon: Icons.brightness_auto_outlined),
    (value: 'on', label: 'مفعَّل دائماً', icon: Icons.dark_mode_outlined),
    (value: 'off', label: 'معطَّل دائماً', icon: Icons.light_mode_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mushafPaletteVersionProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = ref.read(userPrefsProvider).mushafNightMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المصحف الليلي',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        // بطلب صاحب المشروع "خلي الخيارات الثلاث جنب بعض" — صفّ واحد بالثلاث
        // خيارات (بدل `Wrap` اللي كان يلفّ الخيار الثالث لسطر ثانٍ بأسماء
        // أطول)، كل خيار موسَّع بالتساوي (`Expanded`) فلا حاجة لتقصير الاسم.
        Row(
          children: [
            for (final option in _options) ...[
              if (option != _options.first) const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  avatar: Icon(option.icon, size: 15),
                  selected: selected == option.value,
                  showCheckmark: false,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  onSelected: (_) async {
                    await ref
                        .read(userPrefsProvider)
                        .setMushafNightMode(option.value);
                    ref.read(mushafPaletteVersionProvider.notifier).bump();
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// دائرة لونية مملوءة بخلفية اللوحة + اسمها تحتها — بطلب صاحب المشروع
/// "خلي شكل الاعدادات هيك" (تصميم مرجعي: دوائر ألوان مباشرة، لا بطاقة
/// معاينة صفحة). حلقة ذهبية حول الدائرة المختارة بدل تأطير الصندوق كاملاً.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });
  final MushafColorPalette palette;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.bg(isDark),
                border: Border.all(
                  color: isSelected ? themeAccent(context) : AppColors.line,
                  width: isSelected ? 3 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Icon(Icons.check, size: 18, color: palette.fg(isDark))
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              palette.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafFontEditionSection extends ConsumerWidget {
  const _MushafFontEditionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(mushafFontEditionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<MushafFontEdition>(
          segments: [
            for (final edition in MushafFontEdition.values)
              ButtonSegment(
                value: edition,
                label: Text(edition.label, style: const TextStyle(fontSize: 12)),
              ),
          ],
          selected: {current},
          onSelectionChanged: (s) =>
              ref.read(mushafFontEditionProvider.notifier).set(s.first),
        ),
        const SizedBox(height: 10),
        // معاينة شكل كل طبعة جنب بعض (نفس آية الفاتحة الأولى بكل طبعة) —
        // لV1/V4 غير المضمَّنتين هذا يُنزِّل خط صفحة ١ فقط مرّة واحدة
        // بالخلفية (راجع توثيق `mushafEditionPreviewProvider`).
        Row(
          children: [
            for (final edition in MushafFontEdition.values)
              Expanded(child: _FontEditionPreviewCard(edition: edition)),
          ],
        ),
        const SizedBox(height: 10),
        Consumer(
          builder: (context, ref, _) {
            final (first, last) = downloadableRangeFor(current);
            final total = last - first + 1;
            final countAsync = ref.watch(fontDownloadedCountProvider(current));
            final downloaded = countAsync.value ?? 0;
            final isAllDone = downloaded >= total;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: themeAccent(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: themeAccent(context).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    isAllDone ? Icons.check_circle_outline : Icons.download_outlined,
                    size: 18,
                    color: isAllDone ? AppColors.tealDeep : themeAccent(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAllDone
                          ? 'طبعة ${current.label} مكتملة التحميل ($downloaded/$total)'
                          : 'المحمّل من هذه الطبعة: $downloaded من $total صفحة',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FontDownloadScreen(edition: current)),
                    ),
                    child: Text(
                      isAllDone ? 'إدارة' : 'تنزيل الباقي',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: themeAccent(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FontEditionPreviewCard extends ConsumerWidget {
  const _FontEditionPreviewCard({required this.edition});
  final MushafFontEdition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(mushafEditionPreviewProvider(edition));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Center(
              child: previewAsync.when(
                data: (p) => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    p.text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: p.fontFamily, fontSize: 22),
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Icon(
                  Icons.cloud_off_outlined,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            switch (edition) {
              MushafFontEdition.v1 => 'V1',
              MushafFontEdition.v2 => 'V2',
              MushafFontEdition.v4Tajweed => 'V4 Tajweed',
            },
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(height: 2),
          Consumer(
            builder: (context, ref, _) {
              final countAsync = ref.watch(fontDownloadedCountProvider(edition));
              final (first, last) = downloadableRangeFor(edition);
              final total = last - first + 1;
              final count = countAsync.value ?? 0;
              final isComplete = count >= total;
              return Text(
                '$count/$total',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isComplete
                      ? AppColors.tealDeep
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// شريحة انزلاق لحجم خط المصحف (٥ درجات، راجع `MushafTextSize`) — بدل
/// `SegmentedButton`، بطلب صاحب المشروع "زبط شكل حجم الخط" (تصميم مرجعي:
/// شريحة بحرف "نص" صغير بطرف وكبير بالآخر). عدد الدرجات مأخوذ من
/// `MushafTextSize.values.length` مباشرة — تكبر الشريحة تلقائياً لو زادت
/// الدرجات لاحقاً بلا تعديل هون. الانزلاق نفسه دوري عبر `cycle()` (لا
/// اختيار مباشر بالتصميم الأصلي) — يكرّرها حتى يصل الدرجة المطلوبة.
class _TextSizeSlider extends ConsumerWidget {
  const _TextSizeSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = ref.watch(mushafTextSizeProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final index = MushafTextSize.values.indexOf(textSize).toDouble();

    return Row(
      children: [
        Text(
          'نص',
          style: TextStyle(
            fontSize: 12,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Slider(
            value: index,
            min: 0,
            max: (MushafTextSize.values.length - 1).toDouble(),
            divisions: MushafTextSize.values.length - 1,
            activeColor: themeAccent(context),
            onChanged: (v) {
              final target = MushafTextSize.values[v.round()];
              var current = ref.read(mushafTextSizeProvider);
              // `cycle()` دوري فقط — لا اختيار مباشر، الدورة كافية بـ٣ خيارات.
              while (current != target) {
                ref.read(mushafTextSizeProvider.notifier).cycle();
                current = ref.read(mushafTextSizeProvider);
              }
            },
          ),
        ),
        Text(
          'نص',
          style: TextStyle(
            fontSize: 20,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
