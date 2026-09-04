import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// نتيجة "حفظ صورة" عبر قناة MediaStore الأصلية — تعكس بدقة أين حُفظت
/// فعلاً، بدل رسالة "حُفظت بنجاح" الكاذبة التي كانت تظهر رغم الفشل.
class GallerySaveResult {
  const GallerySaveResult({
    required this.saved,
    required this.inGallery,
    this.displayUriOrPath,
  });

  final bool saved;

  /// هل ظهرت الصورة فعلاً بمعرض النظام؟ (`false` تعني حُفظت بمجلد خاص
  /// بالتطبيق بسبب قيود التخزين المقصّى على الأجهزة الأقدم بلا إذن كتابة).
  final bool inGallery;

  /// URI المعرض (أندرويد ١٠+) أو المسار الملف (الأقدم) — للعرض/المشاركة.
  final String? displayUriOrPath;
}

const _kChannel = MethodChannel('com.humam.humam_app/media_store');

/// يحفظ PNG بالمعرض عبر `MediaStore` (أندرويد ١٠+) — بديل الكتابة المباشرة
/// لمسار `Pictures/Humam` اللي كان يفشل بالتخزين المقصّى Scoped Storage على
/// أجهزة أندرويد الحديثة (راجع `MainActivity.kt`). على أنظمة أقدم بلا إذن
/// الكتابة يرجع [GallerySaveResult.inGallery] == `false` مع المسار الفعلي.
Future<GallerySaveResult> savePngToGallery(
  Uint8List bytes, {
  required String displayName,
}) async {
  try {
    final map = await _kChannel.invokeMapMethod<Object?, Object?>(
      'saveImageToGallery',
      {'bytes': bytes, 'displayName': displayName},
    );
    if (map == null) {
      return const GallerySaveResult(saved: false, inGallery: false);
    }
    return GallerySaveResult(
      saved: map['saved'] == true,
      inGallery: map['inGallery'] == true,
      displayUriOrPath: (map['uri'] ?? map['path']) as String?,
    );
  } catch (e) {
    debugPrint('savePngToGallery فشل: $e');
    return const GallerySaveResult(saved: false, inGallery: false);
  }
}