import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_dialog.dart';
import '../../auth/cloud_sync_service.dart';
import '../../auth/sync_status_indicator.dart';

/// بطاقة تسجيل الدخول السحابي بأعلى شاشة الملف الشخصي — تعرض حالة
/// المزامنة الحالية وتتيح تسجيل الدخول/الخروج.
class CloudSyncCard extends ConsumerWidget {
  const CloudSyncCard({super.key, required this.syncState});

  final CloudSyncState syncState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line)
              .withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncState.isSignedIn
                      ? (syncState.user?.email ?? 'متزامن سحابياً')
                      : 'سجّل دخولك لحفظ بياناتك',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  syncState.isSignedIn
                      ? 'أذكارك وإنجازاتك محفوظة عبر جميع أجهزتك'
                      : 'أذكارك وإنجازاتك ستُحفظ وتتزامن تلقائياً',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (syncState.isSignedIn) ...[
                  const SizedBox(height: 4),
                  SyncStatusIndicator(
                    syncState: syncState,
                    onRetry: () => ref.read(cloudSyncControllerProvider.notifier).syncNow(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!syncState.isSignedIn)
            AppPrimaryButton(
              onPressed: () => AuthDialog.show(context),
              icon: Icons.login_rounded,
              label: 'دخول / تسجيل',
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_done, color: Color(0xFF1B8A72)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () =>
                      ref.read(cloudSyncControllerProvider.notifier).signOut(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
