import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attempt.dart';
import '../models/question.dart';

/// storage.js'nin Dart/SharedPreferences karşılığı.
/// Çok kullanıcılı yapı: her anahtar aktif kullanıcı adına göre önekleniyor
/// (JS: kpss_v2_<kullanıcı>_<anahtar>), localStorage yerine SharedPreferences kullanılıyor.
class StorageService extends ChangeNotifier {
  SharedPreferences? _prefs;
  String _activeUser = '';

  static const _usersKey = 'kpss_v2_users';
  static const _activeKey = 'kpss_v2_active_user';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _activeUser = _prefs?.getString(_activeKey) ?? '';
  }

  String _safe(String name) {
    final buf = StringBuffer();
    for (final ch in name.runes) {
      final c = String.fromCharCode(ch);
      if (RegExp(r'[a-zA-Z0-9ğüşıöçĞÜŞİÖÇ]').hasMatch(c)) buf.write(c);
      else buf.write('_');
    }
    final s = buf.toString();
    return s.length > 40 ? s.substring(0, 40) : s;
  }

  String _prefix([String? forUser]) {
    final u = forUser ?? _activeUser;
    return u.isEmpty ? 'kpss_v2_legacy_' : 'kpss_v2_${_safe(u)}_';
  }

  dynamic _get(String key, [dynamic fallback]) {
    final raw = _prefs?.getString(_prefix() + key);
    if (raw == null) return fallback;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return fallback;
    }
  }

  dynamic _getFor(String user, String key, [dynamic fallback]) {
    final raw = _prefs?.getString(_prefix(user) + key);
    if (raw == null) return fallback;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _set(String key, dynamic value) async {
    await _prefs?.setString(_prefix() + key, jsonEncode(value));
    // Neredeyse tüm veri-değiştiren metodlar bu yardımcıdan geçiyor; tek noktadan
    // bildirim vererek Ana Sayfa/Profil gibi dinleyen ekranların (context.watch)
    // test bitince/rozet açılınca vb. otomatik yenilenmesini garantiliyoruz.
    notifyListeners();
  }

  // ── Kullanıcı yönetimi ──
  List<String> getUserList() {
    final raw = _prefs?.getString(_usersKey);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<String> addUser(String rawName) async {
    final name = rawName.trim().substring(0, rawName.trim().length.clamp(0, 24));
    final cap = name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
    final users = getUserList();
    if (!users.contains(cap)) {
      users.add(cap);
      await _prefs?.setString(_usersKey, jsonEncode(users));
    }
    return cap;
  }

  Future<void> deleteUser(String name) async {
    final prefix = _prefix(name);
    final keys = _prefs?.getKeys().where((k) => k.startsWith(prefix)).toList() ?? [];
    for (final k in keys) {
      await _prefs?.remove(k);
    }
    final users = getUserList()..remove(name);
    await _prefs?.setString(_usersKey, jsonEncode(users));
    if (_activeUser == name) {
      _activeUser = '';
      await _prefs?.remove(_activeKey);
    }
  }

  String getActiveUser() => _activeUser;

  Future<void> setActiveUser(String name) async {
    _activeUser = name;
    await _prefs?.setString(_activeKey, name);
    notifyListeners();
  }

  // ── Gender / karakter / isim ──
  String getUserGender() => _get('gender', '') as String;
  Future<void> setUserGender(String g) => _set('gender', g);
  String getUserGenderFor(String name) => (_getFor(name, 'gender', '')) as String;

  String getUserCharacter() => _get('character', '') as String;
  Future<void> setUserCharacter(String c) => _set('character', c);

  String getUserName() => _get('name', '') as String;
  Future<void> setUserName(String n) {
    final c = n.trim();
    if (c.isEmpty) return _set('name', '');
    return _set('name', c[0].toUpperCase() + c.substring(1).toLowerCase());
  }

  // ── Tamamlanan konular ──
  Map<String, bool> getCompletedTopics() => Map<String, bool>.from(_get('completed', <String, dynamic>{}));
  Future<void> markTopicCompleted(String id) async {
    final c = getCompletedTopics();
    c[id] = true;
    await _set('completed', c);
  }

  bool isTopicCompleted(String id) => getCompletedTopics()[id] == true;

  // ── Testler (attempts) ──
  List<Attempt> getAttempts() {
    final raw = _get('attempts', <dynamic>[]) as List;
    return raw.map((a) => Attempt.fromJson(Map<String, dynamic>.from(a as Map))).toList();
  }

  Future<void> addAttempt(Attempt a) async {
    final all = getAttempts()..add(a);
    await _set('attempts', all.map((x) => x.toJson()).toList());
  }

  List<Attempt> getAttemptsForTopic(String id) => getAttempts().where((a) => a.topicId == id).toList();

  int? getBestScore(String id) {
    final arr = getAttemptsForTopic(id);
    if (arr.isEmpty) return null;
    return arr.map((a) => a.skor).reduce((a, b) => a > b ? a : b);
  }

  // ── Kullanılan sorular (tekrar önleme, konu bazlı) ──
  List<String> getUsedQuestions(String topicId) {
    final all = Map<String, dynamic>.from(_get('used_qs', <String, dynamic>{}));
    return List<String>.from(all[topicId] as List? ?? const []);
  }

  Future<void> addUsedQuestions(String topicId, List<String> keys) async {
    final all = Map<String, dynamic>.from(_get('used_qs', <String, dynamic>{}));
    final existing = Set<String>.from(all[topicId] as List? ?? const []);
    existing.addAll(keys);
    all[topicId] = existing.toList();
    await _set('used_qs', all);
  }

  Future<void> resetUsedQuestions(String topicId) async {
    final all = Map<String, dynamic>.from(_get('used_qs', <String, dynamic>{}));
    all.remove(topicId);
    await _set('used_qs', all);
  }

  // ── Yanlışlar bankası ──
  List<Map<String, dynamic>> getWrongBank() =>
      List<Map<String, dynamic>>.from((_get('wrong', <dynamic>[]) as List).map((e) => Map<String, dynamic>.from(e as Map)));

  Future<void> addWrongQuestions(List<Question> questions, String subjectId, String subjectAd) async {
    final bank = getWrongBank();
    for (final q in questions) {
      final key = q.soru.length > 40 ? q.soru.substring(0, 40) : q.soru;
      final idx = bank.indexWhere((w) => w['key'] == key);
      if (idx == -1) {
        bank.add({
          'key': key,
          'subjectId': subjectId,
          'subjectAd': subjectAd,
          'soru': q.soru,
          'secenekler': q.secenekler,
          'dogruIndex': q.dogruIndex,
          'aciklama': q.aciklama,
          'distractorAciklama': q.distractorAciklama,
          'kaynak': q.kaynak,
          'count': 1,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        bank[idx]['count'] = (bank[idx]['count'] as int? ?? 1) + 1;
      }
    }
    final trimmed = bank.length > 200 ? bank.sublist(bank.length - 200) : bank;
    await _set('wrong', trimmed);
  }

  Future<void> removeFromWrongBank(String key) async {
    final bank = getWrongBank()..removeWhere((w) => w['key'] == key);
    await _set('wrong', bank);
  }

  Future<void> clearWrongBank() => _set('wrong', <dynamic>[]);

  // ── Rozetler ──
  List<String> getUnlockedBadges() => List<String>.from(_get('badges', <dynamic>[]));
  Future<bool> unlockBadge(String id) async {
    final b = getUnlockedBadges();
    if (!b.contains(id)) {
      b.add(id);
      await _set('badges', b);
      return true;
    }
    return false;
  }

  bool isBadgeUnlocked(String id) => getUnlockedBadges().contains(id);

  // ── Görevler ──
  Map<String, int> getMissionsDone() => Map<String, int>.from(_get('missions_done', <String, dynamic>{}));
  Future<void> markMissionDone(String id) async {
    final m = getMissionsDone();
    m[id] = DateTime.now().millisecondsSinceEpoch;
    await _set('missions_done', m);
  }

  bool isMissionDone(String id) => getMissionsDone().containsKey(id);

  Future<void> resetDailyMissions() async {
    final m = getMissionsDone();
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    m.removeWhere((k, v) => v < yesterday);
    await _set('missions_done', m);
  }

  // ── Seri (streak) ──
  Map<String, dynamic> getStreak() => Map<String, dynamic>.from(_get('streak', {'count': 0, 'lastDate': null}));

  Future<Map<String, dynamic>> touchStreak() async {
    final today = DateTime.now().toString().split(' ')[0];
    final s = getStreak();
    if (s['lastDate'] == today) return s;
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0];
    s['count'] = (s['lastDate'] == yesterday) ? (s['count'] as int) + 1 : 1;
    s['lastDate'] = today;
    await _set('streak', s);
    return s;
  }

  // ── Taslak test (yarım kalan) ──
  Future<void> saveDraft(Map<String, dynamic> state) => _set('draft', state);
  Map<String, dynamic>? getDraft() {
    final d = _get('draft', null);
    return d == null ? null : Map<String, dynamic>.from(d as Map);
  }

  Future<void> clearDraft() async {
    await _prefs?.remove(_prefix() + 'draft');
    notifyListeners();
  }

  // ── Ayarlar ──
  static const Map<String, dynamic> defaultSettings = {
    'theme': 'default',
    'particleEnabled': true,
    'particleColor': 'rainbow',
    'soundEnabled': true,
    'timerMode': 'auto',
    'secsPerQ': 65,
    'plan': 'free',
    'notifications': {'reminders': true, 'updates': true},
    'cloudBackupEnabled': false,
  };

  Map<String, dynamic> getSettings() {
    final stored = Map<String, dynamic>.from(_get('settings', <String, dynamic>{}));
    final merged = {...defaultSettings, ...stored};
    merged['notifications'] = {
      ...defaultSettings['notifications'] as Map<String, dynamic>,
      ...(stored['notifications'] as Map<String, dynamic>? ?? {}),
    };
    return merged;
  }

  Future<void> saveSettings(Map<String, dynamic> patch) async {
    final merged = {...getSettings(), ...patch};
    await _set('settings', merged); // _set zaten notifyListeners() çağırıyor
  }

  String getUserPlan() => (getSettings()['plan'] as String?) ?? 'free';
  Future<void> setUserPlan(String plan) => saveSettings({'plan': plan});
  bool isPremiumUser() => getUserPlan() == 'premium';

  Map<String, dynamic> getNotificationSettings() =>
      Map<String, dynamic>.from(getSettings()['notifications'] as Map);
  Future<void> saveNotificationSettings(Map<String, dynamic> cfg) async {
    final n = {...getNotificationSettings(), ...cfg};
    await saveSettings({'notifications': n});
  }

  bool getCloudBackupEnabled() => getSettings()['cloudBackupEnabled'] == true;
  Future<void> setCloudBackupEnabled(bool enabled) => saveSettings({'cloudBackupEnabled': enabled});

  // ── Kart Eşleştirme Oyunu: günlük hak takibi ──
  Map<String, dynamic> getCardGameState() {
    final today = DateTime.now().toString().split(' ')[0];
    final s = Map<String, dynamic>.from(_get('cardgame', {'date': today, 'plays': 0}));
    if (s['date'] != today) return {'date': today, 'plays': 0};
    return s;
  }

  Future<int> useCardGamePlay() async {
    final s = getCardGameState();
    s['plays'] = (s['plays'] as int) + 1;
    await _set('cardgame', s);
    return s['plays'] as int;
  }

  // ── Genel oyun günlük hak takibi (Kart Oyunu V2 / Solitaire) — JS: getGamePlayState/useGamePlay.
  // NOT: Kart Oyunu v1 kendi ayrı sayacını (getCardGameState/useCardGamePlay) kullanır; JS'te
  // FREE_CARDGAME_DAILY (v1) ile FREE_GAME_DAILY (v2/solitaire, oyun başına ayrı) farklı sayaçlardır.
  Map<String, dynamic> getGamePlayState(String gameId) {
    final today = DateTime.now().toString().split(' ')[0];
    final s = Map<String, dynamic>.from(_get('gameplays_$gameId', {'date': today, 'plays': 0}));
    if (s['date'] != today) return {'date': today, 'plays': 0};
    return s;
  }

  Future<int> useGamePlay(String gameId) async {
    final s = getGamePlayState(gameId);
    s['plays'] = (s['plays'] as int) + 1;
    await _set('gameplays_$gameId', s);
    return s['plays'] as int;
  }

  // ── Oyun ilerlemesi (Kart Oyunu V2 / Solitaire) — konu bazlı geçme takibi ──
  Map<String, bool> getGamePassedTopics(String gameId) =>
      Map<String, bool>.from(_get('game_passed_$gameId', <String, dynamic>{}));

  Future<void> markGameTopicPassed(String gameId, String topicId) async {
    final m = getGamePassedTopics(gameId);
    m[topicId] = true;
    await _set('game_passed_$gameId', m);
  }

  bool isGameTopicPassed(String gameId, String topicId) => getGamePassedTopics(gameId)[topicId] == true;

  // ── Çalışma kronometresi ──
  Map<String, int> getStudyTime() => Map<String, int>.from(_get('studytime', <String, dynamic>{}));
  Future<void> addStudyTime(String subjectId, int seconds) async {
    final t = getStudyTime();
    t[subjectId] = (t[subjectId] ?? 0) + seconds;
    await _set('studytime', t);
  }

  int getTotalStudyTime() => getStudyTime().values.fold(0, (a, b) => a + b);

  // ── Konu testi sıfırlama ──
  Future<void> resetTopicAttempts(String topicId) async {
    final remaining = getAttempts().where((a) => a.topicId != topicId).toList();
    await _set('attempts', remaining.map((x) => x.toJson()).toList());
    final c = getCompletedTopics()..remove(topicId);
    await _set('completed', c);
    await resetUsedQuestions(topicId);
    await clearDraft();
  }

  // ── İstatistik yardımcıları ──
  int? computeSubjectAvg(String subjectId) {
    final arr = getAttempts().where((a) => a.subjectId == subjectId).toList();
    if (arr.isEmpty) return null;
    return (arr.map((a) => a.skor).reduce((a, b) => a + b) / arr.length).round();
  }

  ({int solved, int correct, int rate, int tests}) computeOverall() {
    final a = getAttempts();
    final solved = a.fold(0, (s, x) => s + x.toplam);
    final correct = a.fold(0, (s, x) => s + x.dogru);
    final rate = solved > 0 ? ((correct / solved) * 100).round() : 0;
    return (solved: solved, correct: correct, rate: rate, tests: a.length);
  }
}
