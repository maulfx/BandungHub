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
}
