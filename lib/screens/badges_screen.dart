import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge.dart';
import '../services/storage_service.dart';

/// JS karşılığı: renderBadges() (src/js/app.js) + rozet tanımları src/js/badges.js.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final unlocked = storage.getUnlockedBadges().toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('🎖 Rozetler')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${unlocked.length} / ${kBadgeDefs.length} kazanıldı',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ??
                      Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: kBadgeDefs.length,
                itemBuilder: (context, i) {
                  final b = kBadgeDefs[i];
                  final isUnlocked = unlocked.contains(b.id);
                  return _BadgeCard(badge: b, unlocked: isUnlocked);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeDef badge;
  final bool unlocked;
  const _BadgeCard({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: unlocked ? 2 : 0,
      color: unlocked ? null : Theme.of(context).cardColor.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1.0 : 0.35,
              child: Text(badge.icon, style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: 10),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: unlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.desc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
            if (unlocked) ...[
              const SizedBox(height: 6),
              const Text(
                'Kazanıldı ✓',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.teal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
