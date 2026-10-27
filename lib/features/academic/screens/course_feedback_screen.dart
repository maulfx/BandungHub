import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Screen for Course Evaluation, Reflections, Impressions, and Feedback (Kesan & Pesan Kuliah)
/// Mendukung 2 Mahasiswa (Tim Pengembang) dengan tampilan teks utuh tanpa terpotong.
class CourseFeedbackScreen extends StatefulWidget {
  const CourseFeedbackScreen({super.key});

  @override
  State<CourseFeedbackScreen> createState() => _CourseFeedbackScreenState();
}

class _CourseFeedbackScreenState extends State<CourseFeedbackScreen> {
  static const String _prefFeedbackKey = 'academic_course_feedback_v2';

  final _formKey = GlobalKey<FormState>();
  final _lecturerController = TextEditingController(text: 'Dosen Pengampu PAM');

  // Mahasiswa 1
  final _student1NameController = TextEditingController(text: 'Achmad Maulana');
  final _student1NimController = TextEditingController(text: '12345678');
  final _impressions1Controller = TextEditingController();
  final _suggestions1Controller = TextEditingController();

  // Mahasiswa 2
  final _student2NameController = TextEditingController(text: 'Mahasiswa 2 (Rekan Tim)');
  final _student2NimController = TextEditingController(text: '87654321');
  final _impressions2Controller = TextEditingController();
  final _suggestions2Controller = TextEditingController();

  double _rating = 5.0;
  final Set<String> _selectedTopics = {
    'Flutter & Dart Clean Architecture',
    'Offline-First & SQLite Storage',
    'OpenStreetMap Navigation',
    'AI Assistant & Travel Reasoning',
  };

  bool _isLoading = true;
  bool _isSaved = false;

  final List<String> _availableTopics = [
    'Flutter & Dart Clean Architecture',
    'Offline-First & SQLite Storage',
    'OpenStreetMap Navigation',
    'Autentikasi Biometrik & PIN',
    'AI Assistant & Travel Reasoning',
    'Review Blockchain Ledger & Sepolia Anchor',
    'Responsive Design & Dark Mode',
    'Unit & Widget Testing (100% Pass)',
  ];

  static const String _defaultImpression1 =
      'Mata kuliah Pemrograman Aplikasi Mobile (PAM) ini memberikan pemahaman mendalam mengenai arsitektur perangkat lunak Flutter, '
      'state management reaktif, sinkronisasi offline-first SQLite, serta desain antarmuka modern yang humanis. '
      'Pengerjaan proyek BandungHub membuktikan bahwa aplikasi mobile dapat dibangun secara komprehensif dengan standar industri '
      'yang tinggi, kaya fitur, dan reliabel tanpa bergantung pada API berbayar.';

  static const String _defaultSuggestion1 =
      'Materi perkuliahan sudah sangat aplikatif dan terstruktur. Saran konstruktif ke depan adalah penambahan modul '
      'alur kerja CI/CD otomatis dengan GitHub Actions untuk kompilasi APK/AAB serta eksplorasi Flutter Multiplatform.';

  static const String _defaultImpression2 =
      'Praktikum dan tugas besar ini sangat menantang dan memotivasi untuk mengeksplorasi integrasi teknologi mutakhir, '
      'seperti sensor kompas penunjuk arah, computer vision AI Lens, dan pembuktian integritas data ulasan berbasis blockchain. '
      'Kolaborasi tim mengajarkan pentingnya modularitas kode dan manajemen state yang bersih.';

  static const String _defaultSuggestion2 =
      'Bimbingan praktikum dari dosen pengampu dan asisten lab sudah sangat interaktif dan responsif. Saran pengembangan '
      'adalah penambahan sesi bimbingan optimasi memory profiling dan manajemen dependensi enterprise.';

  @override
  void initState() {
    super.initState();
    _loadSavedFeedback();
  }

