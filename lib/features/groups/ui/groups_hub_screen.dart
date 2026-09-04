import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_providers.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../models/faith_group.dart';
import '../models/group_avatars.dart';
import '../providers/groups_providers.dart';
import '../services/groups_service.dart';
import 'group_details_screen.dart';

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

  Future<void> _showCreateGroupDialog(BuildContext context) async {
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
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.group_add_rounded, size: 24, color: AppColors.goldDeep),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'إنشاء مجموعة صحبة صالحة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المجموعة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'الهدف من المجموعة (اختياري)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'اختر أفاتارك بالمجموعة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _AvatarPicker(
                  selectedIndex: selectedAvatarIndex,
                  onSelected: (i) => setDlgState(() => selectedAvatarIndex = i),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            AppPrimaryButton(
              label: 'إنشاء المجموعة',
              loading: isLoading,
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
                        ref
                            .read(myGroupIdsProvider.notifier)
                            .addGroup(group.id);
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showJoinGroupDialog(BuildContext context) async {
    final codeCtrl = TextEditingController();
    var isLoading = false;
    var selectedAvatarIndex = await GroupsService.instance.getMyAvatarIndex();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // راجع تعليق `Expanded` بعنوان حوار الإنشاء أعلاه — نفس السبب.
          title: const Row(
            children: [
              Text('🔑', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Expanded(child: Text('الانضمام برمز المجموعة')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل رمز الانضمام المكوّن من ٦ خانات الذي شاركه معك منشئ المجموعة:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'HM1234',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'اختر أفاتارك بالمجموعة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _AvatarPicker(
                  selectedIndex: selectedAvatarIndex,
                  onSelected: (i) => setDlgState(() => selectedAvatarIndex = i),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            AppPrimaryButton(
              label: 'انضمام',
              color: AppColors.gold,
              loading: isLoading,
              onPressed: isLoading
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim();
                      if (code.isEmpty) return;
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
                        final group = await GroupsService.instance
                            .joinGroupByCode(
                              code: code,
                              displayName: name,
                              streak: streak,
                              avatarIndex: selectedAvatarIndex,
                              initialProgress: myProgress,
                            );
                        ref
                            .read(myGroupIdsProvider.notifier)
                            .addGroup(group.id);
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
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
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
          _buildMyDeedsCard(context, myDeeds, isDark),
          const SizedBox(height: 18),

          // أزرار إنشاء / انضمام لمجموعة
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: 'إنشاء مجموعة',
                  icon: Icons.add,
                  color: AppColors.gold,
                  onPressed: () => _showCreateGroupDialog(context),
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
                  onPressed: () => _showJoinGroupDialog(context),
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
                return _buildEmptyState(context, isDark);
              }

              return Column(
                children: [
                  for (final id in ids)
                    _buildGroupItemCard(context, id, isDark),
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

  Widget _buildMyDeedsCard(
    BuildContext context,
    DailyDeedsProgress deeds,
    bool isDark,
  ) {
    final score = deeds.scorePercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌟 إنجازك في أعمال اليوم والليلة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يتم تحديث إنجازك تلقائياً في جميع مجموعاتك',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 5,
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 80 ? const Color(0xFF2E7D32) : AppColors.goldDeep,
                      ),
                    ),
                  ),
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDeedStatus(
                icon: Icons.mosque_outlined,
                label: '${deeds.prayersCompleted}/5 فرائض',
                done: deeds.prayersCompleted == 5,
                context: context,
              ),
              _buildDeedStatus(
                icon: Icons.wb_sunny_outlined,
                label: '${deeds.sunnahCount} سنن',
                done: deeds.sunnahCount > 0,
                context: context,
              ),
              _buildDeedStatus(
                icon: Icons.touch_app_outlined,
                label: deeds.morningAzkar && deeds.eveningAzkar
                    ? 'الأذكار كاملة'
                    : 'الأذكار',
                done: deeds.morningAzkar || deeds.eveningAzkar,
                context: context,
              ),
              _buildDeedStatus(
                icon: Icons.menu_book_outlined,
                label: deeds.quranPages > 0 ? 'ورد القرآن' : 'الورد',
                done: deeds.quranPages > 0,
                context: context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeedStatus({
    required IconData icon,
    required String label,
    required bool done,
    required BuildContext context,
  }) {
    final accent = themeAccent(context);
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done
                ? accent.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? accent.withValues(alpha: 0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 18, color: done ? accent : Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: done ? FontWeight.bold : FontWeight.normal,
            color: done
                ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87)
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupItemCard(
    BuildContext context,
    String groupId,
    bool isDark,
  ) {
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) return const SizedBox.shrink();

        final accent = themeAccent(context);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailsScreen(
                      groupId: group.id,
                      groupName: group.name,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                const SizedBox(height: 3),
                                Text(
                                  group.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 14,
                                color: accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${group.membersCount} أعضاء',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tag_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                group.code,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'عرض التنافس 👈',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
      ),
      child: Column(
        children: [
          const Text('🤝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'وَتَعَاوَنُوا عَلَى الْبِرِّ وَالتَّقْوَىٰ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Kitab',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ حلقة إيمانية مع أهلك أو أصدقائك وشاركهم رمز الانضمام للتواصي على أداء الصلوات والأذكار والسنن ومتابعة همم اليوم معاً.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// شبكة اختيار أفاتار بسيطة (أيقونة+لون من `kGroupAvatarPresets`) —
/// تُستخدَم بحواري إنشاء/الانضمام لمجموعة معاً، نفس عرض الأفاتار المطبَّق
/// بشاشة تفاصيل المجموعة (`group_details_screen.dart._MemberTile` أو ما
/// يعادلها) عبر [groupAvatarByIndex].
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < kGroupAvatarPresets.length; i++)
          _AvatarChoice(
            preset: kGroupAvatarPresets[i],
            isSelected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final GroupAvatarPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: preset.color.withValues(alpha: isSelected ? 1 : 0.15),
          border: Border.all(color: preset.color, width: isSelected ? 2.5 : 1),
        ),
        child: Icon(
          preset.icon,
          color: isSelected ? Colors.white : preset.color,
          size: 20,
        ),
      ),
    );
  }
}
