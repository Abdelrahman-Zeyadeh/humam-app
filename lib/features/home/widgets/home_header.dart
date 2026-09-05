import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_accent_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/cloud_sync_service.dart';
import '../../hijri/hijri_calendar_screen.dart';
import '../../profile/profile_stats_screen.dart';
import '../../search/unified_search_screen.dart';

/// شريط الترحيب أعلى الشاشة الرئيسية — تحية بحسب الوقت، اسم المستخدم،
/// حالة المزامنة السحابية، والتاريخ الهجري. استُخرج من `home_screen.dart`
/// أثناء تفكيك الملف بلا أي تغيير سلوكي.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.hijri});
  final String hijri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userNameVersionProvider);
    ref.watch(accentColorVersionProvider);
    final accent = appAccentColorById(
      ref.read(userPrefsProvider).accentColorId,
    );
    final name = ref.watch(userPrefsProvider).userName.trim();
    final syncState = ref.watch(cloudSyncControllerProvider);
    final h = DateTime.now().hour;
    final greeting = h < 4
        ? 'طاب ليلك وقيامك 🌙'
        : h < 12
        ? 'صباح الخير والبركة 🌅'
        : h < 17
        ? 'طاب يومك بطاعة الله ☀️'
        : 'مساء الخير والسكينة 🕌';

    final welcome = name.isNotEmpty
        ? 'أهلاً بك يا $name في هُمَام'
        : 'أهلاً بك في هُمَام';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 42, 16, 38),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [accent.primaryLight, accent.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            welcome,
                            style: const TextStyle(
                              color: AppColors.goldSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UnifiedSearchScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.search, color: Colors.white, size: 18),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileStatsScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              syncState.isSignedIn
                                  ? Icons.cloud_done
                                  : Icons.account_circle_outlined,
                              color: syncState.isSignedIn
                                  ? const Color(0xFF81C784)
                                  : Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              syncState.isSignedIn
                                  ? (syncState.user?.displayName
                                            ?.split(' ')
                                            .first ??
                                        'متزامن')
                                  : 'حسابي',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HijriCalendarScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 13,
                          color: AppColors.goldSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hijri,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_left,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.7),
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
