import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../notifications/adhan_notification_service.dart';

/// شاشة دليل ومساعد دقة الأذان والإشعارات وتجاوز تحسين البطارية
class PermissionsGuideScreen extends ConsumerWidget {
  const PermissionsGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دقة الأذان والتنبيهات', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // بطاقة التنبيه الهامة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1FC9A24B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0x66C9A24B),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.goldDeep, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لماذا قد يتأخر الأذان أو ينكتم؟',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldDeep,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تفرض أنظمة أندرويد الحديثة (أندرويد 12 و 13 و 14+) قيوداً صارمة لتوفير شحن البطارية توقف التطبيقات في الخلفية. لضمان انطلاق الأذان في وقته الدقيق بالثانية، يرجى تفعيل الخيارات أدناه.',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.85),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // الخطوات الأساسية
          _sectionTitle('الخطوات الضرورية لدقة الأذان'),

          // 1. إذن الإشعارات والمنبهات الدقيقة
          _StepCard(
            isDark: isDark,
            stepNumber: 1,
            title: 'السماح بالإشعارات والمنبهات الدقيقة',
            desc: 'منح التطبيق إذن إرسال الإشعارات الصوتية وإذن المنبهات الدقيقة (Exact Alarms) لجدولة أوقات الصلاة.',
            actionLabel: 'طلب إذن النظام',
            icon: Icons.notifications_active_outlined,
            onAction: () async {
              await AdhanNotificationService.instance.requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم طلب إذن الإشعارات والمنبهات من النظام 🔔')),
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // 2. استثناء توفير البطارية
          _StepCard(
            isDark: isDark,
            stepNumber: 2,
            title: 'استثناء من تحسين البطارية (Unrestricted)',
            desc: 'إعفاء هُمَام من قيود إيقاف التطبيقات في وضع الخمول (Doze Mode) عبر إعدادات الجهاز.',
            actionLabel: 'إرشادات الاستثناء',
            icon: Icons.battery_charging_full_rounded,
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('راجع دليل نوع هاتفك في الأسفل لضبط إعدادات البطارية ⚙️')),
              );
            },
          ),
          const SizedBox(height: 24),

          // إرشادات حسب نوع الهاتف
          _sectionTitle('إرشادات حسب نوع هاتفك'),
          _CardContainer(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VendorGuideItem(
                  brand: 'هواتف سامسونج (Samsung)',
                  steps: 'الإعدادات ← التطبيقات ← هُمَام ← البطارية ← اختر "غير مقيد" (Unrestricted)، وتأكد من إزالة التطبيق من قائمة "التطبيقات في وضع السكون".',
                ),
                const Divider(height: 18),
                _VendorGuideItem(
                  brand: 'هواتف شاومي وبوكو وريدمي (Xiaomi / Redmi / POCO)',
                  steps: 'الإعدادات ← التطبيقات ← إدارة التطبيقات ← هُمَام ← فعّل "التشغيل التلقائي" (Autostart) ← موفر البطارية: اختر "لا توجد قيود" (No restrictions).',
                ),
                const Divider(height: 18),
                _VendorGuideItem(
                  brand: 'هواتف هواوي وهونر (Huawei / Honor)',
                  steps: 'الإعدادات ← البطارية ← بدء تشغيل التطبيقات ← ابحث عن هُمَام وعطّل الإدارة التلقائية، ثم فعّل (التشغيل التلقائي + العمل في الخلفية).',
                ),
                const Divider(height: 18),
                _VendorGuideItem(
                  brand: 'هواتف أوبو وريلمي ووان بلس (Oppo / Realme / OnePlus)',
                  steps: 'الإعدادات ← إدارة التطبيقات ← هُمَام ← استهلاك البطارية ← السماح بالنشاط في الخلفية والسماح بالتشغيل التلقائي.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // اختبار إشعار فوري
          Center(
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('إرسال إشعار تجريبي الآن للتأكد'),
              onPressed: () async {
                await AdhanNotificationService.instance.sendTestHourlyDhikrNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال إشعار تجريبي بنجاح 🔔'),
                      backgroundColor: Color(0xFF1B8A72),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.isDark,
    required this.stepNumber,
    required this.title,
    required this.desc,
    required this.actionLabel,
    required this.icon,
    required this.onAction,
  });

  final bool isDark;
  final int stepNumber;
  final String title;
  final String desc;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.goldDeep,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: AppColors.goldDeep),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.settings_outlined, size: 14),
              label: Text(actionLabel, style: const TextStyle(fontSize: 11.5)),
              onPressed: onAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
        ),
      ),
      child: child,
    );
  }
}

class _VendorGuideItem extends StatelessWidget {
  const _VendorGuideItem({required this.brand, required this.steps});

  final String brand;
  final String steps;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          brand,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E8071),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          steps,
          style: TextStyle(
            fontSize: 11.5,
            color: onSurface.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
