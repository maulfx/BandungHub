import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/offline_sync_repository.dart';
import '../../../models/sync_queue_item.dart';
import '../../../services/network_connectivity_service.dart';

/// Screen for managing offline state, synchronization queue, and local cache
class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key});

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  final _syncRepo = OfflineSyncRepository.instance;
  final _netService = NetworkConnectivityService.instance;
  String _selectedFilter = 'all'; // 'all', 'pending', 'synced'

  @override
  void initState() {
    super.initState();
    _syncRepo.init();
  }

  void _syncNow() async {
    final result = await _syncRepo.syncAll(force: true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearCache() async {
    final freedBytes = await _syncRepo.clearTemporaryCache();
    if (!mounted) return;

    final formatted = freedBytes < 1024 * 1024
        ? '${(freedBytes / 1024).toStringAsFixed(1)} KB'
        : '${(freedBytes / (1024 * 1024)).toStringAsFixed(2)} MB';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cache sementara berhasil dibersihkan ($formatted dibebaskan).'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _clearSyncedHistory() async {
    final removed = await _syncRepo.clearSyncedItems();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$removed riwayat sinkronisasi berhasil dihapus.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Sinkronisasi & Cache Offline'),
        backgroundColor: AppColors.getSurfaceColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Informasi Mode Offline',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Arsitektur Offline BandungHub'),
                  content: const Text(
                    'BandungHub dirancang dengan kapabilitas Offline-First. '
                    'Seluruh katalog 16 destinasi wisata, foto lokal, deskripsi, '
                    'dan rencana itinerary tetap dapat diakses di dataran tinggi Bandung '
                    'tanpa sinyal internet (seperti Lembang, Ciwidey, Tebing Keraton).\n\n'
                    'Perubahan baru (ulasan, like, itinerary) akan otomatis disimpan '
                    'di antrean lokal dan disinkronkan ke server saat jaringan kembali aktif.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Mengerti'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_syncRepo, _netService.isOnlineNotifier]),
        builder: (context, _) {
          final isOnline = _netService.isOnline;
          final isSimulated = _netService.isSimulatedOffline;
          final stats = _syncRepo.getCacheStats();
          final allItems = _syncRepo.queue;
          final filteredItems = allItems.where((item) {
            if (_selectedFilter == 'pending') {
              return item.status == SyncStatus.pending ||
                  item.status == SyncStatus.failed;
            }
            if (_selectedFilter == 'synced') {
              return item.status == SyncStatus.synced;
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Connectivity Status & Simulation Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isOnline
                      ? (isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F5E9))
                      : (isDark ? const Color(0xFF332210) : const Color(0xFFFFF3E0)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOnline ? 'Terhubung ke Internet' : 'Mode Offline Aktif',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isOnline
                                      ? (isDark ? Colors.greenAccent : Colors.green.shade900)
                                      : (isDark ? Colors.amberAccent : Colors.orange.shade900),
                                ),
                              ),
                              Text(
                                isOnline
                                    ? 'Aplikasi siap menyinkronkan data secara real-time.'
                                    : 'Data disimpan lokal di antrean perangkat.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Simulated Offline Switch
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        key: const Key('switch_simulated_offline'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Simulasi Mode Offline (Demo)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Uji coba antrean data tanpa koneksi internet.',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: isSimulated,
                        activeThumbColor: Colors.orange,
                        activeTrackColor: Colors.orange.withValues(alpha: 0.5),
                        onChanged: (val) {
                          _netService.setSimulatedOffline(val);
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Last sync info & sync button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _syncRepo.lastSyncTime != null
                                ? 'Terakhir: ${DateFormat('dd MMM HH:mm', 'id_ID').format(_syncRepo.lastSyncTime!)}'
                                : 'Belum pernah sinkronisasi',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          key: const Key('btn_sync_now'),
                          onPressed: _syncRepo.isSyncing ? null : _syncNow,
                          icon: _syncRepo.isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: Text(_syncRepo.isSyncing
                              ? 'Menyinkronkan...'
                              : 'Sinkronkan Sekarang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Offline Cache Breakdown
              Text(
                'Penyimpanan Cache & Data Lokal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.getBorderColor(context)),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      context,
                      icon: Icons.place_rounded,
                      title: 'Katalog Destinasi Offline',
                      value: '${stats['destinationsCount']} Destinasi (100% Siap)',
                      color: AppColors.primary,
                    ),
                    const Divider(height: 16),
                    _buildStatRow(
                      context,
                      icon: Icons.rate_review_rounded,
                      title: 'Ulasan & Rating Lokal',
                      value: '${stats['reviewsCount']} Ulasan',
                      color: Colors.amber.shade700,
                    ),
                    const Divider(height: 16),
                    _buildStatRow(
                      context,
                      icon: Icons.event_note_rounded,
                      title: 'Rencana Perjalanan (Itinerary)',
                      value: '${stats['itinerariesCount']} Rencana',
                      color: AppColors.primary,
                    ),
                    const Divider(height: 16),
                    _buildStatRow(
                      context,
                      icon: Icons.storage_rounded,
                      title: 'Estimasi Penggunaan Cache',
                      value: stats['formattedSize'].toString(),
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('btn_clear_cache'),
                        onPressed: _clearCache,
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                        label: const Text('Bersihkan Cache Sementara'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.getTextPrimary(context),
                          side: BorderSide(color: AppColors.getBorderColor(context)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Sync Queue Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Antrean Sinkronisasi Cloud (${_syncRepo.queue.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                  if (_syncRepo.syncedItems.isNotEmpty)
                    TextButton(
                      key: const Key('btn_clear_synced'),
                      onPressed: _clearSyncedHistory,
                      child: const Text(
                        'Hapus Riwayat',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Semua (${allItems.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Menunggu (${_syncRepo.pendingCount})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('synced', 'Tersinkron (${_syncRepo.syncedItems.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Queue List
              if (filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 48,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak Ada Antrean Sinkronisasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua data Anda telah tersimpan dengan aman di server dan perangkat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredItems.map((item) => _buildQueueItemTile(context, item)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = key;
        });
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : AppColors.getTextPrimary(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItemTile(BuildContext context, SyncQueueItem item) {
    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case SyncStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case SyncStatus.syncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync_rounded;
        break;
      case SyncStatus.synced:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.queuedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                if (item.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Pesan: ${item.errorMessage}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              if (item.status == SyncStatus.failed)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Coba Lagi',
                  onPressed: () => _syncRepo.retryItem(item.id),
                )
              else if (item.status == SyncStatus.synced)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: 'Hapus Item',
                  onPressed: () => _syncRepo.removeItem(item.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
