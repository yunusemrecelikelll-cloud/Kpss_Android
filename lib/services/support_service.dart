import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_bootstrap.dart';

/// "Yönetici ile İletişim" özelliği Firebase yapılandırılmadan ya da
/// kullanıcı giriş yapmadan kullanılmaya çalışılırsa fırlatılan istisna.
class SupportNotAvailableException implements Exception {
  final String reason;
  const SupportNotAvailableException(this.reason);
  @override
  String toString() => reason;
}

/// Bir destek bileti — 'support_tickets' koleksiyonundaki bir doküman.
class SupportTicket {
  final String id;
  final String uid;
  final String userName;
  final String subject;
  final String message;
  final String status; // 'open' | 'answered' | 'closed'
  final String? adminReply;
  final DateTime? createdAt;

  const SupportTicket({
    required this.id,
    required this.uid,
    required this.userName,
    required this.subject,
    required this.message,
    required this.status,
    required this.adminReply,
    required this.createdAt,
  });

  factory SupportTicket.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['createdAt'];
    return SupportTicket(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      adminReply: data['adminReply'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// "Yönetici ile İletişim" ekranı için basit destek bileti servis katmanı.
///
/// Firebase yapılandırılmamışsa veya kullanıcı giriş yapmamışsa
/// [submitTicket] [SupportNotAvailableException] fırlatır, [streamMyTickets]
/// ise boş bir liste yayınlayan bir stream döner.
class SupportService {
  static const String collection = 'support_tickets';

  bool get isConfigured => isFirebaseConfigured;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _currentUid => isConfigured ? FirebaseAuth.instance.currentUser?.uid : null;

  Future<void> submitTicket({
    required String userName,
    required String subject,
    required String message,
  }) async {
    if (!isConfigured) {
      throw const SupportNotAvailableException(
        'Destek talebi göndermek için Firebase henüz yapılandırılmadı.',
      );
    }
    final uid = _currentUid;
    if (uid == null) {
      throw const SupportNotAvailableException(
        'Destek talebi göndermek için önce giriş yapmalısınız.',
      );
    }
    final trimmedSubject = subject.trim();
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    await _db.collection(collection).add({
      'uid': uid,
      'userName': userName,
      'subject': trimmedSubject.isEmpty ? 'Genel' : trimmedSubject,
      'message': trimmedMessage,
      'status': 'open',
      'adminReply': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Giriş yapmış kullanıcının kendi biletlerini en yeniden en eskiye
  /// dinler. Firebase yapılandırılmamışsa ya da kullanıcı giriş yapmamışsa
  /// boş bir liste yayınlayan sabit bir stream döner.
  Stream<List<SupportTicket>> streamMyTickets() {
    final uid = _currentUid;
    if (!isConfigured || uid == null) {
      return Stream<List<SupportTicket>>.value(const []);
    }
    return _db
        .collection(collection)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SupportTicket.fromDoc).toList());
  }
}
