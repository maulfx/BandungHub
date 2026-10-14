import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/theme_repository.dart';
import 'features/auth/screens/auth_gate.dart';

class BandungHubApp extends StatelessWidget {
  final Widget? home;

  const BandungHubApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    final themeRepo = ThemeRepository();

    return ListenableBuilder(
      listenable: themeRepo,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeRepo.themeMode,
          home: home ?? const AuthGate(),
        );
      },
    );
  }
}
