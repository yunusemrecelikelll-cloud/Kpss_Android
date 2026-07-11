import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_bootstrap.dart';

/// "Yarış Halinde Canlı Online Deneme" özelliği Firebase yapılandırılmadan
/// kullanılmaya çalışılırsa fırlatılan istisna.
class LiveExamNotConfiguredException implements Exception {
  const LiveExamNotConfiguredException();
  @override
  String toString() => 'Canlı deneme özelliği için Firebase henüz yapılandırılmadı.';
}

/// 'live_exams/{examId}' dokümanının modeli: başlangıç zamanı + hangi soru
/// setinin kullanılacağı bilgisi.
class LiveExamInfo {
  final String id;
  final String title;
  final String questionSetRef; // ör. subjectId/topicId veya ayrı bir koleksiyon yolu
  final DateTime? startAt;
  final String status; // 'scheduled' | 'live' | 'finished'
  final int questionCount;

  const LiveExamInfo({
    required this.id,
    required this.title,
    required this.questionSetRef,
    required this.startAt,
    required this.status,
    required this.questionCount,
  });

  factory LiveExamInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['startAt'];
    return LiveExamInfo(
      id: doc.id,
      title: data['title'] as String? ?? 'Canlı Deneme',
      questionSetRef: data['questionSetRef'] as String? ?? '',
      startAt: ts is Timestamp ? ts.toDate() : null,
      status: data['status'] as String? ?? 'scheduled',
      questionCount: data['questionCount'] as int? ?? 0,
    );
  }
}

/// 'live_exams/{examId}/scores' altındaki bir katılımcı skoru.
class LiveExamScoreEntry {
  final String uid;
  final String displayName;
  final int score;
  final int correct;
  final int answered;
  final DateTime? updatedAt;

  const LiveExamScoreEntry({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.correct,
    required this.answered,
    required this.updatedAt,
  });

  factory LiveExamScoreEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['updatedAt'];
    return LiveExamScoreEntry(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Yarışmacı',
      score: data['score'] as int? ?? 0,
      correct: data['correct'] as int? ?? 0,
      answered: data['answered'] as int? ?? 0,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// "Yarış Halinde Canlı Online Deneme" için servis katmanı.
///
/// Bu sınıf SADECE veri katmanını sağlar (Firestore doküman/koleksiyon
/// okuma-yazma + anlık skor tablosu dinleme). Eşzamanlı sınav ekranı/UI'ı
/// ayrı bir işte bu servise bağlanacak.
///
/// Firebase yapılandırılmamışsa yazma metodları
/// [LiveExamNotConfiguredException] fırlatır, dinleme metodları ise boş/null
/// yayınlayan sabit stream'ler döner.
class LiveExamService {
  static const String examsCollection = 'live_exams';
  static const String scoresSubcollection = 'scores';

  bool get isConfigured => isFirebaseConfigured;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  void _requireConfigured() {
    if (!isConfigured) throw const LiveExamNotConfiguredException();
  }

  /// Yeni bir canlı sınav oturumu oluşturur (yönetici/organizatör tarafından
  /// çağrılması beklenir).
  Future<void> createLiveExam({
    required String examId,
    required String title,
    required DateTime startAt,
    required String questionSetRef,
    int questionCount = 20,
  }) async {
    _requireConfigured();
    await _db.collection(examsCollection).doc(examId).set({
      'title': title,
      'questionSetRef': questionSetRef,
      'questionCount': questionCount,
      'startAt': Timestamp.fromDate(startAt),
      'status': 'scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bir sınavın durumunu günceller (ör. 'live' ya da 'finished').
  Future<void> updateExamStatus(String examId, String status) async {
    _requireConfigured();
    await _db.collection(examsCollection).doc(examId).update({'status': status});
  }

  /// Tek bir sınav dokümanını (başlangıç zamanı, soru seti, durum) anlık
  /// dinler. Firebase yapılandırılmamışsa null yayınlayan sabit bir stream
  /// döner.
  Stream<LiveExamInfo?> streamExam(String examId) {
    if (!isConfigured) return Stream<LiveExamInfo?>.value(null);
    return _db
        .collection(examsCollection)
        .doc(examId)
        .snapshots()
        .map((doc) => doc.exists ? LiveExamInfo.fromDoc(doc) : null);
  }

  /// Bir katılımcının anlık skorunu 'live_exams/{examId}/scores/{uid}'
  /// dokümanına yazar/günceller (upsert).
  Future<void> submitScore({
    required String examId,
    required String uid,
    required String displayName,
    required int score,
    required int correct,
    required int answered,
  }) async {
    _requireConfigured();
    await _db
        .collection(examsCollection)
        .doc(examId)
        .collection(scoresSubcollection)
        .doc(uid)
        .set({
      'displayName': displayName,
      'score': score,
      'correct': correct,
      'answered': answered,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Bir sınavın anlık skor tablosunu, en yüksek skordan en düşüğe sıralı
  /// şekilde dinler. Firebase yapılandırılmamışsa boş bir liste yayınlayan
  /// sabit bir stream döner.
  Stream<List<LiveExamScoreEntry>> streamLeaderboard(String examId) {
    if (!isConfigured) return Stream<List<LiveExamScoreEntry>>.value(const []);
    return _db
        .collection(examsCollection)
        .doc(examId)
        .collection(scoresSubcollection)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LiveExamScoreEntry.fromDoc).toList());
  }
}
