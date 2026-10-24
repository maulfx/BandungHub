import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/repositories/auth_repository.dart';
import 'package:projek_akhir/features/auth/screens/bank_app_lock_screen.dart';
import 'package:projek_akhir/features/auth/screens/login_screen.dart';
import 'package:projek_akhir/features/profile/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthRepository().init();
  });

  tearDown(() async {
    await AuthRepository().logout();
  });

  group('Bank-Style Auth Lock Tests', () {
    test('Session unlocks upon login and re-locks with lockSession()', () async {
      final authRepo = AuthRepository();

      // Login as demo user
      await authRepo.loginAsDemo();
      expect(authRepo.isLoggedIn, isTrue);
      expect(authRepo.isSessionUnlocked, isTrue);

      // Lock session (simulates app reopen or 2-min background timeout)
      authRepo.lockSession();
      expect(authRepo.isSessionUnlocked, isFalse);
      expect(authRepo.currentUser, isNotNull);

      // Enter wrong PIN
      final wrongResult = await authRepo.loginWithPin('000000');
      expect(wrongResult, isFalse);
      expect(authRepo.isSessionUnlocked, isFalse);

      // Enter correct PIN (demo user PIN is 123456)
      final correctResult = await authRepo.loginWithPin('123456');
      expect(correctResult, isTrue);
      expect(authRepo.isSessionUnlocked, isTrue);

      // Logout clears session
      await authRepo.logout();
      expect(authRepo.currentUser, isNull);
      expect(authRepo.isSessionUnlocked, isFalse);
    });

    testWidgets('LoginScreen does not contain Google login or in-form biometric card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Google login is removed
      expect(find.text('Masuk dengan Google'), findsNothing);
      expect(find.byKey(const Key('btn_google_sign_in')), findsNothing);

      // Verify biometric card is removed from LoginScreen
      expect(find.text('Masuk Cepat Biometrik'), findsNothing);
      expect(find.text('Pindai Sidik Jari / Wajah'), findsNothing);

      // Verify clean email/password login is present
      expect(find.text('Masuk Akun'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);
      // Verify guest mode is removed
      expect(find.text('Lanjutkan sebagai Tamu (Guest Mode)'), findsNothing);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
    });

    testWidgets('BankAppLockScreen renders user profile, keypad, and unlocks on valid PIN', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authRepo = AuthRepository();
      await authRepo.loginAsDemo();
      authRepo.lockSession();

      bool wasUnlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BankAppLockScreen(
            onUnlocked: () {
              wasUnlocked = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Displays user greeting & name
      expect(find.text('Selamat Datang Kembali,'), findsOneWidget);
      expect(find.text(authRepo.userName), findsOneWidget);
      expect(find.text('Ganti Akun / Masuk dengan Email Lain'), findsOneWidget);

      // Enter 6-digit PIN via keypad: '1', '2', '3', '4', '5', '6'
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      expect(wasUnlocked, isTrue);
      expect(authRepo.isSessionUnlocked, isTrue);
    });

    testWidgets('Logging out from ProfileScreen redirects to LoginScreen and clears session', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authRepo = AuthRepository();
      await authRepo.loginAsDemo();
      expect(authRepo.isLoggedIn, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap 'Keluar dari Akun' button
      final logoutButton = find.text('Keluar dari Akun');
      expect(logoutButton, findsOneWidget);
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Konfirmasi Keluar'), findsOneWidget);
      expect(
        find.text('Apakah Anda yakin ingin keluar dari akun ini? Anda akan diarahkan kembali ke halaman masuk.'),
        findsOneWidget,
      );

      // Tap confirm 'Keluar Akun'
      await tester.tap(find.text('Keluar Akun'));
      await tester.pumpAndSettle();

      // Verify user is redirected to LoginScreen and logged out
      expect(authRepo.isLoggedIn, isFalse);
      expect(authRepo.currentUser, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);
    });
  });
}
