import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/dummy/dummy_destinations.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../models/app_notification.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../destinations/screens/destination_detail_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _repository = NotificationRepository();
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _repository.init();
  }

  void _openCreateReminderSheet() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    String? selectedDestinationId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final timeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jadwalkan Pengingat Wisata',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(bottomSheetContext),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Choose destination (optional)
                      Text(
                        'Tautkan Destinasi (Opsional):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedDestinationId,
                        decoration: InputDecoration(
                          hintText: 'Pilih destinasi Bandung...',
                          prefixIcon: const Icon(Icons.place_rounded),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: DummyDestinations.list.map((dest) {
                          return DropdownMenuItem(
                            value: dest.id,
                            child: Text(
                              dest.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedDestinationId = val;
                            if (val != null) {
                              final dest = DummyDestinations.list.firstWhere(
                                (d) => d.id == val,
                              );
                              titleController.text =
                                  'Jadwal Kunjungan: ${dest.name} 📍';
                              bodyController.text =
                                  'Saatnya bersiap! Jadwal wisata Anda ke ${dest.name} segera tiba.';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'Judul Pengingat:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: 'Misal: Kunjungan Kawah Putih',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Body
                      Text(
                        'Pesan Pengingat:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: bodyController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'Misal: Jangan lupa bawa jaket tebal dan kamera!',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date Time Picker
                      Text(
                        'Waktu Pengingat:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (time != null) {
                              setSheetState(() {
                                selectedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.getBorderColor(context),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.getCardColor(context),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                timeFormat.format(selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Ubah',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const Key('btn_confirm_schedule_reminder'),
                          onPressed: () {
                            final title = titleController.text.trim();
                            final body = bodyController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mohon isi judul pengingat perjalanan Anda.',
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }

                            _repository.scheduleReminder(
                              title: title,
                              body: body.isEmpty
                                  ? 'Pengingat perjalanan liburan BandungHub.'
                                  : body,
                              scheduledTime: selectedDate,
                              type: NotificationType.itineraryReminder,
                              payload: selectedDestinationId != null
                                  ? {'destinationId': selectedDestinationId}
                                  : null,
                            );

                            Navigator.pop(bottomSheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pengingat perjalanan berhasil dijadwalkan!',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          icon: const Icon(Icons.alarm_add_rounded),
                          label: const Text('Simpan Pengingat'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleNotificationTap(AppNotification notif) {
    _repository.markAsRead(notif.id);

    if (notif.payload != null && notif.payload!['destinationId'] != null) {
      final destId = notif.payload!['destinationId'] as String;
      final match = DummyDestinations.list.where((d) => d.id == destId);
      if (match.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DestinationDetailScreen(destination: match.first),
          ),
        );
      }
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return Icons.waving_hand_rounded;
      case NotificationType.itineraryReminder:
        return Icons.map_rounded;
      case NotificationType.destinationReminder:
        return Icons.place_rounded;
      case NotificationType.quizReminder:
        return Icons.sports_esports_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return AppColors.success;
      case NotificationType.itineraryReminder:
        return AppColors.primary;
      case NotificationType.destinationReminder:
        return AppColors.secondary;
      case NotificationType.quizReminder:
        return Colors.purple;
      case NotificationType.general:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final allNotifs = _repository.notifications;
        final activeReminders = _repository.activeReminders;
        final historyNotifs = _repository.historyNotifications;

        List<AppNotification> displayedNotifs;
        if (_selectedFilter == 'Pengingat Aktif') {
          displayedNotifs = activeReminders;
        } else if (_selectedFilter == 'Riwayat') {
          displayedNotifs = historyNotifs;
        } else {
          displayedNotifs = allNotifs;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifikasi & Pengingat'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Menu Opsi',
                onSelected: (val) {
                  if (val == 'read_all') {
                    _repository.markAllAsRead();
                  } else if (val == 'clear_all') {
                    _repository.clearAll();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text('Tandai Semua Dibaca'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text('Hapus Semua Notifikasi'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Demo Notification Testing Banner (Sangat praktis untuk demonstrasi dosen)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Simulasi & Pengujian Demo (Dosen)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _openCreateReminderSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_alarm_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '+ Jadwal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _repository.triggerWelcomeNotification(),
                            icon: const Icon(Icons.waving_hand_rounded, size: 14),
                            label: const Text('Sambutan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _repository.triggerItineraryDemoReminder(),
                            icon: const Icon(Icons.route_rounded, size: 14),
                            label: const Text('Pengingat Itinerary'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _repository.triggerQuizReminder(),
                            icon: const Icon(
                              Icons.sports_esports_rounded,
                              size: 14,
                            ),
                            label: const Text('Jumpy Game'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Semua (${allNotifs.length})'),
                      selected: _selectedFilter == 'Semua',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = 'Semua');
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'Semua'
                            ? Colors.white
                            : AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Aktif (${activeReminders.length})'),
                      selected: _selectedFilter == 'Pengingat Aktif',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = 'Pengingat Aktif');
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'Pengingat Aktif'
                            ? Colors.white
                            : AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Riwayat (${historyNotifs.length})'),
                      selected: _selectedFilter == 'Riwayat',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = 'Riwayat');
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'Riwayat'
                            ? Colors.white
                            : AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Notifications List
              Expanded(
                child: displayedNotifs.isEmpty
                    ? EmptyView(
                        title: 'Tidak Ada Notifikasi',
                        message:
                            'Belum ada pengingat pada kategori ini. Gunakan tombol demo di atas untuk menguji pengingat perjalanan.',
                        buttonText: '+ Jadwalkan Pengingat',
                        onButtonPressed: _openCreateReminderSheet,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        itemCount: displayedNotifs.length,
                        itemBuilder: (context, index) {
                          final notif = displayedNotifs[index];
                          final isUpcoming =
                              notif.scheduledTime.isAfter(DateTime.now()) &&
                              !notif.isDelivered;
                          final color = _getTypeColor(notif.type);
                          final icon = _getTypeIcon(notif.type);
                          final timeStr = DateFormat(
                            'dd MMM, HH:mm',
                            'id_ID',
                          ).format(notif.scheduledTime);

                          return Dismissible(
                            key: ValueKey(notif.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) {
                              _repository.deleteNotification(notif.id);
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: notif.isRead
                                      ? AppColors.getBorderColor(context)
                                      : color.withValues(alpha: 0.5),
                                  width: notif.isRead ? 1 : 1.5,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _handleNotificationTap(notif),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Type Icon
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: color, size: 22),
                                      ),
                                      const SizedBox(width: 12),

                                      // Text Body
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif.title,
                                                    style: TextStyle(
                                                      fontWeight: notif.isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                      fontSize: 14,
                                                      color:
                                                          AppColors.getTextPrimary(
                                                            context,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                if (!notif.isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppColors.primary,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif.body,
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.4,
                                                color:
                                                    AppColors.getTextSecondary(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 12,
                                                  color:
                                                      AppColors.getTextSecondary(
                                                        context,
                                                      ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  timeStr,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.getTextSecondary(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: (isUpcoming
                                                            ? AppColors.warning
                                                            : AppColors.success)
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    isUpcoming
                                                        ? 'Terjadwal'
                                                        : 'Terkirim',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isUpcoming
                                                          ? AppColors.warning
                                                          : AppColors.success,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('btn_create_reminder_fab'),
            onPressed: _openCreateReminderSheet,
            icon: const Icon(Icons.alarm_add_rounded),
            label: const Text('Buat Pengingat'),
          ),
        );
      },
    );
  }
}
