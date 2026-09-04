import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'cloud_sync_service.dart';

/// نافذة تسجيل الدخول / إنشاء حساب للمزامنة السحابية
class AuthDialog extends ConsumerStatefulWidget {
  const AuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AuthDialog(),
    );
  }

  @override
  ConsumerState<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<AuthDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || (_isRegister && name.isEmpty)) {
      setState(() => _error = 'يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final controller = ref.read(cloudSyncControllerProvider.notifier);
    final success = _isRegister
        ? await controller.registerWithEmail(email, pass, name)
        : await controller.signInWithEmail(email, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isRegister ? 'تم إنشاء الحساب ومزامنة البيانات بنجاح ☁️' : 'تم تسجيل الدخول بنجاح ☁️'),
          backgroundColor: const Color(0xFF1B8A72),
        ),
      );
    } else {
      final state = ref.read(cloudSyncControllerProvider);
      setState(() => _error = state.errorMessage ?? 'حدث خطأ أثناء العملية');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.cloud_sync_outlined, color: themeAccent(context)),
          const SizedBox(width: 10),
          Text(
            _isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول للمزامنة',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'احفظ تقدمك وسلاسل الاستمرار والفواصل سحابياً لمزامنتها مع أجهزتك الأخرى بأمان.',
              style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 16),
            // زر المتابعة بحساب Google
            OutlinedButton(
              onPressed: _isLoading ? null : () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                final controller = ref.read(cloudSyncControllerProvider.notifier);
                final success = await controller.signInWithGoogle();
                if (!mounted) return;
                setState(() => _isLoading = false);
                if (success) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('تم تسجيل الدخول بحساب Google بنجاح ☁️'),
                      backgroundColor: Color(0xFF1B8A72),
                    ),
                  );
                } else {
                  final state = ref.read(cloudSyncControllerProvider);
                  if (state.errorMessage != null) {
                    setState(() => _error = state.errorMessage);
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    'المتابعة باستخدام Google',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: onSurface.withValues(alpha: 0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'أو بالبريد الإلكتروني',
                    style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                  ),
                ),
                Expanded(child: Divider(color: onSurface.withValues(alpha: 0.2))),
              ],
            ),
            const SizedBox(height: 14),
            if (_isRegister) ...[
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'الاسم أو اللقب',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _isRegister = !_isRegister;
                _error = null;
              }),
              child: Text(
                _isRegister ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب جديد',
                style: TextStyle(fontSize: 12.5, color: themeAccent(context)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isRegister ? 'إنشاء الحساب' : 'دخول'),
        ),
      ],
    );
  }
}
