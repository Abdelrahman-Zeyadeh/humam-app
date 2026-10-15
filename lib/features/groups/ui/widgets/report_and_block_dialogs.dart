import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/faith_group.dart';
import '../../services/groups_service.dart';
import '../../services/social_safety_service.dart';

/// عرض نافذة الإبلاغ عن عضو
Future<void> showReportMemberDialog(
  BuildContext context,
  WidgetRef ref, {
  required GroupMember member,
  required String groupId,
}) async {
  ReportReason selectedReason = ReportReason.inappropriateContent;
  final detailsController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.flag_outlined, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'إبلاغ عن (${member.displayName})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'يرجى تحديد سبب الإبلاغ لمساعدتنا في الحفاظ على بيئة إيمانية آمنة وصادقة:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              RadioGroup<ReportReason>(
                groupValue: selectedReason,
                onChanged: (val) {
                  if (val != null) setState(() => selectedReason = val);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...ReportReason.values.map(
                      (reason) => RadioListTile<ReportReason>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(reason.title, style: const TextStyle(fontSize: 13)),
                        value: reason,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل إضافية (اختياري)',
                  hintText: 'وضّح ما حدث بإيجاز...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إرسال البلاغ'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return;

  final reporterId = GroupsService.instance.currentUserId ?? 'anonymous';
  final report = UserReport(
    reporterId: reporterId,
    reportedUserId: member.userId,
    reportedUserName: member.displayName,
    groupId: groupId,
    reason: selectedReason,
    details: detailsController.text.trim(),
    timestamp: DateTime.now(),
  );

  await SocialSafetyService.instance.submitReport(report);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم استلام بلاغك وسيقوم الفريق بمراجعته. جزاك الله خيراً.'),
      ),
    );
  }
}

/// عرض نافذة تأكيد حظر عضو
Future<void> showBlockMemberDialog(
  BuildContext context,
  WidgetRef ref, {
  required GroupMember member,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.block, color: Colors.redAccent),
          SizedBox(width: 8),
          Text('حظر هذا العضو؟'),
        ],
      ),
      content: Text(
        'هل أنت متأكد من رغبتك في حظر "${member.displayName}"؟ لن تظهر رسائل التشجيع الواردة منه ولن تتمكن من مراسلته.',
        style: const TextStyle(fontSize: 13.5, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('تأكيد الحظر'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await ref.read(blockedUsersProvider.notifier).blockUser(member.userId);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حظر "${member.displayName}".'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            ref.read(blockedUsersProvider.notifier).unblockUser(member.userId);
          },
        ),
      ),
    );
  }
}
