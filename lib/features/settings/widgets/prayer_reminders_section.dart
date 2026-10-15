import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/platform/dnd_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../../notifications/adhan_notification_service.dart';
import '../../prayer/adhan_voices.dart';
import '../../more/reminders_screen.dart';
import '../permissions_guide_screen.dart';
import 'settings_section_helpers.dart';

/// يُعيد جدولة كل إشعارات الصلاة (أذان + متابعة + أذكار بعد الصلاة) بأحدث
/// الإعدادات — يُستدعى من أكثر من ودجت بهالملف، فاستُخرج دالة حرة بدل تكراره.
Future<void> _rescheduleAllPrayerNotifications(WidgetRef ref) async {
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
    getVoiceIdFor: (m) => userPrefs.adhanVoiceFor(m.name),
    getModeFor: (m) => notifPrefs.notificationModeFor(m),
    preAdhanMinutes: userPrefs.preAdhanMinutes,
    checkinEnabled: userPrefs.prayerCheckinEnabled,
    checkinFirstDelayMinutes: userPrefs.prayerCheckinFirstDelayMinutes,
    postPrayerAzkarEnabled: userPrefs.postPrayerAzkarEnabled,
    postPrayerAzkarDelayMinutes: userPrefs.postPrayerAzkarDelayMinutes,
    rawatibEnabled: userPrefs.rawatibEnabled,
    getIqamahMinutesFor: (m) => userPrefs.iqamahMinutesFor(m.name),
  );
}

/// قسم "الصلاة والتذكيرات" — يجمع ٣ أقسام (صوت الأذان، التذكيرات، دقة
/// الأذان) ببطاقة واحدة بنفس مبدأ بقية أقسام شاشة الإعدادات. استُخرج من
/// `settings_screen.dart` أثناء تفكيكه بلا أي تغيير سلوكي.
///
/// (كان يضم أيضاً "أحكام التجويد والضبط" و"دليل ألوان التجويد" — نُقلا
/// لشاشة "أدواتي" بطلب صريح لاحق: علم قرآني عام مالوش علاقة بالصلاة/الأذان.
/// راجع `_ToolItem` بمعرّف `tajweed` في `more_placeholder_screen.dart`.)
class PrayerRemindersSection extends StatelessWidget {
  const PrayerRemindersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('الصلاة والأذان'),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              const _AdhanVoiceSection(),
              const Divider(height: 1),
              const _DndDuringPrayerSection(),
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
      ],
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
      // دالة مشتركة (أعلى الملف) بدل تكرار كل المعاملات هون — كانت هالدالة
      // ما تمرّر `postPrayerAzkarEnabled` إطلاقاً، فتبديل صوت الأذان كان
      // يُسقِط تنبيه أذكار بعد الصلاة صامتاً لحين إعادة جدولة شاملة لاحقة
      // (`rescheduleUpcoming` تُعيد جدولة الكل من الصفر بكل استدعاء).
      await _rescheduleAllPrayerNotifications(ref);
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


/// ميزة "الصامت التلقائي وقت الصلاة" — كتم صوت الجهاز تلقائياً وقت الصلاة والمساجد
class _DndDuringPrayerSection extends ConsumerWidget {
  const _DndDuringPrayerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final userPrefs = ref.watch(userPrefsProvider);
    final enabled = userPrefs.dndDuringPrayerEnabled;

    return SwitchListTile.adaptive(
      secondary: Icon(Icons.do_not_disturb_on_outlined, color: themeAccent(context)),
      title: const Text('الصامت التلقائي وقت الصلاة'),
      subtitle: Text(
        'وضع الهاتف على الصامت تلقائياً عند دخول وقت الصلاة ولغاية انتهاء الصلاة',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeAccent(context).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.do_not_disturb_on_rounded, color: themeAccent(context), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('وضع الصامت في المسجد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                content: const Text(
                  'لتفعيل الكتم التلقائي وقت الصلاة دون مقاطعة، يحتاج التطبيق إذن "الوصول لسياسة عدم الإزعاج" من إعدادات النظام.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('فتح الإعدادات'),
                  ),
                ],
              ),
            );
            if (proceed == true) {
              await DndService.openPolicyAccessSettings();
            }
            return;
          }
        }
        await userPrefs.setDndDuringPrayerEnabled(v);
      },
    );
  }
}
