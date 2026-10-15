import 'package:flutter/material.dart';

import 'hifz_mushaf_screen.dart';

/// واجهة مراجعة وتثبيت الحفظ عبر المصحف الخاص المخصص [HifzMushafScreen]
class HifzReviewScreen extends StatelessWidget {
  const HifzReviewScreen({super.key, this.planId, this.initialPage});

  final int? planId;
  final int? initialPage;

  @override
  Widget build(BuildContext context) {
    return HifzMushafScreen(
      initialMode: HifzMushafMode.review,
      planId: planId,
      initialPage: initialPage,
    );
  }
}
