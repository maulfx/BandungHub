import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/destination_repository.dart';
import '../../../data/repositories/itinerary_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/repositories/theme_repository.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/pin_lock_screen.dart';
import '../../../data/repositories/offline_sync_repository.dart';
import '../../academic/screens/course_feedback_screen.dart';
import '../../offline/screens/offline_sync_screen.dart';

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

  ImageProvider? _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
    final clean = avatarUrl.trim();
    if (clean.startsWith('data:image')) {
      try {
        final commaIndex = clean.indexOf(',');
        final base64Data =
            commaIndex != -1 ? clean.substring(commaIndex + 1) : clean;
        final bytes = base64Decode(base64Data);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error decoding base64 avatar: $e');
        return null;
      }
    }
    if (clean.startsWith('assets/')) {
      return AssetImage(clean);
    }
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }
    try {
      final file = File(clean);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await _authRepo.updateProfile(avatarUrl: base64String);
        if (mounted) {
          final sourceName =
              source == ImageSource.gallery ? 'galeri' : 'kamera';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto profil dari $sourceName berhasil disimpan ke database!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showChangeAvatarDialog() {
    final presets = [
      {
        'label': 'Bocchi 🎸',
        'url': 'assets/mini_game/bocchi.png',
        'isAsset': true,
      },
      {
        'label': 'Traveler 🎒',
        'url':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=250&q=80',
        'isAsset': false,
      },
      {
        'label': 'Petualang 🧢',
        'url':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=250&q=80',
        'isAsset': false,
      },
      {
        'label': 'Outdoor 🌲',
        'url':
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=250&q=80',
        'isAsset': false,
      },
      {
        'label': 'Explorer 📷',
        'url':
            'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=250&q=80',
        'isAsset': false,
      },
      {
        'label': 'Hiker 🥾',
        'url':
            'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=250&q=80',
        'isAsset': false,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Ganti Foto Profil',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Upload dari Perangkat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await _pickImage(ImageSource.gallery);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.photo_library_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Buka Galeri',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await _pickImage(ImageSource.camera);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Buka Kamera',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Atau Pilih Karakter Avatar BandungHub',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: presets.map((p) {
                    final isAsset = p['isAsset'] as bool;
                    final url = p['url'] as String;
                    final label = p['label'] as String;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _authRepo.updateProfile(avatarUrl: url);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Foto profil berhasil diubah ke $label dan tersimpan di database!',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.getBackgroundColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: isAsset
                                  ? AssetImage(url) as ImageProvider
                                  : NetworkImage(url),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_authRepo.currentUser?.avatarUrl != null &&
                    _authRepo.currentUser!.avatarUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _authRepo.updateProfile(clearAvatar: true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Foto profil berhasil dihapus dari database (kembali ke bawaan).',
                              ),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Hapus Foto Profil Saat Ini'),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                  Text('Pilih Tema'),
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
                    title: const Text('Default (Sistem)'),
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
                    title: const Text('Terang (Light)'),
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
                    title: const Text('Gelap (Dark)'),
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
                        '${_destinationRepo.allDestinations.length} Destinasi aktif (Supabase/Katalog)',
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
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      // 1. Bersihkan ulasan lokal
                      await ReviewRepository().clearLocalReviews();
                      // 2. Bersihkan rencana perjalanan lokal
                      await ItineraryRepository().clearLocalItineraries();
                      // 3. Muat ulang destinasi murni dari Supabase Cloud
                      await DestinationRepository().refreshFromCloud();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Data lokal telah dibersihkan! Aplikasi kini memuat data murni dari Supabase Cloud.',
                            ),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                    label: const Text('Gunakan Data Supabase Murni'),
                  ),
                ),
                const SizedBox(height: 8),
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
                    label: const Text('Bersihkan Cache Singgahan'),
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
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Konfirmasi Keluar'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini? Anda akan diarahkan kembali ke halaman masuk.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _authRepo.logout();
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
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
        final hasPin = _authRepo.hasPin;
        final isBiometric = _authRepo.isBiometricEnabled;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil & Keamanan Akun'),
            actions: [
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

                // User Avatar & Badge with Photo Editor
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showChangeAvatarDialog,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: (_authRepo.isAdmin
                                        ? const Color(0xFF673AB7)
                                        : AppColors.primary)
                                    .withValues(alpha: 0.12),
                                backgroundImage: _getAvatarProvider(
                                    _authRepo.currentUser?.avatarUrl),
                                child: (_authRepo.currentUser?.avatarUrl ==
                                            null ||
                                        _authRepo.currentUser!.avatarUrl!
                                            .trim()
                                            .isEmpty)
                                    ? Icon(
                                        _authRepo.isAdmin
                                            ? Icons.admin_panel_settings_rounded
                                            : Icons.person_rounded,
                                        size: 52,
                                        color: _authRepo.isAdmin
                                            ? const Color(0xFF673AB7)
                                            : AppColors.primary,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _showChangeAvatarDialog,
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text(
                          'Ganti Foto Profil',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
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
                    final badgeColor = isAdmin
                        ? const Color(0xFF673AB7)
                        : AppColors.success;

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
                          ],
                          Text(
                            isAdmin
                                ? 'Hak Akses: Administrator BandungHub'
                                : 'Akun Resmi Terverifikasi',
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            SizedBox(width: 8),
                            Text(
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
                        title: const Text('Tema'),
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

                // Logout Button
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
                  icon: Icons.support_agent_rounded,
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
