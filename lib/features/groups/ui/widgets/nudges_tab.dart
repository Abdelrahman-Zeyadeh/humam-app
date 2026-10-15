import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/faith_group.dart';
import '../../services/social_safety_service.dart';
import 'nudge_dialog.dart';

/// تبويب "حائط التواصي": قائمة رسائل التشجيع المتبادلة بالمجموعة.
class NudgesTab extends ConsumerWidget {
  const NudgesTab({super.key, required this.nudgesAsync, required this.isDark});

  final AsyncValue<List<GroupNudge>> nudgesAsync;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = themeAccent(context);
    final blockedUsers = ref.watch(blockedUsersProvider);

    return nudgesAsync.when(
      data: (nudges) {
        final visibleNudges = nudges
            .where((n) => !blockedUsers.contains(n.fromUserId))
            .toList();

        if (visibleNudges.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_outline_rounded,
            message: 'لا توجد رسائل تشجيع بعد',
            subtitle: 'شجّع إخوانك في المجموعة بالضغط على "تشجيع" في لوحة التنافس',
            color: accent,
            padding: const EdgeInsets.all(32),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visibleNudges.length,
          itemBuilder: (ctx, i) {
            final n = visibleNudges[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.lineDark : AppColors.line,
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(nudgeIconFor(n.type), color: accent, size: 20),
                ),
                title: Text(
                  n.message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'إلى: ${n.toUserName} • من: ${n.fromUserName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('تعذّر تحميل رسائل التواصي. يرجى التحقق من اتصال الإنترنت.'),
        ),
      ),
    );
  }
}
