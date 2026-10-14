import 'package:flutter/foundation.dart';

import '../../models/user_profile.dart';
import '../../services/biometric_service.dart';
import '../local/auth_storage.dart';

class AuthRepository extends ChangeNotifier {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final AuthStorage _storage = AuthStorage();
  final BiometricService _biometricService = BiometricService();

  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Convenience getters
  bool get isLoggedIn => _currentUser != null && !_currentUser!.isGuest;
  bool get isGuest => _currentUser == null || _currentUser!.isGuest;
  bool get isBiometricEnabled => _currentUser?.isBiometricEnabled ?? false;
  bool get hasPin => _currentUser?.hasPin ?? false;
  String get userName => _currentUser?.name ?? 'Tamu BandungHub';
  String get userEmail => _currentUser?.email ?? 'tamu@bandunghub.local';

  // Initialize repository on app launch
  Future<void> init() async {
    if (_isInitialized) return;
    _isLoading = true;

    try {
      final savedUser = await _storage.getCurrentUser();
      if (savedUser != null) {
        _currentUser = savedUser.copyWith(lastLoginAt: DateTime.now());
        await _storage.saveCurrentUser(_currentUser!);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('AuthRepository init error: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Login with Email & Password
  Future<bool> loginWithEmailPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final passHash = UserProfile.hashSecret(password);

      final isValid = await _storage.verifyPassword(cleanEmail, passHash);
      if (!isValid) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final registered = await _storage.getRegisteredUsers();
      UserProfile? user = registered[cleanEmail];

      user ??= UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanEmail.split('@').first,
        email: cleanEmail,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      await _storage.saveCurrentUser(_currentUser!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register new account
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final passHash = UserProfile.hashSecret(password);
      final pinHash = (pin != null && pin.isNotEmpty)
          ? UserProfile.hashSecret(pin)
          : null;

      final newUser = UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: cleanEmail,
        pinHash: pinHash,
        isBiometricEnabled: false,
        isGuest: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _storage.savePasswordHash(cleanEmail, passHash);
      await _storage.saveCurrentUser(newUser);
      _currentUser = newUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Quick Login with Biometrics
  Future<bool> loginWithBiometrics() async {
    if (_currentUser == null) return false;

    final success = await _biometricService.authenticate(
      reason: 'Pindai sidik jari atau wajah untuk membuka BandungHub',
    );

    if (success) {
      _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
      await _storage.saveCurrentUser(_currentUser!);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Quick Login with PIN
  Future<bool> loginWithPin(String pin) async {
    if (_currentUser == null || !_currentUser!.hasPin) return false;

    if (_currentUser!.verifyPin(pin)) {
      _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
      await _storage.saveCurrentUser(_currentUser!);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Login as Guest
  Future<void> loginAsGuest() async {
    _currentUser = UserProfile.guest();
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  // Login as Demo User (One-Click instant login for reviewers)
  Future<void> loginAsDemo() async {
    _currentUser = UserProfile.demoUser();
    await _storage.saveCurrentUser(_currentUser!);
    await _storage.savePasswordHash(
      _currentUser!.email,
      UserProfile.hashSecret('bandung123'),
    );
    notifyListeners();
  }

  // Set or Update PIN (6 digits)
  Future<bool> setPin(String pin) async {
    if (_currentUser == null) return false;
    final pinHash = UserProfile.hashSecret(pin);
    _currentUser = _currentUser!.copyWith(pinHash: pinHash);
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
    return true;
  }

  // Remove PIN
  Future<void> removePin() async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(pinHash: '');
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  // Toggle Biometric Authentication
  Future<bool> toggleBiometric(bool enable) async {
    if (_currentUser == null) return false;

    if (enable) {
      final available = await _biometricService.isBiometricAvailable();
      if (!available) {
        return false;
      }
      final verified = await _biometricService.authenticate(
        reason: 'Konfirmasi biometrik untuk mengaktifkan fitur ini',
      );
      if (!verified) return false;
    }

    _currentUser = _currentUser!.copyWith(isBiometricEnabled: enable);
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
    return true;
  }

  // Update profile details
  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
    );
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  // Login with Google
  Future<bool> loginWithGoogle({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleUser = UserProfile.googleUser(
        name: name,
        email: email,
        avatarUrl: avatarUrl,
      );

      await _storage.saveCurrentUser(googleUser);
      _currentUser = googleUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearSession();
    _currentUser = null;
    notifyListeners();
  }
}
