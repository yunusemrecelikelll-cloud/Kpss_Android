import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase_bootstrap.dart';
import '../models/attempt.dart';
import 'storage_service.dart';

/// StorageService'teki yerel verinin (attempts, tamamlanan konular, rozetler)
/// Firestore'a yedeklenmesi/geri yüklenmesi için servis katmanı.
///
/// Kullanıcı giriş yapmamışsa ya da Firebase yapılandırılmamışsa [syncUp] ve
/// [syncDown] hiçbir şey yapmadan (no-op) `false` döner — hiçbir zaman
/// istisna fırlatıp uygulamayı çökertmez.
class CloudSyncService {
  static const String backupCollection = 'cloud_backups';

  bool get isConfigured => isFirebaseConfigured;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _currentUid => isConfigured ? FirebaseAuth.instance.currentUser?.uid : null;

  DocumentReference<Map<String, dynamic>>? _backupDocFor(String uid) {
    if (!isConfigured) return null;
    return _db.collection(backupCollection).doc(uid);
  }

  /// Yerel StorageService verisini Firestore'a yedekler (upsert/merge).
  /// Kullanıcı giriş yapmamışsa ya da Firebase yapılandırılmamışsa `false`
  /// döner ve hiçbir şey yapmaz.
  Future<bool> syncUp(StorageService storage) async {
    final uid = _currentUid;
    final doc = uid == null ? null : _backupDocFor(uid);
    if (doc == null) return false;

    try {
      final data = <String, dynamic>{
        'attempts': storage.getAttempts().map((a) => a.toJson()).toList(),
        'completed': storage.getCompletedTopics(),
        'badges': storage.getUnlockedBadges(),
        'missionsDone': storage.getMissionsDone(),
        'streak': storage.getStreak(),
        'studyTime': storage.getStudyTime(),
        'wrongBank': storage.getWrongBank(),
        'userName': storage.getUserName(),
        'plan': storage.getUserPlan(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await doc.set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('CloudSyncService.syncUp başarısız: $e');
      return false;
    }
  }

  /// Firestore'daki yedekten yerel StorageService'e geri yükler. Yalnızca
  /// EKSİK olan veriyi ekler (idempotent): zaten var olan denemeler tekrar
  /// eklenmez, tamamlanan konular ve rozetler zaten var olsa da tekrar
  /// işaretlenmesi zararsızdır (StorageService bu metodlarda kendi
  /// tekilliğini garanti eder).
  ///
  /// Kullanıcı giriş yapmamışsa, Firebase yapılandırılmamışsa ya da bulutta
  /// hiç yedek yoksa `false` döner.
  Future<bool> syncDown(StorageService storage) async {
    final uid = _currentUid;
    final doc = uid == null ? null : _backupDocFor(uid);
    if (doc == null) return false;

    try {
      final snap = await doc.get();
      if (!snap.exists) return false;
      final data = snap.data();
      if (data == null) return false;

      // Denemeler: yerelde hiç deneme yoksa buluttakileri geri yükle. Yerelde
      // zaten deneme varsa, bulut kopyasıyla birebir eşleşmeyen bir
      // birleştirme belirsiz kopyalara yol açabileceğinden dokunulmaz —
      // bu durumda önce syncUp ile yerel veri bulutla senkron edilmelidir.
      final localAttempts = storage.getAttempts();
      if (localAttempts.isEmpty) {
        final remoteAttempts = (data['attempts'] as List? ?? const [])
            .map((a) => Attempt.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
        for (final a in remoteAttempts) {
          await storage.addAttempt(a);
        }
      }

      final completed = Map<String, dynamic>.from(data['completed'] as Map? ?? const {});
      for (final entry in completed.entries) {
        if (entry.value == true) await storage.markTopicCompleted(entry.key);
      }

      final badges = List<String>.from(data['badges'] as List? ?? const []);
      for (final b in badges) {
        await storage.unlockBadge(b);
      }

      return true;
    } catch (e) {
      debugPrint('CloudSyncService.syncDown başarısız: $e');
      return false;
    }
  }
}
