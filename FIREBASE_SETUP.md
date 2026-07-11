# Firebase Kurulumu

Bu proje, bulut özellikleri (Google/Apple ile giriş, Genel Sohbet + DM, Yönetici ile
İletişim, Yarış Halinde Canlı Online Deneme, Bulut Yedekleme, Özel Lig) için Firebase
SDK'larını içerir (`pubspec.yaml`: `firebase_core`, `firebase_auth`, `cloud_firestore`,
`google_sign_in`, `sign_in_with_apple`) ve servis katmanı (`lib/services/*.dart`) hazırdır.

**Ancak** gerçek bir Firebase projesi henüz bağlanmadı. Bu dosyalardaki config
dosyaları eklenip aşağıdaki adımlar tamamlanana kadar `lib/firebase_bootstrap.dart`
içindeki `initFirebaseIfConfigured()` fonksiyonu hiçbir yerden çağrılmıyor — bu
sayede uygulama şu an tamamen "offline" modda, hatasız çalışıyor. Tüm servisler
(`AuthService`, `ChatService`, `SupportService`, `LiveExamService`,
`CloudSyncService`, `LeagueService`) Firebase yapılandırılmadığını algılayıp
sessizce devre dışı kalacak şekilde yazıldı.

Aşağıdaki adımları tamamladıktan sonra tek yapmanız gereken `main.dart`'ta
`runApp(...)` çağrısından önce şunu eklemek:

```dart
WidgetsFlutterBinding.ensureInitialized();
await initFirebaseIfConfigured();
```

(ve dosyanın başına `import 'firebase_bootstrap.dart';` eklemek.)

## 1. Firebase Console'da proje oluşturma

1. https://console.firebase.google.com adresine gidin, Google hesabınızla giriş yapın.
2. "Proje ekle" (Add project) düğmesine tıklayın.
3. Proje adını girin (ör. `kpss-hazirlik`), ilerleyin.
4. Google Analytics'i isterseniz açık bırakın ya da kapatın (bu uygulama için
   zorunlu değil), "Proje oluştur"a tıklayın.

## 2. Android uygulaması ekleme

1. Firebase Console'da projenizin içinde "Android" simgesine tıklayarak yeni bir
   Android uygulaması ekleyin.
2. **Android paket adı**: `com.kpsshazirlik.kpss_telefon` girin (bkz.
   `android/app/src/main/kotlin/com/kpsshazirlik/kpss_telefon/MainActivity.kt` ve
   `android/app/build.gradle.kts` içindeki `applicationId`).
