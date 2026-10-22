import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/travel_preference.dart';
import '../../../services/recommendation_engine.dart';
import 'recommendation_results_screen.dart';

class PreferenceFormScreen extends StatefulWidget {
  final TravelPreference? initialPreference;

  const PreferenceFormScreen({super.key, this.initialPreference});

  @override
  State<PreferenceFormScreen> createState() => _PreferenceFormScreenState();
}

class _PreferenceFormScreenState extends State<PreferenceFormScreen> {
  late List<String> _selectedCategories;
  late double _maxBudgetPerPerson;
  late int _durationDays;
  late int _numberOfPeople;
  late List<String> _selectedInterests;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final pref = widget.initialPreference ?? const TravelPreference();
    _selectedCategories = List.from(pref.preferredCategories);
    _maxBudgetPerPerson = pref.maxBudgetPerPerson;
    _durationDays = pref.durationDays;
    _numberOfPeople = pref.numberOfPeople;
    _selectedInterests = List.from(pref.interests);
  }

  void _submitForm() {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu kategori wisata!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final preference = TravelPreference(
      preferredCategories: _selectedCategories,
      maxBudgetPerPerson: _maxBudgetPerPerson,
      durationDays: _durationDays,
      numberOfPeople: _numberOfPeople,
      interests: _selectedInterests,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecommendationResultsScreen(preference: preference),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = AppConstants.categories
        .where((c) => c != 'Semua')
        .toList();
    final availableInterests = RecommendationEngine.availableInterests;

    return Scaffold(
      appBar: AppBar(title: const Text('Preferensi Rekomendasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kustomisasi Preferensi Wisata',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sesuaikan preferensi Anda untuk memperoleh skor kecocokan destinasi terbaik.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Kategori Wisata
            const Text(
              '1. Kategori Wisata Favorit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih satu atau lebih kategori yang ingin Anda kunjungi:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                final catColor = AppColors.getCategoryColor(category);
                final catIcon = AppColors.getCategoryIcon(category);

                return FilterChip(
                  label: Text(category),
                  avatar: Icon(
                    catIcon,
                    size: 16,
                    color: isSelected ? Colors.white : catColor,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                  selectedColor: catColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimaryLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const Divider(height: 36),

            // 2. Anggaran Maksimal per Orang
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '2. Anggaran Tiket per Orang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _maxBudgetPerPerson <= 0
                      ? 'Gratis'
                      : currencyFormatter.format(_maxBudgetPerPerson),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Batas maksimal biaya tiket masuk per destinasi:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _maxBudgetPerPerson,
              min: 0,
              max: 200000,
              divisions: 20,
              activeColor: AppColors.primary,
              label: currencyFormatter.format(_maxBudgetPerPerson),
              onChanged: (val) {
                setState(() {
                  _maxBudgetPerPerson = val;
                });
              },
            ),
            Wrap(
              spacing: 8,
              children: [0.0, 35000.0, 50000.0, 100000.0, 200000.0].map((amt) {
                final isSelected = _maxBudgetPerPerson == amt;
                return ChoiceChip(
                  label: Text(
                    amt == 0 ? 'Gratis' : currencyFormatter.format(amt),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _maxBudgetPerPerson = amt;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const Divider(height: 36),

            // 3. Durasi Perjalanan
            const Text(
              '3. Rencana Durasi Perjalanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [1, 2, 3, 4].map((days) {
                final isSelected = _durationDays == days;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : Colors.white,
                        foregroundColor: isSelected
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _durationDays = days;
                        });
                      },
                      child: Text(
                        days >= 4 ? '4+ Hari' : '$days Hari',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 36),

            // 4. Jumlah Orang / Peserta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4. Jumlah Peserta / Orang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Digunakan untuk menghitung estimasi biaya rombongan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _numberOfPeople > 1
                            ? () {
                                setState(() {
                                  _numberOfPeople--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '$_numberOfPeople Orang',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          setState(() {
                            _numberOfPeople++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 36),

            // 5. Minat Khusus Pengguna
            const Text(
              '5. Minat Spesifik Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih aktivitas atau suasana yang paling Anda harapkan:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: AppColors.secondary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.secondaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.recommend_rounded),
                label: const Text('Hitung Rekomendasi Destinasi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
