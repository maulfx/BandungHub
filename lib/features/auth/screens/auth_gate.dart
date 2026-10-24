import 'package:flutter/material.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../navigation/main_navigation_screen.dart';
import 'bank_app_lock_screen.dart';
import 'login_screen.dart';

/// Authentication gate controlling entry to BandungHub.
/// Implements bank-grade session security:
/// - If user is logged out: displays LoginScreen.
/// - If user is guest: displays MainNavigationScreen without security pin.
/// - If user is a returning authenticated account: displays BankAppLockScreen
///   prompting Biometrics / PIN before granting access to MainNavigationScreen.
/// - Re-locks session if the app remains in the background for more than 2 minutes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _authRepo = AuthRepository();
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        // Lock after 2 minutes of inactivity in background (bank-grade standard)
        // Does not disrupt fast camera/gallery picker operations (<2 mins)
        if (elapsed.inSeconds >= 120) {
          _authRepo.lockSession();
        }
      }
      _backgroundedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authRepo,
      builder: (context, _) {
        if (!_authRepo.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If not logged in, show LoginScreen
        if (_authRepo.currentUser == null) {
          return const LoginScreen();
        }

        // Returning user with saved account session: require Bank-Style Lock Screen
        if (!_authRepo.isSessionUnlocked) {
          return const BankAppLockScreen();
        }

        // Session unlocked: display main app
        return const MainNavigationScreen();
      },
    );
  }
}
