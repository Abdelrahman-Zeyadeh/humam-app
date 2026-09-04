allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// المسار كان `../../build` (يعني `humam_app/build`) — **جوا مجلد
// OneDrive المُزامَن** نفسه. مزامنة OneDrive الحيّة كانت تقفل ملفات
// وسيطة (`R.jar` تحديداً) بلحظة إعادة كتابتها أثناء البناء، فيفشل البناء
// بـ"Couldn't delete ... R.jar" — تكرّر ٥ مرات متتالية بجلسة عمل حقيقية
// (بعضها بعد `flutter clean` كامل وإيقاف Gradle daemon، فلا يوجد تفسير
// آخر غير قفل OneDrive نفسه). الحل: نقل مجلد البناء بالكامل خارج أي
// مجلد مُزامَن — `C:\FlutterBuild\humam_app` مسار ثابت محلي بحت.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
