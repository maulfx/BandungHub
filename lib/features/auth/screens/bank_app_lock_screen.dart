import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

/// Bank-Style App Lock Screen for returning users with saved credentials.
/// Modeled after mobile banking apps (BCA, Livin, Jenius):
/// Displays user avatar, greeting, 6-digit PIN pad, and seamless biometric prompt.
class BankAppLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const BankAppLockScreen({super.key, this.onUnlocked});

  @override
  State<BankAppLockScreen> createState() => _BankAppLockScreenState();
}

class _BankAppLockScreenState extends State<BankAppLockScreen> {
  final _authRepo = AuthRepository();
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;
  bool _isAuthenticatingBio = false;

  static const int _pinLength = 6;

  @override
  void initState() {
    super.initState();
    // Auto-prompt biometrics if enabled for returning user on screen launch
    if (_authRepo.isBiometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometrics();
      });
    }
  }

  Future<void> _triggerBiometrics() async {
    if (_isAuthenticatingBio) return;
    setState(() {
      _isAuthenticatingBio = true;
      _errorMessage = null;
    });

    try {
      final success = await _authRepo.loginWithBiometrics();
      if (mounted) {
        if (success) {
          _handleSuccess();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticatingBio = false);
      }
    }
  }

  void _handleSuccess() {
    _authRepo.unlockSession();
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    }
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin += number;
        _errorMessage = null;
      });

      if (_enteredPin.length == _pinLength) {
        _processPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _processPin() async {
    final user = _authRepo.currentUser;
    final hasPin = user?.hasPin ?? false;

    if (hasPin) {
      // Verify existing PIN
      final success = await _authRepo.loginWithPin(_enteredPin);
      if (mounted) {
        if (success) {
          _handleSuccess();
        } else {
          setState(() {
            _errorMessage = 'PIN salah. Silakan coba lagi.';
            _enteredPin = '';
          });
        }
      }
    } else {
      // User doesn't have a PIN set yet: guide them to create one
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _confirmPin) {
          await _authRepo.setPin(_enteredPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN keamanan berhasil dibuat!'),
                backgroundColor: AppColors.success,
              ),
            );
            _handleSuccess();
          }
        } else {
          setState(() {
            _errorMessage = 'PIN konfirmasi tidak sama. Ulangi kembali.';
            _enteredPin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    }
  }

  Future<void> _handleSwitchAccount() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Ganti Akun'),
        content: const Text(
          'Keluar dari sesi akun ini dan kembali ke halaman masuk?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Ganti Akun'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _authRepo.logout();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildAvatar(BuildContext context) {
    final user = _authRepo.currentUser;
    final avatar = user?.avatarUrl;

    ImageProvider? imageProvider;
    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('data:image') || avatar.contains(',')) {
        try {
          final base64String = avatar.contains(',')
              ? avatar.split(',').last
              : avatar;
          imageProvider = MemoryImage(base64Decode(base64String));
        } catch (_) {}
      } else if (avatar.startsWith('http')) {
        imageProvider = NetworkImage(avatar);
      }
    }

    final initial = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : 'U';

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageProvider != null
            ? Image(image: imageProvider, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildKeypadButton({required String label, VoidCallback? onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkResponse(
      onTap: onPressed,
      radius: 36,
      splashColor: AppColors.primary.withValues(alpha: 0.2),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(
            color: AppColors.getBorderColor(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepo.currentUser;
    final hasPin = user?.hasPin ?? false;

    String subtitleText = 'Masukkan 6 digit PIN akun Anda';
    if (!hasPin) {
      subtitleText = _isConfirming
          ? 'Ketik ulang 6 digit PIN untuk konfirmasi'
          : 'Atur 6 digit PIN untuk akses cepat seperti app bank';
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

            // Top App Brand
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/app_logo_transparent.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Profile Greeting (Bank Style)
            _buildAvatar(context),
            const SizedBox(height: 12),
            Text(
              'Selamat Datang Kembali,',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.name ?? 'Pengguna BandungHub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Mode prompt
            Text(
              subtitleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 20),

            // 6-Digit PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled
                          ? AppColors.primary
                          : AppColors.getBorderColor(context),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            // Error Message
            Container(
              height: 32,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),

            const Spacer(),

            // Custom Keypad (Bank-Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton(
                        label: '1',
                        onPressed: () => _onNumberPressed('1'),
                      ),
                      _buildKeypadButton(
                        label: '2',
                        onPressed: () => _onNumberPressed('2'),
                      ),
                      _buildKeypadButton(
                        label: '3',
                        onPressed: () => _onNumberPressed('3'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton(
                        label: '4',
                        onPressed: () => _onNumberPressed('4'),
                      ),
                      _buildKeypadButton(
                        label: '5',
                        onPressed: () => _onNumberPressed('5'),
                      ),
                      _buildKeypadButton(
                        label: '6',
                        onPressed: () => _onNumberPressed('6'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton(
                        label: '7',
                        onPressed: () => _onNumberPressed('7'),
                      ),
                      _buildKeypadButton(
                        label: '8',
                        onPressed: () => _onNumberPressed('8'),
                      ),
                      _buildKeypadButton(
                        label: '9',
                        onPressed: () => _onNumberPressed('9'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Biometric Trigger Button
                      if (_authRepo.isBiometricEnabled)
                        InkResponse(
                          onTap: _triggerBiometrics,
                          radius: 36,
                          child: Container(
                            width: 70,
                            height: 70,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (!hasPin)
                        // If user doesn't have PIN, provide quick unlock button
                        TextButton(
                          onPressed: _handleSuccess,
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 70, height: 70),

                      _buildKeypadButton(
                        label: '0',
                        onPressed: () => _onNumberPressed('0'),
                      ),

                      // Backspace Button
                      InkResponse(
                        onTap: _onBackspacePressed,
                        radius: 36,
                        child: Container(
                          width: 70,
                          height: 70,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 26,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Switch Account / Logout Option
            TextButton.icon(
              onPressed: _handleSwitchAccount,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text(
                'Ganti Akun / Masuk dengan Email Lain',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
