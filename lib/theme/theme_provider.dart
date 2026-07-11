import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService storage;
  String _themeId = 'default';

  ThemeProvider(this.storage) {
    _themeId = (storage.getSettings()['theme'] as String?) ?? 'default';
  }

  KpssColors get colors => kThemes[_themeId] ?? kThemes['default']!;
  ThemeData get themeData => buildThemeData(colors);
  String get themeId => _themeId;

  Future<void> setTheme(String id) async {
    if (!kThemes.containsKey(id)) return;
    _themeId = id;
    await storage.saveSettings({'theme': id});
    notifyListeners();
  }
}
