import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/platform/floating_dhikr_service.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/adhan_notification_service.dart';

/// مركز إدارة وتوضيح وتفعيل أذونات وصلاحيات تطبيق هُمَام
/// يتيح للمستخدم فهم حاجة كل إذن، معرفة حالته الحالية، وتفعيله مباشرة بنقرة واحدة من نفس الصفحة.
class PermissionsGuideScreen extends ConsumerStatefulWidget {
  const PermissionsGuideScreen({super.key});

  @override
  ConsumerState<PermissionsGuideScreen> createState() =>
      _PermissionsGuideScreenState();
}

class _PermissionsGuideScreenState extends ConsumerState<PermissionsGuideScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _notifsGranted = false;
  bool _locationGranted = false;
  bool _exactAlarmsGranted = false;
  bool _overlayGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    try {
      final notifs =
          await AdhanNotificationService.instance.areNotificationsEnabled();
      final exactAlarms = await AdhanNotificationService.instance
          .canScheduleExactNotifications();

      final locPerm = await Geolocator.checkPermission();
      final loc =
          locPerm == LocationPermission.always ||
          locPerm == LocationPermission.whileInUse;

      final overlay = await FloatingDhikrService.canDrawOverlays();

      if (mounted) {
        setState(() {
          _notifsGranted = notifs;
          _exactAlarmsGranted = exactAlarms;
          _locationGranted = loc;
          _overlayGranted = overlay;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestOverlayPermission() async {
    await FloatingDhikrService.requestOverlayPermission();
    await Future.delayed(const Duration(milliseconds: 400));
    await _checkAllPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _overlayGranted
                ? 'تم تفعيل إذن الظهور فوق التطبيقات بنجاح ✓'
                : 'يرجى تفعيل خيار الظهور فوق التطبيقات من الإعدادات الظاهرة',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    await AdhanNotificationService.instance.requestPermissions();
    await Future.delayed(const Duration(milliseconds: 400));
    await _checkAllPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notifsGranted
                ? 'تم تفعيل إذن الإشعارات بنجاح ✓'
                : 'إذا لم تظهر نافذة الإذن، يرجى تفعيله من إعدادات النظام بالأسفل',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    final perm = await Geolocator.requestPermission();
    await _checkAllPermissions();
    if (mounted) {
      final granted =
          perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'تم تفعيل إذن الموقع الجغرافي بنجاح ✓'
                : 'تم رفض إذن الموقع، يمكنك إدخال مدينتك يدوياً أو تفعيله من الإعدادات',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);

    final totalCount = FloatingDhikrService.isSupported ? 4 : 3;
    final grantedCount =
        (_notifsGranted ? 1 : 0) +
        (_locationGranted ? 1 : 0) +
        (_exactAlarmsGranted ? 1 : 0) +
        (FloatingDhikrService.isSupported && _overlayGranted ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أذونات وصلاحيات التطبيق',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث حالة الأذونات',
            onPressed: () {
              setState(() => _loading = true);
              _checkAllPermissions();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                // 1. بطاقة أمان وشفافية الخصوصية
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: accent,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أمانك وخصوصيتك أولويتنا المطلقة',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'لا يجمع هُمَام أي بيانات شخصية أو يتتبع نشاطك. الأذونات مطلوبة فقط محلياً على جهازك لتشغيل الأذان الصوتي ومواقيت الصلاة الدقيقة وبوصلة القبلة.',
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.withValues(alpha: 0.85),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // شريط ملخص حالة الأذونات
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الأذونات الأساسية',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (grantedCount == totalCount
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100))
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$grantedCount من $totalCount مفعلة',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: grantedCount == totalCount
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 1. كرت إذن الإشعارات والأذان
                _InteractivePermissionCard(
                  isDark: isDark,
                  onSurface: onSurface,
                  title: 'إذن الإشعارات والأذان الصوتي',
                  desc:
                      'ضروري لإطلاق الأذان عند كل صلاة، وتنبيهات أذكار الصباح والمساء، وتذكيرات صيام التطوع (الإثنين والخميس والأيام البيض) والورد اليومي.',
                  icon: Icons.notifications_active_rounded,
                  accentColor: const Color(0xFF1B8A72),
                  isGranted: _notifsGranted,
                  actionLabel:
                      _notifsGranted ? 'الإذن مفعّل ✓' : 'تفعيل الإذن الآن',
                  onAction: _requestNotificationPermission,
                ),
                const SizedBox(height: 12),

                // 2. كرت إذن الموقع الجغرافي (GPS)
                _InteractivePermissionCard(
                  isDark: isDark,
                  onSurface: onSurface,
                  title: 'إذن الموقع الجغرافي (GPS)',
                  desc:
                      'يُستخدم لتحديد إحداثيات موقعك بدقة لحساب مواقيت الصلاة الفلكية الدقيقة لمدينتك، وتوجيه بوصلة القبلة نحو الكعبة المشرفة بدقة تامة.',
                  icon: Icons.location_on_rounded,
                  accentColor: const Color(0xFF1976D2),
                  isGranted: _locationGranted,
                  actionLabel:
                      _locationGranted ? 'الموقع مفعّل ✓' : 'تفعيل إذن الموقع',
                  onAction: _requestLocationPermission,
                ),
                const SizedBox(height: 12),

                // 3. كرت المنبهات والمواقيت الدقيقة
                _InteractivePermissionCard(
                  isDark: isDark,
                  onSurface: onSurface,
                  title: 'المنبهات والمواقيت الدقيقة (Exact Alarms)',
                  desc:
                      'يسمح لنظام أندرويد بإطلاق الأذان في وقته بالثانية بالضبط حتى لو كان الهاتف مقفلاً أو في وضع السكون العميق (Doze Mode).',
                  icon: Icons.alarm_on_rounded,
                  accentColor: const Color(0xFF8E24AA),
                  isGranted: _exactAlarmsGranted,
                  actionLabel: _exactAlarmsGranted
                      ? 'المنبهات جاهزة ✓'
                      : 'ضبط المنبهات الدقيقة',
                  onAction: () async {
                    await Geolocator.openAppSettings();
                  },
                ),
                if (FloatingDhikrService.isSupported) ...[
                  const SizedBox(height: 12),
                  // 4. كرت إذن الظهور فوق التطبيقات (للذكر العائم)
                  _InteractivePermissionCard(
                    isDark: isDark,
                    onSurface: onSurface,
                    title: 'إذن الظهور فوق التطبيقات (للذكر العائم)',
                    desc:
                        'يتيح تشغيل كبسولة التسبيح والذكر العائمة الذكية أثناء تصفحك للتطبيقات الأخرى، لتستمر في ذكر الله دون الحاجة لفتح التطبيق.',
                    icon: Icons.layers_rounded,
                    accentColor: const Color(0xFF5C6BC0),
                    isGranted: _overlayGranted,
                    actionLabel: _overlayGranted
                        ? 'الظهور مفعّل ✓'
                        : 'تفعيل الظهور فوق التطبيقات',
                    onAction: _requestOverlayPermission,
                  ),
                ],
                const SizedBox(height: 20),

                // 4. قسم تحسين البطارية حسب نوع الجهاز
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'استثناء من توفير البطارية (لضمان سماع الفجر)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2836) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.lineDark : AppColors.line,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.battery_saver_rounded,
                            color: Color(0xFFE5A93C),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'إرشادات ضبط البطارية حسب نوع هاتفك',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'تقوم بعض الهواتف بوضع التطبيقات في السكون لتوفير الطاقة. اختر نوع هاتفك لاتباع الخطوات البسيطة لضمان عمل الأذان دائماً:',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      const Divider(height: 20),
                      _vendorTile(
                        brand: 'هواتف سامسونج (Samsung)',
                        steps:
                            'الضبط ← التطبيقات ← هُمَام ← البطارية ← اختر "غير مقيد" (Unrestricted).',
                      ),
                      const Divider(height: 16),
                      _vendorTile(
                        brand: 'هواتف شاومي وبوكو وريدمي (Xiaomi / POCO / Redmi)',
                        steps:
                            'الإعدادات ← التطبيقات ← هُمَام ← التشغيل التلقائي (مفعّل) ← موفر البطارية: "لا توجد قيود".',
                      ),
                      const Divider(height: 16),
                      _vendorTile(
                        brand: 'هواتف هواوي وهونر (Huawei / Honor)',
                        steps:
                            'الإعدادات ← البطارية ← بدء تشغيل التطبيقات ← هُمَام ← عطّل الإدارة التلقائية، وفعّل العمل بالخلفية.',
                      ),
                      const Divider(height: 16),
                      _vendorTile(
                        brand: 'هواتف أوبو وريلمي ووان بلس (Oppo / Realme / OnePlus)',
                        steps:
                            'الإعدادات ← إدارة التطبيقات ← هُمَام ← البطارية ← السماح بالنشاط في الخلفية والتشغيل التلقائي.',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: const Text(
                            'فتح إعدادات هُمَام في نظام الهاتف',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => Geolocator.openAppSettings(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _vendorTile({required String brand, required String steps}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          brand,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B8A72),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          steps,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InteractivePermissionCard extends StatelessWidget {
  const _InteractivePermissionCard({
    required this.isDark,
    required this.onSurface,
    required this.title,
    required this.desc,
    required this.icon,
    required this.accentColor,
    required this.isGranted,
    required this.actionLabel,
    required this.onAction,
  });

  final bool isDark;
  final Color onSurface;
  final String title;
  final String desc;
  final IconData icon;
  final Color accentColor;
  final bool isGranted;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
              : (isDark ? AppColors.lineDark : AppColors.line),
          width: isGranted ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة: أيقونة + عنوان + شارة الحالة
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isGranted ? const Color(0xFF2E7D32) : accentColor)
                      .withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: isGranted ? const Color(0xFF2E7D32) : accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isGranted
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGranted
                          ? Icons.check_circle_rounded
                          : Icons.cancel_outlined,
                      size: 13,
                      color: isGranted
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGranted ? 'مفعّل' : 'غير مفعّل',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isGranted
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // الوصف
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.72),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),

          // زر التفعيل المباشر
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: isGranted
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'تم تفعيل الإذن بنجاح',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onAction,
                        child: const Text('إعادة فحص', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  )
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.touch_app_rounded, size: 15),
                    label: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: onAction,
                  ),
          ),
        ],
      ),
    );
  }
}
