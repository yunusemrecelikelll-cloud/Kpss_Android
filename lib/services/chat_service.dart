import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_bootstrap.dart';

/// Genel sohbet / DM özellikleri Firebase yapılandırılmadan kullanılmaya
/// çalışılırsa fırlatılan istisna.
class ChatNotConfiguredException implements Exception {
  const ChatNotConfiguredException();
  @override
  String toString() =>
      'Sohbet özelliği için Firebase henüz yapılandırılmadı. '
      'google-services.json / GoogleService-Info.plist eklenip '
      'initFirebaseIfConfigured() çağrıldıktan sonra aktif olacak.';
}

/// Bir mesaj gönderilmeden önce basit kötü-söz filtresine takıldığında
/// fırlatılan istisna. Ekran bunu yakalayıp kullanıcıya "mesajın uygunsuz
/// içerik barındırıyor" gibi bir uyarı gösterebilir.
class ProfanityDetectedException implements Exception {
  final String matchedWord;
  const ProfanityDetectedException(this.matchedWord);
  @override
  String toString() => 'Mesaj uygunsuz bir kelime içeriyor: $matchedWord';
}

/// Genel sohbet mesajı — 'chat_messages' koleksiyonundaki bir doküman.
class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String character;
  final String message;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.character,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['createdAt'];
    return ChatMessage(
      id: doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Bilinmeyen',
      character: data['character'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// İki kullanıcı arasındaki özel mesaj — 'dm_threads/{threadId}/messages'
/// altındaki bir doküman.
class DirectMessage {
  final String id;
  final String senderUid;
  final String message;
  final DateTime? createdAt;

  const DirectMessage({
    required this.id,
    required this.senderUid,
    required this.message,
    required this.createdAt,
  });

  factory DirectMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['createdAt'];
    return DirectMessage(
      id: doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Genel sohbet + DM + basit moderasyon (kötü-söz filtresi, rapor, engelleme)
/// servis katmanı.
///
/// Firebase yapılandırılmamışsa (bkz. [isFirebaseConfigured]) yazma
/// metodları [ChatNotConfiguredException] fırlatır, dinleme (stream)
/// metodları ise boş bir liste yayınlayan bir stream döner — hiçbir zaman
/// uygulamayı çökertmez.
class ChatService {
  static const String chatCollection = 'chat_messages';
  static const String reportsCollection = 'chat_reports';
  static const String dmCollection = 'dm_threads';
  static const String blockedCollection = 'blocked_users';

  /// Çok kısa, temel bir uygunsuz kelime listesi. Gerçek bir moderasyon
  /// ekibi/servisi (ör. Cloud Functions + üçüncü parti bir moderasyon API'si)
  /// devreye alınana kadar en azından bariz küfürleri engelleyen bir güvenlik
  /// ağı. Liste kolayca genişletilebilir.
  static const List<String> _bannedWords = [
    'aptal',
    'gerizekalı',
    'salak',
    'mal',
    'yavşak',
    'piç',
    'orospu',
    'ibne',
    'amk',
    'aq',
    'siktir',
    'kahpe',
    'göt',
  ];

  bool get isConfigured => isFirebaseConfigured;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Verilen metnin basit kötü-söz listesine göre uygunsuz olup olmadığını
  /// döner. Türkçe karakter/aksan farklarını normalize etmeden, düz
  /// küçük-harf alt-dize eşleşmesi yapar (basit ama gerçek bir kontrol).
  bool containsProfanity(String text) {
    final lower = text.toLowerCase();
    return _bannedWords.any((w) => lower.contains(w));
  }

  /// [text] içinde geçen ilk yasaklı kelimeyi döner, yoksa null.
  String? findProfanity(String text) {
    final lower = text.toLowerCase();
    for (final w in _bannedWords) {
      if (lower.contains(w)) return w;
    }
    return null;
  }

  void _requireConfigured() {
    if (!isConfigured) throw const ChatNotConfiguredException();
  }

  // ── Genel sohbet ──

  /// Mesajı, gönderilmeden önce kötü-söz filtresinden geçirerek
  /// 'chat_messages' koleksiyonuna yazar. Filtreye takılırsa
  /// [ProfanityDetectedException] fırlatır ve mesaj GÖNDERİLMEZ.
  Future<void> sendMessage({
    required String senderUid,
    required String senderName,
    required String character,
    required String message,
  }) async {
    _requireConfigured();
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    final bad = findProfanity(trimmed);
    if (bad != null) throw ProfanityDetectedException(bad);

    await _db.collection(chatCollection).add({
      'senderUid': senderUid,
      'senderName': senderName,
      'character': character,
      'message': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Genel sohbet akışını en yeniden en eskiye dinler. Firebase
  /// yapılandırılmamışsa boş bir liste yayınlayan sabit bir stream döner.
  Stream<List<ChatMessage>> streamMessages({int limit = 200}) {
    if (!isConfigured) return Stream<List<ChatMessage>>.value(const []);
    return _db
        .collection(chatCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Bir mesajı 'chat_reports' koleksiyonuna rapor eder (moderatörlerin
  /// incelemesi için). Mesajın kendisini silmez.
  Future<void> reportMessage({
    required String messageId,
    required String reporterUid,
    required String reason,
  }) async {
    _requireConfigured();
    await _db.collection(reportsCollection).add({
      'messageId': messageId,
      'collection': chatCollection,
      'reporterUid': reporterUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }

  /// Bir kullanıcıyı yerel/bulut engelli listesine ekler — engellenen
  /// kullanıcının mesajları istemci tarafında filtrelenebilir. Basit bir
  /// tamamlayıcı; tam bir engelleme motoru değildir.
  Future<void> blockUser({required String myUid, required String blockedUid}) async {
    _requireConfigured();
    await _db
        .collection(blockedCollection)
        .doc(myUid)
        .collection('users')
        .doc(blockedUid)
        .set({'blockedAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblockUser({required String myUid, required String blockedUid}) async {
    _requireConfigured();
    await _db
        .collection(blockedCollection)
        .doc(myUid)
        .collection('users')
        .doc(blockedUid)
        .delete();
  }

  Stream<Set<String>> streamBlockedUids(String myUid) {
    if (!isConfigured) return Stream<Set<String>>.value(const {});
    return _db
        .collection(blockedCollection)
        .doc(myUid)
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  // ── Kullanıcıdan kullanıcıya özel mesaj (DM) ──

  /// İki kullanıcı arasındaki DM thread kimliğini belirlenimli (deterministic)
  /// biçimde üretir: uid'ler sıralanıp birleştirilir, böylece hangi kullanıcı
  /// başlatırsa başlatsın her zaman aynı doküman yoluna yazılır/okunur.
  String threadIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendDirectMessage({
    required String fromUid,
    required String toUid,
    required String message,
  }) async {
    _requireConfigured();
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    final bad = findProfanity(trimmed);
    if (bad != null) throw ProfanityDetectedException(bad);

    final threadId = threadIdFor(fromUid, toUid);
    final threadRef = _db.collection(dmCollection).doc(threadId);
    await threadRef.set({
      'participants': [fromUid, toUid]..sort(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await threadRef.collection('messages').add({
      'senderUid': fromUid,
      'message': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<DirectMessage>> streamDirectMessages({
    required String uidA,
    required String uidB,
    int limit = 200,
  }) {
    if (!isConfigured) return Stream<List<DirectMessage>>.value(const []);
    final threadId = threadIdFor(uidA, uidB);
    return _db
        .collection(dmCollection)
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(DirectMessage.fromDoc).toList());
  }

  /// Bir DM mesajını rapor eder — genel sohbet raporlarıyla aynı
  /// 'chat_reports' koleksiyonuna, hangi thread'e ait olduğu bilgisiyle yazar.
  Future<void> reportDirectMessage({
    required String uidA,
    required String uidB,
    required String messageId,
    required String reporterUid,
    required String reason,
  }) async {
    _requireConfigured();
    await _db.collection(reportsCollection).add({
      'messageId': messageId,
      'collection': '$dmCollection/${threadIdFor(uidA, uidB)}/messages',
      'reporterUid': reporterUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }
}
