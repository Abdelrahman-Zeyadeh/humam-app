import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/user/user_prefs.dart';
import '../../../../core/theme/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/adhan_notification_service.dart';
import '../../models/faith_group.dart';
import '../../services/groups_service.dart';

/// تبويب "تحدي جماعي": يعرض التحدي النشط الحالي (إن وُجد) بموعد نهائي
/// وتقدّم كل عضو نحو الهدف الرقمي، مع زر لإنشاء تحدٍ جديد ولإضافة تقدّمك،
/// وسجل قابل للطي للتحديات المؤرشَفة السابقة. راجع توثيق `GroupChallenge`/
/// `GroupsService.createChallenge` لتفاصيل النموذج والأرشفة.
class ChallengeTab extends ConsumerWidget {
  const ChallengeTab({super.key, required this.groupId, required this.isDark});

  final String groupId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = themeAccent(context);
    final activeAsync = ref.watch(_activeChallengeStreamProvider(groupId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.flag_circle_rounded, size: 20, color: accent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'التحدي الجماعي الحالي',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('تحدٍ جديد'),
              onPressed: () => _showCreateChallengeDialog(context, ref, groupId),
            ),
          ],
        ),
        const SizedBox(height: 12),
        activeAsync.when(
          data: (challenge) {
            if (challenge == null) {
              return const EmptyState(
                icon: Icons.flag_outlined,
                message: 'لا يوجد تحدٍ جماعي نشط الآن — أنشئ واحداً وادعُ أعضاء مجموعتك',
                padding: EdgeInsets.all(32),
              );
            }
            return _ActiveChallengeCard(groupId: groupId, challenge: challenge, isDark: isDark);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(child: Text('خطأ في جلب التحدي: $e')),
        ),
        const SizedBox(height: 24),
        _ChallengeHistorySection(groupId: groupId, isDark: isDark),
      ],
    );
  }
}

final _activeChallengeStreamProvider =
    StreamProvider.family<GroupChallenge?, String>((ref, groupId) {
  return GroupsService.instance.streamActiveChallenge(groupId);
});

final _challengeProgressStreamProvider = StreamProvider.family<
    List<ChallengeProgress>, ({String groupId, String challengeId})>((ref, args) {
  return GroupsService.instance.streamChallengeProgress(
    groupId: args.groupId,
    challengeId: args.challengeId,
  );
});

class _ActiveChallengeCard extends ConsumerWidget {
  const _ActiveChallengeCard({
    required this.groupId,
    required this.challenge,
    required this.isDark,
  });

