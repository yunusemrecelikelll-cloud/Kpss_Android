import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'tools_hub_screen.dart';

class _Tier {
  final String name;
  final String icon;
  const _Tier(this.name, this.icon);
}

/// JS: _tierFromRate — yerel başarı oranına göre lig rütbesi.
/// Not: JS'teki gerçek çok-kullanıcılı/çevrimiçi yüzdelik dilim kısmı (Leaderboard.getTopList)
/// Firebase gerektirdiği için bilinçli olarak atlandı; PORT_NOTES.md'de "Yeni eklenecek özellikler"
/// altında Firebase geldiğinde eklenmesi planlanan bir madde olarak listeleniyor.
_Tier _tierFromRate(int rate) {
  if (rate >= 80) return const _Tier('Platin', '💎');
  if (rate >= 60) return const _Tier('Altın', '🥇');
  if (rate >= 40) return const _Tier('Gümüş', '🥈');
  return const _Tier('Bronz', '🥉');
}

const _tiers = [_Tier('Bronz', '🥉'), _Tier('Gümüş', '🥈'), _Tier('Altın', '🥇'), _Tier('Platin', '💎')];

/// Özel Lig — JS: renderLeague.
class LeagueScreen extends StatelessWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    if (!storage.isPremiumUser()) {
      return const LockedFeatureCard(
        title: 'Özel Lig',
        desc: "Başarı seviyene göre lig rütbeni görmek için Premium'a geç.",
      );
    }

    final overall = storage.computeOverall();
    final tier = _tierFromRate(overall.rate);

    return Scaffold(
      appBar: AppBar(title: const Text('🏆 Özel Lig')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Text(tier.icon, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 8),
                  Text('${tier.name} Lig', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Genel başarı oranın: %${overall.rate} — yerel başarı oranına göre hesaplandı. '
                    'Çevrimiçi karşılaştırma yakında eklenecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final t in _tiers)
                Chip(
                  label: Text('${t.icon} ${t.name}'),
                  backgroundColor: t.name == tier.name
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
