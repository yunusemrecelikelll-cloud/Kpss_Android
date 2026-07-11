import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'premium_screen.dart';
import 'user_select_screen.dart';

const List<String> _kCharacterOpts = ['🦉', '🦁', '🐯', '🦄', '🐼', '🚀', '🏆', '📚'];
const List<int> _kSecsOpts = [30, 45, 60, 90, 120];

/// JS karşılığı: renderSettings() (src/js/app.js).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _switchUser() async {
    final data = context.read<DataService>();
    final subjects = await data.loadAll();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserSelectScreen(subjects: subjects)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final themeProvider = context.watch<ThemeProvider>();
    final settings = storage.getSettings();
    final soundOn = settings['soundEnabled'] != false;
    final timerMode = (settings['timerMode'] as String?) ?? 'auto';
    final secsPerQ = (settings['secsPerQ'] as int?) ?? 65;
    final notif = storage.getNotificationSettings();
    final premium = storage.isPremiumUser();
    final cloudBackup = storage.getCloudBackupEnabled();

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Ayarlar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Tema ──
            const _SectionTitle('🎨 Uygulama Teması'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final entry in kThemes.entries)
                      _ThemeSwatch(
                        colors: entry.value,
                        active: themeProvider.themeId == entry.key,
                        onTap: () async {
                          await themeProvider.setTheme(entry.key);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tema değiştirildi!')),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // ── Ses ──
            const _SectionTitle('🔊 Ses Efektleri'),
            Card(
              child: SwitchListTile(
                title: const Text('Buton sesleri', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Tıklamalarda ses çıkar; son 5 saniye tik-tak sesi gelir',
                    style: TextStyle(fontSize: 12)),
                value: soundOn,
                onChanged: (v) => storage.saveSettings({'soundEnabled': v}),
              ),
            ),

            // ── Süre Modu ──
            const _SectionTitle('⏱️ Test Süresi'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Süre hesaplama modu', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _ChoiceButton(
                          label: '🤖 Otomatik (KPSS oranı — 65sn/soru)',
                          selected: timerMode == 'auto',
                          onTap: () {
                            storage.saveSettings({'timerMode': 'auto'});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Otomatik süre modu seçildi.')),
                            );
                          },
                        ),
                        _ChoiceButton(
                          label: '✏️ Soru başına süre — Sen belirle',
                          selected: timerMode == 'perq',
                          onTap: () {
                            storage.saveSettings({'timerMode': 'perq'});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Soru başına süre modu seçildi.')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: timerMode == 'perq' ? 1 : 0.4,
                      child: IgnorePointer(
                        ignoring: timerMode != 'perq',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Her soru için süre:', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final n in _kSecsOpts)
                                  _ChoiceButton(
                                    label: '${n}s',
                                    selected: secsPerQ == n,
                                    onTap: () {
                                      storage.saveSettings({'secsPerQ': n});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Soru başına $n saniye seçildi.')),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Örnek: 10 soru × ${secsPerQ}sn = ${(10 * secsPerQ / 60).round()} dakika',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Kullanıcılar ──
            const _SectionTitle('👤 Kullanıcılar'),
            Card(
              child: ListTile(
                title: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
                    children: [
                      const TextSpan(text: 'Aktif: '),
                      TextSpan(
                        text: storage.getActiveUser(),
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
                subtitle: Text('${storage.getUserList().length} kayıtlı kullanıcı',
                    style: const TextStyle(fontSize: 12)),
                trailing: OutlinedButton(
                  onPressed: _switchUser,
                  child: const Text('👤 Kullanıcı Değiştir'),
                ),
              ),
            ),

            // ── Abonelik ──
            const _SectionTitle('💎 Abonelik'),
            Card(
              child: ListTile(
                title: Row(
                  children: [
                    const Text('Planın: ', style: TextStyle(fontWeight: FontWeight.w700)),
                    Chip(
                      label: Text(premium ? 'Premium' : 'Ücretsiz'),
                      backgroundColor: premium ? Colors.amber.withValues(alpha: 0.2) : null,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Premium paketinde detaylı grafikler, özel testler ve VIP ayrıcalıklar yer alır.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                isThreeLine: true,
                trailing: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
                  child: const Text('Ayrıntıları Gör'),
                ),
              ),
            ),

            // ── Premium Karakter ──
            const _SectionTitle('🦉 Premium Karakter'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: premium
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Profilinde ve üst menüde görünecek karakteri seç.',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in _kCharacterOpts)
                                _ChoiceButton(
                                  label: c,
                                  fontSize: 20,
                                  selected: storage.getUserCharacter() == c,
                                  onTap: () async {
                                    await storage.setUserCharacter(c);
                                    if (!mounted) return;
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Karakter güncellendi!')),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      )
                    : const Text(
                        "Premium'a geçerek profilin için özel karakterler açabilirsin.",
                        style: TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
              ),
            ),

            // ── Bildirimler ──
            const _SectionTitle('🔔 Bildirimler'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Hatırlatma bildirimleri', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Günlük soru hatırlatıcısı ve KPSS güncellemeleri al.',
                        style: TextStyle(fontSize: 12)),
                    value: notif['reminders'] == true,
                    onChanged: (v) => storage.saveNotificationSettings({'reminders': v}),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Güncelleme bildirimleri', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Yeni içerik ve duyuruları uygulama içinde gör.',
                        style: TextStyle(fontSize: 12)),
                    value: notif['updates'] == true,
                    onChanged: (v) => storage.saveNotificationSettings({'updates': v}),
                  ),
                ],
              ),
            ),

            // ── Bulut Yedekleme ──
            const _SectionTitle('☁️ Bulut Yedekleme'),
            Card(
              child: SwitchListTile(
                title: const Text('Bulut yedekleme', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Profilini ve ilerlemeni çevrimiçi yedeklemeye hazırlık.',
                    style: TextStyle(fontSize: 12)),
                value: cloudBackup,
                onChanged: (v) {
                  // TODO: Gerçek bulut senkronizasyonu (Firestore) henüz yok.
                  // Bu switch şimdilik sadece tercihi yerelde saklıyor; asıl
                  // yedekleme mantığı PORT_NOTES.md'deki Firebase entegrasyonu
                  // tamamlanınca buraya bağlanacak.
                  storage.setCloudBackupEnabled(v);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(v ? 'Bulut yedekleme hazırlandı.' : 'Bulut yedekleme kapatıldı.')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final KpssColors colors;
  final bool active;
  final VoidCallback onTap;
  const _ThemeSwatch({required this.colors, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 104,
        height: 76,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.bg, colors.bg2],
          ),
          border: Border.all(
            color: active ? colors.violet : colors.border,
            width: active ? 2.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(colors.icon, style: const TextStyle(fontSize: 18)),
            const Spacer(),
            Text(
              colors.name,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? fontSize;
  const _ChoiceButton({required this.label, required this.selected, required this.onTap, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return selected
        ? ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: Colors.white),
            child: Text(label, style: TextStyle(fontSize: fontSize)),
          )
        : OutlinedButton(
            onPressed: onTap,
            child: Text(label, style: TextStyle(fontSize: fontSize)),
          );
  }
}
