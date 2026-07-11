import 'package:flutter/services.dart' show rootBundle;
import 'package:home_widget/home_widget.dart';
import 'dart:convert';

import '../models/subject.dart';
import '../models/topic.dart';

/// "Günün Kilit Ekranı Kodu" (akılda kalıcı kodlama) özelliğinin gerçek OS
/// ana ekran widget'ı karşılığı.
///
/// JS tarafındaki karşılığı (referans davranış — birebir taşındı):
///   `c:\Users\PC\Desktop\KPSS\src\js\app.js` içindeki `_collectMnemonics()` /
///   `_dailyMnemonic()` fonksiyonları. O sürüm sadece uygulama içi bir kart
///   olarak gösteriliyordu (Electron masaüstü, gerçek OS widget'ı yoktu).
///   Burada aynı seçim mantığı `home_widget` paketi ile gerçek bir Android
///   App Widget / iOS Home Screen Widget'a yazılıyor.
///
/// Android tarafı: `android/app/src/main/kotlin/.../LockWidgetProvider.kt`
/// iOS tarafı: `ios/DailyCodeWidget/` (WidgetKit extension iskeleti — bkz. WIDGET_SETUP.md)
class LockWidgetService {
  LockWidgetService._();

  /// Android'de `home_widget` paketinin App Widget'ı bulması için kullandığı
  /// isim. `LockWidgetProvider.kt`'deki sınıf adıyla birebir aynı olmalı.
  static const String androidWidgetName = 'LockWidgetProvider';

  /// iOS'ta WidgetKit widget'ının `kind` değeriyle birebir aynı olmalı
  /// (bkz. ios/DailyCodeWidget/DailyCodeWidget.swift → `kind: "DailyCodeWidget"`).
  static const String iosWidgetName = 'DailyCodeWidget';

  /// iOS'ta App + Widget Extension arasında veri paylaşımı için gereken
  /// App Group kimliği. Gerçek bir Apple Developer takımı/App Group
  /// oluşturulunca bu değer güncellenmeli (bkz. WIDGET_SETUP.md).
  static const String iosAppGroupId = 'group.com.kpsshazirlik.kpss_telefon';

  /// HomeWidget.saveWidgetData ile yazılan anahtarlar. Android layout'unda
  /// (`res/layout/lock_widget_layout.xml`) ve iOS widget'ında bu anahtarlarla
  /// eşleşen alanlar okunur.
  static const String keyEyebrow = 'lock_widget_eyebrow'; // "Ders • Konu"
  static const String keyText = 'lock_widget_text'; // asıl kodlama metni
  static const String keyUpdatedAt = 'lock_widget_updated_at';

  /// Günün mnemonik'ini seçer, home_widget'a yazar ve native widget'ların
  /// yeniden çizilmesini tetikler.
  ///
  /// Uygulama her açıldığında (ör. `main.dart`'taki başlangıç akışından ya da
  /// ana ekran `initState`'inden) çağrılabilir. main.dart'a şu an dokunulmadı;
  /// entegre eden kişi tek satırla `LockWidgetService.updateDailyWidget();`
  /// çağırabilir.
  static Future<void> updateDailyWidget() async {
    final mnemonic = await _dailyMnemonic();
    if (mnemonic == null) return;

    // iOS App Group'unu her ihtimale karşı burada da ayarlıyoruz (main.dart'a
    // dokunmadan servis kendi kendine yeterli olsun diye). setAppGroupId
    // Android'de no-op'tur, güvenle çağrılabilir.
    await HomeWidget.setAppGroupId(iosAppGroupId);

    await HomeWidget.saveWidgetData<String>(keyEyebrow, mnemonic.eyebrow);
    await HomeWidget.saveWidgetData<String>(keyText, mnemonic.text);
    await HomeWidget.saveWidgetData<String>(
      keyUpdatedAt,
      DateTime.now().toIso8601String(),
    );

    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      iOSName: iosWidgetName,
    );
  }

  /// JS: `_collectMnemonics()` — tüm derslerin tüm konularındaki
  /// `anlatim.anahtarNoktalar` maddelerini tek bir listede toplar.
  static Future<List<_MnemonicItem>> _collectMnemonics() async {
    final items = <_MnemonicItem>[];
    for (final meta in kSubjects) {
      try {
        final raw = await rootBundle.loadString(meta.dosya);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final konular = (json['konular'] as List? ?? const [])
            .map((k) => Topic.fromJson(k as Map<String, dynamic>))
            .toList();
        for (final topic in konular) {
          for (final point in topic.anlatim.anahtarNoktalar) {
            items.add(
              _MnemonicItem(subjectAd: meta.ad, topicBaslik: topic.baslik, text: point),
            );
          }
        }
      } catch (_) {
        // Bir ders dosyası okunamasa bile diğerleriyle devam et.
      }
    }
    return items;
  }

  /// JS: `_dailyMnemonic()` — `dayOfYear % items.length` ile deterministik
  /// bir seçim yapar; aynı gün içinde her çağrıda aynı sonucu döndürür.
  static Future<_MnemonicItem?> _dailyMnemonic() async {
    final items = await _collectMnemonics();
    if (items.isEmpty) return null;
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays; // 0-based, JS ile aynı
    final index = dayOfYear % items.length;
    return items[index];
  }
}

class _MnemonicItem {
  final String subjectAd;
  final String topicBaslik;
  final String text;

  const _MnemonicItem({
    required this.subjectAd,
    required this.topicBaslik,
    required this.text,
  });

  String get eyebrow => '$subjectAd • $topicBaslik';
}
