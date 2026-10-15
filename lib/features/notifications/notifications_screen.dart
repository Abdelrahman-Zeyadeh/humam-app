import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../azkar/azkar_repository.dart';
import '../azkar/azkar_screen.dart';
import '../khatma/khatma_screen.dart';
import '../mushaf/mushaf_screen.dart';
import '../prayer/prayer_screen.dart';
import 'notification_history_service.dart';

/// شاشة الإشعارات مطابقة تماماً للتصميم المعتمد في الصورة
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final allNotifications = ref.watch(notificationHistoryProvider);

    // فلترة الإشعارات بحسب الفئة المختارة
    final filteredNotifications = allNotifications.where((item) {
      if (_selectedCategory == NotificationCategory.all) return true;
      final cat = NotificationCategory.fromString(item.category);
      return cat == _selectedCategory;
    }).toList();

    final bgColor = isDark ? const Color(0xFF12171F) : const Color(0xFFFBF8F2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الإشعارات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded, color: onSurface, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),

          // شريط أزرار الإجراءات العلوية: تمييز الكل / تحديث / حذف الكل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // حذف الكل
                _TopActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'حذف الكل',
                  textColor: const Color(0xFFE55353),
                  bgColor: isDark
                      ? const Color(0xFF381E1E)
                      : const Color(0xFFFFEEEE),
                  borderColor: const Color(0xFFE55353).withValues(alpha: 0.25),
                  onTap: () => _confirmClearAll(context),
                ),
                const Spacer(),

                // تحديث
                _TopActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'تحديث',
                  textColor: isDark ? const Color(0xFF8CD8B8) : const Color(0xFF2E8B57),
                  bgColor: isDark
                      ? const Color(0xFF183328)
                      : const Color(0xFFEAF7EE),
                  borderColor: const Color(0xFF2E8B57).withValues(alpha: 0.25),
                  onTap: () {
                    ref.read(notificationHistoryProvider.notifier).refresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث قائمة الإشعارات'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // تمييز الكل
                _TopActionButton(
                  icon: Icons.done_all_rounded,
                  label: 'تمييز الكل',
                  textColor: isDark ? const Color(0xFFDCC89E) : const Color(0xFF7A5C38),
                  bgColor: isDark
                      ? const Color(0xFF2E261B)
                      : const Color(0xFFF3ECE0),
                  borderColor: const Color(0xFF7A5C38).withValues(alpha: 0.25),
                  onTap: () {
                    ref.read(notificationHistoryProvider.notifier).markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تمييز كل الإشعارات كمقروءة'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // شريط تبويبات الفئات
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              reverse: true, // RTL
              children: [
                _CategoryChip(
                  label: 'الكل',
                  isSelected: _selectedCategory == NotificationCategory.all,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.all),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'الصلاة',
                  isSelected: _selectedCategory == NotificationCategory.prayer,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.prayer),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'الأذكار',
                  isSelected: _selectedCategory == NotificationCategory.azkar,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.azkar),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'القرآن',
                  isSelected: _selectedCategory == NotificationCategory.quran,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.quran),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'المناسبات',
                  isSelected: _selectedCategory == NotificationCategory.occasions,
                  onTap: () => setState(() => _selectedCategory = NotificationCategory.occasions),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // قائمة الإشعارات
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 54,
                          color: onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد إشعارات في هذا القسم',
                          style: TextStyle(
                            fontSize: 15,
                            color: onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final item = filteredNotifications[index];
                      return _NotificationCard(
                        item: item,
                        onTap: () => _handleNotificationTap(context, ref, item),
                      );
                    },
                  ),
          ),

          // الملاحظة السفلية: تختفي الإشعارات تلقائياً بعد انقضاء وقتها
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Text(
                  'تختفي الإشعارات تلقائياً بعد انقضاء وقتها',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotificationItem item,
  ) {
    // تمييز كمقروء
    ref.read(notificationHistoryProvider.notifier).markAsRead(item.id);

    // توجيه ذكي حسب محتوى الإشعار
    final title = item.title;
    if (title.contains('المساء')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AzkarScreen(period: AzkarPeriod.evening),
        ),
      );
    } else if (title.contains('الصباح')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AzkarScreen(period: AzkarPeriod.morning),
        ),
      );
    } else if (item.category == 'prayer' || title.contains('صلاة')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PrayerScreen(),
        ),
      );
    } else if (title.contains('ختمتك') || title.contains('الختمة')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const KhatmaScreen(),
        ),
      );
    } else if (item.category == 'quran') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MushafScreen(),
        ),
      );
    }
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف جميع الإشعارات', textDirection: TextDirection.rtl),
        content: const Text(
          'هل تريد بالتأكيد مسح كافة سجل الإشعارات؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE55353),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(notificationHistoryProvider.notifier).clearAll();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

/// زر إجراء علوي صغير (تمييز الكل / تحديث / حذف)
class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريحة فلترة الفئات (الكل / الصلاة / الأذكار / القرآن / المناسبات)
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFFB58E58) : const Color(0xFF7A5C38);
    final inactiveBg = isDark ? const Color(0xFF1E2733) : const Color(0xFFF2ECE1);
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF4A443C);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : inactiveText,
          ),
        ),
      ),
    );
  }
}

/// بطاقة الإشعار المفردة كما بالصورة المرفقة
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final AppNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final cardBg = isDark ? const Color(0xFF1B232D) : const Color(0xFFFBF8F2);
    final borderColor = isDark ? const Color(0xFF2C394A) : const Color(0xFFE9DFD0);

    // تنسيق التاريخ والساعة
    final formattedDate = _formatTimestamp(item.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نقطة التنبيه غير المقروءة على اليسار
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isRead
                        ? Colors.transparent
                        : (isDark ? const Color(0xFFD6A868) : const Color(0xFF8C6239)),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // محتوى الإشعار: العنوان + النص + التاريخ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // أيقونة الفئة على اليمين داخل مربع بيج ناعم
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF273240) : const Color(0xFFF1E8DA),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _categoryIcon(item.category),
                  size: 22,
                  color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6D3F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'prayer':
      case 'salah':
        return Icons.mosque_outlined;
      case 'quran':
      case 'khatma':
        return Icons.auto_stories_rounded;
      case 'occasions':
      case 'hadith':
        return Icons.event_note_rounded;
      case 'azkar':
      default:
        return Icons.menu_book_rounded;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    // يعرض التاريخ والساعة بدقة كما طلب المستخدم: "بقلك شو بعث التطبيق اشعارات وباي ساعة"
    return '$y/$m/$d • $h:$min $period';
  }
}
