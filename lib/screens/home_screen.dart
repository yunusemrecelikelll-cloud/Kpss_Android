import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/mission.dart';
import '../models/badge.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../theme/theme_provider.dart';
import '../utils/exam_dates.dart';
import 'subject_screen.dart';
import 'quiz_screen.dart';
import 'wrong_bank_screen.dart';
import 'tools_hub_screen.dart';
import 'profile_screen.dart';
import 'premium_screen.dart';

const int kFreeMaxFullTestAttempts = 3;

/// Cinsiyete göre hitap eden anasayfa karşılama mesajı.
/// JS karşılığı: src/js/app.js içindeki _heroGreeting(gender, name).
String _heroGreetingFor(String gender, String name) {
  if (gender == 'k') return 'Merhaba Prensesim $name! Hazır mısın? 👸';
  if (gender == 'e') return 'Merhaba Aslanım $name! Hazır mısın? 🦁';
  return 'Merhaba, $name! Hazır mısın? 🌸';
}

class HomeScreen extends StatefulWidget {
  final List<Subject> subjects;
  const HomeScreen({super.key, required this.subjects});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMissionsAndBadges());
  }

  Future<void> _checkMissionsAndBadges() async {
    final storage = context.read<StorageService>();
    final newlyDone = <MissionDef>[];
    for (final m in kMissions) {
      if (!storage.isMissionDone(m.id) && m.check(storage)) {
        await storage.markMissionDone(m.id);
        newlyDone.add(m);
      }
    }
    if (newlyDone.isEmpty) return;

    final newlyUnlocked = <BadgeDef>[];
    final total = storage.getMissionsCompletedTotal();
    final thresholds = {'gorev-1': 1, 'gorev-10': 10, 'gorev-50': 50};
    for (final entry in thresholds.entries) {
      if (total >= entry.value && !storage.isBadgeUnlocked(entry.key)) {
        final unlocked = await storage.unlockBadge(entry.key);
        if (unlocked) {
          newlyUnlocked.add(kBadgeDefs.firstWhere((b) => b.id == entry.key));
        }
      }
    }

    if (!mounted) return;
    final missionText = newlyDone.length == 1
        ? '🎉 Görevi tamamladın: ${newlyDone.first.title}!'
        : '🎉 ${newlyDone.length} görevi tamamladın!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(missionText), duration: const Duration(seconds: 4)),
    );
    for (final b in newlyUnlocked) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🏅 Yeni rozet: ${b.name}!'), duration: const Duration(seconds: 4)),
        );
      });
    }
  }

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
    for (final s in widget.subjects) {
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
    final subjects = widget.subjects;
    final storage = context.watch<StorageService>();
    final c = context.watch<ThemeProvider>().colors;
    final name = storage.getActiveUser();
    final gender = storage.getUserGender();
    final premium = storage.isPremiumUser();
    final overall = storage.computeOverall();
    final completed = storage.getCompletedTopics();
    final totalTopics = subjects.fold(0, (s, x) => s + x.konular.length);
    final doneTopics = subjects.fold(0, (s, x) => s + x.konular.where((t) => completed[t.id] == true).length);
    final fullTestDone = storage.getAttempts().where((a) => a.topicId == 'full-test').length;
    final examInfo = examInfoFor(storage.getExamType());

    return Scaffold(
      appBar: AppBar(
        title: Text('KPSS Hazırlık', style: GoogleFonts.baloo2(fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<SoundService>().click();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: const Icon(Icons.person_outline),
            label: const Text('Profil'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              DrawerHeader(
                child: Text('🌙 KPSS Hazırlık',
                    style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              ListTile(
                leading: const Text('🎮'),
                title: const Text('Oyunlar'),
                onTap: () {
                  context.read<SoundService>().click();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ToolsHubScreen()));
                },
              ),
              ListTile(
                leading: const Text('💎'),
                title: const Text('Premium'),
                onTap: () {
                  context.read<SoundService>().click();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
                },
              ),
              ListTile(
                leading: const Text('❌'),
                title: const Text('Yanlışlarım'),
                onTap: () {
                  context.read<SoundService>().click();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WrongBankScreen()));
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (examInfo != null) _ExamCountdownBar(examInfo: examInfo),
            if (examInfo != null) const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_heroGreetingFor(gender, name),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('2026 KPSS hazırlığında bugün ne çalışmak istersin?'),
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
            if (!premium) ...[
              const SizedBox(height: 16),
              Card(
                color: c.violet.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💎 Ek ayrıcalıklar ve daha fazla soru için Premium\'a geç!',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      const SizedBox(height: 6),
                      Text('100 soruluk konu havuzları, sınırsız test, oyunlar ve daha fazlası.',
                          style: TextStyle(fontSize: 12, color: c.textFaint)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          context.read<SoundService>().click();
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
                        },
                        child: const Text("Premium'a Geç →"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              color: c.gold.withValues(alpha: 0.08),
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
                      style: TextStyle(fontSize: 12, color: c.warn),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SoundService>().click();
                        _startFullTest(context);
                      },
                      child: const Text('Sınava Gir ➜'),
                    ),
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
                    onTap: () {
                      context.read<SoundService>().click();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SubjectScreen(subject: s)),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamCountdownBar extends StatelessWidget {
  final ExamInfo examInfo;
  const _ExamCountdownBar({required this.examInfo});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    final date = nextExamDate(examInfo);
    final countdown = formatCountdown(date);
    final dateStr = '${date.day} ${_monthName(date.month)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.14)],
        ),
      ),
      child: Column(
        children: [
          Text('📅 ${examInfo.label} KPSS — $dateStr', style: TextStyle(fontSize: 12, color: c.textDim)),
          const SizedBox(height: 2),
          Text('Sınava kalan süre: $countdown',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const names = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return names[m - 1];
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
