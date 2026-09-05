import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/user/user_prefs.dart';
import '../../../../core/data/user/user_providers.dart';
import '../../../../core/theme/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/groups_providers.dart';
import '../../services/groups_service.dart';
import '../group_details_screen.dart';
import 'avatar_picker.dart';

/// حوار "الانضمام برمز المجموعة" — يُفتح من زر الانضمام بأعلى مركز
/// المجموعات.
Future<void> showJoinGroupDialog(BuildContext context, WidgetRef ref) async {
  final codeCtrl = TextEditingController();
  var isLoading = false;
  var selectedAvatarIndex = await GroupsService.instance.getMyAvatarIndex();
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // راجع تعليق `Expanded` بعنوان حوار الإنشاء — نفس السبب.
        title: const Row(
          children: [
            Text('🔑', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Expanded(child: Text('الانضمام برمز المجموعة')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'أدخل رمز الانضمام المكوّن من ٦ خانات الذي شاركه معك منشئ المجموعة:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                decoration: const InputDecoration(
                  hintText: 'HM1234',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'اختر أفاتارك بالمجموعة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      ctx,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AvatarPicker(
                selectedIndex: selectedAvatarIndex,
                onSelected: (i) => setDlgState(() => selectedAvatarIndex = i),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          AppPrimaryButton(
            label: 'انضمام',
            color: AppColors.gold,
            loading: isLoading,
            onPressed: isLoading
                ? null
                : () async {
                    final code = codeCtrl.text.trim();
                    if (code.isEmpty) return;
                    setDlgState(() => isLoading = true);
                    try {
                      final myProgress = ref.read(
                        myDailyDeedsProgressProvider,
                      );
                      final userPrefs = ref.read(userPrefsProvider);
                      final name = userPrefs.userName.isNotEmpty
                          ? userPrefs.userName
                          : 'صاحب همّة';
                      final streak = ref
                          .read(userRepositoryProvider)
                          .bestCurrentStreakDays();
                      await GroupsService.instance.setMyAvatarIndex(
                        selectedAvatarIndex,
                      );
                      final group = await GroupsService.instance
                          .joinGroupByCode(
                            code: code,
                            displayName: name,
                            streak: streak,
                            avatarIndex: selectedAvatarIndex,
                            initialProgress: myProgress,
                          );
                      ref.read(myGroupIdsProvider.notifier).addGroup(group.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailsScreen(
                              groupId: group.id,
                              groupName: group.name,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      setDlgState(() => isLoading = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(
                          ctx,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
}
