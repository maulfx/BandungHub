import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/sources/bandung_destinations.dart';
import '../../../data/repositories/itinerary_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../models/app_notification.dart';
import '../../../models/destination.dart';
import '../../../models/itinerary.dart';
import '../widgets/itinerary_export_sheet.dart';
import '../../../services/travel_converter_service.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final String itineraryId;

  const ItineraryDetailScreen({super.key, required this.itineraryId});

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  final _repository = ItineraryRepository();
  int _selectedDay = 1;

  // Currency & Timezone state for international/domestic tourists
  String _selectedCurrencyCode = 'IDR';
  TimezoneInfo _selectedTimezone =
      TravelConverterService.supportedTimezones.first; // Default Bandung (WIB)

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    TravelConverterService.loadCachedRates().then((_) {
      if (mounted) setState(() {});
    });
  }

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
                            '${dest.category} • ${_formatItemPrice(dest.estimatedPrice)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            _openScheduleVisitDialog(
                              itinerary: itinerary,
                              destination: dest,
                              dayNumber: _selectedDay,
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add_circle_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              _openScheduleVisitDialog(
                                itinerary: itinerary,
                                destination: dest,
                                dayNumber: _selectedDay,
                              );
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                            Expanded(
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Estimasi Anggaran',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Interactive Currency Dropdown Selector
                                Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCurrencyCode,
                                      isDense: true,
                                      icon: const Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      items: TravelConverterService
                                          .supportedCurrencies
                                          .map(
                                            (c) => DropdownMenuItem<String>(
                                              value: c.code,
                                              child: Text(
                                                '${c.flag} ${c.code}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => _selectedCurrencyCode = val,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () =>
                                      _openEditCostsDialog(itinerary),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.edit_rounded, size: 13),
                                  label: const Text(
                                    'Edit Biaya',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        const SizedBox(height: 6),
                        _buildBudgetRow(
                          'Tiket Masuk (${itinerary.items.length} Tempat × ${itinerary.numberOfPeople} Org)',
                          itinerary.totalTicketCost,
                        ),
                        _buildBudgetRow(
                          'Transportasi',
                          itinerary.transportationCost,
                        ),
                        _buildBudgetRow(
                          'Makanan / Konsumsi',
                          itinerary.foodCost,
                        ),
                        _buildBudgetRow(
                          'Biaya Tambahan',
                          itinerary.additionalCost,
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL ESTIMASI BIAYA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (itinerary.numberOfPeople > 1) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedCurrencyCode == 'IDR'
                                          ? 'Per orang: ${currencyFormatter.format(itinerary.costPerPerson)}'
                                          : 'Per orang: ${currencyFormatter.format(itinerary.costPerPerson)} (≈ ${TravelConverterService.formatCurrency(TravelConverterService.convertCurrency(amount: itinerary.costPerPerson, fromCode: "IDR", toCode: _selectedCurrencyCode), _selectedCurrencyCode)})',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(
                                    itinerary.totalEstimatedBudget,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (_selectedCurrencyCode != 'IDR') ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '≈ ${TravelConverterService.formatCurrency(TravelConverterService.convertCurrency(amount: itinerary.totalEstimatedBudget, fromCode: "IDR", toCode: _selectedCurrencyCode), _selectedCurrencyCode)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ],
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

                // Schedule Header with Timezone Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                fontSize: 11,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Interactive Timezone Dropdown Selector
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TimezoneInfo>(
                            value: _selectedTimezone,
                            isDense: true,
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            items: TravelConverterService.supportedTimezones
                                .map(
                                  (tz) => DropdownMenuItem<TimezoneInfo>(
                                    value: tz,
                                    child: Text(
                                      '${tz.flag} ${tz.code} (${tz.utcOffset})',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTimezone = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedTimezone.code != 'WIB') ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Zona Wisatawan: ${_selectedTimezone.flag} ${_selectedTimezone.name} (${_selectedTimezone.diffStringFromBandung} dibanding WIB)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        itinerary.durationDays +
                        (itinerary.durationDays < 7 ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == itinerary.durationDays &&
                          itinerary.durationDays < 7) {
                        return ActionChip(
                          avatar: const Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: const Text('Tambah Hari (Maks. 7)'),
                          onPressed: () async {
                            if (itinerary.durationDays < 7) {
                              final newDays = itinerary.durationDays + 1;
                              await _repository.updateItinerary(
                                itinerary.copyWith(durationDays: newDays),
                              );
                              setState(() => _selectedDay = newDays);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Hari $newDays berhasil ditambahkan ke rencana!',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      }
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
                                        // Name, Price & Scheduled Time
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
                                                '${item.destinationCategory} • ${_formatItemPrice(item.ticketPrice)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondaryLight,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 13,
                                                    color: _selectedTimezone.code != 'WIB'
                                                        ? AppColors.secondary
                                                        : AppColors.textSecondaryLight,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      _getItemEstimatedTime(
                                                        item,
                                                        item.visitOrder,
                                                        _selectedTimezone,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: _selectedTimezone.code != 'WIB'
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                        color: _selectedTimezone.code != 'WIB'
                                                            ? AppColors.secondary
                                                            : AppColors.textSecondaryLight,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Edit Time button
                                        IconButton(
                                          tooltip: 'Ubah Waktu Kunjungan',
                                          icon: const Icon(
                                            Icons.edit_calendar_rounded,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () {
                                            final dest = BandungDestinations.list.firstWhere(
                                              (d) =>
                                                  d.id == item.destinationId ||
                                                  d.name == item.destinationName,
                                              orElse: () => Destination(
                                                id: item.destinationId,
                                                name: item.destinationName,
                                                description: '',
                                                category: item.destinationCategory,
                                                address: '',
                                                latitude: -6.9175,
                                                longitude: 107.6191,
                                                estimatedPrice: item.ticketPrice,
                                                operationalHours: 'Setiap Hari 08.00 - 18.00 WIB',
                                                imageUrl: item.imageUrl,
                                                rating: 4.5,
                                              ),
                                            );
                                            _openScheduleVisitDialog(
                                              itinerary: itinerary,
                                              destination: dest,
                                              dayNumber: _selectedDay,
                                              existingItem: item,
                                            );
                                          },
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

  String _formatItemPrice(double price) {
    if (price <= 0) return 'Gratis';
    final idr = currencyFormatter.format(price);
    if (_selectedCurrencyCode == 'IDR') return idr;
    final converted = TravelConverterService.convertCurrency(
      amount: price,
      fromCode: 'IDR',
      toCode: _selectedCurrencyCode,
    );
    return '$idr (≈ ${TravelConverterService.formatCurrency(converted, _selectedCurrencyCode)})';
  }

  String _getItemEstimatedTime(ItineraryItem item, int order, TimezoneInfo tz) {
    if (item.startTime != null && item.endTime != null) {
      final startParts = item.startTime!.split(':');
      final startH = int.tryParse(startParts[0]) ?? 9;
      final startM =
          startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;
      final durationStr =
          item.durationMinutes != null ? ' (${item.durationMinutes} mnt)' : '';
      final bandungTime = '${item.startTime} - ${item.endTime} WIB$durationStr';
      if (tz.code == 'WIB') {
        return 'Jadwal: $bandungTime';
      }
      final targetH = (startH + tz.diffHoursFromBandung) % 24;
      final targetTime =
          '${targetH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} ${tz.code}';
      return '$bandungTime (Zona Anda: $targetTime)';
    }

    // Fallback yang aman dan dibatasi agar TIDAK PERNAH melebihi 24.00 WIB (tidak ada jam 25.00!)
    final baseHours = [9, 11, 14, 16, 19, 21];
    final slotHour = (order - 1) < baseHours.length
        ? baseHours[order - 1]
        : (8 + (order * 2)).clamp(8, 22);
    final bandungTime = '${slotHour.toString().padLeft(2, '0')}:00 WIB';
    if (tz.code == 'WIB') {
      return 'Estimasi: $bandungTime';
    }
    final targetHour = (slotHour + tz.diffHoursFromBandung) % 24;
    final targetTime = '${targetHour.toString().padLeft(2, '0')}:00 ${tz.code}';
    return '$bandungTime (Waktu Anda: $targetTime)';
  }

  OperationalHoursInfo _parseOperationalHours(String raw) {
    if (raw.toLowerCase().contains('24 jam')) {
      return OperationalHoursInfo(
        openHour: 0,
        openMinute: 0,
        closeHour: 23,
        closeMinute: 59,
        is24Hours: true,
        rawText: raw,
      );
    }

    final regex = RegExp(
      r'(\d{1,2})[.:](\d{2})\s*[-–—s.d.to]+\s*(\d{1,2})[.:](\d{2})',
    );
    final match = regex.firstMatch(raw);
    if (match != null) {
      final h1 = int.parse(match.group(1)!);
      final m1 = int.parse(match.group(2)!);
      final h2 = int.parse(match.group(3)!);
      final m2 = int.parse(match.group(4)!);
      return OperationalHoursInfo(
        openHour: h1,
        openMinute: m1,
        closeHour: h2,
        closeMinute: m2,
        is24Hours: false,
        rawText: raw,
      );
    }

    return OperationalHoursInfo(
      openHour: 8,
      openMinute: 0,
      closeHour: 18,
      closeMinute: 0,
      is24Hours: false,
      rawText: raw,
    );
  }

  void _openScheduleVisitDialog({
    required Itinerary itinerary,
    required Destination destination,
    required int dayNumber,
    ItineraryItem? existingItem,
  }) {
    final opInfo = _parseOperationalHours(destination.operationalHours);

    int parseTimeToMinutes(String timeStr) {
      final parts = timeStr.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return h * 60 + m;
    }

    final sameDayScheduledItems = itinerary.items.where((item) {
      return item.dayNumber == dayNumber &&
          item.id != existingItem?.id &&
          item.startTime != null &&
          item.endTime != null &&
          item.startTime!.contains(':') &&
          item.endTime!.contains(':');
    }).toList()
      ..sort((a, b) =>
          parseTimeToMinutes(a.startTime!).compareTo(parseTimeToMinutes(b.startTime!)));

    TimeOfDay selectedStartTime;
    if (existingItem?.startTime != null) {
      final parts = existingItem!.startTime!.split(':');
      selectedStartTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? opInfo.openHour,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );
    } else {
      if (sameDayScheduledItems.isNotEmpty) {
        final lastEndMinutes =
            parseTimeToMinutes(sameDayScheduledItems.last.endTime!);
        final fitsInOpHours = opInfo.is24Hours ||
            (lastEndMinutes >= opInfo.openTotalMinutes &&
                lastEndMinutes + 60 <= opInfo.closeTotalMinutes);
        if (fitsInOpHours && lastEndMinutes + 60 <= 24 * 60) {
          selectedStartTime = TimeOfDay(
            hour: (lastEndMinutes ~/ 60) % 24,
            minute: lastEndMinutes % 60,
          );
        } else {
          final defaultHour = opInfo.is24Hours ? 9 : opInfo.openHour;
          final defaultMin = opInfo.is24Hours ? 0 : opInfo.openMinute;
          selectedStartTime = TimeOfDay(hour: defaultHour, minute: defaultMin);
        }
      } else {
        final defaultHour = opInfo.is24Hours ? 9 : opInfo.openHour;
        final defaultMin = opInfo.is24Hours ? 0 : opInfo.openMinute;
        selectedStartTime = TimeOfDay(hour: defaultHour, minute: defaultMin);
      }
    }

    int selectedDurationMinutes = existingItem?.durationMinutes ?? 90;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final startTotal =
                selectedStartTime.hour * 60 + selectedStartTime.minute;
            final endTotal = startTotal + selectedDurationMinutes;
            final endHour = (endTotal ~/ 60) % 24;
            final endMinute = endTotal % 60;

            final startFormatted =
                '${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}';
            final endFormatted =
                '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

            final bool isPastMidnight = endTotal >= 24 * 60;
            final bool isWithinHours = opInfo.is24Hours ||
                (startTotal >= opInfo.openTotalMinutes &&
                    endTotal <= opInfo.closeTotalMinutes);

            // Collision detection with other destinations on the same day
            ItineraryItem? collidingItem;
            for (final item in sameDayScheduledItems) {
              final itemStart = parseTimeToMinutes(item.startTime!);
              final itemEnd = parseTimeToMinutes(item.endTime!);
              if (startTotal < itemEnd && endTotal > itemStart) {
                collidingItem = item;
                break;
              }
            }
            final bool hasCollision = collidingItem != null;
            final bool isValid = !isPastMidnight && isWithinHours && !hasCollision;

            final String warningMessage;
            if (isPastMidnight) {
              warningMessage =
                  'Jadwal kunjungan melebihi batas hari (24.00 WIB). Silakan kurangi jam mulai atau durasi.';
            } else if (!isWithinHours) {
              final openStr =
                  '${opInfo.openHour.toString().padLeft(2, '0')}:${opInfo.openMinute.toString().padLeft(2, '0')}';
              final closeStr =
                  '${opInfo.closeHour.toString().padLeft(2, '0')}:${opInfo.closeMinute.toString().padLeft(2, '0')}';
              warningMessage =
                  'Waktu kunjungan ($startFormatted - $endFormatted WIB) berada di luar jam operasional ($openStr - $closeStr WIB). Silakan sesuaikan jam atau durasi.';
            } else if (collidingItem != null) {
              warningMessage =
                  'Bentrok dengan jadwal "${collidingItem.destinationName}" (${collidingItem.startTime} - ${collidingItem.endTime} WIB). Silakan pilih jam atau durasi lain.';
            } else {
              warningMessage = '';
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      existingItem != null
                          ? 'Ubah Waktu Kunjungan'
                          : 'Pilih Waktu & Durasi Kunjungan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${destination.name} • Hari $dayNumber',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Operational Hours Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 18,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jam Operasional Destinasi:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destination.operationalHours,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Existing items on this day
                    if (sameDayScheduledItems.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_note_rounded,
                                  size: 16,
                                  color: Color(0xFF15803D),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Jadwal Wisata Lain di Hari $dayNumber:',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...sameDayScheduledItems.map((item) {
                              final itemStart =
                                  parseTimeToMinutes(item.startTime!);
                              final itemEnd =
                                  parseTimeToMinutes(item.endTime!);
                              final isColliding = startTotal < itemEnd &&
                                  endTotal > itemStart;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isColliding
                                      ? Colors.red.shade50
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isColliding
                                        ? Colors.red.shade300
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isColliding
                                          ? Icons.error_rounded
                                          : Icons.schedule_rounded,
                                      size: 14,
                                      color: isColliding
                                          ? Colors.red.shade700
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${item.destinationName} (${item.startTime} - ${item.endTime} WIB)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isColliding
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isColliding
                                              ? Colors.red.shade900
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    if (isColliding)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Bentrok',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 1. Pilih Jam Mulai
                    const Text(
                      '1. Jam Mulai Kunjungan (WIB)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedStartTime,
                          helpText: 'PILIH JAM MULAI KUNJUNGAN',
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedStartTime = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alarm_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$startFormatted WIB',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Ganti Jam',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Pilih Durasi Kunjungan
                    const Text(
                      '2. Durasi Kunjungan (Bebas Dipilih)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'label': '30 Menit', 'mins': 30},
                        {'label': '1 Jam', 'mins': 60},
                        {'label': '1.5 Jam', 'mins': 90},
                        {'label': '2 Jam', 'mins': 120},
                        {'label': '2.5 Jam', 'mins': 150},
                        {'label': '3 Jam', 'mins': 180},
                        {'label': '4 Jam', 'mins': 240},
                      ].map((dur) {
                        final mins = dur['mins'] as int;
                        final isSelected = selectedDurationMinutes == mins;
                        return ChoiceChip(
                          label: Text(dur['label'] as String),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                selectedDurationMinutes = mins;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Status & Validasi Jam Operasional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isValid
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isValid
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isValid
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_rounded,
                                size: 18,
                                color: isValid
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isValid
                                      ? 'Jadwal Kunjungan: $startFormatted - $endFormatted WIB'
                                      : (hasCollision
                                          ? 'Jadwal Bentrok dengan Wisata Lain'
                                          : 'Waktu Tidak Valid'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isValid
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isValid) ...[
                            const SizedBox(height: 4),
                            Text(
                              warningMessage,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade900,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          existingItem != null
                              ? Icons.save_rounded
                              : Icons.add_rounded,
                        ),
                        label: Text(
                          existingItem != null
                              ? 'Simpan Perubahan Waktu'
                              : 'Tambahkan ke Hari $dayNumber',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isValid
                              ? AppColors.primary
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: !isValid
                            ? null
                            : () async {
                                if (existingItem != null) {
                                  await _repository
                                      .updateDestinationTimeInItinerary(
                                        itineraryId: itinerary.id,
                                        itemId: existingItem.id,
                                        startTime: startFormatted,
                                        endTime: endFormatted,
                                        durationMinutes:
                                            selectedDurationMinutes,
                                      );
                                } else {
                                  await _repository.addDestinationToItinerary(
                                    itineraryId: itinerary.id,
                                    destination: destination,
                                    dayNumber: dayNumber,
                                    startTime: startFormatted,
                                    endTime: endFormatted,
                                    durationMinutes:
                                        selectedDurationMinutes,
                                  );
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetContext);
                                  if (existingItem == null) {
                                    Navigator.pop(context);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        existingItem != null
                                            ? 'Jadwal ${destination.name} berhasil diperbarui ($startFormatted - $endFormatted WIB)!'
                                            : '${destination.name} berhasil dijadwalkan pada $startFormatted - $endFormatted WIB!',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              },
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

  Widget _buildBudgetRow(String label, double amountInIdr) {
    final idrText = currencyFormatter.format(amountInIdr);
    final String rightText;
    if (_selectedCurrencyCode == 'IDR') {
      rightText = idrText;
    } else {
      final converted = TravelConverterService.convertCurrency(
        amount: amountInIdr,
        fromCode: 'IDR',
        toCode: _selectedCurrencyCode,
      );
      final convText = TravelConverterService.formatCurrency(
        converted,
        _selectedCurrencyCode,
      );
      rightText = '$idrText (≈ $convText)';
    }

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
          Flexible(
            child: Text(
              rightText,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class OperationalHoursInfo {
  final int openHour;
  final int openMinute;
  final int closeHour;
  final int closeMinute;
  final bool is24Hours;
  final String rawText;

  const OperationalHoursInfo({
    required this.openHour,
    required this.openMinute,
    required this.closeHour,
    required this.closeMinute,
    required this.is24Hours,
    required this.rawText,
  });

  int get openTotalMinutes => openHour * 60 + openMinute;
  int get closeTotalMinutes => closeHour * 60 + closeMinute;
}
