import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/user/user_prefs.dart';
import '../../../../core/data/user/user_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/groups_providers.dart';
import '../../services/groups_service.dart';
import '../group_details_screen.dart';

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
      builder: (ctx, setDlgState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final onSurface = Theme.of(ctx).colorScheme.onSurface;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E242B) : const Color(0xFFFCFAF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رأس الحوار الأنيق
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFAA8010)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إنشاء مجموعة صحبة صالحة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تواصوا بالحق وتنافسوا في الطاعات وأحيوا السنن معاً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // حقل اسم المجموعة
                  Text(
                    'اسم المجموعة',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 14, color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'اكتب اسم المجموعة هنا...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.38),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF2EFE9),
                      prefixIcon: const Icon(
                        Icons.groups_rounded,
                        color: AppColors.goldDeep,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE4DFD5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.goldDeep,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // حقل الهدف من المجموعة
                  Text(
                    'الهدف من المجموعة (اختياري)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    style: TextStyle(fontSize: 13.5, color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'اكتب الهدف المشترك لهذه الصحبة...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.38),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF2EFE9),
                      prefixIcon: const Icon(
                        Icons.flag_outlined,
                        color: AppColors.goldDeep,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE4DFD5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.goldDeep,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // أزرار الإلغاء والإنشاء
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'إنشاء المجموعة',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
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
          ),
        );
      },
    ),
  );
}
