import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Screen for Course Evaluation, Reflections, Impressions, and Feedback (Kesan & Pesan Kuliah)
class CourseFeedbackScreen extends StatefulWidget {
  const CourseFeedbackScreen({super.key});

  @override
  State<CourseFeedbackScreen> createState() => _CourseFeedbackScreenState();
}

class _CourseFeedbackScreenState extends State<CourseFeedbackScreen> {
  static const String _prefFeedbackKey = 'academic_course_feedback_v1';

  final _formKey = GlobalKey<FormState>();
  final _lecturerController = TextEditingController(text: 'Dosen Pengampu PAM');
  final _studentNameController = TextEditingController(text: 'Mahasiswa BandungHub');
  final _studentNimController = TextEditingController(text: '12345678');
  final _impressionsController = TextEditingController();
  final _suggestionsController = TextEditingController();

  double _rating = 5.0;
  final Set<String> _selectedTopics = {
    'Flutter & Dart Clean Architecture',
    'Offline-First & SQLite Storage',
    'OpenStreetMap Navigation',
  };

  bool _isLoading = true;
  bool _isSaved = false;

  final List<String> _availableTopics = [
    'Flutter & Dart Clean Architecture',
    'Offline-First & SQLite Storage',
    'OpenStreetMap Navigation',
    'Autentikasi Biometrik & PIN',
    'AI Assistant & Travel Reasoning',
    'Responsive Design & Dark Mode',
    'Unit & Widget Testing (100% Pass)',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedFeedback();
  }

  Future<void> _loadSavedFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefFeedbackKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _lecturerController.text = data['lecturer'] ?? _lecturerController.text;
          _studentNameController.text = data['studentName'] ?? _studentNameController.text;
          _studentNimController.text = data['studentNim'] ?? _studentNimController.text;
          _impressionsController.text = data['impressions'] ?? '';
          _suggestionsController.text = data['suggestions'] ?? '';
          _rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
          if (data['topics'] is List) {
            _selectedTopics.clear();
            _selectedTopics.addAll(
              (data['topics'] as List).map((e) => e.toString()),
            );
          }
          _isSaved = true;
        });
      } else {
        // Default template feedback for rich UX
        _impressionsController.text =
            'Mata kuliah Pemrograman Aplikasi Mobile ini memberikan pemahaman mendalam mengenai ekosistem Flutter, '
            'state management reaktif, arsitektur offline-first, dan desain antarmuka modern. '
            'Implementasi BandungHub dari Phase 1 hingga Phase 14 membuktikan bahwa aplikasi mobile dapat dibangun '
            'secara komprehensif dengan standar industri yang tinggi, ramah pengguna, dan kaya fitur tanpa ketergantungan API berbayar.';
        _suggestionsController.text =
            'Materi perkuliahan sudah sangat baik dan aplikatif. Saran untuk pengembangan ke depan adalah penambahan modul '
            'CI/CD otomatis dengan GitHub Actions untuk kompilasi APK/AAB dan eksplorasi Flutter Web/Desktop multiplatform.';
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'lecturer': _lecturerController.text.trim(),
      'studentName': _studentNameController.text.trim(),
      'studentNim': _studentNimController.text.trim(),
      'rating': _rating,
      'impressions': _impressionsController.text.trim(),
      'suggestions': _suggestionsController.text.trim(),
      'topics': _selectedTopics.toList(),
      'savedAt': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFeedbackKey, jsonEncode(data));

    if (!mounted) return;

    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Kesan & pesan kuliah berhasil disimpan! Terima kasih atas evaluasi Anda.',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copySummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== EVALUASI, KESAN & PESAN KULIAH PEMROGRAMAN APLIKASI MOBILE ===');
    buffer.writeln('Aplikasi: ${AppConstants.appName} v${AppConstants.appVersion}');
    buffer.writeln('Mahasiswa: ${_studentNameController.text} (${_studentNimController.text})');
    buffer.writeln('Dosen Pengampu: ${_lecturerController.text}');
    buffer.writeln('Rating Perkuliahan: ${_rating.toStringAsFixed(1)} / 5.0 ★');
    buffer.writeln('\nTopik Paling Berkesan:');
    for (final topic in _selectedTopics) {
      buffer.writeln('• $topic');
    }
    buffer.writeln('\nKesan Perkuliahan:');
    buffer.writeln(_impressionsController.text);
    buffer.writeln('\nPesan & Saran Pengembangan:');
    buffer.writeln(_suggestionsController.text);
    buffer.writeln('\nStatus Proyek: 14/14 Fase Selesai (100% Passing Tests)');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan evaluasi kuliah disalin ke clipboard!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Kesan & Pesan Kuliah'),
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('btn_copy_feedback_summary'),
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Salin Ringkasan',
            onPressed: _copySummary,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Hero Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evaluasi & Refleksi Akademik',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Projek Akhir Pemrograman Aplikasi Mobile (PAM)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating Pengalaman Kuliah
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating Pengalaman Perkuliahan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        key: Key('rating_star_$starValue'),
                        icon: Icon(
                          starValue <= _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  Center(
                    child: Text(
                      '${_rating.toStringAsFixed(1)} / 5.0 Bintang - Sangat Memuaskan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Identitas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Identitas Mahasiswa & Pengampu',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Mahasiswa',
                      prefixIcon: Icon(Icons.person_rounded, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentNimController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Induk Mahasiswa (NIM)',
                      prefixIcon: Icon(Icons.badge_rounded, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lecturerController,
                    decoration: const InputDecoration(
                      labelText: 'Dosen Pengampu / Laboratorium',
                      prefixIcon: Icon(Icons.cast_for_education_rounded, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Topik Paling Berkesan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Topik Perkuliahan Paling Berkesan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTopics.map((topic) {
                      final isSelected = _selectedTopics.contains(topic);
                      return FilterChip(
                        label: Text(topic),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextPrimary(context),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTopics.add(topic);
                            } else {
                              _selectedTopics.remove(topic);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kesan Perkuliahan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kesan Selama Mengikuti Perkuliahan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('input_impressions'),
                    controller: _impressionsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Tuliskan pengalaman, wawasan baru, dan hal berkesan selama mengerjakan projek...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Kesan tidak boleh kosong' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pesan & Saran Pengembangan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesan & Saran untuk Dosen / Laboratorium',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('input_suggestions'),
                    controller: _suggestionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Saran konstruktif untuk pengembangan silabus dan metode pembelajaran ke depan...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Pesan tidak boleh kosong' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              key: const Key('btn_save_feedback'),
              onPressed: _saveFeedback,
              icon: const Icon(Icons.save_rounded),
              label: Text(_isSaved ? 'Perbarui Evaluasi' : 'Kirim Evaluasi Kuliah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _copySummary,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Bagikan / Salin Ringkasan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.getTextPrimary(context),
                side: BorderSide(color: AppColors.getBorderColor(context)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
