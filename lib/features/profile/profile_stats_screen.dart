import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../auth/cloud_sync_service.dart';
import 'widgets/achievement_badges_grid.dart';
import 'widgets/challenges_groups_card.dart';
import 'widgets/cloud_sync_card.dart';
import 'widgets/daily_streak_section.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/profile_header.dart';
import 'widgets/progress_goals_section.dart';
import 'widgets/today_stats_section.dart';
import 'widgets/total_stats_section.dart';

/// شاشة الملف الشخصي والإحصائيات: تجميع تفضيلات وإحصائيات المستخدم
/// المبعثرة سابقاً في مكان واحد.
///
/// الشاشة نفسها مجرّد تنسيق (composition) لثمانية أقسام مستقلة بمجلد
/// `widgets/` (رأس الملف الشخصي، حوار التعديل، بطاقة المزامنة السحابية،
/// إحصائيات اليوم، الانتظام اليومي، الإجمالي الكلي، تحليل التقدم،
/// التحديات والمجموعات، وشارات الإنجاز) — استُخرجت من هون أثناء تفكيك
/// الملف، كان ~١٠١٣ سطراً بكل شي بملف واحد، بلا أي تغيير سلوكي.
class ProfileStatsScreen extends ConsumerStatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  ConsumerState<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends ConsumerState<ProfileStatsScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    ref.watch(userNameVersionProvider);
    final syncState = ref.watch(cloudSyncControllerProvider);

    final streakDays = userPrefs.streakDays;
    final displayName = userPrefs.userName.trim().isNotEmpty
        ? userPrefs.userName.trim()
        : (syncState.user?.displayName?.trim().isNotEmpty == true
              ? syncState.user!.displayName!.trim()
              : 'مستخدم هُمَام');
    final avatar = userPrefs.userAvatar.trim();

    // إحصائيات الأنشطة
    final fajrStreak = userPrefs.streakDaysFor(UserCategories.fajr);
    final morningStreak = userPrefs.streakDaysFor(UserCategories.morningAzkar);
    final eveningStreak = userPrefs.streakDaysFor(UserCategories.eveningAzkar);
    final hifzStreak = userPrefs.streakDaysFor(UserCategories.hifz);

    return Scaffold(
      // هيدر بتدرّج مطابق لأسلوب لوحة التصميم المعتمدة — `AppBar` عادي
      // بلا لمس هيكل الجسم، فقط زُيِّن بصرياً (`flexibleSpace`).
      appBar: GradientAppBar(
        title: 'الملف الشخصي والإحصائيات',
        centerTitle: true,
        colors: const [AppColors.blue, AppColors.navy],
        actions: [
          if (syncState.isSignedIn)
            IconButton(
              icon: syncState.status == CloudSyncStatus.syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync_outlined),
              tooltip: 'مزامنة الآن',
              onPressed: syncState.status == CloudSyncStatus.syncing
                  ? null
                  : () async {
                      final ok = await ref
                          .read(cloudSyncControllerProvider.notifier)
                          .syncNow();
                      if (!context.mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'تمّت المزامنة السحابية ☁️'
                                : 'تعذّرت المزامنة السحابية',
                          ),
                        ),
                      );
                    },
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => setState(() {}),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          ProfileHeader(
            displayName: displayName,
            avatar: avatar,
            onTap: () => showEditProfileDialog(
              context,
              ref,
              displayName,
              avatar,
              onSaved: () => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          CloudSyncCard(syncState: syncState),
          const SizedBox(height: 20),
          TodayStatsSection(
            morningStreak: morningStreak,
            eveningStreak: eveningStreak,
            streakDays: streakDays,
          ),
          const SizedBox(height: 20),
          DailyStreakSection(streakDays: streakDays),
          const SizedBox(height: 20),
          TotalStatsSection(streakDays: streakDays, fajrStreak: fajrStreak),
          const SizedBox(height: 20),
          ProgressGoalsSection(
            morningStreak: morningStreak,
            eveningStreak: eveningStreak,
            streakDays: streakDays,
            fajrStreak: fajrStreak,
            hifzStreak: hifzStreak,
          ),
          const SizedBox(height: 20),
          const ChallengesGroupsCard(),
          const SizedBox(height: 24),
          AchievementBadgesGrid(streakDays: streakDays, fajrStreak: fajrStreak),
        ],
      ),
    );
  }
}
