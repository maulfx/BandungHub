import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  // Check if device hardware supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric availability check failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking biometrics: $e');
      return false;
    }
  }

  // Get list of supported biometric types (Fingerprint, Face, Iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Failed to get available biometrics: ${e.message}');
      return [];
    } catch (_) {
      return [];
    }
  }

  // Authenticate user with biometric prompt
  Future<bool> authenticate({
    String reason = 'Gunakan sensor biometrik (Sidik Jari / Wajah) untuk masuk ke BandungHub',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('Biometrics not available on this device');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }

  // Human-readable biometric type label
  Future<String> getBiometricTypeLabel() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) {
      return 'Face ID / Pengenalan Wajah';
    } else if (types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong)) {
      return 'Sidik Jari (Fingerprint)';
    } else if (types.contains(BiometricType.iris)) {
      return 'Pemindai Iris';
    }
    return 'Autentikasi Biometrik';
  }
}
