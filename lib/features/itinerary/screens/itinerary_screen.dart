import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/itinerary_repository.dart';
import '../../../shared/widgets/empty_view.dart';
import 'create_itinerary_screen.dart';
import 'itinerary_detail_screen.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final _repository = ItineraryRepository();

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _repository.init();
  }

  void _openCreateScreen() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateItineraryScreen()),
    );

    if (created != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryDetailScreen(itineraryId: created.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final itineraries = _repository.itineraries;

        return Scaffold(
          appBar: AppBar(title: const Text('Rencana Perjalanan (Itinerary)')),
          body: itineraries.isEmpty
              ? EmptyView(
                  icon: Icons.calendar_today_rounded,
                  title: 'Belum Ada Rencana Perjalanan',
                  message: 'Susun jadwal liburan ke Bandung, kelompokkan destinasi per hari, dan hitung estimasi biaya secara otomatis.',
                  buttonText: 'Buat Itinerary Pertama',
                  onButtonPressed: _openCreateScreen,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itineraries.length,
                  itemBuilder: (context, index) {
                    final item = itineraries[index];
                    final endDate = item.startDate.add(
                      Duration(days: item.durationDays - 1),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItineraryDetailScreen(itineraryId: item.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.durationDays} Hari',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.numberOfPeople} Orang',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 13,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${AppDateUtils.formatDate(item.startDate)} - ${AppDateUtils.formatDate(endDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.items.length} Destinasi',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Estimasi Total',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      Text(
                                        currencyFormatter.format(
                                          item.totalEstimatedBudget,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateScreen,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Itinerary'),
          ),
        );
      },
    );
  }
}
