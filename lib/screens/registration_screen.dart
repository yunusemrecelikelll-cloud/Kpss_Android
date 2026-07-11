import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../utils/exam_dates.dart';
import 'main_shell.dart';

/// Tek kullanıcılı kayıt ekranı — uygulama ilk açıldığında bir kez gösterilir.
/// JS karşılığı yok (orijinal masaüstü uygulaması çok kullanıcılıydı); bu,
/// mobil sürüme özel yeni bir akış: isim + cinsiyet + sınav türü sorar,
/// isteğe bağlı Google/Apple ile giriş sunar.
class RegistrationScreen extends StatefulWidget {
  final List<Subject> subjects;
  const RegistrationScreen({super.key, required this.subjects});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameCtrl = TextEditingController();
  String _gender = '';
  String _examType = '';
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lütfen adını gir.')));
      return;
    }
    if (_gender.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lütfen cinsiyetini seç.')));
      return;
    }
    if (_examType.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lütfen hangi sınava gireceğini seç.')));
      return;
    }
    final storage = context.read<StorageService>();
    final capName = await storage.addUser(name);
    await storage.setActiveUser(capName);
    await storage.setUserName(capName);
    await storage.setUserGender(_gender);
    await storage.setExamType(_examType);
    await storage.resetDailyMissions();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(subjects: widget.subjects)),
    );
  }

  Future<void> _socialSignIn(Future<AuthResult> Function() method) async {
    setState(() => _busy = true);
    final result = await method();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      final displayName = result.user?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        _nameCtrl.text = displayName;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş başarılı! Şimdi bilgilerini tamamla.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Giriş başarısız oldu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

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
                const Text('2026 KPSS hazırlığına hoş geldin!',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 28),

                SizedBox(
                  width: 320,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _socialSignIn(auth.signInWithGoogle),
                    icon: const Text('🇬', style: TextStyle(fontSize: 16)),
                    label: const Text('Google ile Giriş Yap'),
                  ),
                ),
                if (auth.isAppleSignInAvailable) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 320,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _socialSignIn(auth.signInWithApple),
                      icon: const Icon(Icons.apple, size: 18),
                      label: const Text('Apple ile Giriş Yap'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('veya', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _nameCtrl,
                    maxLength: 24,
                    decoration: const InputDecoration(labelText: 'Adın nedir?'),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sen kimsin?', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Hangi sınava gireceksin?', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final e in kExamTypes)
                      ChoiceChip(
                        label: Text(e.label),
                        selected: _examType == e.id,
                        onSelected: (_) => setState(() => _examType = e.id),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 320,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _finish,
                    child: const Text('Hazırlığa Başla ✨'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
