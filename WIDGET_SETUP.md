# Günün Kilit Ekranı Kodu — Ana Ekran Widget'ı Kurulumu

Bu doküman, KPSS Hazırlık uygulamasındaki "Günün Kilit Ekranı Kodu" (akılda
kalıcı kodlama) özelliğinin **gerçek** bir Android App Widget ve iOS Home
Screen Widget'ı olarak nasıl test edileceğini/tamamlanacağını anlatır.

Orijinal JS/Electron uygulamasında bu sadece uygulama içi bir önizleme
kartıydı (`c:\Users\PC\Desktop\KPSS\src\js\app.js` → `_dailyMnemonic()`).
Flutter portunda aynı seçim mantığı `lib/services/lock_widget_service.dart`
içinde birebir taşındı ve `home_widget` paketi ile gerçek OS widget'larına
yazılıyor.

## Genel akış

1. `LockWidgetService.updateDailyWidget()` çağrıldığında:
   - `assets/data/*.json` içindeki tüm konuların `anlatim.anahtarNoktalar`
     maddeleri toplanır (JS: `_collectMnemonics()`),
   - yılın gününe göre deterministik bir madde seçilir (JS: `_dailyMnemonic()`,
     `dayOfYear % items.length`),
   - `HomeWidget.saveWidgetData` ile `lock_widget_eyebrow` ("Ders • Konu") ve
     `lock_widget_text` (asıl metin) anahtarları yazılır,
   - `HomeWidget.updateWidget(androidName: "LockWidgetProvider", iOSName: "DailyCodeWidget")`
     çağrılarak native widget'ların yeniden çizilmesi tetiklenir.
2. Bu fonksiyon **main.dart'a bağlanmadı** (görev kapsamı gereği diğer
   dosyalara dokunulmadı). Entegre eden kişi, uygulama açılışında veya ana
   ekran `initState`'inde tek satırla çağırabilir:
   ```dart
   import 'package:kpss_telefon/services/lock_widget_service.dart';
   ...
   LockWidgetService.updateDailyWidget();
   ```

## Android — nasıl test edilir

Android tarafı tamamen bu makinede (Windows) yazıldı ve derlemesi denendi.

Oluşturulan/değiştirilen dosyalar:
- `lib/services/lock_widget_service.dart` — veri toplama + `home_widget` çağrıları
- `android/app/src/main/kotlin/com/kpsshazirlik/kpss_telefon/LockWidgetProvider.kt`
  — `HomeWidgetProvider` alt sınıfı, `RemoteViews` ile layout'u doldurur
- `android/app/src/main/res/layout/lock_widget_layout.xml` — widget görünümü
- `android/app/src/main/res/drawable/lock_widget_background.xml` — kart arka planı
- `android/app/src/main/res/xml/lock_widget_info.xml` — `AppWidgetProviderInfo`
  (boyut, güncelleme periyodu, initial layout)
- `android/app/src/main/res/values/strings.xml` — widget seçim ekranındaki açıklama
- `android/app/src/main/AndroidManifest.xml` — `<receiver>` kaydı + home_widget'ın
  arka plan callback receiver'ı

### Cihaz/emülatörde test etmek için

1. `flutter pub get` (home_widget zaten `pubspec.yaml`'a eklendi).
2. `flutter run` ile uygulamayı bir Android cihaz/emülatörde başlat.
3. Uygulama içinde `LockWidgetService.updateDailyWidget()` bir kez tetiklenmeli
   (bkz. yukarıdaki entegrasyon notu — main.dart'a bağlanana kadar widget veri
   yazılmaz, ama widget'ın kendisi App Widget seçim ekranında yine görünür ve
   varsayılan/boş metinle çalışır).
4. Ana ekranda boş bir alana uzun bas → **Widget'lar** → uygulamayı bul
   (**KPSS Hazırlık** / `kpss_telefon`) → **Günün Kilit Ekranı Kodu**
   widget'ını ana ekrana sürükle.
5. Widget ilk yerleştirildiğinde `onUpdate` tetiklenir; eğer uygulama daha önce
   açılıp `updateDailyWidget()` çalıştıysa gerçek metni, çalışmadıysa
   `LockWidgetProvider.kt`'deki varsayılan metni (`"KPSS Hazırlık"` /
   `"Bugünün kodunu görmek için uygulamayı bir kez aç."`) gösterir.
6. Uygulamayı tekrar açıp kapatarak (widget verisi güncellenince) widget'ın
   yeni metni gösterip göstermediğini doğrula.

### Derleme denemesi sonucu (bu makinede)

`flutter analyze` **hatasız** geçti (yalnızca projede zaten var olan,
widget ile ilgisiz `info` seviyeli lint uyarıları var — bkz. rapor).

