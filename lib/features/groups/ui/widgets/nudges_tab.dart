import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/faith_group.dart';
import 'nudge_dialog.dart';

/// تبويب "حائط التواصي": قائمة رسائل التشجيع المتبادلة بالمجموعة.
class NudgesTab extends StatelessWidget {
  const NudgesTab({super.key, required this.nudgesAsync, required this.isDark});

  final AsyncValue<List<GroupNudge>> nudgesAsync;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = themeAccent(context);

    return nudgesAsync.when(
      data: (nudges) {
        if (nudges.isEmpty) {
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
          itemCount: nudges.length,
          itemBuilder: (ctx, i) {
            final n = nudges[i];
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
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}
