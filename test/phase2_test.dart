import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/repositories/auth_repository.dart';
import 'package:projek_akhir/features/auth/screens/login_screen.dart';
import 'package:projek_akhir/features/auth/screens/pin_lock_screen.dart';
import 'package:projek_akhir/features/auth/screens/register_screen.dart';
import 'package:projek_akhir/features/profile/screens/profile_screen.dart';
import 'package:projek_akhir/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 2 - UserProfile & Crypto Security Unit Tests', () {
    test('UserProfile hashSecret produces consistent SHA-256 hash', () {
      final hash1 = UserProfile.hashSecret('123456');
      final hash2 = UserProfile.hashSecret('123456');
      final hash3 = UserProfile.hashSecret('different');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
      expect(hash1.length, 64); // SHA-256 hex string length
    });

    test('UserProfile verifyPin correctly validates PIN', () {
      final user = UserProfile(
        id: 'user_1',
        name: 'Tester',
        email: 'test@example.com',
        pinHash: UserProfile.hashSecret('987654'),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      expect(user.hasPin, isTrue);
      expect(user.verifyPin('987654'), isTrue);
      expect(user.verifyPin('000000'), isFalse);
      expect(user.verifyPin('123456'), isFalse);
    });

    test('UserProfile serialization toMap and fromMap works seamlessly', () {
      final original = UserProfile(
        id: 'u_100',
        name: 'Siti Aminah',
        email: 'siti@bandunghub.id',
        avatarUrl: 'https://images.unsplash.com/photo-test',
        pinHash: UserProfile.hashSecret('654321'),
        isBiometricEnabled: true,
        isGuest: false,
        createdAt: DateTime(2026, 2, 1),
        lastLoginAt: DateTime(2026, 2, 10),
      );

      final map = original.toMap();
      final reconstructed = UserProfile.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.email, original.email);
      expect(reconstructed.pinHash, original.pinHash);
      expect(reconstructed.isBiometricEnabled, isTrue);
      expect(reconstructed.isGuest, isFalse);
    });

    test('Demo user and guest factory defaults are correct', () {
      final demo = UserProfile.demoUser();
      expect(demo.email, 'traveler@bandunghub.id');
      expect(demo.hasPin, isTrue);
      expect(demo.verifyPin('123456'), isTrue);
      expect(demo.isGuest, isFalse);

      final guest = UserProfile.guest();
      expect(guest.isGuest, isTrue);
      expect(guest.hasPin, isFalse);
    });
  });

  group('Phase 2 - AuthRepository Flow Tests', () {
    test('AuthRepository register and login workflow', () async {
      final repo = AuthRepository();
      await repo.init();

      // Register new user
      final registered = await repo.register(
        name: 'Rudi Hartono',
        email: 'rudi@bandung.id',
        password: 'passwordRahasia',
        pin: '112233',
      );
      expect(registered, isTrue);
      expect(repo.userName, 'Rudi Hartono');
      expect(repo.userEmail, 'rudi@bandung.id');
      expect(repo.hasPin, isTrue);

      // Verify PIN login
      expect(await repo.loginWithPin('112233'), isTrue);
      expect(await repo.loginWithPin('999999'), isFalse);

      // Logout to guest
      await repo.logout();
      expect(repo.isGuest, isTrue);

      // Login with credentials
      final loggedIn = await repo.loginWithEmailPassword(
        'rudi@bandung.id',
        'passwordRahasia',
      );
      expect(loggedIn, isTrue);
      expect(repo.userName, 'Rudi Hartono');
    });

    test('AuthRepository demo login and PIN management', () async {
      final repo = AuthRepository();
      await repo.loginAsDemo();

      expect(repo.isLoggedIn, isTrue);
      expect(repo.userEmail, 'traveler@bandunghub.id');

      // Change PIN
      await repo.setPin('654321');
      expect(await repo.loginWithPin('654321'), isTrue);

      // Remove PIN
      await repo.removePin();
      expect(repo.hasPin, isFalse);
    });

    test('AuthRepository Google login sets profile and logs in', () async {
      final repo = AuthRepository();
      final success = await repo.loginWithGoogle(
        name: 'Test Google User',
        email: 'test.user@gmail.com',
      );
      expect(success, isTrue);
      expect(repo.isLoggedIn, isTrue);
      expect(repo.userName, 'Test Google User');
      expect(repo.userEmail, 'test.user@gmail.com');
      expect(repo.currentUser?.authProvider, 'google');
    });
  });

  group('Phase 2 - UI Widget Tests', () {
    testWidgets(
      'LoginScreen renders email, password, demo button, guest button, and google button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Masuk Akun'), findsOneWidget);
        expect(find.text('Alamat Email'), findsOneWidget);
        expect(find.text('Kata Sandi'), findsOneWidget);
        expect(find.byKey(const Key('btn_google_sign_in')), findsOneWidget);
        expect(find.text('Masuk dengan Google'), findsOneWidget);
        expect(find.text('Masuk Cepat Akun Demo (1-Click)'), findsOneWidget);
        expect(
          find.text('Lanjutkan sebagai Tamu (Guest Mode)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Tapping Masuk dengan Google opens account picker sheet and logs in',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final googleBtn = find.byKey(const Key('btn_google_sign_in'));
      expect(googleBtn, findsOneWidget);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pilih Akun Google'), findsOneWidget);
      expect(find.byKey(const Key('btn_google_account_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_google_account_0')));
      await tester.pump();

      expect(AuthRepository().isLoggedIn, isTrue);
      expect(AuthRepository().currentUser?.authProvider, 'google');
    });

    testWidgets('RegisterScreen renders form fields and allows validation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Akun Baru'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Daftar Akun'), findsOneWidget);
    });

    testWidgets('PinLockScreen renders custom numeric keypad and indicators', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: PinLockScreen(mode: PinScreenMode.verify)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi PIN'), findsOneWidget);
      expect(find.text('Masukkan PIN Keamanan'), findsOneWidget);

      // Numbers 0 to 9 on custom keypad
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tapping numbers
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();
    });

    testWidgets(
      'ProfileScreen renders user details, security card, and stats',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = AuthRepository();
        await repo.loginAsDemo();

        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Profil & Keamanan Akun'), findsOneWidget);
        expect(find.text('Wisatawan Bandung'), findsOneWidget);
        expect(find.text('traveler@bandunghub.id'), findsOneWidget);
        expect(find.text('Keamanan & Privasi (Phase 2)'), findsOneWidget);
        expect(find.text('Autentikasi Biometrik'), findsOneWidget);
        expect(find.text('Keluar dari Akun'), findsOneWidget);
      },
    );
  });
}
