import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import 'card_game_screen.dart';
import 'card_game_v2_screen.dart';
import 'solitaire_screen.dart';
import 'mnemonics_screen.dart';
import 'predictor_screen.dart';
import 'league_screen.dart';
import 'stopwatch_screen.dart';
import 'mentor_screen.dart';
import 'premium_screen.dart';

/// JS: FREE_CARDGAME_DAILY / FREE_GAME_DAILY — üç oyunun da günlük ücretsiz hakkı 3'tür
/// (JS'te her oyunun kendi ayrı sayacı vardır, bkz. StorageService.getGamePlayState).
const int kFreeGameDailyLimit = 3;

/// Oyunlar Hub — JS: renderToolsHub (eski adıyla "Araçlar").
class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  late final Future<List<Subject>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<DataService>().loadAll();
  }

  void _goPremiumGated(BuildContext context, bool premium, Widget screen) {
    if (!premium) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final premium = storage.isPremiumUser();

    return Scaffold(
      appBar: AppBar(title: const Text('🎮 Oyunlar')),
      body: FutureBuilder<List<Subject>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final subjects = snap.data!.where((s) => s.konular.isNotEmpty).toList();

          final cg = storage.getCardGameState();
          final cgLeft = (kFreeGameDailyLimit - (cg['plays'] as int)).clamp(0, kFreeGameDailyLimit);
          final g2 = storage.getGamePlayState('cardgame2');
          final g2Left = (kFreeGameDailyLimit - (g2['plays'] as int)).clamp(0, kFreeGameDailyLimit);
          final sol = storage.getGamePlayState('solitaire');
          final solLeft = (kFreeGameDailyLimit - (sol['plays'] as int)).clamp(0, kFreeGameDailyLimit);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Çalışmanı güçlendirecek oyunlar ve ekstra araçlar.',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey)),
              const SizedBox(height: 18),
              const _SectionTitle('🎮 Oyunlar'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  ToolCard(
                    icon: '🃏',
                    title: 'Kart Eşleştirme Oyunu',
                    desc: premium ? 'Sınırsız oyna.' : 'Bugün $cgLeft hakkın kaldı.',
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => CardGameScreen(subjects: subjects))),
                  ),
                  ToolCard(
                    icon: '🃏',
                    title: 'Kart Oyunu V2',
                    desc: 'Ders/konu seç, açık kartları eşleştir. '
                        '${premium ? "Sınırsız oyna." : "Bugün $g2Left hakkın kaldı."}',
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => CardGameV2Screen(subjects: subjects))),
                  ),
                  ToolCard(
                    icon: '🂡',
                    title: 'Solitaire',
                    desc: 'Ders/konu seç, kartları sırayla temizle. '
                        '${premium ? "Sınırsız oyna." : "Bugün $solLeft hakkın kaldı."}',
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => SolitaireScreen(subjects: subjects))),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _SectionTitle('🧰 Diğer Araçlar'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  ToolCard(
                    icon: '🧠',
                    title: 'Akılda Kalıcı Kodlama',
                    desc: 'Konuların kısa, şifreli özetleriyle hızlı tekrar.',
                    locked: !premium,
                    onTap: () => _goPremiumGated(context, premium, MnemonicsScreen(subjects: subjects)),
                  ),
                  ToolCard(
                    icon: '🎯',
                    title: 'Bugün Sınava Girsen Kaç Alırsın?',
                    desc: 'Geçmiş performansına göre tahmini puan.',
                    locked: !premium,
                    onTap: () => _goPremiumGated(context, premium, const PredictorScreen()),
                  ),
                  ToolCard(
                    icon: '🏆',
                    title: 'Özel Lig',
                    desc: 'Başarı seviyene göre lig rütbeni gör.',
                    locked: !premium,
                    onTap: () => _goPremiumGated(context, premium, const LeagueScreen()),
                  ),
                  ToolCard(
                    icon: '⏱️',
                    title: 'Çalışma Kronometresi',
                    desc: 'Ders bazlı çalışma sürelerini kaydet ve analiz et.',
                    locked: !premium,
                    onTap: () => _goPremiumGated(context, premium, const StopwatchScreen()),
                  ),
                  ToolCard(
                    icon: '🎓',
                    title: 'Mentörlük Seansları',
                    desc: 'Sınav stratejileri ve haftalık plan önerileri.',
                    locked: !premium,
                    onTap: () => _goPremiumGated(context, premium, const MentorScreen()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800));
}

/// Oyunlar/Araçlar hub'ındaki tek bir kart.
class ToolCard extends StatelessWidget {
  final String icon, title, desc;
  final bool locked;
  final VoidCallback onTap;
  const ToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locked ? '🔒' : icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  desc,
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium kilitli özellik ekranı — JS: renderLockedFeature.
class LockedFeatureCard extends StatelessWidget {
  final String title;
  final String desc;
  const LockedFeatureCard({super.key, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🔒 $title')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(desc, style: const TextStyle(color: Colors.grey, height: 1.6)),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
                  child: const Text("Premium'a Geç"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
