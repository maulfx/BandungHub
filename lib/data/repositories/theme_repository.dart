import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepository extends ChangeNotifier {
  static final ThemeRepository _instance = ThemeRepository._internal();
  factory ThemeRepository() => _instance;
  ThemeRepository._internal();

  static const String _key = 'bandunghub_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Inisialisasi tema dari SharedPreferences saat aplikasi dibuka
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (saved == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeRepository init error: $e');
    }
  }

  /// Ubah mode tema (Terang, Gelap, atau Ikuti Sistem) dan simpan preferensi
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'system';
      if (mode == ThemeMode.dark) val = 'dark';
      if (mode == ThemeMode.light) val = 'light';
      await prefs.setString(_key, val);
    } catch (e) {
      debugPrint('ThemeRepository save error: $e');
    }
  }

  /// Label deskriptif bahasa Indonesia
  String get themeModeLabel => getModeLabel(_themeMode);

  static String getModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Gelap';
      case ThemeMode.system:
        return 'Default';
    }
  }

  /// Cek apakah mode aktif efektif adalah gelap
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Helper untuk reset state pada unit test
  void resetForTesting({ThemeMode mode = ThemeMode.system}) {
    _themeMode = mode;
    notifyListeners();
  }
}
