import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/adhan_notification_service.dart';
import '../prayer/prayer_location_controller.dart';
import '../shell/root_shell.dart';
import 'onboarding_screen.dart';

/// مفتاح SharedPreferences لتسجيل إتمام شاشة الأذونات الترحيبية
const String kPermissionsSeenKey = 'permissions_seen_v1';

/// شاشة الأذونات الترحيبية — تظهر عند أول تشغيل للتطبيق لتوضيح سبب كل إذن
/// وتمكين المستخدم من تفعيله مباشرة من نفس الشاشة بنقرة واحدة ودون الحاجة
/// للذهاب إلى إعدادات الجهاز.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _notificationsGranted = false;
  bool _locationGranted = false;
  bool _isChecking = true;
  bool _isRequestingNotifications = false;
  bool _isRequestingLocation = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    try {
      final notifs = await AdhanNotificationService.instance.areNotificationsEnabled();
      final locPermission = await Geolocator.checkPermission();
      final loc = locPermission == LocationPermission.whileInUse ||
          locPermission == LocationPermission.always;

      if (mounted) {
        setState(() {
          _notificationsGranted = notifs;
          _locationGranted = loc;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_notificationsGranted || _isRequestingNotifications) return;
    setState(() => _isRequestingNotifications = true);

    try {
      await AdhanNotificationService.instance.requestPermissions();
      final enabled = await AdhanNotificationService.instance.areNotificationsEnabled();
      if (mounted) {
        setState(() {
          _notificationsGranted = enabled;
          _isRequestingNotifications = false;
        });
      }
    } catch (e) {
      debugPrint('طلب إذن الإشعارات: $e');
      if (mounted) setState(() => _isRequestingNotifications = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    if (_locationGranted || _isRequestingLocation) return;
    setState(() => _isRequestingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خدمة الموقع (GPS) مغلقة على جهازك. يُرجى تشغيلها.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isRequestingLocation = false);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        try {
          Position? position = await Geolocator.getLastKnownPosition();
          position ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 4),
            ),
          );

          final locPrefs = ref.read(locationPrefsProvider);
          await locPrefs.setLocation(
            lat: position.latitude,
            lon: position.longitude,
            cityName: 'الموقع الحالي (GPS)',
          );
          ref.read(locationVersionProvider.notifier).bump();
        } catch (_) {}

        if (mounted) {
          setState(() {
            _locationGranted = true;
            _isRequestingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isRequestingLocation = false);
        }
      }
    } catch (e) {
      debugPrint('طلب إذن الموقع: $e');
      if (mounted) setState(() => _isRequestingLocation = false);
    }
  }

  Future<void> _requestAllPermissions() async {
    await _requestNotificationPermission();
    await _requestLocationPermission();
  }

  Future<void> _proceedToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPermissionsSeenKey, true);

    if (!mounted) return;
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      final seenOnboarding = prefs.getBool(kOnboardingSeenKey) ?? false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RootShell(startTour: !seenOnboarding),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allGranted = _notificationsGranted && _locationGranted;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C161D) : const Color(0xFFF7F9FB),
      body: SafeArea(
        child: _isChecking
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // الترويسة العلوية الترحيبية
                    const SizedBox(height: 12),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 38,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'أهلاً بك في هُمَام 🌿',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لتقديم تجربة إيمانية متكاملة ودقيقة، يحتاج التطبيق للأذونات الأساسية التالية. يمكنك تفعيلها بلمسة واحدة مباشرة من هنا:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // بطاقات الأذونات
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _PermissionCard(
                            isDark: isDark,
                            title: 'إذن التنبيهات والأذان',
                            reason:
                                'ضروري لإطلاق صوت الأذان في موعد كل صلاة بدقة، وتذكيرك بأذكار الصباح والمساء والورد اليومي دون تفويت.',
                            icon: Icons.notifications_active_rounded,
                            accentColor: AppColors.goldDeep,
                            isGranted: _notificationsGranted,
                            isLoading: _isRequestingNotifications,
                            onGrant: _requestNotificationPermission,
                          ),
                          const SizedBox(height: 14),
                          _PermissionCard(
                            isDark: isDark,
                            title: 'إذن الموقع الجغرافي (GPS)',
                            reason:
                                'ضروري لحساب مواقيت الصلاة الدقيقة لمدينتك تلقائياً، وتحديد اتجاه بوصلة القبلة نحو الكعبة المشرفة بدقة متناهية أينما كنت.',
                            icon: Icons.location_on_rounded,
                            accentColor: AppColors.teal,
                            isGranted: _locationGranted,
                            isLoading: _isRequestingLocation,
                            onGrant: _requestLocationPermission,
                          ),
                        ],
                      ),
                    ),

                    // أزرار المتابعة وتفعيل الكل
                    const SizedBox(height: 12),
                    if (!allGranted) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _requestAllPermissions,
                          icon: const Icon(Icons.bolt_rounded, size: 20),
                          label: const Text(
                            'تفعيل جميع الأذونات دفعة واحدة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            side: const BorderSide(color: AppColors.teal, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _proceedToApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allGranted ? AppColors.teal : AppColors.gold,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          allGranted ? 'الدخول إلى هُمَام' : 'متابعة إلى التطبيق',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    TextButton(
                      onPressed: _proceedToApp,
                      child: Text(
                        'تخطي مؤقتاً وسأفعّلها لاحقاً',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.isDark,
    required this.title,
    required this.reason,
    required this.icon,
    required this.accentColor,
    required this.isGranted,
    required this.isLoading,
    required this.onGrant,
  });

  final bool isDark;
  final String title;
  final String reason;
  final IconData icon;
  final Color accentColor;
  final bool isGranted;
  final bool isLoading;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
              : (isDark ? AppColors.lineDark : AppColors.line),
          width: isGranted ? 1.4 : 1.0,
        ),
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
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                      : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGranted ? Icons.check_circle_rounded : icon,
                  size: 22,
                  color: isGranted ? const Color(0xFF2E7D32) : accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
              if (isGranted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text(
                        'مُفعَّل',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: isLoading ? null : onGrant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'تفعيل الإذن',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reason,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
