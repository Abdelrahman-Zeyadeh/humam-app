import 'package:flutter/material.dart';

import 'hifz_mushaf_screen.dart';

/// واجهة اختبار الحفظ عبر المصحف الخاص المخصص [HifzMushafScreen]
class HifzQuizScreen extends StatelessWidget {
  const HifzQuizScreen({super.key, this.initialSurahId});

  final int? initialSurahId;

  @override
  Widget build(BuildContext context) {
    return HifzMushafScreen(
      initialMode: HifzMushafMode.quiz,
      initialSurahId: initialSurahId,
    );
  }
}
