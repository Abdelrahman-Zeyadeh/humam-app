import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/tasbih_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_providers.dart';
import '../../../core/data/user/user_repository.dart';
import '../../notifications/adhan_notification_service.dart';
import '../models/faith_group.dart';
import '../services/groups_service.dart';

/// موفر استماع شامل لجميع تشجيعات المجموعات الواردة
final globalNudgesListenerProvider = Provider<void>((ref) {
  try {
    final groupIdsAsync = ref.watch(myGroupIdsProvider);
    final currentUid = GroupsService.instance.currentUserId;
    if (currentUid == null) return;

    final groupIds = groupIdsAsync.value ?? [];
    for (final gId in groupIds) {
      ref.listen<AsyncValue<List<GroupNudge>>>(
        groupNudgesStreamProvider(gId),
        (prev, next) {
          final list = next.value ?? [];
          if (list.isNotEmpty) {
            final latest = list.first;
            if (latest.toUserId == currentUid &&
                DateTime.now().difference(latest.sentAt).inMinutes < 5) {
              final prevLatestId =
                  prev?.value?.isNotEmpty == true ? prev!.value!.first.id : null;
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
    }
  } catch (e) {
    // Firebase may not be initialized in test runner
  }
});

/// قائمة معرفات المجموعات التي ينتمي إليها المستخدم
final myGroupIdsProvider =
    AsyncNotifierProvider<MyGroupIdsNotifier, List<String>>(
  MyGroupIdsNotifier.new,
);

class MyGroupIdsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return GroupsService.instance.getMyGroupIds();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => GroupsService.instance.getMyGroupIds());
  }

  Future<void> addGroup(String id) async {
    final current = state.value ?? [];
    if (!current.contains(id)) {
      state = AsyncValue.data([...current, id]);
    }
  }

  Future<void> removeGroup(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((i) => i != id).toList());
  }
}

/// موفر تدفق بيانات مجموعة واحدة
final groupStreamProvider =
    StreamProvider.family<FaithGroup?, String>((ref, groupId) {
  return GroupsService.instance.streamGroup(groupId);
});

/// موفر تدفق أعضاء المجموعة وترتيبهم
final groupMembersStreamProvider =
    StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
  return GroupsService.instance.streamMembers(groupId);
});

/// موفر تدفق رسائل التشجيع والتذكيرات
final groupNudgesStreamProvider =
    StreamProvider.family<List<GroupNudge>, String>((ref, groupId) {
  return GroupsService.instance.streamNudges(groupId);
});

/// حساب التقدّم الحالي لأعمال اليوم والليلة للمستخدم من البيانات المحلية
final myDailyDeedsProgressProvider = Provider<DailyDeedsProgress>((ref) {
  ref.watch(categoryStreakVersionProvider);
  final repo = ref.watch(userRepositoryProvider);
  final tasbih = ref.watch(tasbihPrefsProvider);

  // الصلوات الخمس المفروضة
  var prayersCount = 0;
  if (repo.completedTodayFor(UserCategories.fajr)) prayersCount++;
  if (repo.completedTodayFor(UserCategories.dhuhr)) prayersCount++;
  if (repo.completedTodayFor(UserCategories.asr)) prayersCount++;
  if (repo.completedTodayFor(UserCategories.maghrib)) prayersCount++;
  if (repo.completedTodayFor(UserCategories.isha)) prayersCount++;

  // السنن والنوافل (الرواتب، الضحى، قيام الليل)
  var sunnahCount = 0;
  if (repo.completedTodayFor(UserCategories.sunnahDuha)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.sunnahFajrQabliyah)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.sunnahDhuhrQabliyah)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.sunnahDhuhrBadiyah)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.sunnahAsrQabliyah)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.sunnahMaghribQabliyah)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.sunnahMaghribBadiyah)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.sunnahIshaBadiyah)) sunnahCount++;
  if (repo.completedTodayFor(UserCategories.qiyam)) sunnahCount++;

  // أذكار الصباح والمساء والنوم
  final morningDone = repo.completedTodayFor(UserCategories.morningAzkar);
  final eveningDone = repo.completedTodayFor(UserCategories.eveningAzkar);
  final sleepDone = repo.completedTodayFor(UserCategories.nightAzkar);

  // الورد اليومي (قراءة القرآن الكريم)
  final wirdDone = repo.readToday;

  return DailyDeedsProgress(
    prayersCompleted: prayersCount,
    sunnahCount: sunnahCount,
    morningAzkar: morningDone,
    eveningAzkar: eveningDone,
    sleepAzkar: sleepDone,
    quranPages: wirdDone ? 4 : 0,
    tasbihCount: tasbih.totalCount,
  );
});
