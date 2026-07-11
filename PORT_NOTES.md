# KPSS Hazırlık — Flutter Port Notları

Bu proje, `c:\Users\PC\Desktop\KPSS` altındaki web/Electron uygulamasının Flutter (Dart) ile
Android + iOS için yeniden yazılmış halidir. Orijinal JS kodu (`src/js/*.js`), her ekranın/
özelliğin **davranış referansıdır** — bir ekranı port ederken önce oradaki karşılığını oku.

## Mimari

- `lib/models/` — Question, Topic, Subject, Attempt/ReviewItem/KpssPoints (JSON şeması JS ile birebir aynı)
- `lib/services/data_service.dart` — assets/data/*.json yükler (JS: loadAllSubjects)
- `lib/services/storage_service.dart` — storage.js'nin SharedPreferences karşılığı, ChangeNotifier.
  Çok kullanıcılı yapı korunuyor (`kpss_v2_<kullanıcı>_<anahtar>` önekleri).
- `lib/services/quiz_engine.dart` — quiz.js karşılığı (start/answer/next/prev/finish/draft)
- `lib/services/timer_service.dart` — timer.js karşılığı, basit saniye sayacı
- `lib/services/question_picker.dart` — pickQuestions (app.js) karşılığı + free(20)/premium(100) havuz sınırı
- `lib/theme/app_theme.dart` — styles.css'teki 6 temanın (:root ve [data-theme]) birebir renk karşılığı
- `lib/theme/theme_provider.dart` — aktif tema yönetimi
- `lib/screens/` — her ekran bir dosya, Navigator.push ile ilerliyor (go_router eklendi ama henüz
  kullanılmıyor; basit projelerde MaterialPageRoute yeterli, karmaşıklaşırsa go_router'a geçilebilir)

## Önemli davranış kararları (JS tarafında zaten çözüldü, aynen taşınmalı)

- **Soru başına süre modu**: Bir soruya tekrar cevap verme/değiştirme, süreyi SIFIRLAMAMALI.
  Önceki soruya dönünce o sorunun kalan süresinden devam etmeli. Süresi dolan bir soruya geri
  dönülürse şıklar tıklanamaz olmalı + üstte uyarı banner'ı çıkmalı. Bu mantık
  `lib/screens/quiz_screen.dart`'ta `_perqRemaining`/`_perqTimerIndex` ile zaten uygulandı —
  yeni ekranlar bu deseni bozmamalı.
- **Cevap toggle**: Aynı şıkka ikinci kez tıklayınca seçim iptal olur (null'a döner).
- **Buton yerleşimi**: "Testi Bitir" solda (Önceki ile birlikte), "Sonraki →" sağda.
- **Ücretsiz/Premium limitleri**:
  - Konu testi: ücretsiz 2 deneme (10'ar soru, 20 soruluk havuzdan), premium sınırsız (100
    soruluk havuzdan, farklı sorular tükenince kullanılmışlar karıştırılıp tekrar gelir).
  - Tam deneme: ücretsiz 3 deneme, premium sınırsız.
  - Kart Eşleştirme Oyunu (v1/v2) ve Solitaire: ücretsiz günde 3 hak, premium sınırsız.
- **"Neden yanlış yaptım" analizi** ve **Yanlışlarım sayfası**: sadece premium.

## Yeni eklenecek özellikler (JS tarafında YOKTU, sadece burada — Firebase gerektirir)

Bunlar `lib/services/` altında ayrı servisler olarak eklenecek, henüz iskelet yok:
- Google/Apple ile giriş (firebase_auth + google_sign_in + sign_in_with_apple)
- Genel Sohbet + DM (cloud_firestore, temel bir küfür/uygunsuzluk filtresi + rapor/engelle
  butonu ekle — tam moderasyon ekibi yok ama en azından bu temel güvenlik ağı olsun)
- Yönetici ile İletişim (Firestore'da basit bir destek bileti koleksiyonu)
- Yarış Halinde Canlı Online Deneme (Firestore listener ile eşzamanlı başlangıç + anlık skor tablosu)
- Bulut Yedekleme (StorageService'in Firestore ile senkronizasyonu — şu an sadece yerel)
- Özel Lig (gerçek çok kullanıcılı, Firestore skorlarına göre yüzdelik dilim)

**ÖNEMLİ**: Bu özellikler gerçek bir Firebase projesi (google-services.json /
GoogleService-Info.plist) olmadan derlenip test edilemez. O dosyalar gelene kadar bu
servisleri "interface hazır, gerçek Firebase çağrıları TODO" şeklinde iskelet olarak bırak.

## Ödeme (in_app_purchase)

`lib/services/purchase_service.dart` eklenecek (StoreKit/Play Billing). Ürün ID'leri gerçek
App Store Connect / Play Console kayıtlarına bağlı olduğu için placeholder ID kullan
(`premium_ogrenci_aylik`, `premium_tam_aylik` gibi) ve net bir TODO yorumuyla işaretle.

## Test etme

```
flutter analyze
flutter run -d web-server --web-port=8090 --web-hostname=localhost
```
Web hedefi hızlı iterasyon için kullanılıyor (Android SDK cmdline-tools henüz eksik,
iOS bu makinede hiç derlenemez — Mac gerekiyor).
