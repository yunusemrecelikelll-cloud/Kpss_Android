import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase_bootstrap.dart';
import 'storage_service.dart';

/// "Özel Lig" ligi/kademesi.
enum LeagueTier { bronz, gumus, altin, platin }

extension LeagueTierLabel on LeagueTier {
  String get label => switch (this) {
        LeagueTier.bronz => 'Bronz',
        LeagueTier.gumus => 'Gümüş',
        LeagueTier.altin => 'Altın',
        LeagueTier.platin => 'Platin',
      };
}

/// Gerçek zamanlı Firestore skorlarına göre hesaplanan lig sonucu.
class LeagueResult {
  final LeagueTier tier;
  /// 0-100 arası: katılımcıların yüzde kaçından daha iyi (ya da eşit)
  /// olduğu.
  final double percentile;
  final int totalParticipants;
  final int myRate;

  const LeagueResult({
    required this.tier,
    required this.percentile,
    required this.totalParticipants,
    required this.myRate,
  });
}

/// Firestore'daki gerçek kullanıcı skorlarına göre "Özel Lig" yüzdelik
/// dilimini hesaplayan servis.
///
/// Firebase yapılandırılmamışsa, kullanıcı giriş yapmamışsa ya da ağ
/// hatası/offline durum varsa [computeMyLeagueTier] `null` döner — hiçbir
/// zaman istisna fırlatıp uygulamayı çökertmez.
class LeagueService {
  static const String scoresCollection = 'league_scores';

  bool get isConfigured => isFirebaseConfigured;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _currentUid => isConfigured ? FirebaseAuth.instance.currentUser?.uid : null;

  /// Kendi güncel skorunu (StorageService.computeOverall'dan) Firestore'daki
  /// toplu havuza yayınlar, böylece diğer kullanıcılar da bu kullanıcıyla
  /// karşılaştırılabilir. computeMyLeagueTier() bunu otomatik çağırır.
  Future<void> publishMyScore(StorageService storage) async {
    final uid = _currentUid;
    if (!isConfigured || uid == null) return;
    try {
      final overall = storage.computeOverall();
      await _db.collection(scoresCollection).doc(uid).set({
        'displayName': storage.getUserName(),
        'rate': overall.rate,
        'solved': overall.solved,
        'correct': overall.correct,
        'tests': overall.tests,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('LeagueService.publishMyScore başarısız: $e');
    }
  }

  /// Kendi skorunu yayınlar ve Firestore'daki tüm katılımcı skorlarıyla
  /// karşılaştırıp bir [LeagueResult] (yüzdelik dilim + Bronz/Gümüş/Altın/
  /// Platin kademesi) döner.
  ///
  /// Firebase yapılandırılmamışsa, kullanıcı giriş yapmamışsa ya da bir ağ
  /// hatası oluşursa (offline) `null` döner.
  Future<LeagueResult?> computeMyLeagueTier(StorageService storage) async {
    final uid = _currentUid;
    if (!isConfigured || uid == null) return null;

    try {
      await publishMyScore(storage);
      final myOverall = storage.computeOverall();

      final snap = await _db.collection(scoresCollection).get();
      final rates = snap.docs
          .map((d) => (d.data()['rate'] as num?)?.toInt() ?? 0)
          .toList();

      if (rates.isEmpty) {
        return LeagueResult(
          tier: _tierFor(0),
          percentile: 0,
          totalParticipants: 1,
          myRate: myOverall.rate,
        );
      }

      final below = rates.where((r) => r < myOverall.rate).length;
      final percentile = (below / rates.length) * 100;

      return LeagueResult(
        tier: _tierFor(percentile),
        percentile: percentile,
        totalParticipants: rates.length,
        myRate: myOverall.rate,
      );
    } catch (e) {
      debugPrint('LeagueService.computeMyLeagueTier başarısız (offline olabilir): $e');
      return null;
    }
  }

  LeagueTier _tierFor(double percentile) {
    if (percentile >= 90) return LeagueTier.platin;
    if (percentile >= 70) return LeagueTier.altin;
    if (percentile >= 40) return LeagueTier.gumus;
    return LeagueTier.bronz;
  }
}
