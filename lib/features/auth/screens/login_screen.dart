import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/google_logo_icon.dart';
import '../../navigation/main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _obscurePassword = true;
  String? _errorMessage;
  bool _canUseBiometrics = false;
  UserProfile? _biometricUser;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canBio = await _authRepo.canUseBiometricLogin();
    if (canBio) {
      final user = await _authRepo.getBiometricUser();
      if (mounted) {
        setState(() {
          _canUseBiometrics = true;
          _biometricUser = user;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _canUseBiometrics = false;
          _biometricUser = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateForward() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final success = await _authRepo.loginWithEmailPassword(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        _navigateForward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang kembali, ${_authRepo.userName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              'Email atau kata sandi tidak cocok. Silakan periksa kembali atau daftar baru.';
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _buildGoogleAccountPickerSheet(sheetContext);
      },
    );
  }

  Widget _buildGoogleAccountPickerSheet(BuildContext sheetContext) {
    final accounts = [
      {
        'name': 'Maulana BandungHub',
        'email': 'maulana.fx@gmail.com',
        'color': const Color(0xFF4285F4),
        'initial': 'M',
      },
      {
        'name': 'Wisatawan Parahyangan',
        'email': 'wisatawan.bandung@gmail.com',
        'color': const Color(0xFF34A853),
        'initial': 'W',
      },
      {
        'name': 'Mahasiswa PAM',
        'email': 'mahasiswa.pam@gmail.com',
        'color': const Color(0xFFEA4335),
        'initial': 'P',
      },
    ];

    return Material(
      color: AppColors.getCardColor(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Google Header
            Row(
              children: [
                const GoogleLogoIcon(size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Akun Google',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'untuk melanjutkan ke BandungHub',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const Divider(height: 28),

            // Google Accounts List
            ...List.generate(accounts.length, (index) {
              final acc = accounts[index];
              return ListTile(
                key: Key('btn_google_account_$index'),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: acc['color'] as Color,
                  foregroundColor: Colors.white,
                  child: Text(
                    acc['initial'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  acc['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  acc['email'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _authRepo.loginWithGoogle(
                    name: acc['name'] as String,
                    email: acc['email'] as String,
                  );
                  if (mounted) {
                    _navigateForward();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Berhasil masuk dengan Google sebagai ${acc['name']}!',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              );
            }),

            const Divider(height: 16),

            // Use another custom Google Account
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AppColors.getBorderColor(context),
                child: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              ),
              title: const Text(
                'Gunakan akun Google lain...',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _openCustomGoogleAccountDialog();
              },
            ),

            const SizedBox(height: 16),
            Text(
              'Dengan melanjutkan, Google akan memverifikasi profil dan email Anda dengan aman kepada BandungHub.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _openCustomGoogleAccountDialog() {
    final nameCtrl = TextEditingController(text: 'Google User');
    final emailCtrl = TextEditingController(text: 'traveler.user@gmail.com');

    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Row(
          children: [
            GoogleLogoIcon(size: 22),
            SizedBox(width: 10),
            Text('Masuk Akun Google', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Akun Google',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Alamat Gmail (@gmail.com)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgContext);
              await _authRepo.loginWithGoogle(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
              if (mounted) {
                _navigateForward();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Berhasil masuk sebagai ${nameCtrl.text.trim()}!',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Masuk Google'),
          ),
        ],
      ),
    );
  }


  Future<void> _handleGuestLogin() async {
    await _authRepo.loginAsGuest();
    if (mounted) {
      _navigateForward();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Melanjutkan sebagai Tamu'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    final success = await _authRepo.loginWithBiometrics();
    if (mounted) {
      if (success) {
        _navigateForward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Autentikasi biometrik berhasil! Halo, ${_authRepo.userName}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentikasi biometrik gagal atau dibatalkan.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk Akun'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon & Title
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Silakan masuk untuk menyimpan rencana liburan Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Quick Biometric Login for Returning Authenticated User
                if (_canUseBiometrics && _biometricUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Masuk Cepat Biometrik',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Lanjutkan sebagai ${_biometricUser!.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _handleBiometricLogin,
                          icon: const Icon(Icons.fingerprint_rounded, size: 20),
                          label: const Text(
                            'Pindai Sidik Jari / Wajah',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau masukkan email & sandi',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Error Message if any
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Alamat Email',
                    hintText: 'nama@domain.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan alamat email Anda';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan kata sandi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Submit Login Button
                ElevatedButton(
                  onPressed: _authRepo.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _authRepo.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Masuk ke Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Divider Or
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign-In Button
                OutlinedButton(
                  key: const Key('btn_google_sign_in'),
                  onPressed: _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.getCardColor(context),
                    side: BorderSide(color: AppColors.getBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogoIcon(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Masuk dengan Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Guest Login
                TextButton(
                  onPressed: _handleGuestLogin,
                  child: const Text('Lanjutkan sebagai Tamu (Guest Mode)'),
                ),
                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum memiliki akun? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
