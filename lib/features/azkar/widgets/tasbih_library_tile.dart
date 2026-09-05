import 'package:flutter/material.dart';

import 'tasbih_library_data.dart';

/// صف سبحة واحدة بشيت الاختيار (`tasbih_phrase_picker.dart`) — عرض عمودي
/// كامل العرض (بدل بطاقة ضيقة ١٥٥ بيكسل بالشريط الأفقي القديم) فيه مساحة
/// كافية لعرض النص والهدف وآخر إتمام معاً بلا اقتطاع.
class TasbihLibraryItemTile extends StatelessWidget {
  const TasbihLibraryItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.lastLabel,
    required this.accent,
    required this.surface,
    required this.border,
    required this.fg,
    required this.onTap,
  });

  final TasbihLibraryItem item;
  final bool isSelected;
  final String lastLabel;
  final Color accent;
  final Color surface;
  final Color border;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.12) : surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: isSelected ? accent : fg.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? accent : fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: fg.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'الهدف ${item.target}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
