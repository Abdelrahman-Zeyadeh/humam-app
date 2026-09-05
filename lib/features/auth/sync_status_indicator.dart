import 'package:flutter/material.dart';

import 'cloud_sync_service.dart';

/// "منذ ٥ دقائق"/"منذ ساعتين"/"أمس"... من فرق زمني — دقّة يوم فما فوق،
/// وإلا دقائق/ساعات. يكفي لعرض "آخر مزامنة" (لا حاجة لثوانٍ دقيقة هون).
String _relativeArabicTime(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} ${diff.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ${diff.inHours == 1 ? 'ساعة' : 'ساعات'}';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
  return 'منذ فترة';
}

/// سطر حالة مزامنة صغير — "جارٍ المزامنة"/"آخر مزامنة: منذ ٥ دقائق"/
/// "تعذّرت المزامنة" مع زر إعادة محاولة. كان `syncState.status`/
/// `errorMessage`/`lastSyncedAt` (بـ[CloudSyncState]) محسوبين أصلاً بـ
/// `CloudSyncController` بلا أي عرض بالواجهة — المستخدم ما كان يعرف لو
/// فشلت مزامنة بصمت. يُستخدَم بكل مكان يعرض حالة السحابة
/// (`account_data_section.dart` بالإعدادات، `cloud_sync_card.dart`
/// بالملف الشخصي) بدل تكرار نفس المنطق بكل واحد لحاله.
///
/// لا يعرض شيئاً لو المستخدم غير مسجَّل دخول (`isSignedIn == false`) —
/// لا حالة مزامنة ذات معنى قبل تسجيل الدخول.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.syncState,
    required this.onRetry,
  });

  final CloudSyncState syncState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!syncState.isSignedIn) return const SizedBox.shrink();

    final onSurface = Theme.of(context).colorScheme.onSurface;

    switch (syncState.status) {
      case CloudSyncStatus.syncing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(strokeWidth: 1.6),
            ),
            const SizedBox(width: 6),
            Text(
              'جارٍ المزامنة...',
              style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.6)),
            ),
          ],
        );

      case CloudSyncStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 13, color: Color(0xFFB3261E)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                syncState.errorMessage ?? 'تعذّرت المزامنة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFFB3261E)),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 10.5)),
            ),
          ],
        );

      case CloudSyncStatus.success:
      case CloudSyncStatus.idle:
        final lastSyncedAt = syncState.lastSyncedAt;
        if (lastSyncedAt == null) return const SizedBox.shrink();
        return Text(
          'آخر مزامنة: ${_relativeArabicTime(lastSyncedAt, DateTime.now())}',
          style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.5)),
        );
    }
  }
}
