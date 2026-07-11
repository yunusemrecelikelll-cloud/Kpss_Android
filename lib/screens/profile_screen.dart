import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import 'premium_screen.dart';

/// JS karşılığı: renderProfile() (src/js/app.js).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final name = storage.getActiveUser().isNotEmpty
        ? storage.getActiveUser()
        : (storage.getUserName().isNotEmpty ? storage.getUserName() : 'Aday');
    final premium = storage.isPremiumUser();
    final overall = storage.computeOverall();
    final streak = storage.getStreak();
    final streakCount = (streak['count'] as int?) ?? 0;
    final wrongCount = storage.getWrongBank().length;
    final badgeCount = storage.getUnlockedBadges().length;

    // JS: SUBJECTS.filter(s => s.data).map(...).filter(avg !== null)
    final subjectAverages = <({String id, String label, int avg})>[];
    for (final meta in kSubjects) {
      final avg = storage.computeSubjectAvg(meta.id);
      if (avg != null) subjectAverages.add((id: meta.id, label: meta.ad, avg: avg));
    }
    ({String id, String label, int avg})? bestSub;
    ({String id, String label, int avg})? worstSub;
    for (final s in subjectAverages) {
      if (bestSub == null || s.avg >= bestSub.avg) bestSub = s;
      if (worstSub == null || s.avg <= worstSub.avg) worstSub = s;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('👤 Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('👤 $name Profili',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text(
                            "Ücretsiz hesabın temel özetini, Premium'da ise detaylı analizleri gör.",
                            style: TextStyle(fontSize: 12.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Chip(
                          label: Text(premium ? 'Premium' : 'Ücretsiz'),
                          backgroundColor: premium
                              ? Colors.amber.withValues(alpha: 0.2)
                              : null,
                        ),
                        if (premium) ...[
                          const SizedBox(height: 4),
                          const Text('VIP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _StatCard(label: 'Genel Başarı', value: '${overall.rate}%', foot: 'Çözdüğün soruların başarı oranı.'),
                _StatCard(label: 'Çözülen Soru', value: '${overall.solved}', foot: 'Toplam tamamlanan soru adedi.'),
                _StatCard(label: 'Günlük Seri', value: '$streakCount', foot: 'Kesintisiz çalışma gün sayısı.'),
                _StatCard(label: 'Yanlışlar', value: '$wrongCount', foot: 'Yanlış soruların özel çalışma bankası.'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoBox(
                    title: '$badgeCount Rozet',
                    text: 'Topladığın rozetleri ve başarı puanlarını takip et.',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoBox(
                    title: bestSub != null ? '${bestSub.label} en iyi ders' : 'Daha fazla çöz',
                    text: bestSub != null ? 'Başarı oranın %${bestSub.avg}' : 'Test çözerek ilk dersini belirle.',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoBox(
                    title: worstSub != null ? '${worstSub.label} üzerinde çalış' : 'Henüz veri yok',
                    text: worstSub != null ? 'Başarı oranın %${worstSub.avg}' : 'Çözdüğün sorular burada listelenecek.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (premium)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📈 Konu Başarı Grafiği', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 14),
                      if (subjectAverages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Henüz yeterli veri yok. Birkaç test çöz, grafik burada oluşsun.'),
                        )
                      else
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              maxY: 100,
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(enabled: false),
                              gridData: const FlGridData(show: true, drawVerticalLine: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 42,
                                    getTitlesWidget: (value, meta) {
                                      final i = value.toInt();
                                      if (i < 0 || i >= subjectAverages.length) return const SizedBox.shrink();
                                      final label = subjectAverages[i].label;
                                      final short = label.length > 6 ? label.substring(0, 6) : label;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(short, style: const TextStyle(fontSize: 9)),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                for (var i = 0; i < subjectAverages.length; i++)
                                  BarChartGroupData(x: i, barRods: [
                                    BarChartRodData(
                                      toY: subjectAverages[i].avg.toDouble(),
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 20,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ]),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      const Text(
                        'Premium hesapta konu skorların görselleştirilir.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                color: Colors.amber.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🔒 Premium İstatistiklere Geç",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text(
                        "Ücretsiz hesapla temel verileri görürsün. Premium'da grafikler, konu analizi ve gelişmiş raporlar açılır.",
                        style: TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
                        child: const Text("Premium'a Geç →"),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (premium)
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
                    child: const Text('Premium Ayrıntıları Gör'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, foot;
  const _StatCard({required this.label, required this.value, required this.foot});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(foot, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title, text;
  const _InfoBox({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
