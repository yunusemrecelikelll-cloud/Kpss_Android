import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../games/card_game_engine.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/theme_provider.dart';
import 'tools_hub_screen.dart';

/// JS: FREE_CARDGAME_DAILY
const int kFreeCardGameDaily = 3;

/// Kart Eşleştirme Oyunu (v1) — JS: renderCardGame / renderCardGameBoard.
/// Kapalı kartlar, hafıza oyunu — tüm derslerin karışık kart havuzundan oynanır.
class CardGameScreen extends StatefulWidget {
  final List<Subject> subjects;
  const CardGameScreen({super.key, required this.subjects});

  @override
  State<CardGameScreen> createState() => _CardGameScreenState();
}

class _CardGameScreenState extends State<CardGameScreen> {
  final _engine = CardGameEngine();
  bool _started = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final storage = context.read<StorageService>();
    final premium = storage.isPremiumUser();
    if (!premium) {
      final cg = storage.getCardGameState();
      if ((cg['plays'] as int) >= kFreeCardGameDaily) {
        if (!mounted) return;
        setState(() => _locked = true);
        return;
      }
      await storage.useCardGamePlay();
    }
    _engine.start(widget.subjects, pairCount: 6);
    if (!mounted) return;
    setState(() {
      _started = true;
      _locked = false;
    });
  }

  void _newGame() {
    setState(() {
      _started = false;
      _locked = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  void _onFlip(int i) {
    context.read<SoundService>().click();
    final res = _engine.flip(i);
    if (res.status == 'ignored') return;
    setState(() {});
    if (res.status == 'pending-nomatch') {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _engine.clearPending();
        setState(() {});
      });
    }
    if (_engine.isComplete) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Tebrikler, tüm kartları eşleştirdin!')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return const LockedFeatureCard(
        title: 'Kart Eşleştirme Oyunu',
        desc: "Bugünkü 3 ücretsiz hakkını kullandın. Yarın tekrar oynayabilir ya da Premium'a geçip "
            'sınırsız oynayabilirsin.',
      );
    }
    if (!_started) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final storage = context.watch<StorageService>();
    final colors = context.watch<ThemeProvider>().colors;
    final premium = storage.isPremiumUser();
    final remaining =
        (kFreeCardGameDaily - (storage.getCardGameState()['plays'] as int)).clamp(0, kFreeCardGameDaily);

    if (_engine.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('🃏 Kart Eşleştirme Oyunu')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('🃏  Kart havuzu için önce ders içeriklerinin yüklenmesini bekle.',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🃏 Kart Eşleştirme Oyunu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terimi tanımıyla eşleştir. Hamle: ${_engine.moves}'
              '${premium ? '' : ' • Kalan günlük hakkın: $remaining'}',
              style: TextStyle(fontSize: 13, color: colors.textFaint),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _engine.cards.length,
                itemBuilder: (context, i) {
                  final c = _engine.cards[i];
                  final flippedNow = _engine.flipped.contains(i) || c.matched;
                  return InkWell(
                    onTap: () => _onFlip(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.matched
                            ? colors.success.withValues(alpha: 0.18)
                            : flippedNow
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                                : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        flippedNow ? c.text : '❓',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: flippedNow ? 11 : 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                context.read<SoundService>().click();
                _newGame();
              },
              child: const Text('🔄 Yeni Oyun'),
            ),
          ],
        ),
      ),
    );
  }
}
