import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/groups/ui/widgets/join_group_dialog_route.dart';

/// **رابط دعوة مباشر لمجموعات الصحبة** — بطلب "دعوة صديق بلينك مباشر":
/// مشاركة رمز المجموعة نصّاً فقط (الحال القديم بـ`group_details_screen.
/// dart._shareGroupCode`) يحتاج من المدعوّ نسخ الرمز يدوياً وفتح التطبيق
/// وإيجاد زر "انضمام" بنفسه. رابط `humam://join/<code>` بدل ذلك: أي نقرة
/// عليه (واتساب/رسائل/أي تطبيق) تفتح هُمَام مباشرة على حوار الانضمام
/// بالرمز مُعبَّأً مسبقاً.
///
/// **قيد معروف**: بلا رابط ويب حقيقي (`https://...`) لا يوجد سيرفر يستضيف
/// صفحة تطبيق — الرابط مخصَّص `scheme` (`humam://`) لا نطاقاً فعلياً، فلا
/// يعمل بمتصفح لا يعرفه (يفشل بصمت أو يعرض خطأ "تعذّر فتح الرابط" حسب
/// التطبيق المرسِل)، لكنه يعمل بشكل طبيعي وموثوق داخل واتساب/تيليجرام/
/// الرسائل النصية على جهاز عليه هُمَام مثبَّتاً فعلاً (هدف الميزة الأساسي:
/// دعوة صديق لديه التطبيق أصلاً، أو سيُثبّته بعد فتح الرابط عبر متجر
/// التطبيقات ثم إعادة النقر عليه).
class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  final _appLinks = AppLinks();
  GlobalKey<NavigatorState>? _navigatorKey;

  /// يُستدعى مرّة واحدة من `main.dart` بعد بناء `MaterialApp` (يحتاج
  /// `navigatorKey` جاهزاً للتنقّل بلا `BuildContext` محلي). يتحقّق من رابط
  /// أطلق التطبيق أصلاً (`getInitialLink`، تطبيق كان مغلقاً تماماً) ثم
  /// يستمع لأي رابط لاحق أثناء عمل التطبيق (`uriLinkStream`).
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      debugPrint('DeepLinkService.getInitialLink فشل: $e');
    }
    _appLinks.uriLinkStream.listen(_handle, onError: (e) {
      debugPrint('DeepLinkService.uriLinkStream خطأ: $e');
    });
  }

  void _handle(Uri uri) {
    // `humam://join/<code>` فقط حالياً — أي رابط آخر (مثل launch
    // `home_widget` المسجَّل بنفس الـscheme بالمانفست) يُتجاهَل هنا بصمت.
    if (uri.scheme != 'humam' || uri.host != 'join') return;
    if (uri.pathSegments.isEmpty) return;
    final code = uri.pathSegments.first.trim();
    if (code.isEmpty) return;

    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => JoinGroupDialogRoute(initialCode: code)));
  }
}
