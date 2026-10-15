import 'package:flutter/material.dart';

import 'hifz_center_screen.dart';

/// واجهة خريطة إتقان الحفظ الموحدة ضمن [HifzCenterScreen]
class HifzHeatmapScreen extends StatelessWidget {
  const HifzHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HifzCenterScreen(
      initialTab: 2,
    );
  }
}
