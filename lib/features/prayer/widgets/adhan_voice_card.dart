import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../../notifications/adhan_notification_service.dart';
import '../../onboarding/onboarding_target_keys.dart';
import '../adhan_download_service.dart';
import '../adhan_voices.dart';

/// بطاقة اختيار صوت الأذان والمؤذن مباشرة من شاشة الصلاة مع الاستماع والمعاينة
class AdhanVoiceCard extends ConsumerStatefulWidget {
  const AdhanVoiceCard({super.key, required this.prefs});
  final LocationPrefs prefs;

  @override
  ConsumerState<AdhanVoiceCard> createState() => _AdhanVoiceCardState();
}

class _AdhanVoiceCardState extends ConsumerState<AdhanVoiceCard> {
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
      if (mounted) setState(() => _previewingId = voice.id);
      final path = await AdhanDownloadService.instance.getEffectiveAudioPath(
        voice,
      );
      if (path == null) {
        if (mounted) setState(() => _previewingId = null);
        return;
      }
      if (path.startsWith('assets/')) {
        await _player.setAsset(path);
      } else if (path.startsWith('http')) {
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      await _player.play();
      if (mounted) {
        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) setState(() => _previewingId = null);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _previewingId = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذّر تشغيل المقطع: $e')));
      }
    }
  }

  Future<void> _select(AdhanVoice voice) async {
    await _player.stop();
    if (mounted) setState(() => _previewingId = null);
    await ref.read(userPrefsProvider).setAdhanVoiceId(voice.id);
    ref.read(adhanVoiceVersionProvider.notifier).bump();
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
      postPrayerAzkarEnabled: userPrefs.postPrayerAzkarEnabled,
      postPrayerAzkarDelayMinutes: userPrefs.postPrayerAzkarDelayMinutes,
      getIqamahMinutesFor: (m) => userPrefs.iqamahMinutesFor(m.name),
    );
  }

  void _showAllVoicesSheet() {
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
            final currentSelected = ref.watch(userPrefsProvider).adhanVoiceId;
            final onSurface = Theme.of(context).colorScheme.onSurface;
            final downloadedVoices = ref.watch(adhanDownloadedVoicesProvider);

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
                            final isDownloaded = downloadedVoices.contains(
                              voice.id,
                            );

                            return ListTile(
                              leading: Radio<String>(
                                value: voice.id,
                                activeColor: themeAccent(context),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
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
                                  ),
                                  if (isDownloaded && voice.remoteUrl != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1B8A72,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'محلي ✓',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF1B8A72),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (voice.remoteUrl != null && !isDownloaded)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.download_for_offline_outlined,
                                        size: 20,
                                      ),
                                      tooltip: 'تنزيل للاستماع بلا إنترنت',
                                      onPressed: () async {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'جاري تنزيل أذان ${voice.label}...',
                                            ),
                                          ),
                                        );
                                        final success =
                                            await AdhanDownloadService.instance
                                                .downloadVoice(voice);
                                        if (success) {
                                          await ref
                                              .read(
                                                adhanDownloadedVoicesProvider
                                                    .notifier,
                                              )
                                              .refresh();
                                          setModalState(() {});
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'تم تنزيل أذان ${voice.label} بنجاح ✓',
                                                ),
                                                backgroundColor: const Color(
                                                  0xFF1B8A72,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  if (voice.assetPath != null ||
                                      voice.remoteUrl != null)
                                    IconButton(
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
                                    ),
                                ],
                              ),
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

  @override
  Widget build(BuildContext context) {
    ref.watch(adhanVoiceVersionProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selectedId = ref.watch(userPrefsProvider).adhanVoiceId;
    final selectedVoice = adhanVoiceById(selectedId);
    final isPreviewing = _previewingId == selectedVoice.id;

    return Card(
      key: adhanVoiceCardKey,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeAccent(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.record_voice_over_outlined,
                    size: 20,
                    color: themeAccent(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صوت الأذان والمؤذن',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedVoice.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeAccent(context),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAllVoicesSheet,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('تغيير', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (selectedVoice.subLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                selectedVoice.subLabel!,
                style: TextStyle(
                  fontSize: 11.5,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (selectedVoice.assetPath != null ||
                    selectedVoice.remoteUrl != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _togglePreview(selectedVoice),
                      icon: Icon(
                        isPreviewing ? Icons.stop : Icons.play_arrow,
                        size: 16,
                        color: isPreviewing
                            ? Colors.redAccent
                            : themeAccent(context),
                      ),
                      label: Text(
                        isPreviewing ? 'إيقاف المعاينة' : 'استماع للأذان',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isPreviewing ? Colors.redAccent : onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
