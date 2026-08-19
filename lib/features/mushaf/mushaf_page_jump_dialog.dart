import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mushaf_screen.dart' show kMushafPageCount;

/// حوار صغير لكتابة رقم صفحة (١-٦٠٤) والقفز إليها مباشرة.
class MushafPageJumpDialog extends StatefulWidget {
  const MushafPageJumpDialog({super.key});

  static Future<int?> show(BuildContext context) {
    return showDialog<int>(context: context, builder: (_) => const MushafPageJumpDialog());
  }

  @override
  State<MushafPageJumpDialog> createState() => _MushafPageJumpDialogState();
}

class _MushafPageJumpDialogState extends State<MushafPageJumpDialog> {
  final _controller = TextEditingController();
  String? _error;

  void _submit() {
    final page = int.tryParse(_controller.text.trim());
    if (page == null || page < 1 || page > kMushafPageCount) {
      setState(() => _error = 'رقم الصفحة بين ١ و $kMushafPageCount');
      return;
    }
    Navigator.of(context).pop(page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الانتقال إلى صفحة'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(hintText: '١-$kMushafPageCount', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(onPressed: _submit, child: const Text('انتقال')),
      ],
    );
  }
}
