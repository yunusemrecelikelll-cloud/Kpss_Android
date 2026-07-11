# KPSS Hazırlık — Android

Bu klasör, KPSS Hazırlık uygulamasının **sadece Android** için hazırlanmış sürümüdür.
`Kpss_Telefon` klasöründeki ortak Flutter kod tabanından türetildi; `ios/`, `web/`
ve `windows/` platform klasörleri kasıtlı olarak kaldırıldı — bu klasör Play Store'a
yüklenecek Android derlemesi için tek kaynaktır.

iOS sürümü için `Kpss_Ios` klasörüne bakın.

## Derleme

```
flutter pub get
flutter build apk --release      # ya da
flutter build appbundle --release  # Play Console yüklemesi için
```

## Notlar

- `lib/`, `assets/` ve `pubspec.yaml` içeriği Kpss_Ios ile birebir aynı tutulmalı —
  bundan sonraki özellik/hata düzeltme istekleri hem bu klasöre hem Kpss_Ios'a
  aynı şekilde uygulanacak.
- Firebase/Ödeme/Widget kurulumu için kök dizindeki `FIREBASE_SETUP.md`,
  `IAP_SETUP.md`, `WIDGET_SETUP.md` dosyalarına bakın.
