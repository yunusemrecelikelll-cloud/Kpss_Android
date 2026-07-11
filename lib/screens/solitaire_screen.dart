import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../games/solitaire_engine.dart';
import '../services/storage_service.dart';
import '../services/question_picker.dart';
import 'tools_hub_screen.dart';
import 'topic_screen.dart';

/// JS: FREE_GAME_DAILY
const int kFreeSolitaireDaily = 3;
const String kSolitaireGameId = 'solitaire';
const List<String> kOptionLetters = ['A', 'B', 'C', 'D', 'E'];

/// Solitaire — JS: renderGameSubjectPicker('solitaire') girişi.
/// Ders seç → konu seç → kartları (soruları) sırayla temizle.
class SolitaireScreen extends StatelessWidget {
  final List<Subject> subjects;
  const SolitaireScreen({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final premium = storage.isPremiumUser();
    final gp = storage.getGamePlayState(kSolitaireGameId);
    final left = (kFreeSolitaireDaily - (gp['plays'] as int)).clamp(0, kFreeSolitaireDaily);
    final progress = storage.getGamePassedTopics(kSolitaireGameId);

    return Scaffold(
      appBar: AppBar(title: const Text('🂡 Solitaire')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bir ders seç. ${premium ? "Sınırsız oynarsın." : "Bugün $left hakkın kaldı."}',
            style: const TextStyle(fontSize: 13.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          for (final s in subjects)
            Card(
              child: ListTile(
                leading: Text(s.icon, style: const TextStyle(fontSize: 22)),
                title: Text(s.ad, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: s.konular.isEmpty
                          ? 0
                          : s.konular.where((t) => progress[t.id] == true).length / s.konular.length,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.konular.where((t) => progress[t.id] == true).length}/${s.konular.length} konu geçildi',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SolTopicPicker(subject: s))),
              ),
            ),
        ],
      ),
    );
  }
}

class _SolTopicPicker extends StatelessWidget {
  final Subject subject;
  const _SolTopicPicker({required this.subject});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final progress = storage.getGamePassedTopics(kSolitaireGameId);

