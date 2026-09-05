import 'package:flutter/material.dart';

/// كرت "فوائد وتأملات نبوية": يعرض الدروس المستنبطة من الحديث الحالي
/// مرقّمة بشكل عمودي.
class DailyHadithFawaidCard extends StatelessWidget {
  const DailyHadithFawaidCard({super.key, required this.fawaid});

  final List<String> fawaid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : const Color(0xFFFAF7EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.25 : 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFFC89218), size: 20),
              SizedBox(width: 8),
              Text(
                'فوائد وتأملات نبوية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC89218),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (i, item) in fawaid.indexed) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC89218)),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
