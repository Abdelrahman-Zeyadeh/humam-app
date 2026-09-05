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

/// حوار "إنشاء مجموعة صحبة صالحة" — يُفتح من زر الإنشاء بأعلى مركز
/// المجموعات.
Future<void> showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  var isLoading = false;
  // يُقرأ قبل فتح الحوار — آخر أفاتار اختاره المستخدم بمجموعة سابقة،
  // بدل البدء دائماً من نفس الخيار الأول.
  var selectedAvatarIndex = await GroupsService.instance.getMyAvatarIndex();
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, size: 24, color: AppColors.goldDeep),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'إنشاء مجموعة صحبة صالحة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'اسم المجموعة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'الهدف من المجموعة (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 14),
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
            label: 'إنشاء المجموعة',
            loading: isLoading,
            onPressed: isLoading
                ? null
                : () async {
                    if (nameCtrl.text.trim().isEmpty) return;
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
                      final group = await GroupsService.instance.createGroup(
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        creatorName: name,
                        emoji: '',
                        avatarIndex: selectedAvatarIndex,
                        initialProgress: myProgress,
                        streak: streak,
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
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('تعذّر إنشاء المجموعة: $e')),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
}
