import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../services/storage_service.dart';
import '../services/question_picker.dart';
import 'quiz_screen.dart';
import 'premium_screen.dart';

const int kFreeMaxAttemptsPerTopic = 2;

class TopicScreen extends StatelessWidget {
  final Subject subject;
  final Topic topic;
  const TopicScreen({super.key, required this.subject, required this.topic});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final premium = storage.isPremiumUser();
    final attempts = storage.getAttemptsForTopic(topic.id);
    final maxAtt = premium ? 1 << 30 : kFreeMaxAttemptsPerTopic;
    final maxed = attempts.length >= maxAtt;
    final a = topic.anlatim;

    return Scaffold(
      appBar: AppBar(title: Text(topic.baslik)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.ozet != null) ...[
                    Text(a.ozet!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                  ],
                  for (final p in a.icerik) ...[
                    Text(p),
                    const SizedBox(height: 10),
                  ],
                  if (a.anahtarNoktalar.isNotEmpty) ...[
                    const Divider(),
                    for (final p in a.anahtarNoktalar)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $p', style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (attempts.isNotEmpty) ...[
            const Text('Geçmiş Testlerin', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (var i = 0; i < attempts.length; i++)
              Card(
                child: ListTile(
                  dense: true,
                  leading: Text('${i + 1}. Test'),
                  title: Text('${attempts[i].dogru} doğru / ${attempts[i].yanlis} yanlış'),
                  trailing: Text('%${attempts[i].skor}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (maxed)
            Card(
              color: Colors.amber.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎓 Ücretsiz pakette bu konuyu $maxAtt kez çözdün. '
                        "Sınırsız test için Premium'a geç ya da sıfırlayıp yeniden başla."),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: [
                      OutlinedButton(
                        onPressed: () async {
                          await storage.resetTopicAttempts(topic.id);
                        },
                        child: const Text('🔄 Testleri Sıfırla'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
                        child: const Text("💎 Premium'a Geç"),
                      ),
                    ]),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(premium
                          ? '${topic.sorular.length} soruluk havuz • Sınırsız test hakkın var ✨'
                          : '${topic.sorular.length} soruluk havuz • ${maxAtt - attempts.length} hak kaldı'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final picker = QuestionPicker(storage);
                        final qs = picker.pickForTopic(topic.sorular, 10, topic.id, premium: premium);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            subjectId: subject.id,
                            subjectAd: subject.ad,
                            topicId: topic.id,
                            topicBaslik: topic.baslik,
                            questions: qs,
                            isFullTest: false,
                          ),
                        ));
                      },
                      child: Text(attempts.isNotEmpty ? 'Tekrar Çöz →' : 'Teste Başla →'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
