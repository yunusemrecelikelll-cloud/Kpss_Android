//
//  DailyCodeWidget.swift
//  DailyCodeWidget (WidgetKit Extension)
//
//  "Günün Kilit Ekranı Kodu" — KPSS Hazırlık uygulamasının iOS Ana Ekran
//  Widget'ı. Flutter tarafı (lib/services/lock_widget_service.dart) günün
//  akılda kalıcı kodlama metnini `home_widget` paketi ile App Group'taki
//  UserDefaults'a yazar; bu dosya o veriyi okuyup gösterir.
//
//  ÖNEMLİ (Windows'ta yazıldı, bir Mac + Xcode olmadan DERLENEMEZ/TEST
//  EDİLEMEZ):
//  Bu dosyanın gerçekten işe yaraması için bir Mac'te Xcode'da:
//    1) Runner.xcworkspace açılıp File > New > Target > Widget Extension
//       eklenmeli (adı "DailyCodeWidget" seçilmeli — bu dosya o target'ın
//       içine taşınmalı/eklenmeli, Xcode otomatik oluşturduğu şablon
//       dosyasının yerine bu içerik kullanılmalı).
//    2) Hem Runner hem DailyCodeWidgetExtension target'larına aynı App Group
//       (aşağıdaki `appGroupId` ile birebir aynı string) eklenmeli
//       (Signing & Capabilities > + Capability > App Groups).
//    3) Bkz. WIDGET_SETUP.md — adım adım talimatlar orada.
//
//  Bu dosyadaki `appGroupId` değeri, Dart tarafındaki
//  `LockWidgetService.iosAppGroupId` ile BİREBİR AYNI olmalı.
//  Bu dosyadaki `kind` değeri, Dart tarafındaki
//  `LockWidgetService.iosWidgetName` ile BİREBİR AYNI olmalı.
//

import SwiftUI
import WidgetKit

// TODO(Mac/Xcode): Gerçek bir App Group oluşturulunca bu ID'nin Apple
// Developer hesabındaki App Group ile eşleştiğinden emin ol.
private let appGroupId = "group.com.kpsshazirlik.kpss_telefon"

// home_widget paketinin Flutter tarafında `HomeWidget.saveWidgetData` ile
// yazdığı anahtarlar — bkz. LockWidgetService.keyEyebrow / keyText.
private let keyEyebrow = "lock_widget_eyebrow"
private let keyText = "lock_widget_text"

struct DailyCodeEntry: TimelineEntry {
    let date: Date
    let eyebrow: String
    let text: String
}

struct DailyCodeProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyCodeEntry {
        DailyCodeEntry(
            date: Date(),
            eyebrow: "Türkçe • Ses Bilgisi",
            text: "Büyük ünlü uyumu: ilk hecedeki ünlü kalınsa sonraki ünlüler de kalın olur."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyCodeEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyCodeEntry>) -> Void) {
        let entry = readEntry()
        // Günün kodu bir sonraki gün başlangıcına kadar geçerli; günde bir kez
        // yenilenmesi yeterli. Uygulama açıldığında da HomeWidget.updateWidget
        // çağrısıyla anında yenilenir.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(86_400)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func readEntry() -> DailyCodeEntry {
        let data = UserDefaults(suiteName: appGroupId)
        return DailyCodeEntry(
            date: Date(),
            eyebrow: data?.string(forKey: keyEyebrow) ?? "KPSS Hazırlık",
            text: data?.string(forKey: keyText)
                ?? "Bugünün kodunu görmek için uygulamayı bir kez aç."
        )
    }
}

struct DailyCodeWidgetEntryView: View {
    var entry: DailyCodeProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🔒 Günün Kilit Ekranı Kodu")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15)) // altın tonu

            Text(entry.eyebrow)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(entry.text)
                .font(.footnote)
                .lineLimit(4)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // TODO(Mac/Xcode, iOS 17+): containerBackground gerekir, aksi halde
        // Xcode uyarı verir. iOS 17 hedeflenmiyorsa bu satırı kaldırıp
        // .background(Color(...)) kullan.
        .containerBackground(Color(red: 0.11, green: 0.11, blue: 0.14), for: .widget)
    }
}

@main
struct DailyCodeWidget: Widget {
    // LockWidgetService.iosWidgetName ile birebir aynı olmalı.
    let kind: String = "DailyCodeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyCodeProvider()) { entry in
            DailyCodeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Günün Kilit Ekranı Kodu")
        .description("KPSS konularından günün akılda kalıcı kodlamasını gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyCodeWidget_Previews: PreviewProvider {
    static var previews: some View {
        DailyCodeWidgetEntryView(
            entry: DailyCodeEntry(
                date: Date(),
                eyebrow: "Türkçe • Ses Bilgisi",
                text: "Büyük ünlü uyumu: ilk hecedeki ünlü kalınsa sonraki ünlüler de kalın olur."
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
