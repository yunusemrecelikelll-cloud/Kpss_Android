import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../services/quiz_engine.dart';
import '../services/timer_service.dart';
import '../services/sound_service.dart';
import 'result_screen.dart';

const int kAutoSecsPerQ = 65; // KPSS GY-GK oranı

class QuizScreen extends StatefulWidget {
  final String subjectId, subjectAd, topicId, topicBaslik;
  final List<Question> questions;
  final bool isFullTest;

  const QuizScreen({
    super.key,
    required this.subjectId,
    required this.subjectAd,
    required this.topicId,
    required this.topicBaslik,
    required this.questions,
    required this.isFullTest,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _perqTimerIndex = -1;
  List<int> _perqRemaining = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  void _boot() {
    final quiz = context.read<QuizEngine>();
    final storage = context.read<StorageService>();
    final settings = storage.getSettings();
    final timerMode = settings['timerMode'] as String? ?? 'auto';
    final secsPerQ = (settings['secsPerQ'] as int?) ?? 65;
    final duration = timerMode == 'perq'
        ? widget.questions.length * secsPerQ
        : widget.questions.length * kAutoSecsPerQ;

    quiz.start(
      subjectId: widget.subjectId,
      subjectAd: widget.subjectAd,
      topicId: widget.topicId,
      topicBaslik: widget.topicBaslik,
      questions: widget.questions,
      durationSec: duration,
      isFullTest: widget.isFullTest,
    );

    if (timerMode != 'perq') {
      context.read<TimerService>().start(duration, onExpire: _finish);
    } else {
      _perqTimerIndex = -1;
      _perqRemaining = List<int>.filled(widget.questions.length, secsPerQ);
      setState(() {});
    }
  }

  Future<void> _finish() async {
    final quiz = context.read<QuizEngine>();
    context.read<TimerService>().stop();
    final startedAt = quiz.startedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    final result = await quiz.finish(elapsed);
    final storage = context.read<StorageService>();
    await storage.addAttempt(result);
    await storage.touchStreak();
    if (result.skor == 100 || result.skor >= 60) {
      await storage.markTopicCompleted(result.topicId);
    }
    if (!widget.isFullTest && !result.topicId.endsWith('-sinav')) {
      final usedKeys = result.review.map((r) => r.soru.length > 50 ? r.soru.substring(0, 50) : r.soru).toList();
      await storage.addUsedQuestions(result.topicId, usedKeys);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizEngine>();
    final storage = context.watch<StorageService>();
    if (!quiz.isActive) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final settings = storage.getSettings();
    final timerMode = settings['timerMode'] as String? ?? 'auto';
    final secsPerQ = (settings['secsPerQ'] as int?) ?? 65;
    final q = quiz.questions[quiz.currentIndex];
    final timer = context.watch<TimerService>();

    int displaySecs;
    bool isNewPerqQuestion = false;
    if (timerMode == 'perq') {
      if (_perqRemaining.length != quiz.questions.length) {
        _perqRemaining = List<int>.filled(quiz.questions.length, secsPerQ);
      }
      isNewPerqQuestion = _perqTimerIndex != quiz.currentIndex;
      displaySecs = isNewPerqQuestion ? _perqRemaining[quiz.currentIndex] : timer.remaining;
      if (isNewPerqQuestion) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _switchPerqQuestion(quiz.currentIndex, secsPerQ));
      }
    } else {
      displaySecs = timer.remaining;
    }

    final isExpiredQuestion = timerMode == 'perq' && displaySecs <= 0;

    // JS updateTimer(): son 5 saniye tik-tak sesi (Timer her saniye bir kez
    // notifyListeners() çağırıyor, bu build de saniyede bir kez tetikleniyor).
    if (displaySecs <= 5 && displaySecs > 0) {
      context.read<SoundService>().tick();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectAd} • ${widget.topicBaslik}', style: const TextStyle(fontSize: 14)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                TimerService.format(displaySecs),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: displaySecs <= 5 ? Colors.red : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Soru ${quiz.currentIndex + 1} / ${quiz.questions.length}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quiz.questions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final answered = quiz.answers[i] != null;
                  final current = i == quiz.currentIndex;
                  return InkWell(
                    onTap: () => quiz.goTo(i),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: current
                          ? Theme.of(context).colorScheme.primary
                          : answered
                              ? Colors.green.withValues(alpha: 0.3)
                              : null,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (isExpiredQuestion)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Text('⏱️ Bu sorunun süresi doldu — cevabını artık değiştiremezsin.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.soru, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    for (var i = 0; i < q.secenekler.length; i++)
                      _OptionTile(
                        letter: String.fromCharCode(65 + i),
                        text: q.secenekler[i],
                        selected: quiz.answers[quiz.currentIndex] == i,
                        locked: isExpiredQuestion,
                        onTap: () {
                          context.read<SoundService>().click();
                          final already = quiz.answers[quiz.currentIndex];
                          quiz.answer(already == i ? null : i);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  OutlinedButton(
                    onPressed: quiz.currentIndex == 0 ? null : quiz.prev,
                    child: const Text('← Önceki'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final unanswered = quiz.answers.where((a) => a == null).length;
                      if (unanswered > 0) {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            content: Text('$unanswered soru boş. Yine de bitirmek istiyor musun?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bitir')),
                            ],
                          ),
                        );
                        if (ok != true) return;
                      }
                      _finish();
                    },
                    child: const Text('Testi Bitir'),
                  ),
                ]),
                if (quiz.currentIndex < quiz.questions.length - 1)
                  ElevatedButton(onPressed: quiz.next, child: const Text('Sonraki →')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Soru başına süre modu: sadece gerçekten yeni bir soruya geçildiğinde
  // zamanlayıcıyı yeniden başlat; önceki sorunun kalan süresini kaydet,
  // geri dönülünce kaldığı yerden devam etsin.
  void _switchPerqQuestion(int newIndex, int secsPerQ) {
    if (_perqTimerIndex == newIndex) return;
    final timer = context.read<TimerService>();
    if (_perqTimerIndex != -1 && _perqTimerIndex < _perqRemaining.length) {
      _perqRemaining[_perqTimerIndex] = timer.remaining;
    }
    _perqTimerIndex = newIndex;
    timer.start(_perqRemaining[newIndex], onExpire: () {
      final quiz = context.read<QuizEngine>();
      if (quiz.currentIndex < quiz.questions.length - 1) {
        quiz.next();
      } else {
        _finish();
      }
    });
  }
}

class _OptionTile extends StatelessWidget {
  final String letter, text;
  final bool selected, locked;
  final VoidCallback onTap;
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
              ),
              color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : null,
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 13, child: Text(letter, style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