  final String groupId;
  final GroupChallenge challenge;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = themeAccent(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final currentUid = GroupsService.instance.currentUserId;
    final isCreator = challenge.createdBy == currentUid;
    final progressAsync = ref.watch(
      _challengeProgressStreamProvider((groupId: groupId, challengeId: challenge.id)),
    );

    final remaining = challenge.remaining;
    final isEnded = challenge.isEnded;
    
    final String endedLabel;
    final Color statusColor;
    if (isEnded) {
      endedLabel = 'انتهت المهلة';
      statusColor = Colors.redAccent;
    } else if (remaining.inDays >= 1) {
      endedLabel = 'باقي ${remaining.inDays} يوم و${remaining.inHours % 24} ساعة';
      statusColor = remaining.inDays > 2 ? accent : Colors.orangeAccent;
    } else if (remaining.inHours >= 1) {
      endedLabel = 'باقي ${remaining.inHours} ساعة و${remaining.inMinutes % 60} دقيقة';
      statusColor = Colors.orangeAccent;
    } else {
      endedLabel = 'باقي ${remaining.inMinutes} دقيقة فقط!';
      statusColor = Colors.redAccent;
    }

    return AppCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEnded ? Icons.timer_off_outlined : Icons.timer_outlined,
                        size: 13,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        endedLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'الهدف: ${challenge.targetValue} ${challenge.unit} لكل عضو — أنشأه ${challenge.createdByName}',
              style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            progressAsync.when(
              data: (progressList) {
                final mine = progressList.where((p) => p.userId == currentUid).toList();
                final myValue = mine.isEmpty ? 0 : mine.first.value;
                final myPercent = (myValue / challenge.targetValue).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تقدّمك: $myValue / ${challenge.targetValue} ${challenge.unit}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent),
                        ),
                        Text(
                          '${(myPercent * 100).toInt()}%',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: myPercent,
                        minHeight: 8,
                        backgroundColor: onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لوحة شرف وإنجاز الأعضاء',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (progressList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'لا أحد بدأ التقدّم بعد — كن أول من يشارك',
                          style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                        ),
                      )
                    else
                      for (var i = 0; i < progressList.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                i == 0
                                    ? '🥇'
                                    : i == 1
                                        ? '🥈'
                                        : i == 2
                                            ? '🥉'
                                            : '${i + 1}.',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  progressList[i].displayName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: progressList[i].userId == currentUid
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: progressList[i].userId == currentUid ? accent : onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${progressList[i].value} ${challenge.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('تعذّر جلب التقدّم: $e'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('تسجيل إنجاز'),
                    onPressed: () => _showContributeDialog(context, ref, groupId, challenge),
                  ),
                ),
                if (isCreator && challenge.isEnded) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('أرشفة'),
                    onPressed: () => GroupsService.instance.archiveChallenge(
                      groupId: groupId,
                      challengeId: challenge.id,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeHistorySection extends ConsumerWidget {
  const _ChallengeHistorySection({required this.groupId, required this.isDark});

  final String groupId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_challengeHistoryStreamProvider(groupId));
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            'سجل التحديات السابقة (${history.length})',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          children: [
            for (final c in history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(c.title, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  'الهدف ${c.targetValue} ${c.unit} — انتهى ${_formatDate(c.endDate)}',
                  style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';
}

final _challengeHistoryStreamProvider =
    StreamProvider.family<List<GroupChallenge>, String>((ref, groupId) {
  return GroupsService.instance.streamChallengeHistory(groupId);
});

Future<void> _showCreateChallengeDialog(
  BuildContext context,
  WidgetRef ref,
  String groupId,
) async {
  final titleCtrl = TextEditingController();
  final unitCtrl = TextEditingController(text: 'صفحة');
  final targetCtrl = TextEditingController(text: '100');
  var durationDays = 7;

  final created = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('إنشاء تحدٍ جماعي جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان التحدي',
                  hintText: 'مثلاً: ختمة جماعية بالعشر الأواخر',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الهدف (رقم)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'الوحدة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('المدة:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: durationDays,
                    items: const [3, 7, 14, 30]
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d أيام')))
                        .toList(),
                    onChanged: (v) => setState(() => durationDays = v ?? durationDays),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    ),
  );

  if (created != true) return;
  final title = titleCtrl.text.trim();
  final target = int.tryParse(targetCtrl.text.trim()) ?? 0;
  if (title.isEmpty || target <= 0) return;

  final userPrefs = ref.read(userPrefsProvider);
  final startDate = DateTime.now();
  final endDate = startDate.add(Duration(days: durationDays));

  try {
    final challenge = await GroupsService.instance.createChallenge(
      groupId: groupId,
      title: title,
      unit: unitCtrl.text.trim(),
      targetValue: target,
      startDate: startDate,
      endDate: endDate,
      creatorName: userPrefs.userName.isNotEmpty ? userPrefs.userName : 'صاحب همّة',
    );
    await AdhanNotificationService.instance.scheduleGroupChallengeDeadlineReminder(
      challengeId: challenge.id,
      challengeTitle: challenge.title,
      endDate: challenge.endDate,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إنشاء التحدي: $e')),
      );
    }
  }
}

Future<void> _showContributeDialog(
  BuildContext context,
  WidgetRef ref,
  String groupId,
  GroupChallenge challenge,
) async {
  final valueCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('أضف تقدّمك'),
      content: TextField(
        controller: valueCtrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'عدد ${challenge.unit} المنجَزة الآن'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('إضافة'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  final addValue = int.tryParse(valueCtrl.text.trim()) ?? 0;
  if (addValue <= 0) return;

  final userPrefs = ref.read(userPrefsProvider);
  await GroupsService.instance.contributeToChallenge(
    groupId: groupId,
    challengeId: challenge.id,
    addValue: addValue,
    displayName: userPrefs.userName.isNotEmpty ? userPrefs.userName : 'صاحب همّة',
    avatarIndex: await GroupsService.instance.getMyAvatarIndex(),
  );
  // نجدول تذكير المهلة أيضاً هون (لا فقط عند الإنشاء) — عضو انضمّ لتحدٍ
  // أنشأه غيره لم يُجدوَل له تذكير عند الإنشاء أصلاً، وأول مشاركة فعلية
  // منه (أضف تقدّمك) نقطة طبيعية لتسجيله محلياً.
  await AdhanNotificationService.instance.scheduleGroupChallengeDeadlineReminder(
    challengeId: challenge.id,
    challengeTitle: challenge.title,
    endDate: challenge.endDate,
  );
}
