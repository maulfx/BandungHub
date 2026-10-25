import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/sources/bandung_destinations.dart';
import '../../../data/repositories/itinerary_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../models/app_notification.dart';
import '../../../models/itinerary.dart';
import '../widgets/itinerary_export_sheet.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final String itineraryId;

  const ItineraryDetailScreen({super.key, required this.itineraryId});

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  final _repository = ItineraryRepository();
  int _selectedDay = 1;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  void _openAddDestinationSheet(Itinerary itinerary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = BandungDestinations.list.where((d) {
              return searchQuery.isEmpty ||
                  d.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  d.category.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Tambah Wisata ke Hari $_selectedDay',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) {
                      setSheetState(() => searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari destinasi...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final dest = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              dest.imageUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 54,
                                    height: 54,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: const Icon(
                                      Icons.place_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                            ),
                          ),
                          title: Text(
                            dest.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${dest.category} • ${dest.estimatedPrice <= 0 ? "Gratis" : currencyFormatter.format(dest.estimatedPrice)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add_circle_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () async {
                              await _repository.addDestinationToItinerary(
                                itineraryId: itinerary.id,
                                destination: dest,
                                dayNumber: _selectedDay,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${dest.name} ditambahkan ke Hari $_selectedDay!',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditCostsDialog(Itinerary itinerary) {
    final transportCtrl = TextEditingController(
      text: itinerary.transportationCost.toInt().toString(),
    );
    final foodCtrl = TextEditingController(
      text: itinerary.foodCost.toInt().toString(),
    );
    final additionalCtrl = TextEditingController(
      text: itinerary.additionalCost.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Estimasi Biaya'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: transportCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Biaya Transportasi (Rp)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: foodCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Biaya Makanan / Kuliner (Rp)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: additionalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Biaya Tambahan (Rp)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final transport =
                  double.tryParse(transportCtrl.text.trim()) ?? 0.0;
              final food = double.tryParse(foodCtrl.text.trim()) ?? 0.0;
              final additional =
                  double.tryParse(additionalCtrl.text.trim()) ?? 0.0;

              await _repository.updateCosts(
                itineraryId: itinerary.id,
                transportationCost: transport,
                foodCost: food,
                additionalCost: additional,
              );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan Biaya'),
          ),
        ],
      ),
    );
  }

  void _openScheduleItineraryReminderDialog(
    BuildContext context,
    Itinerary itinerary,
  ) {
    DateTime selectedDate = itinerary.startDate;
    if (selectedDate.isBefore(DateTime.now())) {
      selectedDate = DateTime.now().add(const Duration(days: 1));
    }
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    final noteController = TextEditingController(
      text:
          'Hari ini jadwal trip "${itinerary.title}" dimulai! Terdapat ${itinerary.items.length} destinasi yang akan dikunjungi.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final formattedDate =
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate);
            final formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} WIB';

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.alarm_add_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengingat Jadwal Trip',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                itinerary.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_pick_itinerary_reminder_date'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                            ),
                            label: Text(
                              DateFormat(
                                'd MMM yyyy',
                                'id_ID',
                              ).format(selectedDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_pick_itinerary_reminder_time'),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setSheetState(() => selectedTime = picked);
                              }
                            },
                            icon: const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                            ),
                            label: Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Pesan Pengingat',
                        hintText: 'Tulis pesan pengingat...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('btn_confirm_itinerary_reminder'),
                        onPressed: () async {
                          final scheduledDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          await NotificationRepository().scheduleReminder(
                            title: 'Pengingat Trip: ${itinerary.title}',
                            body: noteController.text.trim().isEmpty
                                ? 'Waktunya berangkat untuk trip ${itinerary.title}!'
                                : noteController.text.trim(),
                            scheduledTime: scheduledDateTime,
                            type: NotificationType.itineraryReminder,
                            payload: {
                              'itineraryId': itinerary.id,
                              'itineraryTitle': itinerary.title,
                            },
                          );

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Pengingat trip "${itinerary.title}" dijadwalkan pada $formattedDate ($formattedTime)!',
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.notification_add_rounded),
                        label: const Text('Pasang Pengingat Jadwal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final itinerary = _repository.getItineraryById(widget.itineraryId);

        if (itinerary == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Rencana Perjalanan')),
            body: const Center(child: Text('Rencana perjalanan tidak ditemukan')),
          );
        }

        final itemsByDay = itinerary.itemsByDay;
        final currentDayItems = itemsByDay[_selectedDay] ?? [];
        final endDate = itinerary.startDate.add(
          Duration(days: itinerary.durationDays - 1),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(itinerary.title),
            actions: [
              IconButton(
                key: const Key('btn_itinerary_export_action'),
                tooltip: 'Bagikan Rencana',
                icon: const Icon(Icons.share_rounded),
                onPressed: () => ItineraryExportSheet.show(
                  context,
                  itinerary,
                ),
              ),
              IconButton(
                key: const Key('btn_itinerary_reminder_action'),
                tooltip: 'Ingatkan Jadwal',
                icon: const Icon(Icons.alarm_add_rounded),
                onPressed: () => _openScheduleItineraryReminderDialog(
                  context,
                  itinerary,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'export') {
                    ItineraryExportSheet.show(context, itinerary);
                  } else if (val == 'reminder') {
                    _openScheduleItineraryReminderDialog(context, itinerary);
                  } else if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Rencana Perjalanan?'),
                        content: Text(
                          'Apakah Anda yakin ingin menghapus "${itinerary.title}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _repository.deleteItinerary(itinerary.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  } else if (val == 'hash') {
                    await _repository.saveHashVerification(itinerary.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Hash SHA-256 integritas berhasil disimpan!',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text('Bagikan Rencana Perjalanan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reminder',
                    child: Row(
                      children: [
                        Icon(
                          Icons.alarm_add_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 8),
                        Text('Atur Pengingat Jadwal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'hash',
                    child: Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text('Buat Hash Integritas'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hapus Rencana Perjalanan',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${itinerary.durationDays} Hari • ${itinerary.numberOfPeople} Orang',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Integrity Hash Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: itinerary.savedHash == null
                                  ? Colors.grey.shade100
                                  : itinerary.isHashValid
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 13,
                                  color: itinerary.savedHash == null
                                      ? Colors.grey
                                      : itinerary.isHashValid
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  itinerary.savedHash == null
                                      ? 'Hash: Belum Dibuat'
                                      : itinerary.isHashValid
                                      ? 'Integritas Valid'
                                      : 'Data Berubah!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: itinerary.savedHash == null
                                        ? Colors.grey
                                        : itinerary.isHashValid
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        itinerary.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${AppDateUtils.formatDate(itinerary.startDate)} s/d ${AppDateUtils.formatDate(endDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Budget Breakdown Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Estimasi Anggaran',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => _openEditCostsDialog(itinerary),
                              icon: const Icon(Icons.edit_rounded, size: 14),
                              label: const Text(
                                'Edit Biaya',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        const SizedBox(height: 6),
                        _buildBudgetRow(
                          'Tiket Masuk (${itinerary.items.length} Tempat × ${itinerary.numberOfPeople} Org)',
                          currencyFormatter.format(itinerary.totalTicketCost),
                        ),
                        _buildBudgetRow(
                          'Transportasi',
                          currencyFormatter.format(
                            itinerary.transportationCost,
                          ),
                        ),
                        _buildBudgetRow(
                          'Makanan / Konsumsi',
                          currencyFormatter.format(itinerary.foodCost),
                        ),
                        _buildBudgetRow(
                          'Biaya Tambahan',
                          currencyFormatter.format(itinerary.additionalCost),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL ESTIMASI BIAYA',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(
                                itinerary.totalEstimatedBudget,
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Export & Share Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('btn_open_export_sheet'),
                          onPressed: () => ItineraryExportSheet.show(
                            context,
                            itinerary,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Bagikan Rencana Perjalanan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Day Selector Pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jadwal Destinasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: ${itinerary.items.length} Destinasi',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: itinerary.durationDays,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = _selectedDay == day;
                      final count = (itemsByDay[day] ?? []).length;

                      return ChoiceChip(
                        label: Text('Hari $day ($count)'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedDay = day);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Destinations List for Selected Day
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: currentDayItems.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum Ada Destinasi di Hari $_selectedDay',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tambahkan tempat wisata Bandung ke hari ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _openAddDestinationSheet(itinerary),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text('Tambah ke Hari $_selectedDay'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentDayItems.length,
                              itemBuilder: (context, index) {
                                final item = currentDayItems[index];
                                final isFirst = index == 0;
                                final isLast =
                                    index == currentDayItems.length - 1;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Visit sequence badge
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${item.visitOrder}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Image thumbnail
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            item.imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  child: const Icon(
                                                    Icons.place_rounded,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Name & Price
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.destinationName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.destinationCategory} • ${item.ticketPrice <= 0 ? "Gratis" : currencyFormatter.format(item.ticketPrice)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Reorder Up/Down buttons
                                        Column(
                                          children: [
                                            InkWell(
                                              onTap: isFirst
                                                  ? null
                                                  : () => _repository
                                                        .reorderItineraryItem(
                                                          itineraryId:
                                                              itinerary.id,
                                                          itemId: item.id,
                                                          moveUp: true,
                                                        ),
                                              child: Icon(
                                                Icons.arrow_drop_up_rounded,
                                                color: isFirst
                                                    ? Colors.grey.shade300
                                                    : AppColors.primary,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: isLast
                                                  ? null
                                                  : () => _repository
                                                        .reorderItineraryItem(
                                                          itineraryId:
                                                              itinerary.id,
                                                          itemId: item.id,
                                                          moveUp: false,
                                                        ),
                                              child: Icon(
                                                Icons.arrow_drop_down_rounded,
                                                color: isLast
                                                    ? Colors.grey.shade300
                                                    : AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () => _repository
                                              .removeDestinationFromItinerary(
                                                itineraryId: itinerary.id,
                                                itemId: item.id,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _openAddDestinationSheet(itinerary),
                                icon: const Icon(
                                  Icons.add_location_alt_outlined,
                                ),
                                label: Text(
                                  'Tambah Wisata ke Hari $_selectedDay',
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