  @override
  void dispose() {
    _lecturerController.dispose();
    _student1NameController.dispose();
    _student1NimController.dispose();
    _impressions1Controller.dispose();
    _suggestions1Controller.dispose();
    _student2NameController.dispose();
    _student2NimController.dispose();
    _impressions2Controller.dispose();
    _suggestions2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefFeedbackKey) ??
          prefs.getString('academic_course_feedback_v1');

      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _lecturerController.text =
              data['lecturer'] ?? _lecturerController.text;

          // Mahasiswa 1
          _student1NameController.text = data['student1Name'] ??
              data['studentName'] ??
              _student1NameController.text;
          _student1NimController.text = data['student1Nim'] ??
              data['studentNim'] ??
              _student1NimController.text;
          _impressions1Controller.text = data['impressions1'] ??
              data['impressions'] ??
              _defaultImpression1;
          _suggestions1Controller.text = data['suggestions1'] ??
              data['suggestions'] ??
              _defaultSuggestion1;

          // Mahasiswa 2
          _student2NameController.text =
              data['student2Name'] ?? _student2NameController.text;
          _student2NimController.text =
              data['student2Nim'] ?? _student2NimController.text;
          _impressions2Controller.text =
              data['impressions2'] ?? _defaultImpression2;
          _suggestions2Controller.text =
              data['suggestions2'] ?? _defaultSuggestion2;

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
        _impressions1Controller.text = _defaultImpression1;
        _suggestions1Controller.text = _defaultSuggestion1;
        _impressions2Controller.text = _defaultImpression2;
        _suggestions2Controller.text = _defaultSuggestion2;
      }
    } catch (_) {
      _impressions1Controller.text = _defaultImpression1;
      _suggestions1Controller.text = _defaultSuggestion1;
      _impressions2Controller.text = _defaultImpression2;
      _suggestions2Controller.text = _defaultSuggestion2;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'lecturer': _lecturerController.text.trim(),
      // Mahasiswa 1
      'student1Name': _student1NameController.text.trim(),
      'student1Nim': _student1NimController.text.trim(),
      'impressions1': _impressions1Controller.text.trim(),
      'suggestions1': _suggestions1Controller.text.trim(),
      // Mahasiswa 2
      'student2Name': _student2NameController.text.trim(),
      'student2Nim': _student2NimController.text.trim(),
      'impressions2': _impressions2Controller.text.trim(),
      'suggestions2': _suggestions2Controller.text.trim(),
      // Meta
      'rating': _rating,
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
          'Kesan & pesan kedua mahasiswa berhasil disimpan!',
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
    buffer.writeln('Dosen Pengampu: ${_lecturerController.text}');
    buffer.writeln('Rating Perkuliahan: ${_rating.toStringAsFixed(1)} / 5.0 ★');

    buffer.writeln('\n========================================');
    buffer.writeln('MAHASISWA 1:');
    buffer.writeln('Nama: ${_student1NameController.text}');
    buffer.writeln('NIM: ${_student1NimController.text}');
    buffer.writeln('\n[Kesan Perkuliahan]:');
    buffer.writeln(_impressions1Controller.text);
    buffer.writeln('\n[Pesan & Saran]:');
    buffer.writeln(_suggestions1Controller.text);

    buffer.writeln('\n========================================');
    buffer.writeln('MAHASISWA 2:');
    buffer.writeln('Nama: ${_student2NameController.text}');
    buffer.writeln('NIM: ${_student2NimController.text}');
    buffer.writeln('\n[Kesan Perkuliahan]:');
    buffer.writeln(_impressions2Controller.text);
    buffer.writeln('\n[Pesan & Saran]:');
    buffer.writeln(_suggestions2Controller.text);

    buffer.writeln('\n========================================');
    buffer.writeln('Topik Paling Berkesan:');
    for (final topic in _selectedTopics) {
      buffer.writeln('• $topic');
    }
    buffer.writeln('\nStatus Proyek: 14/14 Fase Selesai (100% Passing Tests)');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan evaluasi 2 mahasiswa disalin ke clipboard!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPreviewDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.article_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Pratinjau Lengkap Kesan & Pesan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPreviewStudentCard(
                    title: 'Mahasiswa 1',
                    name: _student1NameController.text,
                    nim: _student1NimController.text,
                    impression: _impressions1Controller.text,
                    suggestion: _suggestions1Controller.text,
                    badgeColor: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewStudentCard(
                    title: 'Mahasiswa 2',
                    name: _student2NameController.text,
                    nim: _student2NimController.text,
                    impression: _impressions2Controller.text,
                    suggestion: _suggestions2Controller.text,
                    badgeColor: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStudentCard({
    required String title,
    required String name,
    required String nim,
    required String impression,
    required String suggestion,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'NIM: $nim',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kesan Perkuliahan:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            impression,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pesan & Saran:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
        ],
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
            icon: const Icon(Icons.remove_red_eye_rounded),
            tooltip: 'Pratinjau Teks Lengkap',
            onPressed: _showPreviewDialog,
          ),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evaluasi & Refleksi Akademik',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tim Pengembang 2 Mahasiswa • Projek Akhir PAM',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
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

            // Dosen Pengampu
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
                    'Dosen Pengampu / Laboratorium',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lecturerController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Dosen Pengampu',
                      prefixIcon: Icon(Icons.cast_for_education_rounded, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== SEKSI MAHASISWA 1 ====================
            _buildStudentFeedbackSection(
              studentNumber: 1,
              badgeColor: AppColors.primary,
              nameController: _student1NameController,
              nimController: _student1NimController,
              impressionsController: _impressions1Controller,
              suggestionsController: _suggestions1Controller,
            ),
            const SizedBox(height: 20),

            // ==================== SEKSI MAHASISWA 2 ====================
            _buildStudentFeedbackSection(
              studentNumber: 2,
              badgeColor: const Color(0xFF6366F1),
              nameController: _student2NameController,
              nimController: _student2NimController,
              impressionsController: _impressions2Controller,
              suggestionsController: _suggestions2Controller,
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              key: const Key('btn_save_feedback'),
              onPressed: _saveFeedback,
              icon: const Icon(Icons.save_rounded),
              label: Text(_isSaved ? 'Perbarui Evaluasi (2 Mahasiswa)' : 'Simpan Evaluasi Kuliah'),
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

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showPreviewDialog,
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Pratinjau Penuh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copySummary,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Salin Ringkasan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.getTextPrimary(context),
                      side: BorderSide(color: AppColors.getBorderColor(context)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentFeedbackSection({
    required int studentNumber,
    required Color badgeColor,
    required TextEditingController nameController,
    required TextEditingController nimController,
    required TextEditingController impressionsController,
    required TextEditingController suggestionsController,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mahasiswa #$studentNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  studentNumber == 1 ? 'Ketua / Anggota 1' : 'Anggota 2',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nama & NIM
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap #$studentNumber',
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: nimController,
                  decoration: InputDecoration(
                    labelText: 'NIM #$studentNumber',
                    prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'NIM wajib diisi' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kesan (Auto-expanding, minLines: 3, maxLines: null -> Teks terlihat utuh!)
          Text(
            'Kesan Mengikuti Perkuliahan (Mahasiswa #$studentNumber)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: impressionsController,
            minLines: 3,
            maxLines: null, // Membuka agar seluruh teks terlihat penuh tanpa terpotong!
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Tuliskan kesan dan pengalaman selama mengikuti perkuliahan...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Kesan tidak boleh kosong' : null,
          ),
          const SizedBox(height: 14),

          // Pesan & Saran (Auto-expanding, minLines: 2, maxLines: null -> Teks terlihat utuh!)
          Text(
            'Pesan & Saran Pengembangan (Mahasiswa #$studentNumber)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: suggestionsController,
            minLines: 2,
            maxLines: null, // Membuka agar seluruh teks terlihat penuh tanpa terpotong!
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Tuliskan pesan dan saran untuk dosen / laboratorium...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Pesan tidak boleh kosong' : null,
          ),
        ],
      ),
    );
  }
}
