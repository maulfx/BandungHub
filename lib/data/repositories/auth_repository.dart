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
  bool _isSessionUnlocked = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isSessionUnlocked => _isSessionUnlocked;

  // Convenience getters
  bool get isLoggedIn => _currentUser != null;
  bool get isGuest => false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isBiometricEnabled => _currentUser?.isBiometricEnabled ?? false;
  bool get hasPin => _currentUser?.hasPin ?? false;
  String get userName => _currentUser?.name ?? 'Pengguna';
  String get userEmail => _currentUser?.email ?? '';

  // Initialize repository on app launch
  Future<void> init() async {
    if (_isInitialized) return;
    _isLoading = true;

    try {
      final savedUser = await _storage.getCurrentUser();
      if (savedUser != null && !savedUser.isGuest) {
        _currentUser = savedUser.copyWith(lastLoginAt: DateTime.now());
        await _storage.saveCurrentUser(_currentUser!);
        if (savedUser.isBiometricEnabled) {
          await _storage.saveBiometricUserEmail(savedUser.email);
        }
        // Real saved accounts require biometric or PIN unlock (bank-style)
        _isSessionUnlocked = false;
      } else {
        _currentUser = null;
        _isSessionUnlocked = false;
      }
    } catch (e) {
      debugPrint('AuthRepository init error: $e');
      _currentUser = null;
      _isSessionUnlocked = false;
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

      if (user == null &&
          (cleanEmail == 'admin@bandunghub.id' ||
              cleanEmail == 'admin@gmail.com')) {
        user = UserProfile.admin();
      }

      user ??= UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanEmail.split('@').first,
        email: cleanEmail,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      await _storage.saveCurrentUser(_currentUser!);
      if (user.isBiometricEnabled) {
        await _storage.saveBiometricUserEmail(user.email);
      }

      _isSessionUnlocked = true;
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
      _isSessionUnlocked = true;

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

  // Check if biometric login is available for a returning user on this device
  Future<bool> canUseBiometricLogin() async {
    final available = await _biometricService.isBiometricAvailable();
    if (!available) return false;

    final bioEmail = await _storage.getBiometricUserEmail();
    if (bioEmail == null || bioEmail.isEmpty) return false;

    final registered = await _storage.getRegisteredUsers();
    final user = registered[bioEmail.toLowerCase()];
    return user != null && user.isBiometricEnabled;
  }

  // Get user profile for returning biometric user
  Future<UserProfile?> getBiometricUser() async {
    final bioEmail = await _storage.getBiometricUserEmail();
    if (bioEmail == null || bioEmail.isEmpty) return null;

    final registered = await _storage.getRegisteredUsers();
    final user = registered[bioEmail.toLowerCase()];
    if (user != null && user.isBiometricEnabled) {
      return user;
    }
    return null;
  }

  // Quick Login with Biometrics (Strictly for returning users who enabled biometrics)
  Future<bool> loginWithBiometrics() async {
    final bioEmail = await _storage.getBiometricUserEmail();
    UserProfile? targetUser;

    if (bioEmail != null && bioEmail.isNotEmpty) {
      final registered = await _storage.getRegisteredUsers();
      targetUser = registered[bioEmail.toLowerCase()];
    }

    if (targetUser == null &&
        _currentUser != null &&
        _currentUser!.isBiometricEnabled) {
      targetUser = _currentUser;
    }

    if (targetUser == null || !targetUser.isBiometricEnabled) {
      return false;
    }

    final success = await _biometricService.authenticate(
      reason:
          'Pindai sidik jari atau wajah untuk masuk sebagai ${targetUser.name}',
    );

    if (success) {
      _currentUser = targetUser.copyWith(lastLoginAt: DateTime.now());
      await _storage.saveCurrentUser(_currentUser!);
      _isSessionUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Quick Login with PIN
  Future<bool> loginWithPin(String pin) async {
    UserProfile? targetUser = _currentUser;
    if (targetUser == null) {
      final bioEmail = await _storage.getBiometricUserEmail();
      if (bioEmail != null) {
        final registered = await _storage.getRegisteredUsers();
        targetUser = registered[bioEmail.toLowerCase()];
      }
    }

    if (targetUser == null || !targetUser.hasPin) return false;

    if (targetUser.verifyPin(pin)) {
      _currentUser = targetUser.copyWith(lastLoginAt: DateTime.now());
      await _storage.saveCurrentUser(_currentUser!);
      _isSessionUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Login as Guest
  Future<void> loginAsGuest() async {
    _currentUser = UserProfile.guest();
    await _storage.saveCurrentUser(_currentUser!);
    _isSessionUnlocked = true;
    notifyListeners();
  }

  // Login as Demo User (For internal testing)
  Future<void> loginAsDemo() async {
    _currentUser = UserProfile.demoUser();
    await _storage.saveCurrentUser(_currentUser!);
    await _storage.savePasswordHash(
      _currentUser!.email,
      UserProfile.hashSecret('bandung123'),
    );
    _isSessionUnlocked = true;
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
      await _storage.saveBiometricUserEmail(_currentUser!.email);
    } else {
      await _storage.clearBiometricUserEmail();
    }

    _currentUser = _currentUser!.copyWith(isBiometricEnabled: enable);
    await _storage.saveCurrentUser(_currentUser!);
    notifyListeners();
    return true;
  }

  // Update profile details
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final effectiveAvatar = clearAvatar ? '' : avatarUrl;
    if (_currentUser == null) {
      _currentUser = UserProfile.guest().copyWith(
        name: name,
        avatarUrl: effectiveAvatar,
      );
    } else {
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        avatarUrl: effectiveAvatar ?? _currentUser!.avatarUrl,
      );
    }
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

  // Manual session unlock (e.g. after successful PIN/Biometric verification)
  void unlockSession() {
    _isSessionUnlocked = true;
    notifyListeners();
  }

  // Manual session lock (e.g. on app background timeout)
  void lockSession() {
    if (_currentUser != null) {
      _isSessionUnlocked = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearSession();
    _currentUser = null;
    _isSessionUnlocked = false;
    notifyListeners();
  }
}
