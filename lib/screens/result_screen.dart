import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attempt.dart';
import '../services/storage_service.dart';

class ResultScreen extends StatelessWidget {
  final Attempt result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final premium = storage.isPremiumUser();
    final k = KpssPoints.compute(dogru: result.dogru, yanlis: result.yanlis);

    return Scaffold(
      appBar: AppBar(title: const Text('Sonuç')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('%${result.skor}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                  Text('${result.subjectAd} • ${result.topicBaslik}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(label: 'Doğru ✓', value: '${result.dogru}', color: Colors.green),
                      _Stat(label: 'Yanlış ✗', value: '${result.yanlis}', color: Colors.red),
                      _Stat(label: 'Boş —', value: '${result.bos}', color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Net: ${k.net.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(label: 'P3', value: '${k.p3}'),
                      _Stat(label: 'P93', value: '${k.p93}'),
                      _Stat(label: 'P94', value: '${k.p94}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Anasayfa'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Soru Soru Değerlendirme', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < result.review.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(result.review[i].status == 'dogru'
                              ? 'Doğru ✓'
                              : result.review[i].status == 'yanlis'
                                  ? 'Yanlış ✗'
                                  : 'Boş'),
                          backgroundColor: result.review[i].status == 'dogru'
                              ? Colors.green.withValues(alpha: 0.15)
                              : result.review[i].status == 'yanlis'
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        Text('Soru ${i + 1}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(result.review[i].soru, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (var oi = 0; oi < result.review[i].secenekler.length; oi++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${String.fromCharCode(65 + oi)}) ${result.review[i].secenekler[oi]}',
                          style: TextStyle(
                            color: oi == result.review[i].dogruIndex
                                ? Colors.green
                                : oi == result.review[i].verilenIndex
                                    ? Colors.red
                                    : null,
                            fontWeight: oi == result.review[i].dogruIndex ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text('💡 ${result.review[i].aciklama}', style: const TextStyle(fontSize: 13)),
                    if (result.review[i].status == 'yanlis' && result.review[i].distractorAciklama != null) ...[
                      const SizedBox(height: 8),
                      if (premium)
                        Text('🤔 Büyük ihtimalle neden seçtin? ${result.review[i].distractorAciklama}',
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))
                      else
                        const Text('Premium kullanıcılar için detaylı yanılgı analizi burada gösterilir.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
