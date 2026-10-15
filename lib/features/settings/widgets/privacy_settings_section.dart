import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/auth_dialog.dart';
import '../../auth/cloud_sync_service.dart';
import '../../profile/profile_stats_screen.dart';
import '../permissions_guide_screen.dart';
import '../privacy_policy_screen.dart';
import 'settings_section_helpers.dart';

/// قسم الخصوصية والشفافية — يجمع سياسة الخصوصية، حالة المزامنة والحساب،
/// وتوضيح خيارات حذف البيانات والحساب.
class PrivacySettingsSection extends ConsumerWidget {
  const PrivacySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncControllerProvider);
    final user = syncState.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('الخصوصية والشفافية'),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              // 0. إدارة وتفعيل أذونات التطبيق
              ListTile(
                leading: const Icon(
                  Icons.security_rounded,
                  color: Color(0xFF1B8A72),
                ),
                title: const Text('أذونات وصلاحيات التطبيق'),
                subtitle: const Text(
                  'توضيح وتفعيل أذونات الإشعارات والأذان والموقع والبطارية',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PermissionsGuideScreen()),
                ),
              ),
              const Divider(height: 1),

              // 1. سياسة الخصوصية
              ListTile(
                leading: const Icon(
                  Icons.policy_outlined,
                  color: AppColors.tealDeep,
                ),
                title: const Text('سياسة الخصوصية'),
                subtitle: const Text(
                  'تفاصيل البيانات المحلية، المزامنة السحابية، وحماية الخصوصية',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const Divider(height: 1),

              // 2. المزامنة والبيانات (Data & Sync)
              ListTile(
                leading: const Icon(
                  Icons.cloud_sync_outlined,
                  color: AppColors.infoBlue,
                ),
                title: const Text('المزامنة السحابية والبيانات'),
                subtitle: Text(
                  user == null
                      ? 'غير متصل — بياناتك محفوظة محلياً على هذا الجهاز فقط'
                      : 'متصل بحساب (${user.email ?? user.displayName ?? "المستخدم"})',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () {
                  if (user == null) {
                    AuthDialog.show(context);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileStatsScreen(),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),

              // 3. الحساب (Account)
              ListTile(
                leading: const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.goldDeep,
                ),
                title: const Text('إدارة الحساب'),
                subtitle: Text(
                  user == null
                      ? 'تسجيل الدخول لمزامنة تقدمك واستعادته عند تغيير هاتفك'
                      : 'معرّف الحساب: ${user.uid.substring(0, user.uid.length.clamp(0, 10))}...',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: TextButton(
                  onPressed: () {
                    if (user == null) {
                      AuthDialog.show(context);
                    } else {
                      ref.read(cloudSyncControllerProvider.notifier).signOut();
                    }
                  },
                  child: Text(
                    user == null ? 'دخول' : 'خروج',
                    style: TextStyle(
                      color: user == null ? themeAccent(context) : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (user != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text('حذف الحساب والبيانات'),
                  subtitle: const Text(
                    'إلغاء الحساب وحذف البيانات السحابية',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => _showDeleteAccountDialog(context, ref, true),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref, bool isLoggedIn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('حذف الحساب والبيانات'),
          ],
        ),
        content: Text(
          isLoggedIn
              ? 'تنبيه: ميزة الإلغاء والحذف الشامل لبيانات السحاب ومجموعات الصحبة قيد الاستكمال الآمن من جهة الخادم لضمان تطهير كافة الجداول السحابية دون بقاء أي أثر.\n\nيمكنك الآن تسجيل الخروج ومسح بيانات التطبيق المحلية من إعدادات الهاتف.'
              : 'أنت لست مسجلاً بحساب سحابي حالياً. جميع بياناتك محفوظة محلياً فقط على هاتفك ويمكنك إزالتها في أي وقت عبر مسح بيانات التطبيق من إعدادات الهاتف.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً فهمت'),
          ),
          if (isLoggedIn)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(cloudSyncControllerProvider.notifier).signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تسجيل الخروج بنجاح'),
                  ),
                );
              },
              child: const Text(
                'تسجيل الخروج الآن',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
