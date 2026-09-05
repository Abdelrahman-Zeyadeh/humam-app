import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../adhan_voices.dart';
import '../prayer_location_controller.dart' show rescheduleAdhanNotifications;
import '../prayer_times_service.dart';

/// ورقة سفلية لاختيار مؤذن مخصَّص لصلاة واحدة بعينها — تُفتح من ورقة
/// تفاصيل الصلاة (`prayer_detail_sheet.dart`)، مستقلة عن بطاقة "صوت الأذان
/// والمؤذن" العامة (`AdhanVoiceCard`) اللي تضبط مؤذناً افتراضياً لكل الصلوات.
void showVoicePickerForMoment(
  BuildContext context,
  WidgetRef ref,
  LocationPrefs prefs,
  PrayerMoment moment,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return _VoicePickerContent(
        prefs: prefs,
        moment: moment,
        sheetCtx: sheetCtx,
      );
    },
  );
}

class _VoicePickerContent extends ConsumerStatefulWidget {
  const _VoicePickerContent({
    required this.prefs,
    required this.moment,
    required this.sheetCtx,
  });

  final LocationPrefs prefs;
  final PrayerMoment moment;
  final BuildContext sheetCtx;

  @override
  ConsumerState<_VoicePickerContent> createState() =>
      _VoicePickerContentState();
}

class _VoicePickerContentState extends ConsumerState<_VoicePickerContent> {
  AudioPlayer? _player;
  String? _playingVoiceId;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _player?.stop();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(AdhanVoice voice) async {
    if (voice.assetPath == null) return;
    if (_playingVoiceId == voice.id) {
      await _player?.stop();
      if (mounted) setState(() => _playingVoiceId = null);
      return;
    }

    try {
      await _player?.stop();
      if (mounted) setState(() => _playingVoiceId = voice.id);
      await _player?.setAsset(voice.assetPath!);
      await _player?.play();
      _player?.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playingVoiceId = null);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _playingVoiceId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVoiceId = ref
        .watch(userPrefsProvider)
        .adhanVoiceFor(widget.moment.name);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'مؤذن صلاة ${widget.moment.nameAr}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: kAdhanVoices.length,
                itemBuilder: (ctx, idx) {
                  final voice = kAdhanVoices[idx];
                  final isSelected = voice.id == currentVoiceId;
                  final isPlaying = _playingVoiceId == voice.id;

                  return ListTile(
                    title: Text(
                      voice.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: voice.subLabel != null
                        ? Text(
                            voice.subLabel!,
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                    leading: voice.assetPath != null
                        ? IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.stop_circle_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: isPlaying ? Colors.redAccent : accent,
                              size: 28,
                            ),
                            tooltip: isPlaying
                                ? 'إيقاف الاستماع'
                                : 'استماع لصوت المؤذن',
                            onPressed: () => _togglePlay(voice),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) Icon(Icons.check_circle, color: accent),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.done_all_rounded, size: 20),
                          tooltip: 'اعتماد هذا المؤذن لجميع الصلوات',
                          onPressed: () async {
                            await _player?.stop();
                            final userPrefs = ref.read(userPrefsProvider);
                            for (final m in PrayerMoment.values) {
                              if (m.isPrayer) {
                                await userPrefs.setAdhanVoiceFor(
                                  m.name,
                                  voice.id,
                                );
                              }
                            }
                            await userPrefs.setAdhanVoiceId(voice.id);
                            ref
                                .read(adhanNotificationVersionProvider.notifier)
                                .bump();
                            if (context.mounted)
                              Navigator.of(widget.sheetCtx).pop();
                            if (widget.prefs.hasLocation)
                              unawaited(
                                rescheduleAdhanNotifications(
                                  ref,
                                  widget.prefs,
                                ),
                              );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم اعتماد مؤذن "${voice.label}" لجميع الصلوات الخمس 🕌',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      await _player?.stop();
                      await ref
                          .read(userPrefsProvider)
                          .setAdhanVoiceFor(widget.moment.name, voice.id);
                      ref
                          .read(adhanNotificationVersionProvider.notifier)
                          .bump();
                      if (context.mounted) Navigator.of(widget.sheetCtx).pop();
                      if (widget.prefs.hasLocation)
                        unawaited(
                          rescheduleAdhanNotifications(ref, widget.prefs),
                        );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
