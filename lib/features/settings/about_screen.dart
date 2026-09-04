import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';

/// شاشة عن التطبيق والتوثيق والشفافية والتراخيص وسياسة الخصوصية
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عن هُمَام والمصادر', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // بطاقة الهوية والشعار
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [const Color(0xFF1E2836), const Color(0xFF131D2A)]
                    : [const Color(0xFF0B2545), const Color(0xFF164B7A)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A24B).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC9A24B), width: 2),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 38,
                    color: Color(0xFFC9A24B),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تطبيق هُمَام',
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'رفيقك اليومي للقرآن والعبادات • خفيف وسريع ومريح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'الإصدار 1.0.0 (نشر رسمي)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // فلسفة هُمَام
          _sectionTitle('فلسفة ورؤية التطبيق'),
          _CardContainer(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeatureBullet(
                  icon: Icons.offline_pin_outlined,
                  title: 'محلي بالكامل (Offline-First)',
                  desc: 'المصحف، المواقيت، الأذكار، والتفاسير تعمل بالكامل بدون إنترنت في المساجد والسفر.',
                ),
                _FeatureBullet(
                  icon: Icons.speed_rounded,
                  title: 'أداء فائق واستجابة لحظية',
                  desc: 'بناء تقني متطور بدون أي إعلانات مزعجة وبلا استهلاك للبطارية أو الذاكرة.',
                ),
                _FeatureBullet(
                  icon: Icons.shield_outlined,
                  title: 'خصوصية وأمان 100%',
                  desc: 'لا نقوم بتتبع موقعك أو جمع أي بيانات شخصية، وجميع معلوماتك مخزنة على جهازك حصراً.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // المصادر الدينية المعتمدة
          _sectionTitle('المصادر والبيانات المعتمدة'),
          _CardContainer(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SourceItem(
                  title: 'المصحف الشريف وخطوط QCF v2',
                  source: 'مجمع الملك فهد لطباعة المصحف الشريف بالمدينة المنورة برواية حفص عن عاصم (مصحف المدينة النبوية 604 صفحات).',
                ),
                const Divider(height: 20),
                _SourceItem(
                  title: 'التفاسير والعلوم القرآنية',
                  source: 'التفسير الميسر (مجمع الملك فهد)، تفسير السعدي، تفسير ابن كثير، تفسير الطبري (جامع البيان)، تفسير القرطبي (الجامع لأحكام القرآن)، تفسير البغوي (معالم التنزيل)، أضواء البيان (الشنقيطي)، تفسير ابن عثيمين، المختصر في التفسير، وتفسير الجلالين — إضافة إلى إعراب القرآن (الجدول لمحمود صافي، ودرويش، والإعراب الميسر) ومعاني الكلمات وغريب القرآن.',
                ),
                const Divider(height: 20),
                _SourceItem(
                  title: 'موسوعة الأحاديث النبوية',
                  source: 'صحيح البخاري، صحيح مسلم، سنن أبي داود، جامع الترمذي، سنن النسائي، سنن ابن ماجه، وموطأ مالك، مع توثيق الأبواب والأرقام.',
                ),
                const Divider(height: 20),
                _SourceItem(
                  title: 'الأذكار والمأثورات',
                  source: 'أذكار اليوم والليلة مستخرجة من الأحاديث النبوية الصحيحة والمحققة (صحيح الكلم الطيب، حصن المسلم).',
                ),
                const Divider(height: 20),
                _SourceItem(
                  title: 'حساب مواقيت الصلاة والقبلة',
                  source: 'معادلات فلكية دقيقة معتمدة وفق تقويم أم القرى بمكة المكرمة، رابطة العالم الإسلامي، والهيئات الفلكية الرسمية.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // التراخيص والمصادر المفتوحة
          _sectionTitle('التراخيص والبرمجيات'),
          _CardContainer(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.source_outlined, color: Color(0xFF2E8071)),
                  title: const Text('تراخيص المكتبات مفتوحة المصدر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('استعراض حزم وتراخيص Flutter و Dart المستخدمة في البناء', style: TextStyle(fontSize: 11.5)),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'هُمَام',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.menu_book_rounded, color: AppColors.goldDeep, size: 36),
                    ),
                  ),
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share_outlined, color: Color(0xFF386892)),
                  title: const Text('مشاركة التطبيق واحتساب الأجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('الدال على الخير كفاعله، شارك تطبيق هُمَام مع من تحب', style: TextStyle(fontSize: 11.5)),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'تطبيق «هُمَام» — رفيقك اليومي للقرآن ومواقيت الصلاة والأذكار، خفيف وسريع وبلا إنترنت ولا إعلانات 🌙✨',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // دعاء الختام
          Center(
            child: Text(
              'اللهم اجعل هذا العمل خالصاً لوجهك الكريم وانفع به الإسلام والمسلمين.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
        ),
      ),
      child: child,
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A24B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.goldDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceItem extends StatelessWidget {
  const _SourceItem({required this.title, required this.source});

  final String title;
  final String source;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.goldDeep,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          source,
          style: TextStyle(
            fontSize: 12,
            color: onSurface.withValues(alpha: 0.8),
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
