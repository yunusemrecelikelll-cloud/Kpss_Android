# Uygulama İçi Satın Alma (IAP) Kurulumu

Bu doküman, `lib/services/purchase_service.dart` içindeki gerçek satın alma
entegrasyonunun mağaza tarafında nasıl aktif hale getirileceğini anlatır.
Kod tarafı hazır — eksik olan tek şey, senin kendi Apple Developer / Google
Play Console hesaplarında bu ürünleri tanımlaman.

## 1. Kodda kullanılan ürün ID'leri (DEĞİŞTİRME — mağazada BİREBİR aynı gir)

`lib/services/purchase_service.dart` içinde:

```dart
const String kOgrenciPremiumId = 'premium_ogrenci_aylik';
const String kTamPremiumId = 'premium_tam_aylik';
```

Mağazalarda tanımlayacağın ürün/abonelik ID'leri (App Store'da "Product ID",
Play Console'da "Product ID" / "Base plan ID") **harfi harfine** bu iki
string ile aynı olmalı:

| Sabit                  | ID (mağazada birebir bu şekilde girilecek) |
|------------------------|---------------------------------------------|
| `kOgrenciPremiumId`    | `premium_ogrenci_aylik`                     |
| `kTamPremiumId`        | `premium_tam_aylik`                         |

ID'ler eşleşmezse `queryProductDetails` boş döner ve uygulama satın alma
ekranında "Mağaza şu an kullanılamıyor" mesajı gösterir (çökmez, ama satın
alma da çalışmaz).

Eğer farklı ID kullanmak istersen: SADECE yukarıdaki iki sabiti değiştir,
başka hiçbir yeri değiştirmene gerek yok — servis ve ekran bu sabitler
üzerinden çalışıyor.

## 2. App Store Connect (iOS) kurulumu

1. https://appstoreconnect.apple.com → uygulamanı seç.
2. **Özellikler (Features) → Uygulama İçi Satın Almalar (In-App Purchases)**
   ya da **Abonelikler (Subscriptions)** bölümüne git. Premium'lar aylık
   yenilenen bir hizmet olduğu için **Otomatik Yenilenen Abonelik
   (Auto-Renewable Subscription)** tipini seç (tek seferlik "Non-Consumable"
   değil).
3. Önce bir **Abonelik Grubu (Subscription Group)** oluştur, örn.
   `kpss_premium_group` (aynı gruptaki abonelikler kullanıcı arasında
   yükseltme/düşürme ilişkisine girebilir — Öğrenci Premium ve Tam Premium'u
   aynı gruba koyman mantıklı).
4. Grubun içine iki abonelik ekle:
   - **Reference Name**: `Ogrenci Premium Aylik` (sadece App Store Connect
     içinde görünür, kullanıcı görmez)
     **Product ID**: `premium_ogrenci_aylik` ← kod ile birebir aynı olmalı
   - **Reference Name**: `Tam Premium Aylik`
     **Product ID**: `premium_tam_aylik` ← kod ile birebir aynı olmalı
5. Her abonelik için **Süre (Duration)**: 1 Ay (1 Month).
6. **Fiyatlandırma (Pricing)**: Apple, fiyatları kendi "fiyat katmanları"
   (price tiers) üzerinden yönetir; doğrudan "50 TL" yazamazsın, en yakın
   Apple fiyat katmanını seçersin.
   - Öğrenci Premium → Türkiye (TRY) fiyatı **50,00 TL**'ye en yakın katmanı seç.
   - Tam Premium → Türkiye (TRY) fiyatı **199,90 TL**'ye en yakın katmanı seç.
   - Apple otomatik olarak bu fiyatı diğer ülke/para birimlerine çevirir;
     istersen ülke bazında manuel override yapabilirsin.
7. Her abonelik için yerelleştirme (Türkçe) ekle: görünen ad + açıklama.
8. Vergi/banka bilgileri (Agreements, Tax, and Banking) App Store Connect'te
   tamamlanmış olmalı — yoksa ücretli ürünler "onaya hazır" olamaz.
9. Test için: **Sandbox test kullanıcısı** oluştur (Users and Access →
   Sandbox) ve cihazda bu hesapla test satın alması yap; gerçek para
   çekilmez.
10. Uygulamanın **StoreKit capability**'sinin Xcode projesinde açık olduğundan
    emin ol (Flutter `in_app_purchase` paketi bunu otomatik yönetir ama
    Xcode'da "Signing & Capabilities" altında In-App Purchase eklendiğini
    doğrulamakta fayda var).

## 3. Google Play Console (Android) kurulumu

