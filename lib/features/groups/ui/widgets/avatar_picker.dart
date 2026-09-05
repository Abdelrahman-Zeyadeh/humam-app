import 'package:flutter/material.dart';

import '../../models/group_avatars.dart';

/// شبكة اختيار أفاتار بسيطة (أيقونة+لون من `kGroupAvatarPresets`) —
/// تُستخدَم بحواري إنشاء/الانضمام لمجموعة معاً، نفس عرض الأفاتار المطبَّق
/// بشاشة تفاصيل المجموعة (`group_details_screen.dart`) عبر [groupAvatarByIndex].
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < kGroupAvatarPresets.length; i++)
          _AvatarChoice(
            preset: kGroupAvatarPresets[i],
            isSelected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final GroupAvatarPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: preset.color.withValues(alpha: isSelected ? 1 : 0.15),
          border: Border.all(color: preset.color, width: isSelected ? 2.5 : 1),
        ),
        child: Icon(
          preset.icon,
          color: isSelected ? Colors.white : preset.color,
          size: 20,
        ),
      ),
    );
  }
}
