import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/backup_service.dart' show BackupRestoreResult;
import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_dialog.dart';
import '../../auth/cloud_sync_service.dart';
import '../../onboarding/onboarding_screen.dart';
import '../about_screen.dart';
import 'settings_section_helpers.dart';

/// قسم "الحساب والبيانات" — نسخة احتياطية + كتالوج التطبيق/الجولة
/// التعريفية + عن التطبيق. استُخرج من `settings_screen.dart` أثناء تفكيكه
/// بلا أي تغيير سلوكي.
class AccountDataSection extends ConsumerWidget {
  const AccountDataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('الحساب والبيانات'),
        const _BackupSection(),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.goldDeep,
            ),
            title: const Text('كتالوج التطبيق والجولة التعريفية'),
            subtitle: const Text(
              'استعراض مميزات التطبيق التفاعلية مع دوائر التركيز والشرح',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(tourActiveProvider.notifier).start();
            },
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF386892),
            ),
            title: const Text('عن هُمَام والمصادر المعتمدة'),
            subtitle: const Text(
              'توثيق مصادر المصحف والتفاسير والأحاديث، سياسة الخصوصية، والتراخيص',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
        ),
      ],
    );
  }
}

/// تصدير/استيراد نسخة احتياطية محلية كاملة (`backup_service.dart`) —
/// بلا أي اعتماد شبكي أو حساب، بطلب صاحب المشروع "نسخ احتياطي محلي
/// للبيانات". "استيراد" يستبدل بيانات هذا الجهاز بالكامل — تحذير صريح
/// قبل التنفيذ، وتنويه بإعادة فتح التطبيق بعد النجاح (راجع توثيق
/// `BackupService.pickAndInstallBackup`: لا إعادة تحميل حيّة لمنتصف الجلسة).
class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection();

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final syncState = ref.watch(cloudSyncControllerProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeAccent(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: themeAccent(context).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    syncState.isSignedIn
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_outlined,
                    color: themeAccent(context),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syncState.isSignedIn
                              ? (syncState.user?.email ?? 'متصل بالسحابة')
                              : 'المزامنة وحفظ التقدم سحابياً',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          syncState.isSignedIn
                              ? 'سلاسل الاستمرار والفواصل محفوظة سحابياً'
                              : 'احفظ بياناتك تلقائياً عند تغيير أو ضياع الجهاز',
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!syncState.isSignedIn)
                    FilledButton.tonal(
                      onPressed: () => AuthDialog.show(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'دخول / تسجيل',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.logout, size: 18),
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => ref
                          .read(cloudSyncControllerProvider.notifier)
                          .signOut(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'تصدير نسخة كاملة من بياناتك (علامات، خطط حفظ، سلاسل استمرار، إعدادات...) لملف تحفظه بنفسك، أو استعادتها لاحقاً على هذا الجهاز أو غيره.',
              style: TextStyle(
                fontSize: 12.5,
                color: onSurface.withValues(alpha: 0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('تصدير'),
                    onPressed: _busy ? null : _export,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings_backup_restore_outlined),
                    label: const Text('استيراد'),
                    onPressed: _busy ? null : _confirmAndImport,
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 10),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await ref.read(userPrefsProvider).backup.exportAndShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر تصدير النسخة الاحتياطية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndImport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استيراد نسخة احتياطية؟'),
        content: const Text(
          'سيستبدل هذا كل بيانات هذا الجهاز الحالية (علامات، خطط حفظ، سلاسل استمرار...) بمحتوى الملف المختار، ولا يمكن التراجع بعدها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    BackupRestoreResult result;
    try {
      result = await ref.read(userPrefsProvider).backup.pickAndInstallBackup();
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر استيراد النسخة الاحتياطية: $e')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case BackupRestoreResult.cancelled:
        return;
      case BackupRestoreResult.invalidFile:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الملف المختار ليس نسخة احتياطية صالحة لهذا الإصدار من التطبيق',
            ),
          ),
        );
        return;
      case BackupRestoreResult.success:
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تمّت الاستعادة'),
            content: const Text(
              'أُعيدت بياناتك بنجاح — أغلق التطبيق الآن وأعد فتحه ليظهر التغيير.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
    }
  }
}
