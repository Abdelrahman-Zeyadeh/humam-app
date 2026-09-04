import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_dialog.dart';
import '../auth/cloud_sync_service.dart';
import '../groups/ui/groups_hub_screen.dart';

class ProfileStatsScreen extends ConsumerStatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  ConsumerState<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends ConsumerState<ProfileStatsScreen> {
  void _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String currentAvatar,
  ) {
    final nameCtrl = TextEditingController(
      text: currentName == 'مستخدم هُمَام' ? '' : currentName,
    );
    var avatarPath = currentAvatar;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 24, color: AppColors.goldDeep),
              SizedBox(width: 8),
              Text(
                'تعديل الملف الشخصي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.navy,
                        backgroundImage:
                            avatarPath.isNotEmpty &&
                                File(avatarPath).existsSync()
                            ? FileImage(File(avatarPath))
                            : null,
                        child:
                            (avatarPath.isEmpty ||
                                !File(avatarPath).existsSync())
                            ? Text(
                                currentName.isNotEmpty ? currentName[0] : 'م',
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: themeAccent(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('صورة من المعرض'),
                      onPressed: () async {
                        try {
                          final picked = await FilePicker.pickFile(
                            type: FileType.image,
                          );
                          final rawPath = picked?.path;
                          if (rawPath != null) {
                            // تصغير/ضغط الصورة قبل حفظها محلياً — هذا نفس
                            // الملف اللي بيترفع لاحقاً Base64 للمزامنة
                            // السحابية (راجع cloud_sync_service.dart)، فلازم
                            // يبقى صغيراً بغضّ النظر عن حجم الصورة الأصلية
                            // (قد تكون عدة ميجابايتات من كاميرا حقيقية).
                            final decoded = img.decodeImage(
                              await File(rawPath).readAsBytes(),
                            );
                            if (decoded == null) {
                              throw Exception('صيغة صورة غير مدعومة');
                            }
                            final resized =
                                (decoded.width > 512 || decoded.height > 512)
                                ? img.copyResize(
                                    decoded,
                                    width: decoded.width >= decoded.height
                                        ? 512
                                        : null,
                                    height: decoded.height > decoded.width
                                        ? 512
                                        : null,
                                  )
                                : decoded;
                            final jpgBytes = img.encodeJpg(
                              resized,
                              quality: 82,
                            );
                            final appDir =
                                await getApplicationDocumentsDirectory();
                            final targetPath = p.join(
                              appDir.path,
                              'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
                            );
                            await File(targetPath).writeAsBytes(jpgBytes);
                            setDlgState(() => avatarPath = targetPath);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('تعذّر اختيار الصورة: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    if (avatarPath.isNotEmpty &&
                        File(avatarPath).existsSync()) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'حذف الصورة',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => setDlgState(() => avatarPath = ''),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'الاسم الشخصي أو اللقب:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم أو اللقب',
                    hintText: 'اكتب اسمك هنا',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            AppPrimaryButton(
              label: 'حفظ التعديلات',
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final prefs = ref.read(userPrefsProvider);
                if (newName.isNotEmpty) {
                  await prefs.setUserName(newName);
                }
                await prefs.setUserAvatar(avatarPath);
                ref.read(userNameVersionProvider.notifier).bump();
                try {
                  await ref
                      .read(cloudSyncControllerProvider.notifier)
                      .syncToCloud();
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    ref.watch(userNameVersionProvider);
    final syncState = ref.watch(cloudSyncControllerProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final streakDays = userPrefs.streakDays;
    final displayName = userPrefs.userName.trim().isNotEmpty
        ? userPrefs.userName.trim()
        : (syncState.user?.displayName?.trim().isNotEmpty == true
              ? syncState.user!.displayName!.trim()
              : 'مستخدم هُمَام');
    final avatar = userPrefs.userAvatar.trim();
    final hasAvatarImage = avatar.isNotEmpty && File(avatar).existsSync();
    final initial = displayName.isNotEmpty ? displayName[0] : 'م';

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
          // رأس الملف الشخصي: الصورة والاسم — قابل للتعديل
          Center(
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () =>
                      _showEditProfileDialog(context, displayName, avatar),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: isDark
                            ? const Color(0xFF34495E)
                            : const Color(0xFF8D6E63),
                        backgroundImage: hasAvatarImage
                            ? FileImage(File(avatar))
                            : null,
                        child: !hasAvatarImage
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 34,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeAccent(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      _showEditProfileDialog(context, displayName, avatar),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // بطاقة تسجيل الدخول السحابي
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF9F7F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.lineDark : AppColors.line)
                    .withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncState.isSignedIn
                            ? (syncState.user?.email ?? 'متزامن سحابياً')
                            : 'سجّل دخولك لحفظ بياناتك',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        syncState.isSignedIn
                            ? 'أذكارك وإنجازاتك محفوظة عبر جميع أجهزتك'
                            : 'أذكارك وإنجازاتك ستُحفظ وتتزامن تلقائياً',
                        style: TextStyle(
                          fontSize: 11,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!syncState.isSignedIn)
                  AppPrimaryButton(
                    onPressed: () => AuthDialog.show(context),
                    icon: Icons.login_rounded,
                    label: 'دخول / تسجيل',
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_done, color: Color(0xFF1B8A72)),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 18),
                        tooltip: 'تسجيل الخروج',
                        onPressed: () => ref
                            .read(cloudSyncControllerProvider.notifier)
                            .signOut(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // إحصائيات اليوم
          _SectionHeader(title: 'إحصائيات اليوم'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'أوراد الأذكار',
                  value:
                      '${(morningStreak > 0 ? 1 : 0) + (eveningStreak > 0 ? 1 : 0)}',
                  icon: Icons.auto_awesome,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'تسبيحات',
                  value: '33',
                  icon: Icons.fingerprint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'دقائق قرآن',
                  value: '${streakDays * 5}',
                  icon: Icons.headphones_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'دقائق في التطبيق',
                  value: '${streakDays * 12}',
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الانتظام اليومي (Streaks)
          _SectionHeader(title: 'الانتظام اليومي'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2836) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.lineDark : AppColors.line,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['سب', 'أح', 'إث', 'ثل', 'أر', 'خم', 'جم'].map((
                    day,
                  ) {
                    final isToday = day == 'أر' || streakDays > 0;
                    return Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday
                                ? const Color(0xFFE67E22)
                                : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.04)),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.local_fire_department,
                            size: 18,
                            color: isToday
                                ? Colors.white
                                : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StreakMetric(label: 'الحالي', value: '$streakDays'),
                    _StreakMetric(
                      label: 'الأفضل',
                      value: '${streakDays > 7 ? streakDays : 7}',
                    ),
                    _StreakMetric(
                      label: 'شهرياً',
                      value:
                          '${(streakDays / 30 * 100).clamp(0, 100).toInt()}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // الإجمالي الكلي
          _SectionHeader(title: 'الإجمالي الكلي'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'إجمالي الأوراد',
                  value: '${streakDays * 2}',
                  icon: Icons.auto_stories_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'إجمالي التسبيح',
                  value: '${streakDays * 100 + 33}',
                  icon: Icons.fingerprint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'صلوات مسجلة',
                  value: '${fajrStreak * 5}',
                  icon: Icons.mosque_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'دقائق القرآن',
                  value: '${streakDays * 15}',
                  icon: Icons.headphones_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // تحليل التقدم
          _SectionHeader(title: 'تحليل التقدم'),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProgressGoalRow(
                    label: 'الأذكار',
                    current:
                        (morningStreak > 0 ? 50 : 0) +
                        (eveningStreak > 0 ? 50 : 0),
                    total: 100,
                    icon: Icons.auto_awesome,
                  ),
                  const SizedBox(height: 12),
                  const _ProgressGoalRow(
                    label: 'التسبيح',
                    current: 33,
                    total: 100,
                    icon: Icons.fingerprint,
                  ),
                  const SizedBox(height: 12),
                  _ProgressGoalRow(
                    label: 'القرآن (ساعة)',
                    current: streakDays,
                    total: 10,
                    icon: Icons.headphones,
                  ),
                  const SizedBox(height: 12),
                  _ProgressGoalRow(
                    label: 'الصلوات',
                    current: fajrStreak > 0 ? 5 : 0,
                    total: 5,
                    icon: Icons.mosque,
                  ),
                  const SizedBox(height: 12),
                  _ProgressGoalRow(
                    label: 'الحفظ والمراجعة',
                    current: hifzStreak,
                    total: 7,
                    icon: Icons.school,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // التحديات والمجموعات
          _SectionHeader(title: 'التحديات والمجموعات'),
          const SizedBox(height: 10),
          Material(
            color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF9F7F2),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GroupsHubScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? AppColors.lineDark : AppColors.line),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined, color: Color(0xFFE67E22)),
                    SizedBox(width: 10),
                    Text(
                      'انضم إلى تحدٍّ أو مجموعة إيمانية جديدة 🏆',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // شارات الإنجاز
          _SectionHeader(title: 'شارات الإنجاز'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _BadgeItem(
                icon: Icons.local_fire_department,
                label: '3 أيام',
                isUnlocked: streakDays >= 3,
              ),
              _BadgeItem(
                icon: Icons.local_fire_department,
                label: '7 أيام',
                isUnlocked: streakDays >= 7,
              ),
              _BadgeItem(
                icon: Icons.star_rounded,
                label: '30 يوماً',
                isUnlocked: streakDays >= 30,
              ),
              _BadgeItem(
                icon: Icons.auto_awesome,
                label: '100 ورد',
                isUnlocked: streakDays >= 10,
              ),
              _BadgeItem(
                icon: Icons.fingerprint,
                label: '10K تسبيح',
                isUnlocked: true,
              ),
              _BadgeItem(
                icon: Icons.headphones,
                label: '60 د قرآن',
                isUnlocked: true,
              ),
              _BadgeItem(
                icon: Icons.mosque,
                label: '100 صلاة',
                isUnlocked: fajrStreak >= 20,
              ),
              _BadgeItem(
                icon: Icons.emoji_events,
                label: 'المداومة',
                isUnlocked: streakDays >= 5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final accent = themeAccent(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE67E22),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ProgressGoalRow extends StatelessWidget {
  const _ProgressGoalRow({
    required this.label,
    required this.current,
    required this.total,
    required this.icon,
  });

  final String label;
  final int current;
  final int total;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percent = (current / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current/$total',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: themeAccent(context)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(themeAccent(context)),
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.isUnlocked,
  });

  final IconData icon;
  final String label;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? themeAccent(context).withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border.all(
              color: isUnlocked
                  ? themeAccent(context)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: isUnlocked
                ? themeAccent(context)
                : Colors.grey.withValues(alpha: 0.4),
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
            color: isUnlocked ? onSurface : onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
