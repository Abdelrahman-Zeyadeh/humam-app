import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/floating_dhikr_service.dart';

/// كبسولة/بطاقة تفعيل عداد الذكر والتسبيح العائم فوق التطبيقات
class FloatingDhikrBanner extends ConsumerWidget {
  const FloatingDhikrBanner({
    super.key,
    required this.currentPhrase,
    required this.accent,
    required this.isDark,
  });

  final String currentPhrase;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!FloatingDhikrService.isSupported) {
      return const SizedBox.shrink();
    }

    final isFloatingActive = ref.watch(floatingDhikrProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: isFloatingActive
            ? accent.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark ? const Color(0xFF1E2630) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isFloatingActive
                ? accent
                : (isDark ? Colors.white12 : Colors.black12),
            width: isFloatingActive ? 1.5 : 1,
          ),
        ),
        elevation: isDark ? 0 : 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final notifier = ref.read(floatingDhikrProvider.notifier);
            final hasPerm = await FloatingDhikrService.canDrawOverlays();

            if (!hasPerm) {
              if (!context.mounted) return;
              final grant = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.picture_in_picture_alt_rounded, color: Color(0xFFC5A059)),
                      SizedBox(width: 8),
                      Text('الذكر العائم فوق التطبيقات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: const Text(
                    'لعرض عداد التسبيح العائم على شاشة هاتفك أثناء تصفح التطبيقات الأخرى (مثل واتساب والإنترنت)، يرجى منح إذن "الظهور فوق التطبيقات الأخرى".',
                    style: TextStyle(fontSize: 13.5, height: 1.6),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC5A059),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('منح الإذن'),
                    ),
                  ],
                ),
              );

              if (grant == true) {
                await FloatingDhikrService.requestOverlayPermission();
              }
              return;
            }

            await notifier.toggle(dhikrText: currentPhrase);
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isFloatingActive
                      ? 'تم إيقاف عداد الذكر العائم'
                      : 'تم تفعيل عداد الذكر العائم على شاشتك ✨',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isFloatingActive
                        ? accent
                        : accent.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: isFloatingActive ? Colors.white : accent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'الذكر العائم فوق التطبيقات',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isFloatingActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'نشط الآن',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFloatingActive
                            ? 'اضغط للإيقاف • يظهر على الشاشة أثناء التصفح'
                            : 'سبّح أثناء استخدام واتساب والتطبيقات الأخرى',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isFloatingActive,
                  activeTrackColor: accent.withValues(alpha: 0.6),
                  activeThumbColor: accent,
                  onChanged: (_) async {
                    final notifier = ref.read(floatingDhikrProvider.notifier);
                    final hasPerm = await FloatingDhikrService.canDrawOverlays();
                    if (!hasPerm) {
                      await FloatingDhikrService.requestOverlayPermission();
                      return;
                    }
                    await notifier.toggle(dhikrText: currentPhrase);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
