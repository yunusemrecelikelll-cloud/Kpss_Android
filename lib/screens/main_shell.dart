import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../services/sound_service.dart';
import 'home_screen.dart';
import 'badges_screen.dart';
import 'missions_screen.dart';
import 'settings_screen.dart';

/// Alt navigasyon çubuğu — Anasayfa / Rozetler / Görevler / Ayarlar.
/// Oyunlar, Premium ve Yanlışlarım ekranlarına Anasayfa'daki çekmeceden
/// (Drawer) erişiliyor.
class MainShell extends StatefulWidget {
  final List<Subject> subjects;
  const MainShell({super.key, required this.subjects});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(subjects: widget.subjects),
      const BadgesScreen(),
      const MissionsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          context.read<SoundService>().click();
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Anasayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Rozetler',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Görevler',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
