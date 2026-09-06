import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/user_prefs.dart';

/// حد أقصى احترازي لحجم صورة الملف الشخصي قبل التحويل لـ Base64 وتخزينها
/// داخل مستند Firestore نفسه (بلا Firebase Storage) — مستند Firestore محدود
/// بـ١ ميجابايت، وBase64 يضيف ~٣٣٪ فوق حجم الملف الأصلي.
const int _kMaxAvatarBytesForSync = 700 * 1024;

/// معرّف عميل الويب (`client_type: 3` بـ`android/app/google-services.json`)
/// — لازم لـ`GoogleSignIn.initialize(serverClientId:)` عشان يرجّع `idToken`
/// صالحاً لـ`GoogleAuthProvider.credential`. **هذا ليس سرّاً** (نفس القيمة
/// موجودة أصلاً بملف `google-services.json` المضمَّن بالتطبيق، يقدر أي حد
/// يستخرجها من الـAPK) — لا داعي لإخفائها أو نقلها لمتغيّر بيئة.
const String _kGoogleSignInServerClientId =
    '312827165247-scjdv0abrf8lr8739llt5c7lrc2js5ij.apps.googleusercontent.com';

const _kSyncCheckpointPrefKey = 'cloud_sync_checkpoint_at';

/// **هل يجب سحب نسخة السحابة بدل رفع النسخة المحلية الآن؟** دالة نقيّة
/// (بلا آثار جانبية) — تحمل منطق "last-write-wins" الفعلي لـ[CloudSyncController.
/// syncNow] بمعزل تام عن Firestore الحقيقي، فتُختبَر مباشرة بلا حاجة
/// Firestore Mock. **مستوى المقارنة: الحساب كاملاً، لا حقل بحقل** — قرار
/// متعمَّد (بديل عن نظام CRDT/تعارض حقيقي لكل حقل، يحتاج عمود "آخر تعديل"
/// على كل جدول قابل للمزامنة، تعقيد غير مبرَّر لميزة اختيارية بالكامل
/// راجع توثيق `syncNow`): [remoteLastSyncedAt] وقت آخر كتابة **لأي** جهاز
/// على المستند السحابي، [localSyncCheckpoint] آخر لحظة زامن فيها **هذا**
/// الجهاز تحديداً (نجاحاً، دفعاً أو سحباً) — مخزَّن محلياً بـ
/// `SharedPreferences`. السحابة أحدث ⇐ اسحب؛ وإلا (أو لا بيانات سحابية
/// بعد) ⇐ ارفع نسخة هذا الجهاز.
bool shouldPullInsteadOfPush({
  required DateTime? remoteLastSyncedAt,
  required DateTime? localSyncCheckpoint,
}) {
  if (remoteLastSyncedAt == null) return false;
  if (localSyncCheckpoint == null) return true;
  return remoteLastSyncedAt.isAfter(localSyncCheckpoint);
}

enum CloudSyncStatus { idle, syncing, success, error }

class CloudSyncState {
  const CloudSyncState({
    this.user,
    this.status = CloudSyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
  });

  final User? user;
  final CloudSyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  bool get isSignedIn => user != null && !user!.isAnonymous;

  CloudSyncState copyWith({
    User? user,
    CloudSyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return CloudSyncState(
      user: user ?? this.user,
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage,
    );
  }
}

class CloudSyncController extends Notifier<CloudSyncState> {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  CloudSyncState build() {
    final auth = _auth;
    if (auth != null) {
      auth.authStateChanges().listen((user) {
        state = state.copyWith(user: user);
      });
      return CloudSyncState(user: auth.currentUser);
    }
    return const CloudSyncState();
  }

  bool _googleSignInInitialized = false;

