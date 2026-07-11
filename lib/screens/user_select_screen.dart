import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class UserSelectScreen extends StatefulWidget {
  final List<Subject> subjects;
  const UserSelectScreen({super.key, required this.subjects});

  @override
  State<UserSelectScreen> createState() => _UserSelectScreenState();
}

class _UserSelectScreenState extends State<UserSelectScreen> {
  bool _showForm = false;
  String _gender = '';
  final _nameCtrl = TextEditingController();

  Future<void> _selectUser(String name) async {
    final storage = context.read<StorageService>();
    await storage.setActiveUser(name);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(subjects: widget.subjects)),
    );
  }

  Future<void> _createUser() async {
    final val = _nameCtrl.text.trim();
    if (val.isEmpty) return;
    final storage = context.read<StorageService>();
    final name = await storage.addUser(val);
    await storage.setActiveUser(name);
    await storage.setUserGender(_gender);
    await storage.resetDailyMissions();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(subjects: widget.subjects)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final users = storage.getUserList();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('KPSS Hazırlık', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const Text('Kimi olarak giriş yapıyorsun?', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final u in users)
                      _UserCard(name: u, onTap: () => _selectUser(u)),
                    _NewUserCard(onTap: () => setState(() => _showForm = true)),
                  ],
                ),
                if (_showForm) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _nameCtrl,
                      maxLength: 24,
                      decoration: const InputDecoration(labelText: 'Adın nedir?'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('👩 Kadın'),
                        selected: _gender == 'k',
                        onSelected: (_) => setState(() => _gender = 'k'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('👨 Erkek'),
                        selected: _gender == 'e',
                        onSelected: (_) => setState(() => _gender = 'e'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _createUser, child: const Text('Oluştur ✨')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _UserCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            CircleAvatar(radius: 26, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
            const SizedBox(height: 8),
            Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _NewUserCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewUserCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: const Column(
          children: [
            CircleAvatar(radius: 26, child: Text('+')),
            SizedBox(height: 8),
            Text('Yeni Kullanıcı', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
