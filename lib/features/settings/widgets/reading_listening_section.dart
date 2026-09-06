import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../audio/audio_downloads_screen.dart';
import '../../audio/quran_audio_controller.dart';
import '../../audio/reciters.dart';
import '../../home/dashboard_customize_sheet.dart';
import '../../mushaf/mushaf_settings.dart';
import 'settings_section_helpers.dart';

/// قسم "القراءة والاستماع" — يجمع ٣ أقسام كانت بطاقات منفصلة (تخصيص
/// الداشبورد، القارئ والتلاوات، حجم خط التفسير) ببطاقة واحدة — يقلّص عدد
/// البطاقات المتكرّرة الشكل بلا حذف أي محتوى حقيقي. استُخرج من
/// `settings_screen.dart` أثناء تفكيكه بلا أي تغيير سلوكي.
class ReadingListeningSection extends ConsumerWidget {
  const ReadingListeningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final audio = ref.watch(quranAudioControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('القراءة والاستماع'),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.dashboard_customize_outlined,
                  color: themeAccent(context),
                ),
                title: const Text('تخصيص سلاسل الاستمرار والبطاقات'),
                subtitle: const Text(
                  'اختر الأعمال اليومية التي تود متابعتها بالشاشة الرئيسية',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const DashboardCustomizeSheet(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.record_voice_over_outlined,
                  color: themeAccent(context),
                ),
                title: const Text('القارئ الافتراضي للتلاوة'),
                subtitle: Text(
                  reciterById(audio.reciterId).nameAr,
                  style: TextStyle(
                    color: themeAccent(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () =>
                    _showReciterPickerModal(context, ref, audio.reciterId),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.download_for_offline_outlined,
                  color: onSurface.withValues(alpha: 0.7),
                ),
                title: const Text('تنزيل التلاوات للاستماع بلا إنترنت'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AudioDownloadsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SubHeader('حجم خط التفسير والأحاديث والترجمة وقراءة المصحف مع التفسير'),
                    const _TafsirFontSizeSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _showReciterPickerModal(
  BuildContext context,
  WidgetRef ref,
  String currentReciterId,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      final onSurface = Theme.of(sheetCtx).colorScheme.onSurface;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.record_voice_over_outlined,
                      color: themeAccent(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'اختيار القارئ الافتراضي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: kReciters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, idx) {
                    final r = kReciters[idx];
                    final isSelected = r.id == currentReciterId;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? themeAccent(context)
                            : onSurface.withValues(alpha: 0.4),
                      ),
                      title: Text(
                        r.nameAr,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected ? themeAccent(context) : onSurface,
                        ),
                      ),
                      subtitle: r.mode == ReciterAudioMode.perSurahOnly
                          ? const Text(
                              'تشغيل السورة كاملة فقط — لا تظليل متزامن',
                              style: TextStyle(fontSize: 11),
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(quranAudioControllerProvider.notifier)
                            .setReciter(r.id);
                        Navigator.of(sheetCtx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// شريحة انزلاق دقيقة لحجم خط التفسير والأحاديث والترجمة (وقرآن "قراءة مع
/// التفسير") مع معاينة حية — راجع توثيق `TafsirFontSizeNotifier`.
class _TafsirFontSizeSection extends ConsumerWidget {
  const _TafsirFontSizeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(tafsirFontSizeProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'أ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            Expanded(
              child: Slider(
                value: fontSize,
                min: 13.0,
                max: 34.0,
                divisions: 21,
                label: '${fontSize.toInt()} pt',
                activeColor: themeAccent(context),
                onChanged: (v) =>
                    ref.read(tafsirFontSizeProvider.notifier).setSize(v),
              ),
            ),
            Text(
              'أ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'معاينة نص التفسير والحديث (${fontSize.toInt()} pt):',
                style: TextStyle(
                  fontSize: 11,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '﴿إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ﴾ أي: نخصّك وحدك بالعبادة ونستعين بك وحدك في جميع أمورنا.',
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.6,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
