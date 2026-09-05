import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_providers.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/groups_providers.dart';
import '../services/groups_service.dart';
import 'widgets/create_group_dialog.dart';
import 'widgets/group_item_card.dart';
import 'widgets/groups_empty_state.dart';
import 'widgets/join_group_dialog.dart';
import 'widgets/my_deeds_card.dart';

/// مركز مجموعات الصحبة والتنافس الإيماني.
///
/// الشاشة نفسها مجرّد تنسيق (composition) لخمسة أقسام مستقلة بمجلد
/// `widgets/` (بطاقة إنجاز اليوم، حوارا الإنشاء/الانضمام، بطاقة المجموعة
/// الواحدة، وحالة "لا مجموعات بعد") — استُخرجت من هون أثناء تفكيك الملف،
/// كان ~٨٨٤ سطراً بكل شي بملف واحد، بلا أي تغيير سلوكي.
class GroupsHubScreen extends ConsumerStatefulWidget {
  const GroupsHubScreen({super.key});

  @override
  ConsumerState<GroupsHubScreen> createState() => _GroupsHubScreenState();
}

class _GroupsHubScreenState extends ConsumerState<GroupsHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAllMyGroups();
    });
  }

  Future<void> _syncAllMyGroups() async {
    final groupIds = ref.read(myGroupIdsProvider).value ?? [];
    final myProgress = ref.read(myDailyDeedsProgressProvider);
    final userPrefs = ref.read(userPrefsProvider);
    final name = userPrefs.userName.isNotEmpty
        ? userPrefs.userName
        : 'صاحب همّة';
    // القيمتان الحقيقيتان (لا `0`/`1` ثابتين كالسابق) — راجع
    // `UserRepository.bestCurrentStreakDays`/`GroupsService.getMyAvatarIndex`.
    final avatarIndex = await GroupsService.instance.getMyAvatarIndex();
    final streak = ref.read(userRepositoryProvider).bestCurrentStreakDays();
    for (final id in groupIds) {
      await GroupsService.instance.syncMyProgress(
        groupId: id,
        progress: myProgress,
        displayName: name,
        avatarIndex: avatarIndex,
        streak: streak,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myDeeds = ref.watch(myDailyDeedsProgressProvider);
    final groupIdsAsync = ref.watch(myGroupIdsProvider);

    return Scaffold(
      // هيدر بتدرّج مطابق لأسلوب لوحة التصميم المعتمدة — `AppBar` عادي
      // بلا لمس هيكل الجسم، فقط زُيِّن بصرياً (`flexibleSpace`).
      appBar: const GradientAppBar(
        title: 'مجموعات الصحبة والتنافس الإيماني',
        colors: [AppColors.teal, AppColors.navy],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة إنجاز أعمال اليوم والليلة الشخصية
          MyDeedsCard(deeds: myDeeds, isDark: isDark),
          const SizedBox(height: 18),

          // أزرار إنشاء / انضمام لمجموعة
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: 'إنشاء مجموعة',
                  icon: Icons.add,
                  color: AppColors.gold,
                  onPressed: () => showCreateGroupDialog(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('الانضمام برمز'),
                  onPressed: () => showJoinGroupDialog(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Container(
                width: 3.5,
                height: 16,
                decoration: BoxDecoration(
                  color: themeAccent(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '👥 مجموعاتي الإيمانية',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          groupIdsAsync.when(
            data: (ids) {
              if (ids.isEmpty) {
                return GroupsEmptyState(isDark: isDark);
              }

              return Column(
                children: [
                  for (final id in ids)
                    GroupItemCard(groupId: id, isDark: isDark),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('تعذّر جلب المجموعات: $e')),
          ),
        ],
      ),
    );
  }
}
