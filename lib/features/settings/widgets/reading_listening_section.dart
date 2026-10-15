import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/platform/dnd_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../audio/audio_downloads_screen.dart';
import '../../audio/quran_audio_controller.dart';
import '../../audio/reciters.dart';
import '../../audio/ui/reciter_avatar.dart';
import '../../home/dashboard_customize_sheet.dart';
import '../../mushaf/font_download_screen.dart';
import '../../mushaf/font_download_service.dart';
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
                leading: ReciterAvatar(
                  reciter: reciterById(audio.reciterId),
                  radius: 18,
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
                  Icons.menu_book_outlined,
                  color: themeAccent(context),
                ),
                title: const Text('تنزيل صفحات المصحف كاملاً بلا إنترنت'),
                subtitle: Consumer(
                  builder: (context, ref, _) {
                    final edition = ref.watch(mushafFontEditionProvider);
                    final (first, last) = downloadableRangeFor(edition);
                    final total = last - first + 1;
                    final downloadedAsync = ref.watch(fontDownloadedCountProvider(edition));
                    final downloaded = downloadedAsync.value ?? 0;
                    return Text(
                      'طبعة ${edition.label} — تم تنزيل $downloaded من $total صفحة',
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  final edition = ref.read(mushafFontEditionProvider);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FontDownloadScreen(edition: edition),
                    ),
                  );
                },
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
              const _DndWhileReadingTile(),
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
                      leading: ReciterAvatar(reciter: r, radius: 20),
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
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_off,
                        color: isSelected
                            ? themeAccent(context)
                            : onSurface.withValues(alpha: 0.3),
                        size: 22,
                      ),
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

/// مفتاح "لا تُزعجني وقت القراءة" — كتم إشعارات الجهاز تلقائياً أثناء فتح
/// المصحف (راجع `DndService`/`MushafScreen.initState`/`dispose`). تفعيله
/// أول مرة يطلب تصريح "الوصول لسياسة الإشعارات" الخاص من المستخدم صراحة
/// (لا رسالة إذن قياسية) — بلا هذا التصريح يبقى المفتاح مفعّلاً بالإعداد
/// لكن الكتم الفعلي لا يحدث أبداً (`DndService.setActive` تفشل بصمت).
class _DndWhileReadingTile extends ConsumerWidget {
  const _DndWhileReadingTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final userPrefs = ref.watch(userPrefsProvider);
    final enabled = userPrefs.dndWhileReadingEnabled;

    return SwitchListTile.adaptive(
      secondary: Icon(Icons.do_not_disturb_on_outlined, color: themeAccent(context)),
      title: const Text('لا تُزعجني وقت القراءة'),
      subtitle: Text(
        'يكتم إشعارات الجهاز تلقائياً أثناء فتح المصحف، ويعيدها فور الخروج',
        style: TextStyle(fontSize: 11.5, color: onSurface.withValues(alpha: 0.6)),
      ),
      value: enabled,
      onChanged: (v) async {
        if (v) {
          final granted = await DndService.isPolicyAccessGranted();
          if (!granted) {
            if (!context.mounted) return;
            final proceed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.do_not_disturb_on_rounded,
                        color: AppColors.teal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'وضع الخشوع أثناء القراءة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'لكتم إشعارات الهاتف مؤقتاً طوال وجودك داخل المصحف الشريف وإعادتها فور خروجك تلقائياً، يحتاج أندرويد إذناً خاصاً يسمى "الوصول لسياسة الإشعارات".\n\nسننقلك الآن للإعدادات، اختر تطبيق "هُمَام" وفعّل المفتاح.',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('لاحقاً'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text('الانتقال للإعدادات'),
                  ),
                ],
              ),
            );
            if (proceed == true) {
              await DndService.openPolicyAccessSettings();
            }
            // ما نفعّل الإعداد قبل رجوع المستخدم من الإعدادات وتأكيد الإذن
            // فعلياً — يبقى المفتاح مطفياً هون بانتظار محاولة تفعيل تالية.
            return;
          }
        }
        await ref.read(userPrefsProvider).setDndWhileReadingEnabled(v);
      },
    );
  }
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
