import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/faith_group.dart';

/// بطاقة كود ومعلومات المجموعة العصرية بأعلى لوحة التنافس — الاسم،
/// الوصف، رمز الانضمام (قابل للنسخ)، وعدد الأعضاء.
class GroupInfoCard extends StatelessWidget {
  const GroupInfoCard({super.key, required this.group, required this.isDark});

  final FaithGroup group;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = themeAccent(context);

    return Container(
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
              border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Text(
              group.name.isNotEmpty ? group.name[0] : 'م',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, size: 12, color: Colors.grey),
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
                const SnackBar(content: Text('تم نسخ رمز المجموعة بنجاح')),
              );
            },
          ),
        ],
      ),
    );
  }
}
