import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/itinerary_repository.dart';

class CreateItineraryScreen extends StatefulWidget {
  const CreateItineraryScreen({super.key});

  @override
  State<CreateItineraryScreen> createState() => _CreateItineraryScreenState();
}

class _CreateItineraryScreenState extends State<CreateItineraryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(
    text: 'Eksplorasi Pesona Bandung',
  );
  final _transportController = TextEditingController(text: '150000');
  final _foodController = TextEditingController(text: '200000');
  final _additionalController = TextEditingController(text: '50000');

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  int _durationDays = 2;
  int _numberOfPeople = 2;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _transportController.dispose();
    _foodController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Mulai Perjalanan',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final transport = double.tryParse(_transportController.text.trim()) ?? 0.0;
    final food = double.tryParse(_foodController.text.trim()) ?? 0.0;
    final additional =
        double.tryParse(_additionalController.text.trim()) ?? 0.0;

    final created = await ItineraryRepository().createItinerary(
      title: _titleController.text.trim(),
      startDate: _startDate,
      durationDays: _durationDays,
      numberOfPeople: _numberOfPeople,
      transportationCost: transport,
      foodCost: food,
      additionalCost: additional,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Rencana Perjalanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              const Text(
                'Nama / Judul Rencana Perjalanan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Misal: Liburan Seru Akhir Pekan Bandung',
                  prefixIcon: Icon(
                    Icons.bookmark_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul rencana perjalanan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date Picker
              const Text(
                'Tanggal Keberangkatan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppDateUtils.formatFullDate(_startDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Duration & Number of People
              Row(
                children: [
                  // Duration Days
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Durasi (Hari)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _durationDays,
                              isExpanded: true,
                              items: [1, 2, 3, 4, 5, 7].map((days) {
                                return DropdownMenuItem(
                                  value: days,
                                  child: Text('$days Hari'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _durationDays = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Number of people
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jumlah Orang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _numberOfPeople,
                              isExpanded: true,
                              items: [1, 2, 3, 4, 5, 6, 8, 10].map((count) {
                                return DropdownMenuItem(
                                  value: count,
                                  child: Text('$count Orang'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _numberOfPeople = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 36),

              // Baseline Budget Estimates Header
              const Text(
                'Estimasi Biaya Operasional',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Biaya tiket akan dihitung otomatis saat Anda menambahkan destinasi.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),

              // Transportation Cost
              TextFormField(
                controller: _transportController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimasi Biaya Transportasi (Rp)',
                  prefixIcon: Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Food Cost
              TextFormField(
                controller: _foodController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimasi Biaya Makanan / Kuliner (Rp)',
                  prefixIcon: Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Additional Cost
              TextFormField(
                controller: _additionalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Biaya Lain-lain / Tambahan (Rp)',
                  prefixIcon: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Simpan & Buka Rencana',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
