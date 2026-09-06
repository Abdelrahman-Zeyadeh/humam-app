import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_service.dart';
import '../models/faith_group.dart';
import '../providers/groups_providers.dart';
import '../services/groups_service.dart';
import 'widgets/challenge_tab.dart';
import 'widgets/leaderboard_tab.dart';
import 'widgets/nudges_tab.dart';

/// شاشة تفاصيل مجموعة واحدة: لوحة التنافس اليومي وحائط التواصي.
///
/// الشاشة نفسها مجرّد تنسيق (composition) لتبويبين مستقلين بمجلد
/// `widgets/` (لوحة التنافس وحائط التواصي، وما تحتهما من بطاقة معلومات
/// المجموعة، بطاقة العضو، وحوار التشجيع) — استُخرجت من هون أثناء تفكيك
/// الملف، كان ~٩٢٣ سطراً بكل شي بملف واحد، بلا أي تغيير سلوكي.
class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareGroupCode(String code, String name) {
    SharePlus.instance.share(
      ShareParams(
        text:
            'انضم معي إلى مجموعة "$name" على تطبيق هُمَام للتنافس في أعمال اليوم والليلة والصلوات والأذكار 🌿\n\nرمز الانضمام: $code',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersStreamProvider(widget.groupId));
    final nudgesAsync = ref.watch(groupNudgesStreamProvider(widget.groupId));

    ref.listen<AsyncValue<List<GroupNudge>>>(
      groupNudgesStreamProvider(widget.groupId),
      (prev, next) {
        final currentUid = GroupsService.instance.currentUserId;
        final list = next.value ?? [];
        if (list.isNotEmpty) {
          final latest = list.first;
          if (latest.toUserId == currentUid &&
              DateTime.now().difference(latest.sentAt).inMinutes < 5) {
            final prevLatestId = prev?.value?.isNotEmpty == true
                ? prev!.value!.first.id
                : null;
            if (latest.id != prevLatestId) {
              AdhanNotificationService.instance.showInstantAlert(
                id: 888000 + latest.id.hashCode.abs() % 1000,
                title: 'تشجيع من ${latest.fromUserName} ✨',
                body: latest.message,
              );
            }
          }
        }
      },
    );

    return Scaffold(
      // هيدر بتدرّج كحلي موحَّد مع بقية الأقسام ([AppColors.blue, AppColors.navy])
      // — طابَقناه هون مع `groups_hub_screen.dart` بعد توحيد لون هيدرها هي
      // الأخرى (كان تيل بالاثنين، يكسر الهوية اللونية الموحّدة بين الأقسام).
      appBar: GradientAppBar(
        title: widget.groupName,
        colors: const [AppColors.blue, AppColors.navy],
        actions: [
          groupAsync.when(
            data: (group) => group != null
                ? IconButton(
                    tooltip: 'مشاركة رمز الانضمام',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareGroupCode(group.code, group.name),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'leave') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('مغادرة المجموعة'),
                    content: const Text(
                      'هل أنت متأكد من رغبتك في مغادرة هذه المجموعة؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('مغادرة'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await GroupsService.instance.leaveGroup(widget.groupId);
                  ref
                      .read(myGroupIdsProvider.notifier)
                      .removeGroup(widget.groupId);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('مغادرة المجموعة', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.leaderboard_rounded), text: 'لوحة التنافس'),
            Tab(icon: Icon(Icons.flag_circle_rounded), text: 'تحدٍ جماعي'),
            Tab(icon: Icon(Icons.favorite_rounded), text: 'حائط التواصي'),
          ],
        ),
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('المجموعة غير متوفرة أو تم حذفها'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. لوحة التنافس اليومي
              LeaderboardTab(
                group: group,
                membersAsync: membersAsync,
                isDark: isDark,
              ),

              // 2. التحدي الجماعي بموعد نهائي
              ChallengeTab(groupId: widget.groupId, isDark: isDark),

              // 3. حائط التواصي والدعاء
              NudgesTab(nudgesAsync: nudgesAsync, isDark: isDark),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ في جلب بيانات المجموعة: $e')),
      ),
    );
  }
}
