import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/destination_repository.dart';
import '../../../data/repositories/itinerary_repository.dart';
import '../../../data/repositories/theme_repository.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/pin_lock_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../../data/repositories/offline_sync_repository.dart';
import '../../academic/screens/course_feedback_screen.dart';
import '../../converter/screens/travel_converter_screen.dart';
import '../../offline/screens/offline_sync_screen.dart';
import '../../../shared/widgets/google_logo_icon.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepo = AuthRepository();
  final _itineraryRepo = ItineraryRepository();
  final _destinationRepo = DestinationRepository();
  final _themeRepo = ThemeRepository();

  void _openEditNameDialog() {
    final controller = TextEditingController(text: _authRepo.userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Ubah Nama Profil'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _authRepo.updateProfile(name: controller.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama profil berhasil diperbarui!'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _openThemeSelectorDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentMode = _themeRepo.themeMode;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.palette_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Pilih Tema Aplikasi'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.settings_brightness_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Ikuti Sistem (Otomatis)'),
                    trailing: currentMode == ThemeMode.system
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: AppColors.textSecondaryLight,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      _themeRepo.setThemeMode(ThemeMode.system);
                      Navigator.pop(dialogContext);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.light_mode_rounded,
                      color: AppColors.secondaryLight,
                    ),
                    title: const Text('Mode Terang (Light)'),
                    trailing: currentMode == ThemeMode.light
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: AppColors.textSecondaryLight,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      _themeRepo.setThemeMode(ThemeMode.light);
                      Navigator.pop(dialogContext);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.dark_mode_rounded,
                      color: AppColors.primaryLight,
                    ),
                    title: const Text('Mode Gelap (Dark)'),
                    trailing: currentMode == ThemeMode.dark
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: AppColors.textSecondaryLight,
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      _themeRepo.setThemeMode(ThemeMode.dark);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSimplifiedStorageDialog() {
    final syncRepo = OfflineSyncRepository.instance;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final stats = syncRepo.getCacheStats();
          final formattedSize = stats['formattedSize'] as String;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.cleaning_services_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Penyimpanan & Cache'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Memori Cache:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formattedSize,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '38 Destinasi wisata tersimpan offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final freedBytes = await syncRepo.clearTemporaryCache();
                      setDialogState(() {});
                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        final formattedFreed = freedBytes < 1024 * 1024
                            ? '${(freedBytes / 1024).toStringAsFixed(1)} KB'
                            : '${(freedBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cache berhasil dibersihkan ($formattedFreed dibebaskan).',
                            ),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text('Bersihkan Cache'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfflineSyncScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Pengaturan Teknis Sinkronisasi >',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Konfirmasi Keluar'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini? Sesi Anda akan beralih ke mode Tamu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _authRepo.logout();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Anda telah keluar dari akun.'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              },
              child: const Text(
                'Keluar Akun',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_authRepo, _themeRepo]),
      builder: (context, _) {
        final isGuest = _authRepo.isGuest;
        final hasPin = _authRepo.hasPin;
        final isBiometric = _authRepo.isBiometricEnabled;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil & Keamanan Akun'),
            actions: [
              if (!isGuest)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Ubah Nama Profil',
                  onPressed: _openEditNameDialog,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // User Avatar & Badge
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: (_authRepo.isAdmin
                                ? const Color(0xFF673AB7)
                                : AppColors.primary)
                            .withValues(alpha: 0.12),
                        child: Icon(
                          _authRepo.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : (isGuest
                                  ? Icons.person_outline_rounded
                                  : Icons.person_rounded),
                          size: 50,
                          color: _authRepo.isAdmin
                              ? const Color(0xFF673AB7)
                              : AppColors.primary,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _authRepo.isAdmin
                                ? const Color(0xFF673AB7)
                                : (isGuest
                                    ? AppColors.secondary
                                    : AppColors.success),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _authRepo.isAdmin
                                ? Icons.verified_rounded
                                : (isGuest
                                    ? Icons.hiking_rounded
                                    : Icons.verified_user_rounded),
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Name & Email
                Text(
                  _authRepo.userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _authRepo.userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),

                // Status chip
                Builder(
                  builder: (context) {
                    final isAdmin = _authRepo.isAdmin;
                    final provider = _authRepo.currentUser?.authProvider ?? 'email';
                    final isGoogle = provider == 'google';
                    final badgeColor = isAdmin
                        ? const Color(0xFF673AB7)
                        : (isGuest
                            ? AppColors.warning
                            : (isGoogle ? Colors.blue.shade800 : AppColors.success));

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAdmin) ...[
                            const Icon(
                              Icons.shield_rounded,
                              size: 14,
                              color: Color(0xFF673AB7),
                            ),
                            const SizedBox(width: 6),
                          ] else if (isGoogle) ...[
                            const GoogleLogoIcon(size: 14),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            isAdmin
                                ? 'Hak Akses: Administrator BandungHub'
                                : (isGuest
                                    ? 'Mode Tamu (Guest Traveler)'
                                    : (isGoogle
                                        ? 'Terverifikasi Akun Google'
                                        : 'Akun Resmi Terverifikasi')),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Administrator Overview Card (if admin)
                if (_authRepo.isAdmin) ...[
                  _buildAdminOverviewCard(context),
                  const SizedBox(height: 20),
                ],

                // Guest Login CTA Card (if guest)
                if (isGuest) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.secondary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars_rounded, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dapatkan Akses Penuh BandungHub',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Simpan itinerary liburan, aktifkan login biometrik cepat, dan simpan destinasi favorit Anda.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Masuk Akun',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Daftar Baru',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Statistics Card
                ListenableBuilder(
                  listenable: _itineraryRepo,
                  builder: (context, _) {
                    return ListenableBuilder(
                      listenable: _destinationRepo,
                      builder: (context, _) {
                        final itineraryCount =
                            _itineraryRepo.itineraries.length;
                        final favoriteCount =
                            _destinationRepo.favoriteIds.length;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getCardColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.getBorderColor(context),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '$itineraryCount',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rencana Liburan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: AppColors.getBorderColor(context),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '$favoriteCount',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Destinasi Favorit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: AppColors.getBorderColor(context),
                              ),
                              Column(
                                children: [
                                  Text(
                                    hasPin ? 'Aktif' : 'Belum Diatur',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: hasPin
                                          ? AppColors.success
                                          : AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Status PIN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Security & Settings Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Section Header
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Keamanan & Privasi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Biometric Auth Switch
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text('Autentikasi Biometrik'),
                        value: isBiometric,
                        onChanged: (val) async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await _authRepo.toggleBiometric(val);
                          if (!success && mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sensor biometrik tidak tersedia atau dibatalkan.',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),

                      // Setup or Change PIN
                      ListTile(
                        leading: const Icon(
                          Icons.pin_rounded,
                          color: AppColors.secondary,
                        ),
                        title: Text(
                          hasPin ? 'Change PIN' : 'PIN Belum Diatur',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PinLockScreen(
                                mode: PinScreenMode.create,
                              ),
                            ),
                          );
                        },
                      ),

                      // Remove PIN if exists
                      if (hasPin) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.lock_open_rounded,
                            color: AppColors.warning,
                          ),
                          title: const Text('Hapus PIN Keamanan'),
                          trailing: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.warning,
                          ),
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await _authRepo.removePin();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('PIN keamanan telah dihapus.'),
                                  backgroundColor: AppColors.secondary,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Theme & Appearance Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.palette_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tampilan & Aksesibilitas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          _themeRepo.themeMode == ThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : (_themeRepo.themeMode == ThemeMode.light
                                  ? Icons.light_mode_rounded
                                  : Icons.settings_brightness_rounded),
                          color: AppColors.primary,
                        ),
                        title: const Text('Mode Tampilan (Tema)'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _themeRepo.themeModeLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                        onTap: _openThemeSelectorDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // General App Settings & Feedback Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.currency_exchange_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text('Konverter Mata Uang & Waktu'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TravelConverterScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.school_rounded,
                          color: AppColors.secondary,
                        ),
                        title: const Text('Kesan & Pesan Kuliah'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CourseFeedbackScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.textSecondaryLight,
                        ),
                        title: const Text('Versi Aplikasi & Penyimpanan'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'v${AppConstants.appVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        onTap: _showSimplifiedStorageDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Logout or Switch Account Button
                if (!isGuest)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text(
                        'Masuk / Daftar Akun',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminOverviewCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF673AB7).withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF673AB7).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel Kontrol Administrator',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF673AB7),
                      ),
                    ),
                    Text(
                      'Hak Akses Penuh Sistem BandungHub',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SUPER ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAdminStatTile(
                  icon: Icons.place_rounded,
                  label: 'Destinasi',
                  value: '38 Wisata',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdminStatTile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Asisten AI',
                  value: 'Online',
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdminStatTile(
                  icon: Icons.screen_rotation_rounded,
                  label: 'Sensor',
                  value: 'Gyro + Kompas',
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
