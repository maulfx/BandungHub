import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../navigation/main_navigation_screen.dart';
import 'login_screen.dart';

/// Authentication gate controlling entry to BandungHub.
/// If user has an active session (or chosen guest mode), displays MainNavigationScreen.
/// Otherwise, directs user to LoginScreen first.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository();

    return ListenableBuilder(
      listenable: authRepo,
      builder: (context, _) {
        if (!authRepo.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user has an active session, display the main app
        if (authRepo.currentUser != null) {
          return const MainNavigationScreen();
        }

        // Fresh launch or logged out: prompt user with LoginScreen
        return const LoginScreen();
      },
    );
  }
}
