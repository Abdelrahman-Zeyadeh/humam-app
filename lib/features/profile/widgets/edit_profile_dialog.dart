import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/cloud_sync_service.dart';

/// حوار تعديل الاسم/الصورة الشخصية — يُفتح من رأس شاشة الملف الشخصي
/// والإحصائيات.
void showEditProfileDialog(
  BuildContext context,
  WidgetRef ref,
  String currentName,
  String currentAvatar, {
  required VoidCallback onSaved,
}) {
  final nameCtrl = TextEditingController(
    text: currentName == 'مستخدم هُمَام' ? '' : currentName,
  );
  var avatarPath = currentAvatar;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 24, color: AppColors.goldDeep),
            SizedBox(width: 8),
            Text(
              'تعديل الملف الشخصي',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.navy,
                      backgroundImage:
                          avatarPath.isNotEmpty && File(avatarPath).existsSync()
                          ? FileImage(File(avatarPath))
                          : null,
                      child: (avatarPath.isEmpty || !File(avatarPath).existsSync())
                          ? Text(
                              currentName.isNotEmpty ? currentName[0] : 'م',
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: themeAccent(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('صورة من المعرض'),
                    onPressed: () async {
                      try {
                        final picked = await FilePicker.pickFile(
                          type: FileType.image,
                        );
                        final rawPath = picked?.path;
                        if (rawPath != null) {
                          // تصغير/ضغط الصورة قبل حفظها محلياً — هذا نفس
                          // الملف اللي بيترفع لاحقاً Base64 للمزامنة
                          // السحابية (راجع cloud_sync_service.dart)، فلازم
                          // يبقى صغيراً بغضّ النظر عن حجم الصورة الأصلية
                          // (قد تكون عدة ميجابايتات من كاميرا حقيقية).
                          final decoded = img.decodeImage(
                            await File(rawPath).readAsBytes(),
                          );
                          if (decoded == null) {
                            throw Exception('صيغة صورة غير مدعومة');
                          }
                          final resized =
                              (decoded.width > 512 || decoded.height > 512)
                              ? img.copyResize(
                                  decoded,
                                  width: decoded.width >= decoded.height
                                      ? 512
                                      : null,
                                  height: decoded.height > decoded.width
                                      ? 512
                                      : null,
                                )
                              : decoded;
                          final jpgBytes = img.encodeJpg(resized, quality: 82);
                          final appDir =
                              await getApplicationDocumentsDirectory();
                          final targetPath = p.join(
                            appDir.path,
                            'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );
                          await File(targetPath).writeAsBytes(jpgBytes);
                          setDlgState(() => avatarPath = targetPath);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('تعذّر اختيار الصورة: $e')),
                          );
                        }
                      }
                    },
                  ),
                  if (avatarPath.isNotEmpty && File(avatarPath).existsSync()) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'حذف الصورة',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setDlgState(() => avatarPath = ''),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'الاسم الشخصي أو اللقب:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'الاسم أو اللقب',
                  hintText: 'اكتب اسمك هنا',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          AppPrimaryButton(
            label: 'حفظ التعديلات',
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final prefs = ref.read(userPrefsProvider);
              if (newName.isNotEmpty) {
                await prefs.setUserName(newName);
              }
              await prefs.setUserAvatar(avatarPath);
              ref.read(userNameVersionProvider.notifier).bump();
              try {
                await ref
                    .read(cloudSyncControllerProvider.notifier)
                    .syncToCloud();
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
              onSaved();
            },
          ),
        ],
      ),
    ),
  );
}
