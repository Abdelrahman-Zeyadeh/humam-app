package com.humam.humam_app

import com.ryanheise.audioservice.AudioServiceActivity

// `AudioServiceActivity` (لا `FlutterActivity` العادية) — يعيد استخدام نفس
// محرّك Flutter المشترك اللي تديره خدمة audio_service بالخلفية
// (AudioServicePlugin.getFlutterEngine). بدونها كل الواجهة تشتغل بمحرّك
// Flutter ثانٍ منفصل، فيُنفَّذ main() مرتين فعلياً على الجهاز — وهذا سبب
// عطلين حقيقيين رُصدا فعلياً بجهاز أندرويد حقيقي (ALI NX1):
// ١) IllegalStateException من AudioServicePlugin ("wrongEngineDetected")
//    عند أي نداء تحكّم صوتي.
// ٢) SqliteException "database is locked" عند فتح user.db، لأن نسختي
//    main() يفتحان نفس الملف بترقية مخطط متزامنة.
class MainActivity : AudioServiceActivity()
