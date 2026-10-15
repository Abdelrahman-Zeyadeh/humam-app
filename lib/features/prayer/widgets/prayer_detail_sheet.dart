import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../adhan_voices.dart' show adhanVoiceById;
import '../prayer_location_controller.dart' show rescheduleAdhanNotifications;
import '../prayer_times_service.dart';
import '../../home/home_dashboard_data.dart' show homeDashboardDataProvider;
import '../../home/home_widget_sync.dart' show dispatchHomeWidgetSync;
import 'prayer_display_helpers.dart';
import 'prayer_voice_picker_sheet.dart';

/// ورقة إعدادات الصلاة المستوحاة والمطابقة لتصميم تطبيق «منار» و«فذكر»
/// (تعديل وقت الصلاة، الأذان والتذكير، إشعار الإقامة، والتطبيق على بقية الصلوات).
void showPrayerDetailBottomSheet(
  BuildContext context,
  WidgetRef ref,
  LocationPrefs prefs,
  PrayerMoment moment,
  DateTime time,
  List<PrayerMomentTime> dayTimes,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _PrayerDetailSheetContent(
      prefs: prefs,
      moment: moment,
      originalTime: time,
      dayTimes: dayTimes,
    ),
  );
}

class _PrayerDetailSheetContent extends ConsumerStatefulWidget {
  const _PrayerDetailSheetContent({
    required this.prefs,
    required this.moment,
    required this.originalTime,
    required this.dayTimes,
  });

  final LocationPrefs prefs;
  final PrayerMoment moment;
  final DateTime originalTime;
  final List<PrayerMomentTime> dayTimes;

  @override
  ConsumerState<_PrayerDetailSheetContent> createState() =>
      _PrayerDetailSheetContentState();
}

