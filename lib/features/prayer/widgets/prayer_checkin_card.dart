import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../../notifications/adhan_notification_service.dart';

/// إعداد متابعة "هل صليت؟" — تفعيل مستقل عن إشعار الأذان العادي (بطلب
/// صاحب المشروع: "اشعار بعد كل صلاة... مع تذكير وسؤال صليت؟... وتكرير
/// الاشعار كل ١٠ دقايق اذا ما جاوب"). تأخير أول سؤال (١٠ أو ١٥ دقيقة)
/// إعداد يختاره المستخدم بدل تثبيته بالكود — نفس روح تذكيرات قيام
/// الليل/الحفظ المخصَّصة. الضغط على "صليت" بالإشعار نفسه يسجّل بنفس آلية
/// "الصلوات والعبادات" أعلاه (`CategoryStreaks`) — راجع توثيق
/// `AdhanNotificationService._bumpCategoryStreakIfNewDay`.
class PrayerCheckinCard extends ConsumerWidget {
  const PrayerCheckinCard({super.key, required this.prefs});
  final LocationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final userPrefs = ref.watch(userPrefsProvider);
    final enabled = userPrefs.prayerCheckinEnabled;
    final delay = userPrefs.prayerCheckinFirstDelayMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'متابعة "هل صليت؟"',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (v) =>
                      _apply(context, ref, enabled: v, delay: delay),
                ),
              ],
            ),
            Text(
              'سؤال متكرّر كل ١٠ دقائق حتى تجيب — يبدأ بعد دخول وقت الصلاة بالمدة المختارة.',
              style: TextStyle(
                fontSize: 11.5,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            if (enabled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'أول سؤال بعد:',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  for (final m in [10, 15]) ...[
                    ChoiceChip(
                      label: Text('$m دقيقة'),
                      selected: delay == m,
                      onSelected: (_) =>
                          _apply(context, ref, enabled: true, delay: m),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `PrayerScreen._toggleNotifications`.
  Future<void> _apply(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
    required int delay,
  }) async {
    final userPrefs = ref.read(userPrefsProvider);
    await userPrefs.setPrayerCheckinSettings(
      enabled: enabled,
      firstDelayMinutes: delay,
    );
    try {
      if (!prefs.hasLocation) return;
      final notifPrefs = ref.read(adhanNotificationPrefsProvider);
      if (enabled) await AdhanNotificationService.instance.requestPermissions();
      await AdhanNotificationService.instance.rescheduleUpcoming(
        lat: prefs.lat!,
        lon: prefs.lon!,
        methodKey: prefs.calculationMethod,
        isEnabled: notifPrefs.effectivelyEnabled,
        voiceId: userPrefs.adhanVoiceId,
        checkinEnabled: enabled,
        checkinFirstDelayMinutes: delay,
        postPrayerAzkarEnabled: userPrefs.postPrayerAzkarEnabled,
        postPrayerAzkarDelayMinutes: userPrefs.postPrayerAzkarDelayMinutes,
        getIqamahMinutesFor: (m) => userPrefs.iqamahMinutesFor(m.name),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط متابعة الصلاة على هذا الجهاز: $e')),
      );
    }
  }
}
