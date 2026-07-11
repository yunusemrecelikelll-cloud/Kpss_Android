import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mission.dart';
import '../services/storage_service.dart';

/// JS karşılığı: renderMissions() (src/js/app.js) + görev tanımları src/js/missions.js.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAll());
  }

  // JS: Missions.checkAll() — henüz işaretlenmemiş ama koşulu sağlanan
  // görevleri Storage.markMissionDone ile kalıcı hale getirir.
  Future<void> _checkAll() async {
    final storage = context.read<StorageService>();
    var changed = false;
    for (final m in kMissions) {
      if (!storage.isMissionDone(m.id) && m.check(storage)) {
        await storage.markMissionDone(m.id);
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return Scaffold(
      appBar: AppBar(title: const Text('📋 Görevler')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Günlük ve haftalık görevleri tamamla!',
              style: TextStyle(fontSize: 13.5, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            for (final m in kMissions) ...[
              _MissionRow(
                mission: m,
                done: storage.isMissionDone(m.id) || m.check(storage),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final MissionDef mission;
  final bool done;
  const _MissionRow({required this.mission, required this.done});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(mission.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(mission.desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: done ? 1 : 0,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            done
                ? const Text('✅', style: TextStyle(fontSize: 18))
                : Text('+${mission.pts} 🌟', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
