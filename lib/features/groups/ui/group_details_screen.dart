import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_providers.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_service.dart';
import '../models/faith_group.dart';
import '../models/group_avatars.dart';
import '../providers/groups_providers.dart';
import '../services/groups_service.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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

  void _showNudgeDialog(BuildContext context, GroupMember member) {
    final myId = GroupsService.instance.currentUserId;
    if (member.userId == myId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك إرسال تشجيع لنفسك')),
      );
      return;
    }

    final quickPhrases = [
      ('prayer', 'حيّ على الصلاة وتجهّز لبيت الله'),
      ('azkar', 'أخي الحبيب، لا تنسَ أذكار اليوم والليلة'),
      ('quran', 'رتّل آيات من كتاب الله ونوّر به يومك'),
      ('dua', 'تقبل الله طاعتك وزادك همّة وحرصاً'),
      ('cheer', 'ما شاء الله تبارك الله، واصل ثباتك وتميزك'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final accent = themeAccent(context);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'إرسال تشجيع إيماني إلى: ${member.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              for (final phrase in quickPhrases) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _nudgeIconData(phrase.$1),
                      size: 20,
                      color: accent,
                    ),
                  ),
                  title: Text(
                    phrase.$2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final userPrefs = ref.read(userPrefsProvider);
                    final myName = userPrefs.userName.isNotEmpty
                        ? userPrefs.userName
                        : 'أخوك في الله';
                    await GroupsService.instance.sendNudge(
                      groupId: widget.groupId,
                      toUserId: member.userId,
                      toUserName: member.displayName,
                      fromUserName: myName,
                      message: phrase.$2,
                      type: phrase.$1,
                    );
                    await AdhanNotificationService.instance.showInstantAlert(
                      id: 888000 + DateTime.now().millisecondsSinceEpoch % 1000,
                      title: 'تم إرسال التشجيع ✨',
                      body: 'أرسلت إلى ${member.displayName}: "${phrase.$2}"',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إرسال التشجيع إلى ${member.displayName} بنجاح ✨',
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: (isDark ? AppColors.lineDark : AppColors.line)
                      .withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _nudgeIconData(String type) {
    switch (type) {
      case 'prayer':
        return Icons.mosque_rounded;
      case 'azkar':
        return Icons.touch_app_rounded;
      case 'quran':
        return Icons.menu_book_rounded;
      case 'cheer':
        return Icons.star_rounded;
      default:
        return Icons.favorite_rounded;
    }
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
      // هيدر بتدرّج مطابق لأسلوب لوحة التصميم المعتمدة — كانت هذه الشاشة
      // ("من داخل" مجموعة) الوحيدة بقسم المجموعات اللي فاتها التعديل، رغم
      // تطبيقه على `groups_hub_screen.dart` — بطلب صاحب المشروع "المجموعات
      // من الداخل ما تغيّر شي".
      appBar: GradientAppBar(
        title: widget.groupName,
        colors: const [AppColors.teal, AppColors.navy],
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
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
                    Text(
                      'مغادرة المجموعة',
                      style: TextStyle(color: Colors.red),
                    ),
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
              _buildLeaderboardTab(context, group, membersAsync, isDark),

              // 2. حائط التواصي والدعاء
              _buildNudgesTab(context, nudgesAsync, isDark),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ في جلب بيانات المجموعة: $e')),
      ),
    );
  }

  Widget _buildLeaderboardTab(
    BuildContext context,
    FaithGroup group,
    AsyncValue<List<GroupMember>> membersAsync,
    bool isDark,
  ) {
    final currentUid = GroupsService.instance.currentUserId;
    final accent = themeAccent(context);

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
          // بطاقة كود ومعلومات المجموعة العصرية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.lineDark : AppColors.line,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.25),
                        accent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    group.name.isNotEmpty ? group.name[0] : 'م',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (group.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          group.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.tag_rounded,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  group.code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${group.membersCount} أعضاء',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'نسخ الرمز',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: group.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ رمز المجموعة بنجاح'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
                  for (var i = 0; i < members.length; i++)
                    _buildMemberCard(
                      context,
                      member: members[i],
                      rank: i + 1,
                      isMe: members[i].userId == currentUid,
                      isDark: isDark,
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('خطأ في جلب الأعضاء: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context, {
    required GroupMember member,
    required int rank,
    required bool isMe,
    required bool isDark,
  }) {
    final score = member.progress.scorePercentage;
    final accent = themeAccent(context);

    Color rankColor;
    String rankLabel = '$rank';
    if (rank == 1) {
      rankColor = const Color(0xFFD4AF37); // Gold
      rankLabel = 'الأول';
    } else if (rank == 2) {
      rankColor = const Color(0xFFA0A0A0); // Silver
      rankLabel = 'الثاني';
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankLabel = 'الثالث';
    } else {
      rankColor = isDark ? Colors.white38 : Colors.black38;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMe
            ? accent.withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe
              ? accent.withValues(alpha: 0.8)
              : (rank <= 3
                    ? rankColor.withValues(alpha: 0.4)
                    : (isDark ? AppColors.lineDark : AppColors.line)),
          width: isMe ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // رتبة العضو
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: rankColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    rankLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // أفاتار العضو المختار (راجع `group_avatars.dart`) — لا
                // حرف اسم كالسابق، كل عضو يختار أفاتاره فعلياً وقت
                // إنشاء/الانضمام للمجموعة (`groups_hub_screen.dart._AvatarPicker`).
                Builder(
                  builder: (context) {
                    final avatar = groupAvatarByIndex(member.avatarIndex);
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: avatar.color.withValues(alpha: 0.18),
                      child: Icon(avatar.icon, color: avatar.color, size: 18),
                    );
                  },
                ),
                const SizedBox(width: 10),

                // اسم العضو والشارة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.displayName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: isMe
                                    ? FontWeight.bold
                                    : FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'أنت',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'إنجاز اليوم: $score%',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: score >= 80
                                  ? const Color(0xFF2E7D32)
                                  : (isDark ? Colors.white60 : Colors.black54),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // سلسلة استمرار حقيقية (أفضل سلسلة نشطة حالياً لدى
                          // العضو — راجع `UserRepository.bestCurrentStreakDays`
                          // لسبب "أفضل" لا فئة واحدة محدَّدة) — لا تُعرض
                          // إطلاقاً لو صفر (عضو جديد بلا أي سلسلة بعد).
                          if (member.currentStreak > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '🔥 ${member.currentStreak}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.orangeAccent
                                    : const Color(0xFFB5622A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // مؤشر النسبة الدائري
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        value: score / 100.0,
                        strokeWidth: 3.5,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          score >= 80 ? const Color(0xFF2E7D32) : accent,
                        ),
                      ),
                    ),
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? AppColors.lineDark : AppColors.line,
            ),
            const SizedBox(height: 10),

            // تفاصيل أركان اليوم
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniPillar(
                  icon: Icons.mosque_outlined,
                  label: '${member.progress.prayersCompleted}/5 صلوات',
                  done: member.progress.prayersCompleted > 0,
                  context: context,
                ),
                _buildMiniPillar(
                  icon: Icons.wb_sunny_outlined,
                  label: '${member.progress.sunnahCount} سنن',
                  done: member.progress.sunnahCount > 0,
                  context: context,
                ),
                _buildMiniPillar(
                  icon: Icons.touch_app_outlined,
                  label:
                      member.progress.morningAzkar &&
                          member.progress.eveningAzkar
                      ? 'الأذكار كاملة'
                      : (member.progress.morningAzkar ||
                                member.progress.eveningAzkar
                            ? 'أذكار جزئية'
                            : 'الأذكار'),
                  done:
                      member.progress.morningAzkar ||
                      member.progress.eveningAzkar,
                  context: context,
                ),
                if (!isMe)
                  InkWell(
                    onTap: () => _showNudgeDialog(context, member),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite_rounded, size: 14, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            'تشجيع',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPillar({
    required IconData icon,
    required String label,
    required bool done,
    required BuildContext context,
  }) {
    final accent = themeAccent(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: done ? accent : Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: done ? null : Colors.grey,
            fontWeight: done ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildNudgesTab(
    BuildContext context,
    AsyncValue<List<GroupNudge>> nudgesAsync,
    bool isDark,
  ) {
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
                  child: Icon(_nudgeIconData(n.type), color: accent, size: 20),
                ),
                title: Text(
                  n.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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
