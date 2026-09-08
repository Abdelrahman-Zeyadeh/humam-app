import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'join_group_dialog.dart';

/// شاشة وسيطة شفافة يفتحها `DeepLinkService` عبر `navigatorKey` (بلا
/// `WidgetRef` جاهز بتلك النقطة) — بمجرّد بنائها تفتح حوار الانضمام
/// (`showJoinGroupDialog`) فوراً برمز الدعوة، ثم تُغلَق نفسها (تُزال من
/// المكدّس) سواء أكمل المستخدم الانضمام أو ألغاه، فلا تترك شاشة فارغة خلف
/// الحوار.
class JoinGroupDialogRoute extends ConsumerStatefulWidget {
  const JoinGroupDialogRoute({super.key, required this.initialCode});

  final String initialCode;

  @override
  ConsumerState<JoinGroupDialogRoute> createState() => _JoinGroupDialogRouteState();
}

class _JoinGroupDialogRouteState extends ConsumerState<JoinGroupDialogRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final myRoute = ModalRoute.of(context);
      await showJoinGroupDialog(context, ref, initialCode: widget.initialCode);
      // إزالة **مستهدَفة** لهذا الراوت تحديداً (لا `pop()` العادي) — عند
      // نجاح الانضمام يكون `showJoinGroupDialog` قد دفع `GroupDetailsScreen`
      // فوق هذا الراوت أصلاً، فـ`pop()` كان سيزيلها هي بالخطأ بدل هذا
      // الراوت الوسيط الشفاف.
      if (mounted && myRoute != null) {
        Navigator.of(context).removeRoute(myRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.transparent,
    body: SizedBox.shrink(),
  );
}