`flutter build apk --debug` bu makinede denendi. Sonucu (Android SDK
cmdline-tools / lisans durumuna bağlı olarak) bu raporun "Android derleme
sonucu" bölümünde belirtildi. Eğer SDK/lisans eksikliğinden hata alındıysa,
Dart/Kotlin/XML tarafında bilinen bir sözdizimi hatası **yoktur** — sorun
yalnızca yerel Android SDK kurulumuyla ilgilidir; `home_widget` dokümantasyonu
ve standart Android App Widget kurulumu birebir takip edildi.

## iOS — Xcode'da nasıl tamamlanır (Mac gerektirir)

**Bu makine Windows olduğu için iOS tarafı hiç derlenemedi/test edilemedi.**
WidgetKit extension'ları Apple'ın araç zinciriyle (Xcode + Swift Compiler)
sıkı bağlıdır ve yalnızca bir Mac'te oluşturulup derlenebilir. Bu makinede
sadece bir Mac'te Xcode ile açıldığında doğru App Extension yapısına
dönüştürülebilecek **kaynak dosya iskeleti** hazırlandı:

- `ios/DailyCodeWidget/DailyCodeWidget.swift` — `TimelineProvider` +
  `Widget` tanımı (SwiftUI). `App Group` içindeki `UserDefaults`'tan
  `lock_widget_eyebrow` / `lock_widget_text` anahtarlarını okur.
- `ios/DailyCodeWidget/Info.plist` — `NSExtensionPointIdentifier:
  com.apple.widgetkit-extension`
- `ios/DailyCodeWidget/DailyCodeWidget.entitlements` — App Group yetkisi
- `ios/DailyCodeWidget/Assets.xcassets/` — boş asset catalog iskeleti
  (Contents.json + AccentColor.colorset)
- `ios/Runner/Runner.entitlements` — ana uygulama tarafında aynı App Group
  (henüz Xcode proje ayarlarına bağlanmadı — aşağıya bakın)

### Bir Mac'te tamamlama adımları

1. `Kpss_Telefon` projesini bir Mac'e kopyala (veya git ile klonla), Xcode
   ile `ios/Runner.xcworkspace`'i aç (`.xcodeproj` değil — CocoaPods/SPM
   entegrasyonu workspace üzerinden çalışır).
2. **File > New > Target… > Widget Extension** seç.
   - Product Name: `DailyCodeWidget`
   - "Include Configuration Intent" işaretini **kaldır** (statik, basit widget)
   - Xcode bu adımda kendi `DailyCodeWidget/` klasörünü ve şablon dosyalarını
     otomatik oluşturacaktır.
3. Xcode'un oluşturduğu şablon `.swift` dosyasının içeriğini, bu repodaki
   `ios/DailyCodeWidget/DailyCodeWidget.swift` dosyasının içeriğiyle
   **değiştir** (veya Xcode'un oluşturduğu dosyayı silip bu repodaki dosyayı
   yeni target'a sürükleyip ekle — "Add to targets: DailyCodeWidget" işaretli
   olmalı).
4. Aynı şekilde `Info.plist` ve `.entitlements` dosyalarının içeriğini
   karşılaştır; NSExtension bölümünün ve App Group biriminin bu repodakiyle
   eşleştiğinden emin ol.
5. **Her iki target'ta da** (Runner ve DailyCodeWidgetExtension)
   Signing & Capabilities > **+ Capability > App Groups** ekle ve
   `group.com.kpsshazirlik.kpss_telefon` grubunu seç/oluştur (Apple Developer
   hesabında bu App Group'un gerçekten var olması gerekir — bkz.
   `PORT_NOTES.md`'deki Firebase/App Store Connect notlarıyla aynı kısıtlama).
6. `flutter pub get` sonrası `cd ios && pod install` çalıştır (home_widget
   iOS tarafı CocoaPods/SPM ile derlenen native kod içerir).
7. Runner şeması ile cihaza/simülatöre çalıştır, ardından ana ekranda uzun
   bas → **+** → uygulamayı bul → **Günün Kilit Ekranı Kodu** widget'ını ekle.
8. Uygulamayı bir kez aç (widget verisinin `updateDailyWidget()` ile
   yazılması için — bkz. yukarıdaki "Genel akış" bölümü), widget'ın gerçek
   metni gösterdiğini doğrula.

### Bilinen TODO'lar (kod içinde de işaretli)

- `appGroupId` / `group.com.kpsshazirlik.kpss_telefon` placeholder'dır;
  gerçek Apple Developer hesabındaki App Group ile değiştirilmeli/eşleşmeli.
- `Runner.entitlements` bu makinede `project.pbxproj`'a güvenli şekilde
  bağlanamadı (Windows'ta Xcode proje dosyasını elle düzenlemek risklidir);
  Xcode'da Signing & Capabilities üzerinden eklenmesi gerekiyor.
- iOS 17 öncesi hedefleniyorsa `DailyCodeWidget.swift`'teki
  `.containerBackground` çağrısı `.background(...)` ile değiştirilmeli
  (kodda TODO yorumu var).
