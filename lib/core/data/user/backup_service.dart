import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../asset_sqlite_sync.dart' show readSqliteUserVersion;
import 'user_database.dart';

/// نسخ احتياطي محلي بالكامل لـ`user.db` — بلا أي اعتماد شبكي أو حساب،
/// يطابق مبدأ "أوفلاين أولاً" بالمشروع (خلافاً لميزة "مجموعة الأصدقاء"
/// المخطَّطة بـFirebase، استثناء معماري منفصل وموثَّق). بطلب صاحب المشروع:
/// "نسخ احتياطي محلي للبيانات".
enum BackupRestoreResult { success, cancelled, invalidFile }

class BackupService {
  const BackupService(this._db);
  final UserDatabase _db;

  /// يُنشئ لقطة SQLite **متّسقة كاملة** بمجلد مؤقت عبر `VACUUM INTO` (نفس
  /// آلية النسخ الاحتياطي الداخلية بأدوات تطوير drift نفسها) — أسلم من نسخ
  /// ملف `user.db` الخام مباشرة أثناء اتصال drift مفتوح (قد يلتقط كتابة
  /// جزئية أو ملفَي WAL/SHM غير مُدمَجين). ثم يفتح حوار المشاركة النظامي —
  /// المستخدم يختار أين يحفظها (ملفات الجهاز/درايف/إلخ)، ويُحذف الملف
  /// المؤقت بعد اكتمال أو فشل المشاركة لتفادي تراكم التخزين المؤقت.
  Future<void> exportAndShare() async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final name =
        'humam_backup_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}.db';
    final path = p.join(dir.path, name);
    final file = File(path);
    try {
      await _db.customStatement('VACUUM INTO ?;', [path]);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'نسخة احتياطية من بيانات هُمَام'),
      );
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('تعذّر حذف ملف اللقطة المؤقتة بعد المشاركة: $e');
      }
    }
  }

  /// يفتح منتقي ملفات النظام، يتحقّق أن الملف المختار SQLite صالح بإصدار
  /// مخطط مدعوم (`PRAGMA user_version` — نفس فحص [readSqliteUserVersion])،
  /// ويأخذ لقطة مسبقة تلقائية لـ`user.db` الحالي كحزام أمان قبل الاستبدال،
  /// ثم ينسخ إلى مسار مؤقت ويُجري `rename` ذرّياً فوق `user.db` الحقيقي.
  ///
  /// **لا يُعيد تحميل الحالة داخل الجلسة الحالية عمداً** — يتطلّب إغلاق
  /// التطبيق وإعادة فتحه يدوياً بعد نجاح الاستعادة. تبديل قاعدة بيانات حيّة
  /// بمنتصف جلسة تطبيق (عشرات الشاشات، حالة Riverpod مخبَّأة بكل مكان) خطر
  /// حقيقي غير متناسب مع قيمة الميزة — تبسيط متعمَّد لا نقص تنفيذ.
  Future<BackupRestoreResult> pickAndInstallBackup() async {
    final picked = await FilePicker.pickFile();
    final pickedPath = picked?.path;
    if (pickedPath == null) return BackupRestoreResult.cancelled;

    final pickedFile = File(pickedPath);
    final pickedVersion = await readSqliteUserVersion(pickedFile);
    final currentSchemaVersion = _db.schemaVersion;
    if (pickedVersion == null || pickedVersion < 1 || pickedVersion > currentSchemaVersion) {
      return BackupRestoreResult.invalidFile;
    }

    final tempDir = await getTemporaryDirectory();
    final docDir = await getApplicationDocumentsDirectory();
    final targetPath = p.join(docDir.path, 'user.db');
    final tempTargetPath = p.join(tempDir.path, 'user_restore_${DateTime.now().millisecondsSinceEpoch}.tmp');

    // 1. أخذ لقطة أمان احتياطية تلقائية من user.db الحالي قبل إغلاقه
    final now = DateTime.now();
    final preRestoreName =
        'humam_pre_restore_backup_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}.db';
    final preRestorePath = p.join(tempDir.path, preRestoreName);
    final preRestoreFile = File(preRestorePath);

    try {
      await _db.customStatement('VACUUM INTO ?;', [preRestorePath]);
    } catch (e) {
      debugPrint('تعذّر أخذ لقطة أمان مسبقة قبل الاستعادة: $e');
    }

    try {
      // 2. نسخ الملف المختار إلى مسار مؤقت والتحقق منه أولاً
      final tempFile = await pickedFile.copy(tempTargetPath);
      final verifiedTempVersion = await readSqliteUserVersion(tempFile);
      if (verifiedTempVersion == null || verifiedTempVersion < 1 || verifiedTempVersion > currentSchemaVersion) {
        if (await tempFile.exists()) await tempFile.delete();
        return BackupRestoreResult.invalidFile;
      }

      // 3. إغلاق اتصال قاعدة البيانات الحالي وحذف ملفات WAL/SHM
      await _db.close();
      for (final suffix in ['-wal', '-shm']) {
        final f = File('$targetPath$suffix');
        if (await f.exists()) await f.delete();
      }

      // 4. استبدال ذرّي عبر rename فوق الهدف
      await tempFile.rename(targetPath);
      return BackupRestoreResult.success;
    } catch (e) {
      debugPrint('فشلت عملية استعادة النسخة الاحتياطية: $e');
      // محاولة استعادة لقطة الأمان إذا كان الملف الهدف قد تضرر
      try {
        if (await preRestoreFile.exists()) {
          final targetFile = File(targetPath);
          if (!await targetFile.exists() || (await targetFile.length()) == 0) {
            await preRestoreFile.copy(targetPath);
          }
        }
      } catch (recoveryErr) {
        debugPrint('تعذّرت استعادة لقطة الأمان السابقة: $recoveryErr');
      }
      return BackupRestoreResult.invalidFile;
    } finally {
      // تنظيف ملف الاستيراد المؤقت إن بقي
      try {
        final f = File(tempTargetPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
