import 'package:flutter/material.dart';

/// بطاقة إحصائية صغيرة (الدورات المكتملة / إجمالي التسبيحات) بأعلى شاشة
/// المسبحة — استُخرجت من `tasbih_screen.dart` أثناء تفكيكه بلا أي تغيير
/// سلوكي.
class TasbihStatBadge extends StatelessWidget {
  const TasbihStatBadge({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.border,
    required this.fg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color surface;
  final Color border;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: fg.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
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
