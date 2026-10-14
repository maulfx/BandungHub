import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';

enum PinScreenMode { verify, create }

class PinLockScreen extends StatefulWidget {
  final PinScreenMode mode;
  final VoidCallback? onVerified;

  const PinLockScreen({
    super.key,
    this.mode = PinScreenMode.verify,
    this.onVerified,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _authRepo = AuthRepository();
  String _enteredPin = '';
  String _firstEnteredPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  static const int _pinLength = 6;

  void _onNumberPressed(String number) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin += number;
        _errorMessage = null;
      });

      if (_enteredPin.length == _pinLength) {
        _processCompletePin();
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

  Future<void> _processCompletePin() async {
    if (widget.mode == PinScreenMode.verify) {
      final success = await _authRepo.loginWithPin(_enteredPin);
      if (mounted) {
        if (success) {
          if (widget.onVerified != null) {
            widget.onVerified!();
          } else {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _errorMessage = 'PIN salah. Coba lagi.';
            _enteredPin = '';
          });
        }
      }
    } else {
      // Create mode
      if (!_isConfirming) {
        setState(() {
          _firstEnteredPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _firstEnteredPin) {
          await _authRepo.setPin(_enteredPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN keamanan berhasil disimpan!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _errorMessage = 'PIN konfirmasi tidak sama. Mulai kembali.';
            _enteredPin = '';
            _firstEnteredPin = '';
            _isConfirming = false;
          });
        }
      }
    }
  }

  Future<void> _handleBiometric() async {
    final success = await _authRepo.loginWithBiometrics();
    if (mounted && success) {
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildKeypadButton({required String label, VoidCallback? onPressed}) {
    return InkResponse(
      onTap: onPressed,
      radius: 36,
      splashColor: AppColors.primary.withValues(alpha: 0.2),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String titleText = 'Masukkan PIN Keamanan';
    if (widget.mode == PinScreenMode.create) {
      titleText = _isConfirming
          ? 'Konfirmasi PIN Baru'
          : 'Buat 6-Digit PIN Baru';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == PinScreenMode.verify
              ? 'Verifikasi PIN'
              : 'Atur PIN Keamanan',
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.mode == PinScreenMode.verify
                      ? Icons.lock_outline_rounded
                      : Icons.dialpad_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titleText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.mode == PinScreenMode.verify
                  ? 'Ketik 6 digit PIN akun Anda'
                  : (_isConfirming
                        ? 'Ketik ulang 6 digit PIN untuk memastikan'
                        : 'PIN akan digunakan untuk akses cepat BandungHub'),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            // Error Text
            Container(
              height: 32,
              alignment: Alignment.center,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const Spacer(),

            // Custom Keypad
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
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Biometric button or blank
                      if (widget.mode == PinScreenMode.verify &&
                          _authRepo.isBiometricEnabled)
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: _handleBiometric,
                        )
                      else
                        const SizedBox(width: 72, height: 72),

                      _buildKeypadButton(
                        label: '0',
                        onPressed: () => _onNumberPressed('0'),
                      ),

                      // Backspace
                      IconButton(
                        iconSize: 28,
                        icon: const Icon(
                          Icons.backspace_outlined,
                          color: AppColors.textPrimaryLight,
                        ),
                        onPressed: _onBackspacePressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
