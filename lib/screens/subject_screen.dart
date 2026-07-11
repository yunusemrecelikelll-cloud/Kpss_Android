import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import 'topic_screen.dart';
import 'quiz_screen.dart';

class SubjectScreen extends StatelessWidget {
  final Subject subject;
  const SubjectScreen({super.key, required this.subject});

  void _startSubjectExam(BuildContext context) {
    final rng = Random();
    final allQs = <Question>[];
    for (final t in subject.konular) {
      final pool = List<Question>.of(t.sorular)..shuffle(rng);
      allQs.addAll(pool.take(kSubjectExamQPerTopic).map((q) => q.copyWith(topicBaslik: t.baslik)));
    }
    if (allQs.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeterli soru yüklenemedi.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(
        subjectId: subject.id,
        subjectAd: subject.ad,
        topicId: '${subject.id}-sinav',
        topicBaslik: '${subject.ad} Sınavı',
        questions: allQs,
        isFullTest: false,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final completed = storage.getCompletedTopics();
    final examQCount = subject.konular.length * kSubjectExamQPerTopic;

    return Scaffold(
      appBar: AppBar(title: Text('${subject.icon} ${subject.ad}')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: subject.konular.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Card(
              color: Colors.deepPurple.withValues(alpha: 0.06),
              child: ListTile(
                title: Text('📝 ${subject.ad} Sınavı', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('$examQCount soru (her konudan $kSubjectExamQPerTopic)'),
                trailing: ElevatedButton(
                  onPressed: () => _startSubjectExam(context),
                  child: const Text('Sınava Gir'),
                ),
              ),
            );
          }
          final t = subject.konular[i - 1];
          final done = completed[t.id] == true;
          final best = storage.getBestScore(t.id);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: done ? Colors.green.withValues(alpha: 0.2) : null,
                child: Text(done ? '✓' : '$i'),
              ),
              title: Text(t.baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${t.sorular.length} soru'
                  '${best != null ? ' • %$best en iyi' : ' • Henüz çözülmedi'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TopicScreen(subject: subject, topic: t)),
              ),
            ),
          );
        },
      ),
    );
  }
}