  /// تسجيل الدخول باستخدام حساب Google — **باج حقيقي مُصلَح**: كان يستخدم
  /// `FirebaseAuth.signInWithProvider(GoogleAuthProvider())` (تدفّق ويب
  /// كامل عبر صفحة `*.firebaseapp.com/__/auth/handler` حتى على أندرويد)،
  /// اكتُشف فشله فعلياً على جهاز حقيقي: "Unable to process request due to
  /// missing initial state... storage-partitioned browser environment" —
  /// خطأ معروف لهالتدفّق تحديداً بمتصفحات أندرويد الحديثة (تقسيم تخزين
  /// الجلسة بين نافذة إعادة التوجيه والصفحة الأصلية). **الحل الرسمي
  /// لأندرويد حسب توثيق Firebase نفسه**: حزمة `google_sign_in` (موجودة
  /// أصلاً بـ`pubspec.yaml` كاعتماد بلا استخدام فعلي قبل هذا الإصلاح) عبر
  /// `authenticate()` الأصلية، ثم `signInWithCredential` بدل `signInWithProvider`.
  Future<bool> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      state = state.copyWith(errorMessage: 'خدمة تسجيل الدخول غير متوفرة');
      return false;
    }

    try {
      state = state.copyWith(status: CloudSyncStatus.syncing, errorMessage: null);

      final googleSignIn = GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize(serverClientId: _kGoogleSignInServerClientId);
        _googleSignInInitialized = true;
      }
      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('تعذّر الحصول على رمز مصادقة Google صالح');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final cred = await auth.signInWithCredential(credential);
      if (cred.user?.displayName != null && cred.user!.displayName!.isNotEmpty) {
        await ref.read(userPrefsProvider).setUserName(cred.user!.displayName!);
      }
      state = state.copyWith(user: cred.user, status: CloudSyncStatus.idle);
      await pullFromCloud();
      return true;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      // إلغاء المستخدم للحوار نفسه (لا خطأ حقيقي) يرمي `GoogleSignInException`
      // بكود `canceled` بإصدار ٧.x — لا نعرض رسالة خطأ حمراء لمجرد إلغاء
      // مقصود.
      final isCancel = e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled;
      state = state.copyWith(
        status: isCancel ? CloudSyncStatus.idle : CloudSyncStatus.error,
        errorMessage: isCancel ? null : 'تعذّر تسجيل الدخول بحساب Google: $e',
      );
      return false;
    }
  }

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<bool> signInWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      state = state.copyWith(errorMessage: 'خدمة تسجيل الدخول غير متوفرة');
      return false;
    }

    try {
      state = state.copyWith(status: CloudSyncStatus.syncing);
      final cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(user: cred.user, status: CloudSyncStatus.idle);
      // تنزيل بيانات الحساب (بما فيها الصورة الشخصية) من السحابة فور الدخول —
      // لا نرفع الحالة المحلية فوق السحابية هون، لأنها قد تكون فارغة على هذا
      // الجهاز تحديداً (أول تسجيل دخول من جهاز جديد).
      await pullFromCloud();
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'تعذّر تسجيل الدخول';
      if (e.code == 'user-not-found') {
        msg = 'البريد الإلكتروني غير مسجل، يرجى إنشاء حساب جديد';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        msg = 'صيغة البريد الإلكتروني غير صحيحة';
      }
      state = state.copyWith(status: CloudSyncStatus.error, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(status: CloudSyncStatus.error, errorMessage: '$e');
      return false;
    }
  }

  /// إنشاء حساب جديد بالبريد الإلكتروني
  Future<bool> registerWithEmail(String email, String password, String displayName) async {
    final auth = _auth;
    if (auth == null) {
      state = state.copyWith(errorMessage: 'خدمة التسجيل غير متوفرة');
      return false;
    }

    try {
      state = state.copyWith(status: CloudSyncStatus.syncing);
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
        // لازم نخزّنه محلياً بـ`userPrefs` أيضاً لا Firebase Auth بس —
        // `syncToCloud` صار يرفع `userPrefs.userName` (المصدر المحلي
        // الحقيقي، نفس مصدر الصورة/التقدم) بدل `user.displayName` الثابت،
        // فبلا هالسطر كان الاسم المكتوب هون يضيع فور أول رفع سحابي.
        await ref.read(userPrefsProvider).setUserName(displayName.trim());
      }
      state = state.copyWith(user: cred.user, status: CloudSyncStatus.idle);
      // حفظ بيانات المستخدم الأولية بالسحابة
      await syncToCloud();
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'تعذّر إنشاء الحساب';
      if (e.code == 'email-already-in-use') {
        msg = 'البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول';
      } else if (e.code == 'weak-password') {
        msg = 'كلمة المرور ضعيفة (يجب أن تتكون من 6 خانات على الأقل)';
      }
      state = state.copyWith(status: CloudSyncStatus.error, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(status: CloudSyncStatus.error, errorMessage: '$e');
      return false;
    }
  }

  /// رفع وحفظ نسخة السحابة
  Future<bool> syncToCloud() async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;

    if (auth == null || firestore == null || user == null || user.isAnonymous) {
      return false;
    }

    try {
      state = state.copyWith(status: CloudSyncStatus.syncing);
      final userPrefs = ref.read(userPrefsProvider);
      final khatmaPrefs = ref.read(khatmaPrefsProvider);
      final hifzPrefs = ref.read(hifzPrefsProvider);

      final payload = <String, dynamic>{
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'email': user.email,
        // كان يُرفَع من `user.displayName` (نسخة Firebase Auth الثابتة وقت
        // التسجيل فقط) بدل `userPrefs.userName` (المخزَّن المحلي الفعلي
        // القابل للتعديل من الإعدادات) — فأي تغيير اسم لاحق محلياً ما كان
        // يوصل السحابة إطلاقاً، بعكس الصورة/التقدم اللي بتقرأ من `userPrefs`
        // دايماً. بلاغ مستخدم حقيقي: "الصورة والتقدم بينحفظ، ليش الاسم لا".
        'displayName': userPrefs.userName,
        'streakDays': userPrefs.streakDays,
        'accentColorId': userPrefs.accentColorId,
        'adhanVoiceId': userPrefs.adhanVoiceId,
        'mushafPaletteId': userPrefs.mushafPaletteId,
        'version': 2,
        // لقطة كاملة (ختمة/حفظ/علامات/أذكار) — راجع توثيق [syncNow] لآلية
        // last-write-wins، و[UserRepository.restoreKhatmaPlansIfEmpty]
        // وأخواتها لآلية الاستعادة/الدمج عند السحب.
        'khatmaPlans': [
          for (final plan in khatmaPrefs.activePlans)
            {
              'startDate': plan.startDate.toIso8601String(),
              'targetDays': plan.targetDays,
              'startPage': plan.startPage,
              'currentPage': plan.currentPage,
            },
        ],
        'hifzPlans': [
          for (final plan in hifzPrefs.plans)
            {
              'fromAyahId': plan.fromAyahId,
              'toAyahId': plan.toAyahId,
              'currentAyahId': plan.currentAyahId,
              'createdAt': plan.createdAt.toIso8601String(),
            },
        ],
        'bookmarkedAyahIds': userPrefs.bookmarkedAyahIds.toList(),
        'azkarFavoriteCategoryIds': userPrefs.azkarFavoriteCategoryIds.toList(),
      };

      // الصورة الشخصية: تُخزَّن Base64 داخل نفس المستند (بلا Firebase Storage
      // — بطلب صاحب المشروع تفادي ترقية خطة Blaze). لو المستخدم حذف صورته
      // محلياً، نُرسل قيمة فارغة صراحة عشان تُحذف بالأجهزة الأخرى أيضاً.
      final avatarPath = userPrefs.userAvatar.trim();
      if (avatarPath.isEmpty) {
        payload['photoBase64'] = '';
      } else {
        final avatarFile = File(avatarPath);
        if (await avatarFile.exists()) {
          final bytes = await avatarFile.readAsBytes();
          if (bytes.length <= _kMaxAvatarBytesForSync) {
            payload['photoBase64'] = base64Encode(bytes);
          } else {
            // أكبر من الحد المسموح — لا نُضيف المفتاح إطلاقاً حتى لا نمحو
            // (بالدمج) صورة سابقة صالحة كانت مخزَّنة بالسحابة.
            debugPrint('صورة الملف الشخصي كبيرة جداً للمزامنة السحابية (${bytes.length} بايت)');
          }
        }
      }

      await firestore.collection('users').doc(user.uid).set(payload, SetOptions(merge: true));
      state = state.copyWith(
        status: CloudSyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      debugPrint('CloudSync error: $e');
      state = state.copyWith(
        status: CloudSyncStatus.error,
        errorMessage: 'تعذّرت المزامنة السحابية',
      );
      return false;
    }
  }

  /// تنزيل بيانات الحساب من السحابة وتطبيقها على هذا الجهاز (الاسم +
  /// الصورة الشخصية) — يُستدعى فور تسجيل الدخول بدل `syncToCloud` مباشرة،
  /// لأن الحالة المحلية بجهاز جديد قد تكون فارغة ولا يصح رفعها فوق ما هو
  /// مخزَّن أصلاً بالسحابة. لو لا يوجد مستند سحابي بعد (أول تسجيل دخول لهذا
  /// الحساب من أي جهاز)، تُرفَع الحالة المحلية الحالية كبداية.
  Future<bool> pullFromCloud() async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;

    if (auth == null || firestore == null || user == null || user.isAnonymous) {
      return false;
    }

    try {
      state = state.copyWith(status: CloudSyncStatus.syncing);
      final snap = await firestore.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (data != null) {
        await _applyCloudProfile(data);
      } else {
        // لا بيانات سحابية بعد لهذا الحساب — ابدأ بالحالة المحلية الحالية.
        return await syncToCloud();
      }
      state = state.copyWith(status: CloudSyncStatus.success, lastSyncedAt: DateTime.now());
      return true;
    } catch (e) {
      debugPrint('CloudSync pull error: $e');
      state = state.copyWith(
        status: CloudSyncStatus.error,
        errorMessage: 'تعذّر تنزيل بيانات الحساب من السحابة',
      );
      return false;
    }
  }

  /// يطبّق لقطة السحابة الكاملة (اسم/صورة/لون لوحة + ختمة/حفظ/علامات/أذكار)
  /// على تخزين الجهاز المحلي. خطط الختمة/الحفظ تُستعاد **فقط لو الجهاز
  /// بلا أي خطة محلية أصلاً** (راجع توثيق `UserRepository.
  /// restoreKhatmaPlansIfEmpty`)، والعلامات/الأذكار المفضَّلة تُدمَج
  /// اتحادياً (لا حذف لأي شيء محلي).
  Future<void> _applyCloudProfile(Map<String, dynamic> data) async {
    final userPrefs = ref.read(userPrefsProvider);

    final displayName = data['displayName'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      await userPrefs.setUserName(displayName.trim());
    }

    final paletteId = data['mushafPaletteId'];
    if (paletteId is String && paletteId.isNotEmpty) {
      await userPrefs.setMushafPaletteId(paletteId);
    }

    final khatmaPlans = data['khatmaPlans'];
    if (khatmaPlans is List && khatmaPlans.isNotEmpty) {
      await userPrefs.restoreKhatmaPlansIfEmpty([
        for (final p in khatmaPlans) Map<String, dynamic>.from(p as Map),
      ]);
    }

    final hifzPlans = data['hifzPlans'];
    if (hifzPlans is List && hifzPlans.isNotEmpty) {
      await userPrefs.restoreHifzPlansIfEmpty([
        for (final p in hifzPlans) Map<String, dynamic>.from(p as Map),
      ]);
    }

    final bookmarkIds = data['bookmarkedAyahIds'];
    if (bookmarkIds is List && bookmarkIds.isNotEmpty) {
      await userPrefs.mergeBookmarksFromCloud(bookmarkIds.cast<int>());
    }

    final azkarIds = data['azkarFavoriteCategoryIds'];
    if (azkarIds is List && azkarIds.isNotEmpty) {
      await userPrefs.mergeAzkarFavoritesFromCloud(azkarIds.cast<int>());
    }

    if (data.containsKey('photoBase64')) {
      final photoBase64 = data['photoBase64'];
      if (photoBase64 is String && photoBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(photoBase64);
          final appDir = await getApplicationDocumentsDirectory();
          final targetPath = p.join(
            appDir.path,
            'user_avatar_cloud_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await File(targetPath).writeAsBytes(bytes);
          await userPrefs.setUserAvatar(targetPath);
        } catch (e) {
          debugPrint('تعذّر تطبيق صورة الملف الشخصي من السحابة: $e');
        }
      } else {
        // مفتاح موجود لكنه فارغ = المستخدم حذف صورته من جهاز آخر صراحة.
        await userPrefs.setUserAvatar('');
      }
    }

    ref.read(userNameVersionProvider.notifier).bump();
  }

  /// **"مزامنة الآن"** — نقطة الدخول المخصَّصة للزر اليدوي بالإعدادات/الملف
  /// الشخصي بعد أول تسجيل دخول (`pullFromCloud`/`syncToCloud` الأوليين
  /// تكفيان لحظة الدخول نفسها). تقارن وقت آخر كتابة سحابية بآخر نقطة
  /// تزامن معروفة لهذا الجهاز (راجع [shouldPullInsteadOfPush]) بدل رفع كل
  /// شيء دائماً — لو السحابة أحدث (جهاز آخر عدَّل بعد آخر تزامن هون) تُسحَب
  /// نسخته بدل الكتابة فوقها.
  Future<bool> syncNow() async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;
    if (auth == null || firestore == null || user == null || user.isAnonymous) {
      return false;
    }

    try {
      state = state.copyWith(status: CloudSyncStatus.syncing);
      final docRef = firestore.collection('users').doc(user.uid);
      final snap = await docRef.get();
      final data = snap.data();
      final remoteLastSyncedAt = (data?['lastSyncedAt'] as Timestamp?)?.toDate();
      final localCheckpoint = await _readLocalSyncCheckpoint();

      if (shouldPullInsteadOfPush(
        remoteLastSyncedAt: remoteLastSyncedAt,
        localSyncCheckpoint: localCheckpoint,
      )) {
        if (data != null) await _applyCloudProfile(data);
        await _writeLocalSyncCheckpoint(remoteLastSyncedAt ?? DateTime.now());
        state = state.copyWith(status: CloudSyncStatus.success, lastSyncedAt: DateTime.now());
        return true;
      }

      final pushed = await syncToCloud();
      if (pushed) {
        await _writeLocalSyncCheckpoint(DateTime.now());
      }
      return pushed;
    } catch (e) {
      debugPrint('CloudSync syncNow error: $e');
      state = state.copyWith(
        status: CloudSyncStatus.error,
        errorMessage: 'تعذّرت المزامنة السحابية',
      );
      return false;
    }
  }

  /// **نسخ احتياطي سحابي دوري تلقائي** — يُستدعى من `RootShell` عند إقلاع
  /// التطبيق وعند كل عودة من الخلفية (`AppLifecycleState.resumed`)، بلا أي
  /// واجهة أو مؤشر تحميل (فشل صامت تماماً لو لا اتصال إنترنت الآن — ستُعاد
  /// المحاولة بالمرة التالية). لا نضيف جدولة نظام حقيقية (WorkManager/
  /// AlarmManager) تعمل والتطبيق مغلق تماماً — تعقيد اعتماد أصلي جديد غير
  /// متناسب مع كون هذه أصلاً مزامنة "أفضل جهد" لبيانات خفيفة (راجع
  /// `syncToCloud`)، لا نسخة ملفات ضخمة تحتاج ضمان تنفيذ صارم. يتحقق من:
  /// تسجيل دخول فعلي + تفعيل الإعداد + مرور [interval] منذ آخر تزامن ناجح
  /// لهذا الجهاز (يُعاد استخدام نفس نقطة تفتيش `syncNow` — أي تزامن يدوي
  /// حديث يؤجّل هذا التلقائي أيضاً، لا ازدواجية).
  Future<void> maybeAutoSync({
    Duration interval = const Duration(hours: 24),
  }) async {
    if (!state.isSignedIn) return;
    try {
      if (!ref.read(userPrefsProvider).autoCloudBackupEnabled) return;
      final checkpoint = await _readLocalSyncCheckpoint();
      if (checkpoint != null && DateTime.now().difference(checkpoint) < interval) {
        return;
      }
      await syncNow();
    } catch (e) {
      debugPrint('CloudSync maybeAutoSync error: $e');
    }
  }

  Future<DateTime?> _readLocalSyncCheckpoint() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final iso = sp.getString(_kSyncCheckpointPrefKey);
      return iso == null ? null : DateTime.tryParse(iso);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocalSyncCheckpoint(DateTime at) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kSyncCheckpointPrefKey, at.toIso8601String());
    } catch (_) {}
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _auth?.signOut();
    state = const CloudSyncState();
  }
}

final cloudSyncControllerProvider =
    NotifierProvider<CloudSyncController, CloudSyncState>(
      CloudSyncController.new,
    );
