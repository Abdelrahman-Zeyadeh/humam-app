package com.humam.humam_app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// `AudioServiceActivity` (لا `FlutterActivity` العادية) — يعيد استخدام نفس
// محرّك Flutter المشترك اللي تديره خدمة audio_service بالخلفية
// (AudioServicePlugin.getFlutterEngine). بدونها كل الواجهة تشتغل بمحرّك
// Flutter ثانٍ منفصل، فيُنفَّذ main() مرتين فعلياً على الجهاز — وهذا سبب
// عطلين حقيقيين رُصدا فعلياً بجهاز أندرويد حقيقي (ALI NX1):
// ١) IllegalStateException من AudioServicePlugin ("wrongEngineDetected")
//    عند أي نداء تحكّم صوتي.
// ٢) SqliteException "database is locked" عند فتح user.db، لأن نسختي
//    main() يفتحان نفس الملف بترقية مخطط متزامنة.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // قناة حفظ الصور بالمعرض عبر MediaStore (أندرويد 10+ التخزين
        // المقصّى Scoped Storage). كانت الكتابة المباشرة لمسار
        // `/storage/emulated/0/Pictures/Humam` تفشل على كل الأجهزة الحديثة
        // (بلا إذن WRITE_EXTERNAL_STORAGE ولا requestLegacyExternalStorage)
        // وكان التطبيق يعرض "حُفظت بنجاح" رغم الفشل. راجع الجانب Dart
        // بـ`lib/core/platform/gallery_saver.dart`.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.humam.humam_app/media_store",
        ).setMethodCallHandler { call, result ->
            if (call.method == "saveImageToGallery") {
                val bytes = call.argument<ByteArray>("bytes")
                val displayName = call.argument<String>("displayName")
                    ?: "humam_image_${System.currentTimeMillis()}.png"
                if (bytes == null) {
                    result.error("bad_arguments", "bytes is null", null)
                    return@setMethodCallHandler
                }
                result.success(saveImageToGallery(bytes, displayName))
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(bytes: ByteArray, displayName: String): Map<String, Any?> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveViaMediaStore(bytes, displayName)
        } else {
            saveLegacy(bytes, displayName)
        }
    }

    /// حفظ عبر MediaStore على أندرويد ١٠+ — يظهر بالمعرض فوراً، ويسجّل
    /// في `Pictures/Humam` بلا أي إذن. `IS_PENDING` يخفي الصورة أثناء
    /// الكتابة، ويُرفع عند الاكتمال حتى لا يظهر مقطوع بمعرض المستخدم.
    private fun saveViaMediaStore(bytes: ByteArray, displayName: String): Map<String, Any?> {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Humam")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = try {
            resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        } catch (e: Exception) {
            Log.e(TAG, "MediaStore insert failed", e)
            null
        }
        if (uri == null) {
            return mapOf("saved" to false, "inGallery" to false, "path" to "")
        }
        return try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: return mapOf("saved" to false, "inGallery" to false, "path" to "")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            mapOf("saved" to true, "inGallery" to true, "uri" to uri.toString())
        } catch (e: Exception) {
            // لا تترك إدراجاً فارغاً أوكسر معلقاً بالمعرض عند الفشل.
            try {
                resolver.delete(uri, null, null)
            } catch (e2: Exception) {
                Log.w(TAG, "cleanup failed after MediaStore write error", e2)
            }
            Log.e(TAG, "MediaStore write failed", e)
            mapOf("saved" to false, "inGallery" to false, "path" to "")
        }
    }

    /// أندرويد ٩ فأقل: الكتابة المباشرة لمسار عام تحتاج إذن
    /// `WRITE_EXTERNAL_STORAGE` غير المطلوب هنا — نحاول أولاً (يَنجح فقط
    /// لو كان الإذن مُنحاً خارجياً)، وعند الفشل نلجأ لمجلد التطبيق الخارجي
    /// القابل للكتابة دائماً مع إعلام صادق بعدم ظهوره بالمعرض.
    private fun saveLegacy(bytes: ByteArray, displayName: String): Map<String, Any?> {
        val publicDir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            "Humam",
        )
        try {
            publicDir.mkdirs()
            val target = File(publicDir, displayName)
            target.writeBytes(bytes)
            return mapOf("saved" to true, "inGallery" to true, "path" to target.absolutePath)
        } catch (e: Exception) {
            return try {
                val appDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES)
                requireNotNull(appDir) { "no external files dir" }
                appDir.mkdirs()
                val target = File(appDir, displayName)
                target.writeBytes(bytes)
                mapOf("saved" to true, "inGallery" to false, "path" to target.absolutePath)
            } catch (e2: Exception) {
                Log.e(TAG, "legacy save failed", e2)
                mapOf("saved" to false, "inGallery" to false, "path" to "")
            }
        }
    }

    private companion object {
        const val TAG = "HumamMediaStore"
    }
}