3. Takma ad (nickname) ve SHA-1 imza sertifikası isteğe bağlıdır; Google ile giriş
   kullanacaksanız SHA-1'i eklemeniz **önerilir** (`cd android && ./gradlew
   signingReport` ile debug SHA-1'i alabilirsiniz).
4. `google-services.json` dosyasını indirin.
5. Bu dosyayı projede **`android/app/google-services.json`** konumuna koyun (yani
   `android/app/` klasörünün doğrudan içine — `android/app/src/` ile aynı seviyede).
6. Firebase Console'un gösterdiği Gradle eklentisi adımlarını uygulamanız gerekebilir
   (genellikle `android/build.gradle.kts` ve `android/app/build.gradle.kts` içine
   `com.google.gms.google-services` eklentisinin eklenmesi). `flutterfire configure`
   kullanırsanız (bkz. aşağıdaki "Alternatif" bölümü) bu adım otomatik yapılır.

## 3. iOS uygulaması ekleme

1. Firebase Console'da "iOS" simgesine tıklayarak yeni bir iOS uygulaması ekleyin.
2. **iOS bundle ID**: `ios/Runner.xcodeproj` içindeki `PRODUCT_BUNDLE_IDENTIFIER` ile
   aynı değeri girin (Xcode'da Runner target > General > Bundle Identifier'dan
   kontrol edebilirsiniz; henüz özelleştirilmediyse varsayılan
   `com.example.kpssTelefon` benzeri bir değer olabilir — Apple Developer hesabınızda
   kayıtlı gerçek bundle ID ile eşleştirin).
3. `GoogleService-Info.plist` dosyasını indirin.
4. Bu dosyayı **`ios/Runner/GoogleService-Info.plist`** konumuna koyun.
5. Xcode'u açıp (`ios/Runner.xcworkspace`) dosyayı "Runner" hedefine (target) sürükleyip
   bırakarak projeye dahil edin ("Copy items if needed" işaretli olsun) — sadece dosya
   sistemine kopyalamak yeterli değildir, Xcode proje dosyasına eklenmesi gerekir.
6. Apple ile giriş için Xcode'da Runner target > Signing & Capabilities > "+ Capability"
   > **Sign in with Apple** yeteneğini ekleyin.

## 4. Authentication sağlayıcılarını açma

1. Firebase Console > Build > Authentication > "Get started" (ilk kurulumdaysa).
2. "Sign-in method" sekmesinde:
   - **Google**: sağlayıcıyı etkinleştirin, destek e-postası seçin, kaydedin.
   - **Apple**: sağlayıcıyı etkinleştirin. Apple Developer hesabınızda "Sign in with
     Apple" özelliğinin App ID'nize eklenmiş olması gerekir (Apple Developer Portal >
     Certificates, Identifiers & Profiles > Identifiers > uygulamanızın App ID'si >
     "Sign in with Apple" kapasitesini işaretleyin).

## 5. Firestore'u güvenlik kurallarıyla başlatma

**Önemli**: "Test modunda başlat" (test mode) SEÇMEYİN — test modu 30 gün sonra
herkese kapanan ama o süre boyunca **herkese tam okuma/yazma izni** veren güvensiz bir
moddur. Bunun yerine:

1. Firebase Console > Build > Firestore Database > "Create database".
2. Konum seçin (ör. `eur3 (europe-west)` Türkiye'ye yakın bir bölge).
3. **"Start in production mode"** seçeneğini işaretleyin (bu, varsayılan olarak
   HERKESE KAPALI bir kural seti ile başlar).
4. Veritabanı oluşturulduktan sonra "Rules" sekmesine gidip aşağıdaki örnek kuralları
   yapıştırın ve "Publish" ile yayınlayın.

### Örnek güvenlik kuralları

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    // Genel sohbet: giriş yapmış herkes okuyabilir/yazabilir, sadece kendi
    // mesajını (senderUid alanı kendi uid'i ile eşleşen) oluşturabilir, mesajlar
    // düzenlenemez/silinemez (moderasyon Cloud Functions/admin panel üzerinden
    // yapılmalı).
    match /chat_messages/{messageId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.resource.data.senderUid == request.auth.uid;
      allow update, delete: if false;
    }

    // Sohbet/DM raporları: herkes kendi raporunu oluşturabilir, sadece admin
    // (custom claim: admin == true) okuyabilir/güncelleyebilir.
    match /chat_reports/{reportId} {
      allow create: if isSignedIn() && request.resource.data.reporterUid == request.auth.uid;
      allow read, update, delete: if isSignedIn() && request.auth.token.admin == true;
    }

    // Kullanıcı bazlı engelleme listesi: herkes sadece kendi listesini
    // okuyabilir/yazabilir.
    match /blocked_users/{uid}/users/{blockedUid} {
      allow read, write: if isOwner(uid);
    }

    // DM: sadece thread'in katılımcıları okuyabilir/yazabilir. Thread ID
    // "{küçükUid}_{büyükUid}" biçiminde (ChatService.threadIdFor) olduğundan,
    // isteği yapan kullanıcının uid'i thread ID içinde geçmelidir.
    match /dm_threads/{threadId} {
      allow read, write: if isSignedIn() && threadId.matches('.*' + request.auth.uid + '.*');

      match /messages/{messageId} {
        allow read: if isSignedIn() && threadId.matches('.*' + request.auth.uid + '.*');
        allow create: if isSignedIn()
          && threadId.matches('.*' + request.auth.uid + '.*')
          && request.resource.data.senderUid == request.auth.uid;
        allow update, delete: if false;
      }
    }

    // Destek biletleri: kullanıcı sadece kendi biletini oluşturabilir/okuyabilir,
    // günceleyemez (admin yanıtı admin panel/Cloud Functions üzerinden
    // adminReply/status alanlarını güncellemelidir).
    match /support_tickets/{ticketId} {
      allow create: if isSignedIn() && request.resource.data.uid == request.auth.uid;
      allow read: if isSignedIn() && resource.data.uid == request.auth.uid;
      allow update, delete: if isSignedIn() && request.auth.token.admin == true;
    }

    // Canlı sınavlar: herkes okuyabilir (başlangıç zamanı/durumu görmek için),
    // sadece admin oluşturabilir/güncelleyebilir.
    match /live_exams/{examId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && request.auth.token.admin == true;

      // Skorlar: herkes skor tablosunu okuyabilir, katılımcı SADECE kendi
      // skor dokümanını (doküman ID'si kendi uid'i olan) yazabilir.
      match /scores/{uid} {
        allow read: if isSignedIn();
        allow write: if isOwner(uid);
      }
    }

    // Bulut yedekleme: kullanıcı sadece kendi yedeğini okuyabilir/yazabilir.
    match /cloud_backups/{uid} {
      allow read, write: if isOwner(uid);
    }

    // Özel Lig skorları: herkes tüm skorları okuyabilir (yüzdelik dilim
    // hesaplamak için), kullanıcı sadece kendi skorunu yazabilir.
    match /league_scores/{uid} {
      allow read: if isSignedIn();
      allow write: if isOwner(uid);
    }
  }
}
```

Not: `request.auth.token.admin == true` gibi admin kontrolleri için Firebase
Authentication'da [custom claims](https://firebase.google.com/docs/auth/admin/custom-claims)
kullanılmalıdır (bir Cloud Function veya Admin SDK betiği ile belirli kullanıcılara
`admin: true` claim'i atanır). Bu proje kapsamında admin paneli henüz yok; bu kurallar
ileride bir admin panel/Cloud Functions eklendiğinde kullanılmaya hazır olacak şekilde
yazıldı.

## 6. flutter pub get ve doğrulama

Config dosyalarını ekledikten sonra:

```
flutter pub get
flutter analyze
```

çalıştırıp hata almadığınızı doğrulayın, ardından `lib/main.dart`'a yukarıdaki
`initFirebaseIfConfigured()` çağrısını ekleyip `flutter run` ile test edin.

## Alternatif: FlutterFire CLI ile otomatik kurulum

Adım 2-3'ü elle yapmak yerine, isterseniz [FlutterFire
CLI](https://firebase.google.com/docs/flutter/setup) kullanarak
`google-services.json` / `GoogleService-Info.plist` dosyalarını ve platforma özgü
Gradle/Xcode ayarlarını otomatik oluşturabilirsiniz:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

Bu komut ayrıca `lib/firebase_options.dart` adında bir dosya oluşturur; bu durumda
`Firebase.initializeApp()` çağrısını
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` olarak
güncellemeniz gerekir (bkz. `lib/firebase_bootstrap.dart` içindeki yorum).
