import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// شاشة سياسة الخصوصية — توثّق بشفافية ومصداقية كاملة طبيعة البيانات
/// المحلية والسحابية والخدمات الخارجية المستخدَمة فعلياً في تطبيق هُمَام.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2430) : const Color(0xFFF6F3EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.lineDark : AppColors.line,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.goldDeep, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'ميثاق الخصوصية والشفافية في هُمَام',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'تطبيق هُمَام صُمّم بمبدأ "المحلي أولاً" ليكون رفيقك الإيماني الآمن. نحترم خصوصيتك احتراماً تاماً ولا نبيع بياناتك ولا نستخدم أي شبكات إعلانية أو متعقبات تجارية إطلاقاً.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PolicySection(
              number: '١',
              title: 'البيانات التي تُجمع',
              content:
                  'يقتصر جمع البيانات على ما يخدم ميزات التطبيق حصراً:\n'
                  '• إحصائيات العبادة الذاتية: سجلات القراءة، الدقائق الصوتية، عدادات التسبيح، خطط الختمة والحفظ.\n'
                  '• إعدادات التخصيص: أحجام الخطوط، المظهر، خيارات التذكيرات، وقوائم المفضلة.\n'
                  '• بيانات الحساب (اختيارية): الاسم والبريد الإلكتروني ومعرف الحساب عند تسجيل الدخول للمزامنة.',
            ),
            _PolicySection(
              number: '٢',
              title: 'البيانات المحلية (على جهازك)',
              content:
                  '• كافة سجلات القراءة والتسبيح والخطط والملاحظات تُخزن محلياً في قاعدة بيانات SQLite داخل هاتفك.\n'
                  '• حساب مواقيت الصلاة والقبلة يتم محلياً بالكامل (عبر adhan_dart) دون إرسال إحداثياتك الجغرافية لأي خادم.\n'
                  '• البحث في المصحف والأدوات يعمل محلياً بلا اتصال بالإنترنت.',
            ),
            _PolicySection(
              number: '٣',
              title: 'المزامنة السحابية (Cloud Sync)',
              content:
                  'إذا اخترت تسجيل الدخول، يُرفع ملخص احتياطي لتقدمك في الحفظ والختمات والعلامات المرجعية وسلاسل الاستمرار إلى خوادم Firestore الخاصة بالتطبيق، حتى تتمكن من استعادتها عند تغيير هاتفك.',
            ),
            _PolicySection(
              number: '٤',
              title: 'خدمات Firebase',
              content:
                  '• Firebase Authentication: للتحقق الآمن من الهوية وحماية حسابك.\n'
                  '• Cloud Firestore: لقواعد بيانات المزامنة السحابية ومجموعات التنافس.\n'
                  '• Firebase Crashlytics: لتتبع أعطال التطبيق المفاجئة برمجياً وتحسين استقرار التطبيق دون جمع أي بيانات شخصية.',
            ),
            _PolicySection(
              number: '٥',
              title: 'تسجيل الدخول عبر Google',
              content:
                  'نستخدم واجهة Google Sign-In المعتمدة رسمياً للحصول على رمز مصادقة آمن. لا يطّلع التطبيق على جهات اتصالك أو بريدك الإلكتروني الشخصي ولا نطلب أي أذونات تتجاوز المصادقة الأساسية.',
            ),
            _PolicySection(
              number: '٦',
              title: 'بيانات المجموعات والتنافس',
              content:
                  'عند انضمامك إلى مجموعات الصحبة، يظهر لأعضاء المجموعة فقط اسمك وصورتك الرمزية وتقدمك الإيماني التنافسي، لتحقيق التعاون على البر والتقوى. يمكنك مغادرة أي مجموعة في أي وقت.',
            ),
            _PolicySection(
              number: '٧',
              title: 'الخدمات الخارجية والطرف الثالث',
              content:
                  '• التحقق من صحة الحديث: يرسل الاستعلام لموسوعة الدرر السنية الموثوقة (dorar.net) لجلب التخريج والحكم.\n'
                  '• التلاوات الصوتية: يتم بث الصوت مباشرة من خوادم EveryAyah و Mp3Quran المفتوحة.\n'
                  '• لا توجد أي خدمات تتبع إعلاني أو تسويقي طرف ثالث.',
            ),
            _PolicySection(
              number: '٨',
              title: 'حذف الحساب وإدارة البيانات',
              content:
                  '• البيانات المحلية: يمكنك حذفها أو إعادة ضبطها في أي وقت عبر إعدادات التطبيق أو مسح التخزين.\n'
                  '• حذف الحساب السحابي: يتوفر زر طلب حذف الحساب والبيانات السحابية داخل قسم الخصوصية، ويجري العمل على إتمام الربط البرمجي الشامل لكافة الجداول السحابية لضمان الحذف التام والآمن.',
            ),
            _PolicySection(
              number: '٩',
              title: 'الأمان والسرية',
              content:
                  'نعتمد تشفير اتصالات TLS/HTTPS لكافة الطلبات الشبكية، ونطبق قواعد أمان مشددة على خوادم السحاب تمنع أي مستخدم من الوصول إلى بيانات غيره.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.number,
    required this.title,
    required this.content,
  });

  final String number;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1E2630) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.line,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
