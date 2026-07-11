import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import 'subject_screen.dart';
import 'quiz_screen.dart';
import 'badges_screen.dart';
import 'wrong_bank_screen.dart';
import 'missions_screen.dart';
import 'tools_hub_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'premium_screen.dart';

const int kFreeMaxFullTestAttempts = 3;

class HomeScreen extends StatelessWidget {
  final List<Subject> subjects;
  const HomeScreen({super.key, required this.subjects});

  void _startFullTest(BuildContext context) {
    final storage = context.read<StorageService>();
    final premium = storage.isPremiumUser();
    if (!premium) {
      final done = storage.getAttempts().where((a) => a.topicId == 'full-test').length;
      if (done >= kFreeMaxFullTestAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ücretsiz pakette $kFreeMaxFullTestAttempts deneme hakkın var. "
              "Sınırsız deneme için Premium'a geç."),
        ));
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
        return;
      }
    }

    final rng = Random();
    final allQs = <Question>[];
    for (final s in subjects) {
      final n = kFullTestDist[s.id] ?? 0;
      if (n == 0 || s.konular.isEmpty) continue;
      final pool = <Question>[];
      for (final t in s.konular) {
        for (final q in t.sorular) {
          pool.add(q.copyWith(subjectId: s.id, subjectAd: s.ad));
        }
      }
      pool.shuffle(rng);
      allQs.addAll(pool.take(n));
    }
    if (allQs.length < 10) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Yeterli soru yüklenemedi.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(
        subjectId: 'full',
        subjectAd: 'Genel Deneme',
        topicId: 'full-test',
        topicBaslik: '120 Soruluk Deneme Sınavı',
        questions: allQs,
        isFullTest: true,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final name = storage.getActiveUser();
    final premium = storage.isPremiumUser();
    final overall = storage.computeOverall();
    final completed = storage.getCompletedTopics();
    final totalTopics = subjects.fold(0, (s, x) => s + x.konular.length);
    final doneTopics = subjects.fold(0, (s, x) => s + x.konular.where((t) => completed[t.id] == true).length);
    final fullTestDone = storage.getAttempts().where((a) => a.topicId == 'full-test').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KPSS Hazırlık'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Chip(
                avatar: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                label: Text(premium ? '$name · VIP' : name),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(child: Text('🌙 KPSS Hazırlık', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              ListTile(leading: const Text('🎖'), title: const Text('Rozetler'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgesScreen()))),
              ListTile(leading: const Text('❌'), title: const Text('Yanlışlarım'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WrongBankScreen()))),
              ListTile(leading: const Text('📋'), title: const Text('Görevler'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MissionsScreen()))),
              ListTile(leading: const Text('🎮'), title: const Text('Oyunlar'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ToolsHubScreen()))),
              ListTile(leading: const Text('👤'), title: const Text('Profil'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              ListTile(leading: const Text('💎'), title: const Text('Premium'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()))),
              ListTile(leading: const Text('⚙️'), title: const Text('Ayarlar'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selam, $name! Hazır mısın? 🚀',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('2026 Ortaöğretim KPSS hazırlığında bugün ne çalışmak istersin?'),
                    const SizedBox(height: 10),
                    Chip(label: Text(premium ? 'Premium' : 'Ücretsiz')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(icon: '🎯', value: '${overall.rate}%', label: 'Genel Başarı')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(icon: '📝', value: '${overall.solved}', label: 'Çözülen Soru')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(icon: '✅', value: '$doneTopics/$totalTopics', label: 'Konu')),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 Tam Deneme Sınavı', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Gerçek KPSS formatında 120 soru', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      premium
                          ? '✨ Sınırsız deneme hakkın var'
                          : '${(kFreeMaxFullTestAttempts - fullTestDone).clamp(0, kFreeMaxFullTestAttempts)} / $kFreeMaxFullTestAttempts deneme hakkın kaldı',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: () => _startFullTest(context), child: const Text('Sınava Gir ➜')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Dersler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                for (final s in subjects.where((s) => s.konular.isNotEmpty))
                  _SubjectCard(
                    subject: s,
                    completedCount: s.konular.where((t) => completed[t.id] == true).length,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SubjectScreen(subject: s)),
                    ),
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
  final String icon, value, label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final int completedCount;
  final VoidCallback onTap;
  const _SubjectCard({required this.subject, required this.completedCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(subject.ad, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              LinearProgressIndicator(
                value: subject.konular.isEmpty ? 0 : completedCount / subject.konular.length,
              ),
              const SizedBox(height: 4),
              Text('$completedCount/${subject.konular.length} konu', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
