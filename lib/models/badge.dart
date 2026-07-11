/// Rozet tanımı — JS karşılığı: src/js/badges.js (Badges.DEFS)
class BadgeDef {
  final String id;
  final String icon;
  final String name;
  final String desc;

  const BadgeDef({
    required this.id,
    required this.icon,
    required this.name,
    required this.desc,
  });
}

/// Tüm rozet tanımlarının listesi — JS: Badges.getAll()
/// Kazanma koşulu kontrolü (Badges.check) burada YOK; bu liste sadece
/// tanımları taşır. Kazanılmış olup olmadığı StorageService.isBadgeUnlocked
/// ile kontrol edilir. Otomatik tetikleme (testi bitirince rozet kontrolü)
/// ayrı bir işte quiz akışına eklenebilir.
const List<BadgeDef> kBadgeDefs = [
  // — Görevler —
  BadgeDef(id: 'gorev-1', icon: '🎯', name: 'İlk Görev', desc: 'İlk günlük/haftalık görevini tamamladın'),
  BadgeDef(id: 'gorev-10', icon: '🏹', name: 'Görev Avcısı', desc: 'Toplam 10 görev tamamladın'),
  BadgeDef(id: 'gorev-50', icon: '🎖️', name: 'Görev Ustası', desc: 'Toplam 50 görev tamamladın'),
  // — Başlangıç —
  BadgeDef(id: 'ilk-adim', icon: '🌱', name: 'İlk Adım', desc: 'İlk testini çözdün!'),
  BadgeDef(id: 'hizli-basla', icon: '🚀', name: 'Hızlı Başla', desc: '3 farklı konu testi çözdün'),
  BadgeDef(id: 'pratisyen', icon: '📝', name: 'Pratisyen', desc: '10 farklı konu testi çözdün'),
  BadgeDef(id: 'uzman', icon: '🧠', name: 'Uzman', desc: '20 test çözdün'),

  // — Başarı —
  BadgeDef(id: 'yukselen', icon: '⭐', name: 'Yükselen Yıldız', desc: 'Bir konuda %70+ aldın'),
  BadgeDef(id: 'ustun', icon: '👑', name: 'Üstün Performans', desc: 'Bir testde %90+ aldın'),
  BadgeDef(id: 'mukemmel', icon: '✨', name: 'Mükemmel', desc: 'Bir testde hiç yanlış yapmadın'),
  BadgeDef(id: 'mukemmeliyetci', icon: '💫', name: 'Mükemmeliyetçi', desc: '3 farklı konuda %90+ aldın'),
  BadgeDef(id: 'genel-uzman', icon: '🎓', name: 'Genel Uzman', desc: 'Genel başarı oranın %70 üzeri'),
  BadgeDef(id: 'surekli-gelisim', icon: '📈', name: 'Sürekli Gelişim', desc: 'Aynı konuda skoru %10+ artırdın'),

  // — Seri & Çalışma —
  BadgeDef(id: 'devam-et', icon: '🔥', name: 'Devam Et!', desc: '3 günlük seri yaptın'),
  BadgeDef(id: 'seri-5', icon: '🌋', name: 'Ateş Halkası', desc: '5 günlük seri yaptın'),
  BadgeDef(id: 'azimli', icon: '💎', name: 'Azimli', desc: '7 günlük seri yaptın'),
  BadgeDef(id: 'sabahci', icon: '🌅', name: 'Sabahçı', desc: 'Sabah 6-10 arası test çözdün'),
  BadgeDef(id: 'gece-kusu', icon: '🌙', name: 'Gece Kuşu', desc: 'Gece 22-02 arası test çözdün'),

  // — Soru Sayısı —
  BadgeDef(id: 'toplam-50', icon: '🌸', name: '50 Soru', desc: 'Toplamda 50 soru çözdün'),
  BadgeDef(id: 'toplam-100', icon: '💯', name: '100 Soru', desc: 'Toplamda 100 soru çözdün'),
  BadgeDef(id: 'toplam-500', icon: '🌟', name: '500 Soru', desc: 'Toplamda 500 soru çözdün'),
  BadgeDef(id: 'toplam-1000', icon: '🏆', name: 'Efsane', desc: 'Toplamda 1000 soru çözdün'),
  BadgeDef(id: 'dogru-100', icon: '🎯', name: '100 Doğru', desc: 'Toplamda 100 doğru cevap verdin'),

  // — Çeşitlilik —
  BadgeDef(id: 'koleksiyoncu', icon: '🗂️', name: 'Koleksiyoncu', desc: '5 farklı derste test çözdün'),
  BadgeDef(id: 'hizli', icon: '⚡', name: 'Hızlı Düşünen', desc: "Bir testi 2 dk'dan kısa sürede tamamladın"),
  BadgeDef(id: 'mucadeleci', icon: '🏅', name: 'Mücadeleci', desc: 'Yanlış sorular bankasından 20+ soru çözdün'),
  BadgeDef(id: 'deneme-sav', icon: '🎯', name: 'Deneme Savaşçısı', desc: 'İlk 120 soruluk deneme testini tamamladın'),

  // — Ders Ustalıkları —
  BadgeDef(id: 'turkce-uzm', icon: '📖', name: 'Türkçe Ustası', desc: "Türkçe'nin tüm konularını tamamladın"),
  BadgeDef(id: 'mat-uzm', icon: '🔢', name: 'Matematik Ustası', desc: 'Matematiğin tüm konularını tamamladın'),
  BadgeDef(id: 'tarih-uzm', icon: '🏛️', name: 'Tarihçi', desc: 'Tarihin tüm konularını tamamladın'),
  BadgeDef(id: 'cog-uzm', icon: '🗺️', name: 'Gezgin', desc: 'Coğrafyanın tüm konularını tamamladın'),
  BadgeDef(id: 'vat-uzm', icon: '⚖️', name: 'Vatandaş', desc: 'Vatandaşlığın tüm konularını tamamladın'),
  BadgeDef(id: 'gk-uzm', icon: '📰', name: 'Güncel Takip', desc: 'Güncel Bilgiler konularını tamamladın'),
  BadgeDef(id: 'tam-kpss', icon: '👸', name: 'KPSS Prensi', desc: 'Tüm ders konularını tamamladın!'),
];
