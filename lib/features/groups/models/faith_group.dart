import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات مجموعة الصحبة الصالحة
class FaithGroup {
  final String id;
  final String name;
  final String code;
  final String creatorId;
  final String description;
  final String emoji;
  final int membersCount;
  final DateTime createdAt;

  const FaithGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.creatorId,
    required this.description,
    this.emoji = '🌿',
    required this.membersCount,
    required this.createdAt,
  });

  factory FaithGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FaithGroup(
      id: doc.id,
      name: data['name'] as String? ?? 'مجموعة الصحبة',
      code: data['code'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '🌿',
      membersCount: (data['membersCount'] as num?)?.toInt() ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'creatorId': creatorId,
      'description': description,
      'emoji': emoji,
      'membersCount': membersCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// نموذج بيانات تقدّم العضو في أعمال اليوم والليلة
class DailyDeedsProgress {
  final int prayersCompleted; // 0..5
  final int sunnahCount; // عدد ركعات أو صلوات السنن (ضحى، وتر، رواتب، قيام)
  final bool morningAzkar;
  final bool eveningAzkar;
  final bool sleepAzkar;
  final int quranPages;
  final int tasbihCount;

  const DailyDeedsProgress({
    this.prayersCompleted = 0,
    this.sunnahCount = 0,
    this.morningAzkar = false,
    this.eveningAzkar = false,
    this.sleepAzkar = false,
    this.quranPages = 0,
    this.tasbihCount = 0,
  });

  /// حساب النسبة المئوية لإنجاز أعمال اليوم (0 إلى 100%)
  int get scorePercentage {
    var points = 0.0;
    const maxPoints = 100.0;

    // الصلوات الخمس: 50 نقطة (10 لكل صلاة)
    points += (prayersCompleted.clamp(0, 5) * 10);

    // أذكار الصباح والمساء والنوم: 20 نقطة
    if (morningAzkar) points += 7;
    if (eveningAzkar) points += 7;
    if (sleepAzkar) points += 6;

    // السنن والنوافل: 15 نقطة
    if (sunnahCount > 0) points += (sunnahCount.clamp(0, 5) * 3);

    // الورد القرآني: 10 نقاط
    if (quranPages > 0) points += (quranPages >= 4 ? 10 : quranPages * 2.5);

    // التسبيح والأذكار العامة: 5 نقاط
    if (tasbihCount > 0) points += (tasbihCount >= 100 ? 5 : 2.5);

    return points.clamp(0.0, maxPoints).round();
  }

  factory DailyDeedsProgress.fromMap(Map<String, dynamic> map) {
    return DailyDeedsProgress(
      prayersCompleted: (map['prayersCompleted'] as num?)?.toInt() ?? 0,
      sunnahCount: (map['sunnahCount'] as num?)?.toInt() ?? 0,
      morningAzkar: map['morningAzkar'] as bool? ?? false,
      eveningAzkar: map['eveningAzkar'] as bool? ?? false,
      sleepAzkar: map['sleepAzkar'] as bool? ?? false,
      quranPages: (map['quranPages'] as num?)?.toInt() ?? 0,
      tasbihCount: (map['tasbihCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prayersCompleted': prayersCompleted,
      'sunnahCount': sunnahCount,
      'morningAzkar': morningAzkar,
      'eveningAzkar': eveningAzkar,
      'sleepAzkar': sleepAzkar,
      'quranPages': quranPages,
      'tasbihCount': tasbihCount,
      'scorePercentage': scorePercentage,
    };
  }
}

/// عضو في المجموعة
class GroupMember {
  final String userId;
  final String displayName;
  final int avatarIndex;
  final int currentStreak;
  final DailyDeedsProgress progress;
  final DateTime lastUpdated;

  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.avatarIndex,
    required this.currentStreak,
    required this.progress,
    required this.lastUpdated,
  });

  factory GroupMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupMember(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? 'صاحب همّة',
      avatarIndex: (data['avatarIndex'] as num?)?.toInt() ?? 0,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      progress: DailyDeedsProgress.fromMap(data),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = progress.toMap();
    // `userId` كان غائباً كلياً عن هالخريطة — باج حقيقي كان كامناً منذ أول
    // كتابة (راجع تعليق `firestore.rules.match /members/{userId}`: قاعدة
    // الإنشاء تشترط `request.resource.data.userId == userId`، وهاي دائماً
    // تفشل بلا هالحقل لأن الطرف الأيسر `null` لا يطابق أي `userId` حقيقي
    // أبداً). لم يظهر إلا اليوم لأن القواعد الفعلية بـFirebase Console
    // كانت "test mode" مفتوحة بلا شرط — أول اختبار حقيقي بعد نشر القواعد
    // الصحيحة كشفه فوراً (`PERMISSION_DENIED` عند batch.commit بإنشاء
    // مجموعة).
    map['userId'] = userId;
    map['displayName'] = displayName;
    map['avatarIndex'] = avatarIndex;
    map['currentStreak'] = currentStreak;
    map['lastUpdated'] = Timestamp.fromDate(lastUpdated);
    return map;
  }
}

/// تحدٍ جماعي بموعد نهائي — هدف رقمي واحد (مثلاً "١٠٠ صفحة قرآن") يتنافس/
/// يتعاون عليه أعضاء المجموعة خلال مدة محدَّدة. مستند واحد بمجموعة فرعية
/// `groups/{id}/challenges`، وتقدّم كل عضو محفوظ بمستند مستقل بمجموعة فرعية
/// `challenges/{id}/progress/{userId}` (راجع [ChallengeProgress]) — لا تعارض
/// كتابة متزامنة بين الأعضاء على نفس المستند.
///
/// **الأرشفة**: `archived` يقلبها منشئ التحدي يدوياً فقط (زر صريح بالواجهة)
/// بعد انتهاء الموعد — لا أرشفة تلقائية صامتة (المستخدم قد يريد مراجعة
/// النتيجة النهائية قبل نقلها لسجل "تحديات سابقة"). `isEnded` (حساب محلي
/// بلا كتابة) يفرّق بصرياً بين "منتهٍ بانتظار الأرشفة" و"نشط فعلياً"، بمعزل
/// عن `archived` نفسها.
class GroupChallenge {
  final String id;
  final String title;
  final String unit;
  final int targetValue;
  final String createdBy;
  final String createdByName;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final bool archived;

  const GroupChallenge({
    required this.id,
    required this.title,
    required this.unit,
    required this.targetValue,
    required this.createdBy,
    required this.createdByName,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.archived = false,
  });

  bool get isEnded => DateTime.now().isAfter(endDate);

  Duration get remaining => endDate.difference(DateTime.now());

  factory GroupChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupChallenge(
      id: doc.id,
      title: data['title'] as String? ?? 'تحدٍ جماعي',
      unit: data['unit'] as String? ?? 'نقطة',
      targetValue: (data['targetValue'] as num?)?.toInt() ?? 1,
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'صاحب همّة',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      archived: data['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'unit': unit,
      'targetValue': targetValue,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'archived': archived,
    };
  }
}

/// تقدّم عضو واحد بتحدٍ جماعي معيّن (راجع [GroupChallenge]).
class ChallengeProgress {
  final String userId;
  final String displayName;
  final int avatarIndex;
  final int value;
  final DateTime updatedAt;

  const ChallengeProgress({
    required this.userId,
    required this.displayName,
    required this.avatarIndex,
    required this.value,
    required this.updatedAt,
  });

  factory ChallengeProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChallengeProgress(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? 'صاحب همّة',
      avatarIndex: (data['avatarIndex'] as num?)?.toInt() ?? 0,
      value: (data['value'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarIndex': avatarIndex,
      'value': value,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// رسالة تشجيع ونكزة إيمانية بين الأعضاء
class GroupNudge {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String type; // prayer, azkar, quran, dua
  final String message;
  final DateTime sentAt;

  const GroupNudge({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.type,
    required this.message,
    required this.sentAt,
  });

  factory GroupNudge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupNudge(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? 'أخوك في الله',
      toUserId: data['toUserId'] as String? ?? '',
      toUserName: data['toUserName'] as String? ?? '',
      type: data['type'] as String? ?? 'dua',
      message: data['message'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'type': type,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
