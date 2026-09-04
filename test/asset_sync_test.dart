import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/asset_sqlite_sync.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('humam_asset_sync_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('readSqliteUserVersion يرجع null إذا كان الملف غير موجود', () async {
    final file = File('${tempDir.path}/non_existent.db');
    final version = await readSqliteUserVersion(file);
    expect(version, isNull);
  });

  test('readSqliteUserVersion يرجع null إذا كان الملف أقل من 64 بايت أو غير صالح', () async {
    final file = File('${tempDir.path}/tiny.db');
    await file.writeAsBytes([1, 2, 3, 4]);
    final version = await readSqliteUserVersion(file);
    expect(version, isNull);
  });

  test('readSqliteUserVersion يرجع null إذا كانت ترويسة SQLite غير مطابقة', () async {
    final file = File('${tempDir.path}/fake.db');
    final fakeBytes = Uint8List(100);
    // ترويسة عشوائية لا تطابق "SQLite format 3\0"
    for (var i = 0; i < 16; i++) {
      fakeBytes[i] = 0xFF;
    }
    await file.writeAsBytes(fakeBytes);
    final version = await readSqliteUserVersion(file);
    expect(version, isNull);
  });

  test('readSqliteUserVersion يقرأ user_version الصحيح عندما تكون الترويسة سليمة', () async {
    final file = File('${tempDir.path}/valid.db');
    final bytes = Uint8List(100);
    // "SQLite format 3\0"
    final header = [
      0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66,
      0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00,
    ];
    for (var i = 0; i < 16; i++) {
      bytes[i] = header[i];
    }
    // user_version = 16 (0x00, 0x00, 0x00, 0x10) عند offset 60
    bytes[60] = 0x00;
    bytes[61] = 0x00;
    bytes[62] = 0x00;
    bytes[63] = 0x10;

    await file.writeAsBytes(bytes);
    final version = await readSqliteUserVersion(file);
    expect(version, 16);
  });
}
