import '../services/storage_service.dart';

/// Görev tanımı — JS karşılığı: src/js/missions.js (Missions.DEFS)
/// `check` her build'de canlı olarak StorageService verisine göre hesaplanır
/// (JS'teki d.check() ile birebir aynı mantık).
class MissionDef {
  final String id;
  final String icon;
  final String title;
  final String desc;
  final int pts;
  final bool Function(StorageService storage) check;

  const MissionDef({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
    required this.pts,
    required this.check,
  });
}

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

/// Tüm görev tanımlarının listesi — JS: Missions.getAll()
final List<MissionDef> kMissions = [
  MissionDef(
    id: 'daily-1test',
    icon: '📝',
    title: 'Günlük Test',
    desc: 'Bugün en az 1 test çöz',
    pts: 10,
    check: (storage) => storage.getAttempts().any((a) => _isToday(a.tarih)),
  ),
  MissionDef(
    id: 'daily-30q',
    icon: '🔥',
    title: '30 Soru',
    desc: 'Bugün toplam 30 soru çöz',
    pts: 20,
    check: (storage) {
      final total = storage
          .getAttempts()
          .where((a) => _isToday(a.tarih))
          .fold(0, (s, a) => s + a.toplam);
      return total >= 30;
    },
  ),
  MissionDef(
    id: 'daily-70pct',
    icon: '⭐',
    title: '%70 Başarı',
    desc: 'Herhangi bir testte %70+ al',
    pts: 15,
    check: (storage) =>
        storage.getAttempts().any((a) => _isToday(a.tarih) && a.skor >= 70),
  ),
  MissionDef(
    id: 'weekly-3topics',
    icon: '📚',
    title: '3 Farklı Konu',
    desc: 'Bu hafta 3 farklı konuyu çalış',
    pts: 25,
    check: (storage) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final topics = storage
          .getAttempts()
          .where((a) => a.tarih.isAfter(weekAgo))
          .map((a) => a.topicId)
          .toSet();
      return topics.length >= 3;
    },
  ),
  MissionDef(
    id: 'weekly-deneme',
    icon: '🎯',
    title: 'Deneme Sınavı',
    desc: 'Bu hafta 1 deneme sınavı çöz',
    pts: 30,
    check: (storage) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return storage
          .getAttempts()
          .any((a) => a.isFullTest && a.tarih.isAfter(weekAgo));
    },
  ),
];
