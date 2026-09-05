import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/user/user_prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/adhan_notification_service.dart';
import '../../models/faith_group.dart';
import '../../services/groups_service.dart';

/// أيقونة تشجيع بحسب نوعه — تُستخدم بحوار إرسال التشجيع وبحائط التواصي
/// معاً.
IconData nudgeIconFor(String type) {
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

/// حوار إرسال تشجيع إيماني سريع لعضو معيّن بالمجموعة.
void showNudgeDialog(
  BuildContext context,
  WidgetRef ref,
  String groupId,
  GroupMember member,
) {
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  child: Icon(nudgeIconFor(phrase.$1), size: 20, color: accent),
                ),
                title: Text(
                  phrase.$2,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final userPrefs = ref.read(userPrefsProvider);
                  final myName = userPrefs.userName.isNotEmpty
                      ? userPrefs.userName
                      : 'أخوك في الله';
                  await GroupsService.instance.sendNudge(
                    groupId: groupId,
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
