import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/data/user/backup_service.dart' show BackupRestoreResult;
import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_accent_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mushaf_palettes.dart';
import '../audio/audio_downloads_screen.dart';
import '../audio/quran_audio_controller.dart';
import '../audio/reciters.dart';
import '../mushaf/font_download_screen.dart';
import '../mushaf/mushaf_page_provider.dart';
import '../mushaf/mushaf_settings.dart';
import '../notifications/adhan_notification_prefs.dart';
import '../notifications/adhan_notification_service.dart';
import '../prayer/adhan_voices.dart';

import '../auth/auth_dialog.dart';
import '../auth/cloud_sync_service.dart';
import '../home/dashboard_customize_sheet.dart';
import '../more/reminders_screen.dart';
import '../tajweed/ui/tajweed_color_legend_sheet.dart';
import '../tajweed/ui/tajweed_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'about_screen.dart';
import 'permissions_guide_screen.dart';

const Map<ThemeMode, String> _kThemeLabels = {
  ThemeMode.system: 'حسب النظام',
  ThemeMode.light: 'فاتح',
  ThemeMode.dark: 'داكن',
};

/// الإعدادات: تجميع تفضيلات عامة مبعثرة سابقاً بين شاشات مختلفة
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final themeMode = ref.watch(themeModeProvider);
    final audio = ref.watch(quranAudioControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('المظهر والألوان'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SubHeader('وضع المظهر (فاتح/داكن)'),
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
                  const SizedBox(height: 16),
                  _SubHeader('لون تمييز التطبيق'),
                  const _AppAccentSection(),
                  const SizedBox(height: 16),
                  _SubHeader('لون خلفية ونصوص صفحة المصحف'),
                  const _MushafColorSection(),
                  const SizedBox(height: 16),
                  _SubHeader('طبعة خط المصحف'),
                  const _MushafFontEditionSection(),
                  const SizedBox(height: 16),
                  _SubHeader('حجم خط صفحة المصحف والتخطيط'),
                  const _TextSizeSlider(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // "القراءة والاستماع" — يجمع ٣ أقسام كانت بطاقات منفصلة (تخصيص
          // الداشبورد، القارئ والتلاوات، حجم خط التفسير) ببطاقة واحدة —
          // يقلّص عدد البطاقات المتكرّرة الشكل بلا حذف أي محتوى حقيقي.
          _SectionTitle('القراءة والاستماع'),
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
                      _SubHeader('حجم خط التفسير والأحاديث والترجمة'),
                      const _TafsirFontSizeSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // "الصلاة والتذكيرات" — يجمع ٤ أقسام (تجويد، صوت الأذان،
          // التذكيرات، دقة الأذان) ببطاقة واحدة بنفس المبدأ أعلاه.
          _SectionTitle('الصلاة والتذكيرات'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.palette_outlined, size: 16),
                            label: const Text(
                              'دليل مفتاح ألوان التجويد',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => const TajweedColorLegendSheet(),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.menu_book_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'أحكام التجويد والضبط',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TajweedScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const _AdhanVoiceSection(),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.notifications_active_outlined,
                    color: themeAccent(context),
                  ),
                  title: const Text('كل تذكيرات التطبيق'),
                  subtitle: const Text(
                    'أذكار الصباح/المساء، الورد اليومي، الملخّص المسائي، أذكار كل ساعة، وتنبيهات السنن',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.alarm_on_rounded,
                    color: AppColors.goldDeep,
                  ),
                  title: const Text('مساعد دقة الأذان والبطارية'),
                  subtitle: const Text(
                    'استثناء توفير الطاقة وضبط المنبهات الدقيقة لضمان انطلاق الأذان في وقته',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PermissionsGuideScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // "الحساب والبيانات" — نسخة احتياطية + عن التطبيق.
          _SectionTitle('الحساب والبيانات'),
          const _BackupSection(),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.goldDeep,
              ),
              title: const Text('كتالوج التطبيق والجولة التعريفية'),
              subtitle: const Text(
                'استعراض مميزات التطبيق التفاعلية مع دوائر التركيز والشرح',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(tourActiveProvider.notifier).start();
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF386892),
              ),
              title: const Text('عن هُمَام والمصادر المعتمدة'),
              subtitle: const Text(
                'توثيق مصادر المصحف والتفاسير والأحاديث، سياسة الخصوصية، والتراخيص',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

/// صوت الأذان المستخدَم بإشعارات دخول وقت الصلاة — اختيار + معاينة (▶) لكل
/// صوت غير الافتراضي عبر مشغّل `just_audio` محلي خاص بهاي الودجت (لا علاقة
/// بمشغّل التلاوة `quranAudioControllerProvider` — نطاقان مختلفان تماماً،
/// يوقف المعاينة تلقائياً عند مغادرة الشاشة). راجع `adhan_voices.dart`.
class _AdhanVoiceSection extends ConsumerStatefulWidget {
  const _AdhanVoiceSection();

  @override
  ConsumerState<_AdhanVoiceSection> createState() => _AdhanVoiceSectionState();
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

class _AdhanVoiceSectionState extends ConsumerState<_AdhanVoiceSection> {
  final _player = AudioPlayer();
  String? _previewingId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(AdhanVoice voice) async {
    if (_previewingId == voice.id) {
      await _player.stop();
      if (mounted) setState(() => _previewingId = null);
      return;
    }
    try {
      await _player.stop();
      if (voice.assetPath != null) {
        await _player.setAsset(voice.assetPath!);
      } else if (voice.remoteUrl != null) {
        await _player.setUrl(voice.remoteUrl!);
      } else {
        return;
      }
      if (!mounted) return;
      setState(() => _previewingId = voice.id);
      unawaited(_player.play());
      unawaited(
        _player.playerStateStream
            .firstWhere((s) => s.processingState == ProcessingState.completed)
            .then((_) {
              if (mounted && _previewingId == voice.id) {
                setState(() => _previewingId = null);
              }
            }),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذّر تشغيل المعاينة: $e')));
    }
  }

  Future<void> _select(AdhanVoice voice) async {
    await _player.stop();
    if (mounted) setState(() => _previewingId = null);
    await ref.read(userPrefsProvider).setAdhanVoiceId(voice.id);
    ref.read(adhanVoiceVersionProvider.notifier).bump();
    await _applyReschedule();
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `_ReminderRow._applyState`. لو ما في موقع محفوظ بعد، التفضيل يُحفَظ
  /// بصمت ويُطبَّق أول جدولة لاحقة (عند فتح شاشة الصلاة أو تحديد الموقع).
  Future<void> _applyReschedule() async {
    try {
      final loc = ref.read(locationPrefsProvider);
      if (!loc.hasLocation) return;
      final notifPrefs = ref.read(adhanNotificationPrefsProvider);
      final userPrefs = ref.read(userPrefsProvider);
      await AdhanNotificationService.instance.rescheduleUpcoming(
        lat: loc.lat!,
        lon: loc.lon!,
        methodKey: loc.calculationMethod,
        isEnabled: notifPrefs.effectivelyEnabled,
        voiceId: userPrefs.adhanVoiceId,
        checkinEnabled: userPrefs.prayerCheckinEnabled,
        checkinFirstDelayMinutes: userPrefs.prayerCheckinFirstDelayMinutes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحديث صوت إشعار الأذان: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(adhanVoiceVersionProvider);
    final selected = ref.read(userPrefsProvider).adhanVoiceId;
    final currentVoice = adhanVoiceById(selected);

    // بلا `Card` خاص فيها — الودجت الأب (قسم "الصلاة والتذكيرات" بـ
    // `settings_screen.dart`) هو اللي يوفّر البطاقة المحيطة الآن، فتصير
    // هاي صفوف عادية جوّاها بدل بطاقة متداخلة ببطاقة.
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.record_voice_over_outlined,
            color: themeAccent(context),
          ),
          title: const Text('صوت الأذان (المؤذن)'),
          subtitle: Text(
            currentVoice.label,
            style: TextStyle(
              color: themeAccent(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _showVoicePickerModal(context, ref, selected),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(
            Icons.notifications_active_outlined,
            color: themeAccent(context),
          ),
          title: const Text('إرسال إشعار أذان تجريبي الآن'),
          subtitle: const Text(
            'يصلك إشعار حقيقي خلال ٣ ثوانٍ بنفس صوت الأذان المختار للتأكد من الصوت',
            style: TextStyle(fontSize: 11.5),
          ),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await AdhanNotificationService.instance.requestPermissions();
              await AdhanNotificationService.instance.sendTestNotification(
                voiceId: selected,
              );
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('راقب شريط الإشعارات خلال ثوانٍ... 🔔'),
                  backgroundColor: Color(0xFF1B8A72),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('تعذّر إرسال الإشعار التجريبي: $e')),
              );
            }
          },
        ),
      ],
    );
  }

  void _showVoicePickerModal(
    BuildContext context,
    WidgetRef ref,
    String currentSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final onSurface = Theme.of(context).colorScheme.onSurface;

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
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
                            'اختيار صوت الأذان (المؤذن)',
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
                      child: RadioGroup<String>(
                        groupValue: currentSelected,
                        onChanged: (value) {
                          if (value == null) return;
                          _select(
                            kAdhanVoices.firstWhere((v) => v.id == value),
                          );
                          setModalState(() {});
                          setState(() {});
                        },
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: kAdhanVoices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final voice = kAdhanVoices[idx];
                            final isSelected = voice.id == currentSelected;
                            final isThisPlaying = _previewingId == voice.id;

                            return ListTile(
                              leading: Radio<String>(
                                value: voice.id,
                                activeColor: themeAccent(context),
                              ),
                              title: Text(
                                voice.label,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 13.5,
                                  color: isSelected
                                      ? themeAccent(context)
                                      : onSurface,
                                ),
                              ),
                              subtitle: voice.subLabel != null
                                  ? Text(
                                      voice.subLabel!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: onSurface.withValues(alpha: 0.6),
                                      ),
                                    )
                                  : null,
                              trailing:
                                  (voice.assetPath != null ||
                                      voice.remoteUrl != null)
                                  ? IconButton(
                                      icon: Icon(
                                        isThisPlaying
                                            ? Icons.stop_circle_outlined
                                            : Icons.play_circle_outline,
                                        color: isThisPlaying
                                            ? Colors.redAccent
                                            : themeAccent(context),
                                      ),
                                      tooltip: isThisPlaying
                                          ? 'إيقاف'
                                          : 'استماع للمعاينة',
                                      onPressed: () async {
                                        await _togglePreview(voice);
                                        setModalState(() {});
                                        if (mounted) setState(() {});
                                      },
                                    )
                                  : null,
                              onTap: () {
                                _select(voice);
                                setModalState(() {});
                                setState(() {});
                              },
                            );
                          },
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
  }
}

/// دوائر لون تمييز التطبيق العام — نفس تصميم [_PaletteSwatch] بالضبط،
/// من قائمة `kAppAccentColors` المحدودة (كلها ألوان هوية معتمدة أصلاً).
/// **موحَّد بصرياً مع [_PaletteSwatch]** (دائرة + حلقة اختيار + تسمية
/// سطر واحد تحتها) — كانا مختلفَين شكلاً (هذا بطاقة مؤطَّرة أكبر، ذاك
/// دائرة بسيطة) رغم كونهما نفس فكرة "اختيار لون من لوحة جاهزة"، بشكوى
/// صريحة "مش متناسقة... ماخذة مساحة كتير". التوحيد على النمط الأبسط
/// (الدائرة) قلَّص المساحة العمودية أيضاً.
class _AppAccentSection extends ConsumerWidget {
  const _AppAccentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accentColorVersionProvider);
    final selected = ref.read(userPrefsProvider).accentColorId;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final accent in kAppAccentColors)
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () async {
              await ref.read(userPrefsProvider).setAccentColorId(accent.id);
              ref.read(accentColorVersionProvider.notifier).bump();
            },
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
                      gradient: LinearGradient(
                        colors: [accent.primaryLight, accent.color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: accent.id == selected
                            ? themeAccent(context)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: accent.id == selected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    accent.label,
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
          ),
      ],
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
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('تنزيل كل صفحات هذه الطبعة', style: TextStyle(fontSize: 12)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FontDownloadScreen(edition: current)),
            ),
          ),
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

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

