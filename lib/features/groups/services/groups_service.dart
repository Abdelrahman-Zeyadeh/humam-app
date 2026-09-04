import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/faith_group.dart';

class GroupsService {
  static final GroupsService instance = GroupsService._();
  GroupsService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static const String _kSavedGroupIdsKey = 'faith_groups_saved_ids';
  static const String _kMyAvatarIndexKey = 'faith_groups_my_avatar_index';

  /// الأفاتار المختار شخصياً (راجع `group_avatars.dart`) — تفضيل بسيط
  /// بمستوى الجهاز لا الحساب، محفوظ محلياً فقط (`SharedPreferences`، نفس
  /// فلسفة تعليق `sharedPreferencesProvider`: "للإعدادات البسيطة فقط") —
  /// لا داعي لعمود/جدول drift جديد لقيمة تجميلية بحتة. يُستخدَم بكل مجموعة
  /// ينشئها/ينضمّ لها المستخدم، لا أفاتار مستقل لكل مجموعة.
  Future<int> getMyAvatarIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kMyAvatarIndexKey) ?? 0;
  }

  Future<void> setMyAvatarIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMyAvatarIndexKey, index);
  }

  /// التأكد من تسجيل الدخول المجهول وحيازة معرّف مستخدم فريد
  Future<User?> ensureAuthenticated() async {
    try {
      final auth = _auth;
      if (auth == null) return null;
      if (auth.currentUser != null) {
        return auth.currentUser;
      }
      final cred = await auth.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint('GroupsService.ensureAuthenticated error: $e');
      return null;
    }
  }

  String? get currentUserId {
    try {
      return _auth?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// قائمة معرفات المجموعات التي انضم إليها المستخدم محلياً
  Future<List<String>> getMyGroupIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kSavedGroupIdsKey) ?? [];
  }

  Future<void> _saveGroupIdLocally(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kSavedGroupIdsKey) ?? [];
    if (!list.contains(groupId)) {
      list.add(groupId);
      await prefs.setStringList(_kSavedGroupIdsKey, list);
    }
  }

  Future<void> _removeGroupIdLocally(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kSavedGroupIdsKey) ?? [];
    list.remove(groupId);
    await prefs.setStringList(_kSavedGroupIdsKey, list);
  }

  /// توليد رمز مجموعة مميز من ٦ خانات باستخدام Random.secure مع التحقق من عدم التكرار
  Future<String> _generateGroupCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
      try {
        final existing = await _firestore
            .collection('groups')
            .where('code', isEqualTo: code)
            .limit(1)
            .get();
        if (existing.docs.isEmpty) return code;
      } catch (e) {
        debugPrint('تحذير عند فحص تفرّد رمز المجموعة: $e');
        return code;
      }
    }
    final fallbackCode = List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
    return fallbackCode;
  }

  /// إنشاء مجموعة جديدة
  Future<FaithGroup> createGroup({
    required String name,
    required String description,
    required String creatorName,
    String emoji = '🌿',
    required int avatarIndex,
    required DailyDeedsProgress initialProgress,
    int streak = 0,
  }) async {
    final user = await ensureAuthenticated();
    if (user == null) {
      throw Exception('تعذّر الاتصال بالخدمة. تأكد من اتصال الإنترنت.');
    }

    final code = await _generateGroupCode();
    final groupRef = _firestore.collection('groups').doc();

    final group = FaithGroup(
      id: groupRef.id,
      name: name.trim(),
      code: code,
      creatorId: user.uid,
      description: description.trim(),
      emoji: emoji,
      membersCount: 1,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(groupRef, group.toMap());

    final memberRef = groupRef.collection('members').doc(user.uid);
    final member = GroupMember(
      userId: user.uid,
      displayName: creatorName.trim().isEmpty ? 'صاحب همّة' : creatorName.trim(),
      avatarIndex: avatarIndex,
      currentStreak: streak,
      progress: initialProgress,
      lastUpdated: DateTime.now(),
    );
    batch.set(memberRef, member.toMap());

    await batch.commit();
    await _saveGroupIdLocally(groupRef.id);

    return group;
  }

  /// الانضمام إلى مجموعة بواسطة رمز الدعوة المكون من ٦ أحرف/أرقام مع معاملة ذرّية
  Future<FaithGroup> joinGroupByCode({
    required String code,
    required String displayName,
    required int avatarIndex,
    required DailyDeedsProgress initialProgress,
    int streak = 0,
  }) async {
    final user = await ensureAuthenticated();
    if (user == null) {
      throw Exception('تعذّر الاتصال بالخدمة. تأكد من اتصال الإنترنت.');
    }

    final cleanCode = code.trim().toUpperCase();
    final query = await _firestore
        .collection('groups')
        .where('code', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('رمز المجموعة غير صحيح أو المجموعة غير موجودة.');
    }

    final groupDoc = query.docs.first;
    final memberRef = groupDoc.reference.collection('members').doc(user.uid);

    final group = await _firestore.runTransaction((transaction) async {
      final groupSnap = await transaction.get(groupDoc.reference);
      if (!groupSnap.exists) {
        throw Exception('المجموعة لم تعد موجودة.');
      }
      final currentMembersCount = (groupSnap.data()?['membersCount'] as num?)?.toInt() ?? 0;
      final memberSnap = await transaction.get(memberRef);
      final isNew = !memberSnap.exists;

      final member = GroupMember(
        userId: user.uid,
        displayName: displayName.trim().isEmpty ? 'صاحب همّة' : displayName.trim(),
        avatarIndex: avatarIndex,
        currentStreak: streak,
        progress: initialProgress,
        lastUpdated: DateTime.now(),
      );

      transaction.set(memberRef, member.toMap(), SetOptions(merge: true));
      if (isNew) {
        transaction.update(groupDoc.reference, {
          'membersCount': currentMembersCount + 1,
        });
      }

      return FaithGroup.fromFirestore(groupSnap);
    });

    await _saveGroupIdLocally(group.id);
    return group;
  }

  /// مغادرة المجموعة بضمان قراءة العضو أولاً وتفادي إنقاص العداد إن لم يكن موجوداً
  Future<void> leaveGroup(String groupId) async {
    final user = _auth?.currentUser;
    if (user == null) {
      await _removeGroupIdLocally(groupId);
      return;
    }

    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      final memberRef = groupRef.collection('members').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final memberDoc = await transaction.get(memberRef);
        if (!memberDoc.exists) {
          return;
        }
        final groupDoc = await transaction.get(groupRef);
        transaction.delete(memberRef);
        if (groupDoc.exists) {
          final count = (groupDoc.data()?['membersCount'] as num?)?.toInt() ?? 1;
          transaction.update(groupRef, {
            'membersCount': max(0, count - 1),
          });
        }
      });
    } catch (e) {
      debugPrint('leaveGroup remote error: $e');
    }

    await _removeGroupIdLocally(groupId);
  }

  /// مزامنة تقدّم أعمال اليوم والليلة في المجموعة
  Future<void> syncMyProgress({
    required String groupId,
    required DailyDeedsProgress progress,
    required String displayName,
    required int avatarIndex,
    required int streak,
  }) async {
    final user = _auth?.currentUser;
    if (user == null) return;

    try {
      final memberRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(user.uid);

      final member = GroupMember(
        userId: user.uid,
        displayName: displayName,
        avatarIndex: avatarIndex,
        currentStreak: streak,
        progress: progress,
        lastUpdated: DateTime.now(),
      );

      await memberRef.set(member.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('syncMyProgress error: $e');
    }
  }

  /// إرسال نكزة أو تشجيع إيماني لعضو في المجموعة
  Future<void> sendNudge({
    required String groupId,
    required String toUserId,
    required String toUserName,
    required String fromUserName,
    required String message,
    required String type,
  }) async {
    final user = await ensureAuthenticated();
    if (user == null) return;

    final nudgeRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('nudges')
        .doc();

    final nudge = GroupNudge(
      id: nudgeRef.id,
      fromUserId: user.uid,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      type: type,
      message: message,
      sentAt: DateTime.now(),
    );

    await nudgeRef.set(nudge.toMap());
  }

  /// الاستماع المباشر لبيانات المجموعة
  Stream<FaithGroup?> streamGroup(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FaithGroup.fromFirestore(doc);
    });
  }

  /// الاستماع المباشر لأعضاء المجموعة مرتبين حسب نسبة إنجاز اليوم تنازلياً
  Stream<List<GroupMember>> streamMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .orderBy('scorePercentage', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => GroupMember.fromFirestore(doc)).toList());
  }

  /// الاستماع المباشر لآخر رسائل التشجيع في المجموعة
  Stream<List<GroupNudge>> streamNudges(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('nudges')
        .orderBy('sentAt', descending: true)
        .limit(25)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => GroupNudge.fromFirestore(doc)).toList());
  }
}
