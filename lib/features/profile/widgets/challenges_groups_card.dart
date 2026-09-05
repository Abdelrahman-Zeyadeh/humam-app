import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../groups/ui/groups_hub_screen.dart';
import 'profile_shared_widgets.dart';

/// قسم "التحديات والمجموعات": بطاقة دعوة للانضمام إلى تحدٍّ أو مجموعة
/// إيمانية جديدة.
class ChallengesGroupsCard extends StatelessWidget {
  const ChallengesGroupsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SectionHeader(title: 'التحديات والمجموعات'),
        const SizedBox(height: 10),
        Material(
          color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF9F7F2),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GroupsHubScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? AppColors.lineDark : AppColors.line),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, color: Color(0xFFE67E22)),
                  SizedBox(width: 10),
                  Text(
                    'انضم إلى تحدٍّ أو مجموعة إيمانية جديدة 🏆',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