/// شريحة انزلاق دقيقة لحجم خط التفسير والأحاديث والترجمة مع معاينة حية
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
                max: 26.0,
                divisions: 13,
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

/// تصدير/استيراد نسخة احتياطية محلية كاملة (`backup_service.dart`) —
/// بلا أي اعتماد شبكي أو حساب، بطلب صاحب المشروع "نسخ احتياطي محلي
/// للبيانات". "استيراد" يستبدل بيانات هذا الجهاز بالكامل — تحذير صريح
/// قبل التنفيذ، وتنويه بإعادة فتح التطبيق بعد النجاح (راجع توثيق
/// `BackupService.pickAndInstallBackup`: لا إعادة تحميل حيّة لمنتصف الجلسة).
class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection();

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final syncState = ref.watch(cloudSyncControllerProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeAccent(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: themeAccent(context).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    syncState.isSignedIn
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_outlined,
                    color: themeAccent(context),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syncState.isSignedIn
                              ? (syncState.user?.email ?? 'متصل بالسحابة')
                              : 'المزامنة وحفظ التقدم سحابياً',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          syncState.isSignedIn
                              ? 'سلاسل الاستمرار والفواصل محفوظة سحابياً'
                              : 'احفظ بياناتك تلقائياً عند تغيير أو ضياع الجهاز',
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!syncState.isSignedIn)
                    FilledButton.tonal(
                      onPressed: () => AuthDialog.show(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'دخول / تسجيل',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.logout, size: 18),
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => ref
                          .read(cloudSyncControllerProvider.notifier)
                          .signOut(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'تصدير نسخة كاملة من بياناتك (علامات، خطط حفظ، سلاسل استمرار، إعدادات...) لملف تحفظه بنفسك، أو استعادتها لاحقاً على هذا الجهاز أو غيره.',
              style: TextStyle(
                fontSize: 12.5,
                color: onSurface.withValues(alpha: 0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('تصدير'),
                    onPressed: _busy ? null : _export,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings_backup_restore_outlined),
                    label: const Text('استيراد'),
                    onPressed: _busy ? null : _confirmAndImport,
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 10),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await ref.read(userPrefsProvider).backup.exportAndShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر تصدير النسخة الاحتياطية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndImport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استيراد نسخة احتياطية؟'),
        content: const Text(
          'سيستبدل هذا كل بيانات هذا الجهاز الحالية (علامات، خطط حفظ، سلاسل استمرار...) بمحتوى الملف المختار، ولا يمكن التراجع بعدها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    BackupRestoreResult result;
    try {
      result = await ref.read(userPrefsProvider).backup.pickAndInstallBackup();
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر استيراد النسخة الاحتياطية: $e')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case BackupRestoreResult.cancelled:
        return;
      case BackupRestoreResult.invalidFile:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الملف المختار ليس نسخة احتياطية صالحة لهذا الإصدار من التطبيق',
            ),
          ),
        );
        return;
      case BackupRestoreResult.success:
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تمّت الاستعادة'),
            content: const Text(
              'أُعيدت بياناتك بنجاح — أغلق التطبيق الآن وأعد فتحه ليظهر التغيير.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