    return Scaffold(
      appBar: AppBar(title: Text('🂡 Solitaire — ${subject.ad}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < subject.konular.length; i++)
            Builder(builder: (context) {
              final t = subject.konular[i];
              final passed = progress[t.id] == true;
              final eligible = t.sorular.length >= 5;
              return Opacity(
                opacity: eligible ? 1 : 0.5,
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: passed ? Colors.green.withValues(alpha: 0.2) : null,
                      child: Text(passed ? '✓' : '${i + 1}'),
                    ),
                    title: Text(t.baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(passed
                        ? 'Geçildi ✓'
                        : eligible
                            ? 'Henüz geçilmedi'
                            : 'Bu oyun için yeterli içerik yok'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (!eligible) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Bu konu için yeterli soru yok.')));
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => _SolPlayScreen(subject: subject, topic: t)),
                      );
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Solitaire tahtası + sonuç ekranı — JS: _renderSolitaireBoard / _renderSolitaireEnd.
class _SolPlayScreen extends StatefulWidget {
  final Subject subject;
  final Topic topic;
  const _SolPlayScreen({required this.subject, required this.topic});

  @override
  State<_SolPlayScreen> createState() => _SolPlayScreenState();
}

class _SolPlayScreenState extends State<_SolPlayScreen> {
  final _engine = SolitaireEngine();
  bool _locked = false;
  bool _started = false;
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final storage = context.read<StorageService>();
    final premium = storage.isPremiumUser();
    if (!premium) {
      final gp = storage.getGamePlayState(kSolitaireGameId);
      if ((gp['plays'] as int) >= kFreeSolitaireDaily) {
        if (!mounted) return;
        setState(() => _locked = true);
        return;
      }
      await storage.useGamePlay(kSolitaireGameId);
    }
    final picker = QuestionPicker(storage);
    final qs = picker.pick(widget.topic.sorular, 8, 'solitaire-${widget.topic.id}');
    _engine.start(qs);
    if (!mounted) return;
    setState(() {
      _started = true;
      _resultHandled = false;
    });
  }

  void _retry() {
    setState(() {
      _started = false;
      _locked = false;
      _resultHandled = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  void _answer(int idx) {
    _engine.answer(idx);
    setState(() {});
  }

  void _advance() {
    _engine.advance();
    setState(() {});
  }

  Future<void> _handleFinish() async {
    if (_resultHandled) return;
    _resultHandled = true;
    final storage = context.read<StorageService>();
    final usedKeys = _engine.cards.map((c) => c.q.key).toList();
    await storage.addUsedQuestions('solitaire-${widget.topic.id}', usedKeys);
    if (_engine.isPassed) {
      await storage.markGameTopicPassed(kSolitaireGameId, widget.topic.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return const LockedFeatureCard(
        title: 'Solitaire',
        desc: "Bugünkü 3 ücretsiz hakkını kullandın. Yarın tekrar oyna ya da Premium'a geçip sınırsız oyna.",
      );
    }
    if (!_started) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_engine.isFinished) {
      _handleFinish();
      return _buildEnd(context);
    }
    return _buildBoard(context);
  }

  Widget _buildBoard(BuildContext context) {
    final st = _engine;
    final cur = st.cards[st.cursor];

    return Scaffold(
      appBar: AppBar(title: Text('🂡 Solitaire — ${widget.topic.baslik}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Kart ${st.cursor + 1} / ${st.cards.length}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: st.cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final c = st.cards[i];
                  Color? bg;
                  String label = '${i + 1}';
                  if (c.status == 'cleared') {
                    bg = Colors.green.withValues(alpha: 0.25);
                    label = '✅';
                  } else if (c.status == 'wrong') {
                    bg = Colors.red.withValues(alpha: 0.25);
                    label = '❌';
                  } else if (i == st.cursor) {
                    bg = Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);
                  }
                  return CircleAvatar(backgroundColor: bg, radius: 18, child: Text(label, style: const TextStyle(fontSize: 12)));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cur.q.soru, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    for (var i = 0; i < cur.q.secenekler.length; i++) _buildOption(cur, i),
                    if (cur.status != 'pending') ...[
                      const Divider(height: 24),
                      Text('💡 ${cur.q.aciklama}', style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (cur.status != 'pending')
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _advance,
                  child: Text(st.cursor < st.cards.length - 1 ? 'Sonraki Kart →' : 'Bitir'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(SolitaireCard cur, int i) {
    Color? borderColor;
    Color? bgColor;
    if (cur.status != 'pending') {
      if (i == cur.q.dogruIndex) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.12);
      } else if (i == cur.given) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.12);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: cur.status == 'pending' ? () => _answer(i) : null,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor ?? Colors.grey.withValues(alpha: 0.3)),
            color: bgColor,
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 13, child: Text(kOptionLetters[i], style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 12),
              Expanded(child: Text(cur.q.secenekler[i])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnd(BuildContext context) {
    final st = _engine;
    final cleared = st.cards.where((c) => c.status == 'cleared').length;
    final passed = st.isPassed;

    return Scaffold(
      appBar: AppBar(title: const Text('🂡 Solitaire')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: passed ? null : Colors.red.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(passed ? '🎉' : '📚', style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                Text(passed ? 'Konuyu geçtin!' : 'Bu konuyu geçemedin',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('$cleared / ${st.cards.length} kartı doğru temizledin.',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  passed
                      ? '${widget.topic.baslik} konusunda iyi gidiyorsun.'
                      : '${widget.topic.baslik} konusunu tekrar çalışman işini kolaylaştırır.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (!passed)
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => TopicScreen(subject: widget.subject, topic: widget.topic)),
                        ),
                        child: const Text('📖 Konuyu Tekrar Çalış'),
                      ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Konu Listesine Dön'),
                    ),
                    TextButton(onPressed: _retry, child: const Text('🔄 Tekrar Dene')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
