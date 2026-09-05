import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_service.dart';

/// كرت ضبط إشعار حديث اليوم: يشرح فكرة التذكير اليومي بحديث اليوم ويوفر
/// زراً لطلب أذونات الإشعارات وتفعيل التذكير.
///
/// الودجت مكتفٍ ذاتياً (لا يعتمد على حالة الشاشة الأم) لأن طلب الإذن
/// وعرض رسالة التأكيد لا يحتاجان إلا إلى `BuildContext` الخاص به.
class DailyHadithNotificationCard extends StatelessWidget {
  const DailyHadithNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: themeAccent(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إشعار حديث اليوم',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      Text(
                        'يصلك يومياً حديث شريف مع شرحه في موعده المحدد',
                        style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await AdhanNotificationService.instance.requestPermissions();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('تم تفعيل التذكير اليومي بحديث اليوم بنجاح 🔔'),
                          backgroundColor: Color(0xFF1B8A72),
                        ),
                      );
                    },
                    icon: const Icon(Icons.alarm_on, size: 16),
                    label: const Text('تفعيل التنبيه اليومي (١:٠٠ م)', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
