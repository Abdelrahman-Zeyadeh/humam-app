import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/user/user_prefs.dart';
import '../../../../core/data/user/user_providers.dart';
import '../../../../core/theme/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/faith_group.dart';
import '../../providers/groups_providers.dart';
import '../../services/groups_service.dart';
import '../../services/social_safety_service.dart';
import 'group_info_card.dart';
import 'member_card.dart';
import 'nudge_dialog.dart';
import 'report_and_block_dialogs.dart';

/// تبويب "لوحة التنافس": بطاقة معلومات المجموعة ثم قائمة الأعضاء
/// المرتّبة، مع سحب-للتحديث الذي يزامن إنجاز اليوم للمستخدم الحالي.
class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({
    super.key,
    required this.group,
    required this.membersAsync,
    required this.isDark,
  });

  final FaithGroup group;
  final AsyncValue<List<GroupMember>> membersAsync;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = GroupsService.instance.currentUserId;
    final accent = themeAccent(context);
    final blockedUsers = ref.watch(blockedUsersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        final myProgress = ref.read(myDailyDeedsProgressProvider);
        final userPrefs = ref.read(userPrefsProvider);
        final myName = userPrefs.userName.isNotEmpty
            ? userPrefs.userName
            : 'صاحب همّة';
        await GroupsService.instance.syncMyProgress(
          groupId: group.id,
          progress: myProgress,
          displayName: myName,
          avatarIndex: await GroupsService.instance.getMyAvatarIndex(),
          streak: ref.read(userRepositoryProvider).bestCurrentStreakDays(),
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupInfoCard(group: group, isDark: isDark),
          const SizedBox(height: 20),

          // عنوان لوحة التنافس
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 20, color: accent),
              const SizedBox(width: 8),
              const Text(
                'لوحة التنافس في الطاعات اليومية',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          membersAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return const EmptyState(
                  icon: Icons.group_outlined,
                  message: 'لا يوجد أعضاء بعد',
                  padding: EdgeInsets.all(32),
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < members.length; i++) ...[
                    Builder(
                      builder: (ctx) {
                        final member = members[i];
                        final isBlocked = blockedUsers.contains(member.userId);
                        return MemberCard(
                          member: member,
                          rank: i + 1,
                          totalMembers: members.length,
                          isMe: member.userId == currentUid,
                          isDark: isDark,
                          isBlocked: isBlocked,
                          onNudge: () =>
                              showNudgeDialog(context, ref, group.id, member),
                          onReport: () => showReportMemberDialog(
                            context,
                            ref,
                            member: member,
                            groupId: group.id,
                          ),
                          onBlock: () {
                            if (isBlocked) {
                              ref.read(blockedUsersProvider.notifier).unblockUser(member.userId);
                            } else {
                              showBlockMemberDialog(context, ref, member: member);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('تعذّر تحميل قائمة الأعضاء. يرجى التحقق من اتصال الإنترنت.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