class _PrayerDetailSheetContentState
    extends ConsumerState<_PrayerDetailSheetContent> {
  late int _offset;
  late bool _adhanEnabled;
  late String _adhanMode; // 'adhan' or 'silent'
  late int _preAdhanMins;
  late bool _iqamahEnabled;
  late int _iqamahMins;
  bool _applyToAllPrayers = false;

  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    final userPrefs = ref.read(userPrefsProvider);
    final notifPrefs = ref.read(adhanNotificationPrefsProvider);

    _offset = userPrefs.prayerOffsetFor(widget.moment.name);
    _adhanEnabled = notifPrefs.effectivelyEnabled(widget.moment);
    _adhanMode = notifPrefs.notificationModeFor(widget.moment);
    if (_adhanMode == 'off' || _adhanMode == 'tone') {
      _adhanMode = 'adhan';
    }
    _preAdhanMins = userPrefs.preAdhanMinutesFor(widget.moment.name);
    _iqamahEnabled =
        userPrefs.iqamahNotificationEnabledFor(widget.moment.name);
    _iqamahMins = userPrefs.iqamahMinutesFor(widget.moment.name);
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _resetToDefault() {
    setState(() {
      _offset = 0;
      _adhanEnabled = true;
      _adhanMode = 'adhan';
      _preAdhanMins = 10;
      _iqamahEnabled = true;
      _iqamahMins = widget.moment == PrayerMoment.fajr
          ? 20
          : (widget.moment == PrayerMoment.maghrib ? 10 : 15);
    });
  }

  void _startContinuousChange(int delta) {
    _changeOffset(delta);
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _changeOffset(delta);
    });
  }

  void _stopContinuousChange() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _changeOffset(int delta) {
    setState(() {
      _offset = (_offset + delta).clamp(-120, 120);
    });
  }

  Future<void> _saveAndClose() async {
    final userPrefs = ref.read(userPrefsProvider);
    final notifPrefs = ref.read(adhanNotificationPrefsProvider);

    final prayersToUpdate = _applyToAllPrayers
        ? [
            PrayerMoment.fajr,
            PrayerMoment.dhuhr,
            PrayerMoment.asr,
            PrayerMoment.maghrib,
            PrayerMoment.isha,
          ]
        : [widget.moment];

    for (final m in prayersToUpdate) {
      if (!_applyToAllPrayers || m == widget.moment) {
        await userPrefs.setPrayerOffsetFor(m.name, _offset);
      }
      await notifPrefs.setNotificationModeFor(
        m,
        _adhanEnabled ? _adhanMode : 'off',
      );
      await userPrefs.setPreAdhanMinutesFor(m.name, _preAdhanMins);
      await userPrefs.setIqamahNotificationEnabledFor(m.name, _iqamahEnabled);
      await userPrefs.setIqamahMinutesFor(m.name, _iqamahMins);
    }

    ref.read(adhanNotificationVersionProvider.notifier).bump();
    if (widget.prefs.hasLocation) {
      unawaited(rescheduleAdhanNotifications(ref, widget.prefs));
      final dashboard = ref.read(homeDashboardDataProvider).asData?.value;
      if (dashboard != null) {
        final dayTimes = computeDayTimes(
          lat: widget.prefs.lat!,
          lon: widget.prefs.lon!,
          date: DateTime.now(),
          methodKey: widget.prefs.calculationMethod,
        );
        dispatchHomeWidgetSync(
          data: dashboard,
          dayTimes: dayTimes,
          accentId: userPrefs.accentColorId,
          userPrefs: userPrefs,
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1B1E22) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF24282D) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF33383F) : const Color(0xFFEDE6DA);
    const bronzePrimary = Color(0xFF8C6B45);
    final titleColor = isDark ? Colors.white : const Color(0xFF3E2D1E);
    final softTextColor = isDark ? Colors.white70 : const Color(0xFF8D7C68);
    final chipUnselectedBg = isDark ? const Color(0xFF2A2F35) : const Color(0xFFFAF7F2);
    final chipUnselectedBorder = isDark ? const Color(0xFF3D444D) : const Color(0xFFE8DFCE);

    final currentVoiceId =
        ref.watch(userPrefsProvider).adhanVoiceFor(widget.moment.name);
    final currentVoice = adhanVoiceById(currentVoiceId);

    // حساب الأوقات التفاعلية
    final adjustedAdhanTime =
        widget.originalTime.add(Duration(minutes: _offset));
    final reminderTime = _preAdhanMins > 0
        ? adjustedAdhanTime.subtract(Duration(minutes: _preAdhanMins))
        : null;
    final iqamahTime = _iqamahEnabled
        ? adjustedAdhanTime.add(Duration(minutes: _iqamahMins))
        : null;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. مقبض السحب العلوي
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white24
                        : const Color(0xFFDCD2C1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. ترويسة الصفحة (زر إعادة التعيين + العنوان + أيقونة الصلاة)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    color: softTextColor,
                    tooltip: 'استعادة الإعدادات الافتراضية',
                    onPressed: _resetToDefault,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'إعدادات ${widget.moment.nameAr}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الوقت الأصلي ${formatPrayerTime12h(widget.originalTime)} · تنطبق على هذا الجهاز',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: softTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C3238)
                          : const Color(0xFFF3ECE0),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      prayerMomentIcon(widget.moment),
                      color: bronzePrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. بطاقة ملخص الأوقات (التذكير، الأذان، الإقامة)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  children: [
                    _TimeSummaryRow(
                      icon: Icons.access_time_rounded,
                      label: 'التذكير',
                      timeText: reminderTime != null
                          ? formatPrayerTime12h(reminderTime)
                          : 'بلا تذكير',
                      softTextColor: softTextColor,
                      titleColor: titleColor,
                    ),
                    const SizedBox(height: 10),
                    _TimeSummaryRow(
                      icon: Icons.campaign_rounded,
                      label: 'الأذان',
                      timeText: formatPrayerTime12h(adjustedAdhanTime),
                      softTextColor: softTextColor,
                      titleColor: titleColor,
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    _TimeSummaryRow(
                      icon: Icons.groups_rounded,
                      label: 'الإقامة',
                      timeText: iqamahTime != null
                          ? formatPrayerTime12h(iqamahTime)
                          : 'معطّلة',
                      softTextColor: softTextColor,
                      titleColor: titleColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. بطاقة تعديل وقت الصلاة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعديل وقت الصلاة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'لمطابقة مسجدك — اضغط مطولاً للتغيير السريع',
                      style: TextStyle(
                        fontSize: 11,
                        color: softTextColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // زر الزيادة (+)
                        GestureDetector(
                          onTap: () => _changeOffset(1),
                          onLongPressStart: (_) => _startContinuousChange(1),
                          onLongPressEnd: (_) => _stopContinuousChange(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2E343B)
                                  : const Color(0xFFF7F3EB),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.add_rounded,
                              size: 24,
                              color: bronzePrimary,
                            ),
                          ),
                        ),
                        // عرض الفارق
                        Text(
                          _offset == 0
                              ? 'بلا تعديل'
                              : (_offset > 0
                                  ? '+$_offset دقيقة'
                                  : '$_offset دقيقة'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: bronzePrimary,
                          ),
                        ),
                        // زر النقصان (-)
                        GestureDetector(
                          onTap: () => _changeOffset(-1),
                          onLongPressStart: (_) => _startContinuousChange(-1),
                          onLongPressEnd: (_) => _stopContinuousChange(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2E343B)
                                  : const Color(0xFFF7F3EB),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.remove_rounded,
                              size: 24,
                              color: bronzePrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5. بطاقة الأذان والتذكير
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الأذان والتذكير',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'إشعار وقت الصلاة، وتذكير قبله بمدّة تختارها',
                      style: TextStyle(
                        fontSize: 11,
                        color: softTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'إشعار الأذان',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        Switch(
                          value: _adhanEnabled,
                          activeThumbColor: bronzePrimary,
                          activeTrackColor: bronzePrimary.withValues(alpha: 0.35),
                          onChanged: (val) {
                            setState(() {
                              _adhanEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_adhanEnabled) ...[
                      // اختيار المؤذن
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          showVoicePickerForMoment(
                            context,
                            ref,
                            widget.prefs,
                            widget.moment,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'صوت المؤذن:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: softTextColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    currentVoice.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: bronzePrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 18,
                                    color: bronzePrimary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // نمط التنبيه (صامت أو أذان)
                      Row(
                        children: [
                          _AlertModePill(
                            label: '🔊 أذان',
                            selected: _adhanMode == 'adhan',
                            onTap: () => setState(() => _adhanMode = 'adhan'),
                          ),
                          const SizedBox(width: 8),
                          _AlertModePill(
                            label: '🔕 صامت',
                            selected: _adhanMode == 'silent',
                            onTap: () => setState(() => _adhanMode = 'silent'),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 20),
                    Text(
                      'التذكير قبل الصلاة',
                      style: TextStyle(
                        fontSize: 12,
                        color: softTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in [0, 5, 10, 15, 20, 30])
                          _SelectionChip(
                            label: m == 0 ? 'بلا' : 'قبل $m د',
                            selected: _preAdhanMins == m,
                            selectedColor: bronzePrimary,
                            unselectedBg: chipUnselectedBg,
                            unselectedBorder: chipUnselectedBorder,
                            textColor: titleColor,
                            onTap: () => setState(() => _preAdhanMins = m),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 6. بطاقة إشعار الإقامة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إشعار الإقامة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'بعد الأذان بالمدّة التي تناسب مسجدك',
                      style: TextStyle(
                        fontSize: 11,
                        color: softTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تفعيل الإقامة',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        Switch(
                          value: _iqamahEnabled,
                          activeThumbColor: bronzePrimary,
                          activeTrackColor: bronzePrimary.withValues(alpha: 0.35),
                          onChanged: (val) {
                            setState(() {
                              _iqamahEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_iqamahEnabled) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final m in [5, 10, 15, 20, 25, 30, 45])
                            _SelectionChip(
                              label: '$m د',
                              selected: _iqamahMins == m,
                              selectedColor: bronzePrimary,
                              unselectedBg: chipUnselectedBg,
                              unselectedBorder: chipUnselectedBorder,
                              textColor: titleColor,
                              onTap: () => setState(() => _iqamahMins = m),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 7. خيار التطبيق على بقية الصلوات
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _applyToAllPrayers = !_applyToAllPrayers),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _applyToAllPrayers,
                        activeColor: bronzePrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) => setState(() => _applyToAllPrayers = val ?? false),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'طبّق الأذان والتذكير والإقامة على بقية الصلوات',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 8. زر الحفظ الرئيسي
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveAndClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bronzePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSummaryRow extends StatelessWidget {
  const _TimeSummaryRow({
    required this.icon,
    required this.label,
    required this.timeText,
    required this.softTextColor,
    required this.titleColor,
    this.isBold = false,
  });

  final IconData icon;
  final String label;
  final String timeText;
  final Color softTextColor;
  final Color titleColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: softTextColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? titleColor : softTextColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          timeText,
          style: TextStyle(
            fontSize: 14,
            color: titleColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedBg,
    required this.unselectedBorder,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedBg;
  final Color unselectedBorder;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedColor : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : unselectedBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}

class _AlertModePill extends StatelessWidget {
  const _AlertModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const bronzePrimary = Color(0xFF8C6B45);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? bronzePrimary.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF2A2F35) : const Color(0xFFF7F3EB)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? bronzePrimary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? bronzePrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