1. https://play.google.com/console → uygulamanı seç.
2. **Monetize (Para Kazan) → Products → Subscriptions** bölümüne git
   (yeni Play Console'da "Abonelikler").
3. **Create subscription** ile iki abonelik oluştur:
   - **Product ID**: `premium_ogrenci_aylik` ← kod ile birebir aynı olmalı
     **Name**: Öğrenci Premium
   - **Product ID**: `premium_tam_aylik` ← kod ile birebir aynı olmalı
     **Name**: Tam Premium
4. Her abonelik için bir **Base plan** ekle (ör. `monthly-autorenew`),
   **Billing period**: 1 ay, **Renewal type**: Auto-renewing.
5. **Fiyatlandırma (Pricing)**: Base plan içinde ülke bazlı fiyat gir:
   - Türkiye (TRY) → Öğrenci Premium: **50,00 TL**
   - Türkiye (TRY) → Tam Premium: **199,90 TL**
   - "Kullan otomatik dönüşüm" seçeneğiyle diğer ülkelerin fiyatını Google'ın
     otomatik hesaplamasına bırakabilirsin ya da manuel girebilirsin.
6. Base plan'ı **Activate (Aktifleştir)** et — aktifleşmeden ürün
   `queryProductDetails` sorgusunda görünmez.
7. Uygulamanın Play Console'da en az bir kez **internal testing / kapalı
   test** kanalına yüklenmiş olması gerekir (ürünler sadece Play Store'a
   yayınlanmış/yüklü bir uygulama üzerinden sorgulanabilir — yerelde
   `flutter run` ile debug APK'da test satın alması çalışmaz, "License
   Testing" hesabı ve Play Console'a yüklenmiş bir build gerekir).
8. **License testing**: Play Console → Setup → License testing altında
   test Gmail hesapları ekle; bu hesaplarla yapılan satın almalarda gerçek
   para çekilmez.
9. `android/app/build.gradle` içindeki `applicationId`'nin Play Console'daki
   uygulama paket adıyla birebir aynı olduğundan emin ol.

## 4. Kodda değişiklik gerekiyor mu?

Hayır — ID'ler eşleştiği sürece `lib/services/purchase_service.dart` ve
`lib/screens/premium_screen.dart` olduğu gibi çalışır:
- `PurchaseService.init()` mağazayı sorgular, ürünler bulunursa fiyatları
  doğrudan mağazadan (App Store/Play Store'un döndürdüğü yerelleştirilmiş
  fiyat string'i) çeker ve ekranda gösterir.
- "Satın Al" butonu `buyNonConsumable` ile gerçek satın alma akışını açar
  (abonelikler de bu paket üzerinden bu metotla satın alınır — pakette ayrı
  bir "buySubscription" metodu yoktur, abonelik/tek seferlik ayrımı mağaza
  tarafındaki ürün tanımında yapılır).
- Satın alma tamamlanınca `StorageService.setUserPlan('premium')` çağrılır.

## 5. Sunucu Taraflı Makbuz Doğrulaması — NEDEN ŞART?

`purchase_service.dart` içindeki `_onPurchaseUpdate` şu an
`PurchaseStatus.purchased`/`restored` durumunu görünce **doğrudan client'ta**
premium'u açıyor. Bu, geliştirme/MVP aşaması için çalışır ama canlıya
çıkmadan önce **mutlaka** değiştirilmesi gerekir, çünkü:

- **Client-side kontrol atlatılabilir.** Cihazda root/jailbreak yapılmış ya
  da tersine mühendislikle değiştirilmiş bir istemci, hiç ödeme yapmadan
  `PurchaseStatus.purchased` durumunu simüle edip `setUserPlan('premium')`
  çağrısını tetikleyebilir. Kod istemci tarafında çalıştığı sürece bu riski
  tamamen ortadan kaldırmak mümkün değildir.
- **Mağaza tarafında iptal/iade olduğunda haberin olmaz.** Kullanıcı
  aboneliği iptal etse, iade alsa ya da "chargeback" yapsa bile, client bunu
  kendiliğinden öğrenemez; sadece bir sonraki `restorePurchases()` çağrısında
  ya da uygulama yeniden başlatıldığında fark edilebilir — bu da premium'un
  gereğinden uzun süre (haksız yere) açık kalmasına yol açar.
- **Tek doğruluk kaynağı sunucuda olmalı.** Gerçek üründe önerilen akış:
  1. İstemci satın alma sonrası `purchase.verificationData.serverVerificationData`
     değerini (iOS'ta App Store receipt / JWS, Android'de Play purchase
     token) bir backend'e (Cloud Function, kendi API sunucun vb.) gönderir.
  2. Backend bu veriyi **Apple App Store Server API** ya da **Google Play
     Developer API (Purchases.subscriptions.get)** ile doğrular — abonelik
     gerçekten aktif mi, hangi ürün, ne zamana kadar geçerli.
  3. Backend doğrulama sonucuna göre kullanıcının premium durumunu
     (örn. Firestore'da bir alan / custom claim) günceller.
  4. İstemci premium durumunu SharedPreferences/localStorage yerine bu
     sunucu kaynaklı durumdan okur (ya da en azından periyodik olarak
     sunucuyla senkronize eder).
  5. Google/Apple'ın **Server Notifications V2 (App Store Server
     Notifications) / Real-time Developer Notifications (RTDN)**
     webhook'larına abone olunursa iptal/iade/yenileme olayları anlık
     olarak backend'e düşer ve premium durumu otomatik güncellenir.

Bu proje şu an bir Firebase projesine bağlı olmadığı için (bkz.
`PORT_NOTES.md`), backend doğrulama adımı bilinçli olarak TODO bırakıldı —
`lib/services/purchase_service.dart` içinde tam olarak nereye ekleneceği
yorumla işaretlendi (`_onPurchaseUpdate` metodu içinde
"SUNUCU TARAFLI MAKBUZ DOĞRULAMASI" başlıklı blok).

## 6. Test / geliştirme modu fallback'i

Mağaza gerçekten kullanılamadığında (emülatör, mağaza hesabı yok, ürünler
henüz onaylanmamış) `PremiumScreen`, sadece `kDebugMode` derlemelerinde,
alt sayfada "Test/Geliştirme Modu: Premium'u Aç" butonu gösterir — bu buton
doğrudan `StorageService.setUserPlan('premium')` çağırır ve **gerçek ödeme
akışının yerine geçmez**; release derlemelerde (`kDebugMode == false`)
görünmez.
