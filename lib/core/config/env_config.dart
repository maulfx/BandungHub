import 'package:flutter/foundation.dart';

class EnvConfig {
  // Base URL for backend API
  // Android Emulator uses 10.0.2.2, while Web/Desktop uses localhost
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000/api';
    }
  }

  static const Duration requestTimeout = Duration(seconds: 15);
  static const bool useLocalMockFallback = true;

  // Supabase Configuration
  // Masukkan Project URL dan Anon Key dari dashboard Supabase: Settings -> API
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ztudzzgehrbiwbprdajk.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_4RNxNlVS96njxXYy6IXi-w_Pg-td0fO',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT_ID') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
}
