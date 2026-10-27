import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/landmark_scan_result.dart';
import '../../../services/ai_assistant_service.dart';
import '../../destinations/screens/destination_detail_screen.dart';
import '../../map/screens/destination_map_screen.dart';
import '../../recommendations/screens/ai_chat_screen.dart';

class BandungLensScreen extends StatefulWidget {
  const BandungLensScreen({super.key});

  @override
  State<BandungLensScreen> createState() => _BandungLensScreenState();
}

class _BandungLensScreenState extends State<BandungLensScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final AiAssistantService _aiService = AiAssistantService();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isScanning = false;
  LandmarkScanResult? _scanResult;
  String? _errorMessage;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  // Preset sample landmarks for rapid testing/presentation
  final List<Map<String, String>> _sampleLandmarks = [
    {
      'name': 'Gedung Sate',
      'category': 'Sejarah & Budaya',
      'imageUrl':
          'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4c/Gedung_Sate_Oktober_2024_-_Rahmatdenas.jpg/960px-Gedung_Sate_Oktober_2024_-_Rahmatdenas.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=thumbnail',
    },
    {
      'name': 'Kawah Putih Ciwidey',
      'category': 'Alam & Pegunungan',
      'imageUrl':
          'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/35/Kawah_Putih_Lake_from_the_viewing_platform%2C_Bandung_Regency%2C_2014-08-21.jpg/960px-Kawah_Putih_Lake_from_the_viewing_platform%2C_Bandung_Regency%2C_2014-08-21.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=thumbnail',
    },
    {
      'name': 'Jalan Braga',
      'category': 'Sejarah & Budaya',
      'imageUrl':
          'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b7/Jl_Braga_Street_Sign_in_Bandung.jpg/960px-Jl_Braga_Street_Sign_in_Bandung.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=thumbnail',
    },
    {
      'name': 'Gunung Tangkuban Parahu',
      'category': 'Alam & Pegunungan',
      'imageUrl':
          'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Panoramic_View_of_Kawah_Ratu_Crater_in_Mt.Tangkuban_Perahu.jpg/960px-Panoramic_View_of_Kawah_Ratu_Crater_in_Mt.Tangkuban_Perahu.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=thumbnail',
    },
    {
      'name': 'Observatorium Bosscha',
      'category': 'Sejarah & Edukasi',
      'imageUrl':
          'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7f/Bosscha_001.JPG/960px-Bosscha_001.JPG?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=thumbnail',
    },
    {
      'name': 'Saung Angklung Udjo',
      'category': 'Keluarga & Budaya',
      'imageUrl':
          'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e0/Saung_Angklung_Udjo.JPG/960px-Saung_Angklung_Udjo.JPG?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=thumbnail',
    },
  ];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = photo.name;
          _scanResult = null;
          _errorMessage = null;
        });
        _processImageAnalysis(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat mengakses kamera atau galeri: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadSampleLandmark(String name, String url) async {
    setState(() {
      _isScanning = true;
      _selectedImageBytes = null;
      _selectedImageName = name;
      _scanResult = null;
      _errorMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final bytes = res.bodyBytes;
        setState(() {
          _selectedImageBytes = bytes;
        });
        _processImageAnalysis(bytes, hintName: name);
      } else {
        throw Exception('Gagal memuat sampel foto');
      }
    } catch (_) {
      // Fallback: analyze directly using hint
      _processImageAnalysis(Uint8List(0), hintName: name);
    }
  }

  Future<void> _processImageAnalysis(Uint8List bytes, {String? hintName}) async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final result = await _aiService.analyzeLandmarkImage(
        imageBytes: bytes,
        hintName: hintName ?? _selectedImageName,
      );

      if (mounted) {
        setState(() {
          _scanResult = result;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Gagal menganalisis foto: $e';
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _scanResult = null;
      _errorMessage = null;
      _isScanning = false;
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.camera_enhance_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Tentang Bandung Lens', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bandung Smart Lens memanfaatkan AI Multimodal Vision (Google Gemini) untuk mengenali objek wisata, bangunan bersejarah, dan cagar budaya di Bandung Raya.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('Cara Penggunaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 6),
            Text('1. Ambil foto langsung atau unggah dari galeri.', style: TextStyle(fontSize: 12)),
            Text('2. AI akan mengidentifikasi nama objek dan akurasi deteksi.', style: TextStyle(fontSize: 12)),
            Text('3. Dapatkan sejarah, arsitektur, trivia unik, dan rekomendasi aktivitas.', style: TextStyle(fontSize: 12)),
            Text('4. Buka peta atau tanyakan lebih lanjut ke Kang Bandung!', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.camera_enhance_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandung AI Lens',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Pemindai Cagar Budaya & Landmark',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Panduan Fitur',
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Viewfinder & Image Preview Container
            _buildViewfinderSection(),

            const SizedBox(height: 20),

            // Main Camera & Gallery Controls
            if (!_isScanning && _scanResult == null) _buildCaptureControls(),

            // Error View if any
            if (_errorMessage != null) _buildErrorCard(),

            // Scan Result Card
            if (_scanResult != null) _buildResultSection(_scanResult!),

            // Preset Sample Landmarks for Presentation
            if (_scanResult == null && !_isScanning) ...[
              const SizedBox(height: 24),
              _buildSampleLandmarksSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinderSection() {
    final hasImage = _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isScanning ? AppColors.secondary : AppColors.primary.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isScanning ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Image or Empty State
            if (hasImage)
              Image.memory(
                _selectedImageBytes!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.center_focus_strong_rounded,
                      size: 56,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Arahkan Kamera ke Objek Wisata',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Gedung bersejarah, monumen cagar budaya, kawah vulkanik, atau lanskap Bandung',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.4),
                    ),
                  ),
                ],
              ),

            // Targeting Reticle Corners
            _buildReticleCorner(top: 16, left: 16, isTop: true, isLeft: true),
            _buildReticleCorner(top: 16, right: 16, isTop: true, isLeft: false),
            _buildReticleCorner(bottom: 16, left: 16, isTop: false, isLeft: true),
            _buildReticleCorner(bottom: 16, right: 16, isTop: false, isLeft: false),

            // Scanning Laser Line Animation
            if (_isScanning)
              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, _) {
                  return Positioned(
                    top: 300 * _laserAnimation.value,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.secondary.withValues(alpha: 0.9),
                            Colors.white,
                            AppColors.secondary.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.8),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Scanning Overlay Label
            if (_isScanning)
              Positioned(
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'AI Vision sedang menganalisis objek...',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            // Scanned Success Badge
            if (_scanResult != null && !_isScanning)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_scanResult!.confidencePercent}% Akurat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReticleCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.secondary, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.secondary, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.secondary, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.secondary, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('btn_lens_camera'),
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Buka Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('btn_lens_gallery'),
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Pilih Galeri'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(LandmarkScanResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Header Title Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                result.category,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Akurasi ${result.confidencePercent}%',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.landmarkName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.shortDescription,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // History & Architecture Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sejarah & Nilai Arsitektur',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.historyFact,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interesting Trivia Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Fakta Unik & Trivia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.interestingTrivia,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Recommended Things To Do
        if (result.recommendedThingsToDo.isNotEmpty) ...[
          Text(
            'Aktivitas Rekomendasi di Lokasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          ...result.recommendedThingsToDo.map(
            (act) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      act,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Action Buttons Row
        if (result.matchedDestination != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_lens_view_destination'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DestinationDetailScreen(
                      destination: result.matchedDestination!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.place_rounded),
              label: const Text('Buka Detail Destinasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DestinationMapScreen(
                          initialDestination: result.matchedDestination,
                          isNavigating: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Rute Peta'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AiChatScreen(
                          initialPrompt:
                              'Kang Bandung, ceritakan lebih banyak kisah sejarah dan spot rahasia di ${result.landmarkName}!',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Tanya AI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Reset Scanner Button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            key: const Key('btn_lens_scan_another'),
            onPressed: _resetScanner,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Pindai Objek Lain'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSampleLandmarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 18),
            const SizedBox(width: 6),
            Text(
              'Uji Coba Cepat (Sampel Foto Landmark):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ketuk salah satu foto untuk mencoba kemampuan AI Vision mengenali landmark ikonik Bandung secara langsung.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sampleLandmarks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final sample = _sampleLandmarks[index];
              return InkWell(
                onTap: () => _loadSampleLandmark(sample['name']!, sample['imageUrl']!),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 135,
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        child: Image.network(
                          sample['imageUrl']!,
                          height: 70,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 70,
                            color: AppColors.primary.withValues(alpha: 0.15),
                            child: const Center(
                              child: Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          sample['name']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
