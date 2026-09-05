import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/faith_group.dart';
import '../../models/group_avatars.dart';

/// بطاقة عضو واحد بلوحة التنافس: الرتبة، الأفاتار، الاسم، إنجاز اليوم،
/// أركان اليوم، وزر التشجيع (لغير المستخدم الحالي).
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.rank,
    required this.totalMembers,
    required this.isMe,
    required this.isDark,
    required this.onNudge,
  });

  final GroupMember member;
  final int rank;
  /// عدد أعضاء المجموعة كلها — يُستخدم فقط لإخفاء شارة الترتيب ("الأول 🥇")
  /// لو كان المستخدم العضو الوحيد بالمجموعة (ملاحظة فعلية: شارة "الأول"
  /// لعضو منفرد لا معنى تنافسياً لها). تظهر الشارة بمجرد انضمام عضو ثانٍ.
  final int totalMembers;
  final bool isMe;
  final bool isDark;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    final score = member.progress.scorePercentage;
    final accent = themeAccent(context);
    final showRankBadge = totalMembers > 1;

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
              : (showRankBadge && rank <= 3
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
                // رتبة العضو — تُخفى كلياً لو كان المستخدم العضو الوحيد
                // بالمجموعة (راجع توثيق [totalMembers] أعلاه).
                if (showRankBadge) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                ],

                // أفاتار العضو المختار (راجع `group_avatars.dart`) — لا حرف
                // اسم كالسابق، كل عضو يختار أفاتاره فعلياً وقت إنشاء/الانضمام
                // للمجموعة (`create_group_dialog.dart`/`join_group_dialog.dart`).
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
                                fontWeight: isMe ? FontWeight.bold : FontWeight.w700,
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
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? AppColors.lineDark : AppColors.line),
            const SizedBox(height: 10),

            // تفاصيل أركان اليوم
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniPillar(
                  icon: Icons.mosque_outlined,
                  label: '${member.progress.prayersCompleted}/5 صلوات',
                  done: member.progress.prayersCompleted > 0,
                ),
                _MiniPillar(
                  icon: Icons.wb_sunny_outlined,
                  label: '${member.progress.sunnahCount} سنن',
                  done: member.progress.sunnahCount > 0,
                ),
                _MiniPillar(
                  icon: Icons.touch_app_outlined,
                  label:
                      member.progress.morningAzkar && member.progress.eveningAzkar
                      ? 'الأذكار كاملة'
                      : (member.progress.morningAzkar || member.progress.eveningAzkar
                            ? 'أذكار جزئية'
                            : 'الأذكار'),
                  done: member.progress.morningAzkar || member.progress.eveningAzkar,
                ),
                if (!isMe)
                  InkWell(
                    onTap: onNudge,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
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
}

class _MiniPillar extends StatelessWidget {
  const _MiniPillar({required this.icon, required this.label, required this.done});

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
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
}
