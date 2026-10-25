import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/itinerary.dart';
import '../../../services/itinerary_export_service.dart';

/// Modal Bottom Sheet untuk Membagikan Itinerary
/// Menghadirkan 2 pilihan praktis: Bagikan Catatan Teks (WhatsApp/Chat) atau Dokumen PDF
class ItineraryExportSheet extends StatefulWidget {
  final Itinerary itinerary;

  const ItineraryExportSheet({super.key, required this.itinerary});

  static Future<void> show(BuildContext context, Itinerary itinerary) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItineraryExportSheet(itinerary: itinerary),
    );
  }

  @override
  State<ItineraryExportSheet> createState() => _ItineraryExportSheetState();
}

class _ItineraryExportSheetState extends State<ItineraryExportSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSharingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnackbar({
    required String message,
    required bool isSuccess,
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sharePdf(Itinerary itinerary) async {
    if (_isSharingPdf) return;

    setState(() => _isSharingPdf = true);

    try {
      await ItineraryExportService.shareItineraryPdf(itinerary);
    } catch (e) {
      _showSnackbar(
        message: 'Gagal membagikan PDF: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary;
    final plainText = ItineraryExportService.generatePlainText(itinerary);

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bagikan Rencana Perjalanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        itinerary.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Pilihan Format: Catatan atau PDF
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.getTextSecondary(context),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.notes_rounded, size: 20),
                text: 'Bagikan Catatan',
              ),
              Tab(
                icon: Icon(Icons.picture_as_pdf_rounded, size: 20),
                text: 'Dokumen PDF',
              ),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pilihan 1: Bagikan Catatan
                _buildNotesTab(plainText, itinerary),

                // Pilihan 2: Dokumen PDF
                _buildPdfTab(itinerary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Pilihan 1: Bagikan Catatan
  Widget _buildNotesTab(String plainText, Itinerary itinerary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Format catatan rapi berisi jadwal & rincian biaya, cocok untuk dibagikan ke WhatsApp atau aplikasi catatan.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  plainText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn_copy_plain_text'),
                  onPressed: () async {
                    await ItineraryExportService.copyToClipboard(plainText);
                    _showSnackbar(
                      message: 'Catatan itinerary berhasil disalin ke clipboard!',
                      isSuccess: true,
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Salin Catatan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('btn_share_itinerary_sheet'),
                  onPressed: () async {
                    await ItineraryExportService.shareItineraryText(itinerary);
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Bagikan'),
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
        ],
      ),
    );
  }

  /// Tampilan Pilihan 2: Dokumen PDF
  Widget _buildPdfTab(Itinerary itinerary) {
    final endDate = itinerary.startDate.add(
      Duration(days: itinerary.durationDays - 1),
    );

    final formattedBudget = 'Rp ${itinerary.totalEstimatedBudget.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Preview Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.getBorderColor(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${itinerary.title}.pdf',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Dokumen A4 Siap Simpan & Cetak',
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
                  ),
                  const SizedBox(height: 14),

                  // Ringkasan Isi PDF
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.getBorderColor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Dokumen:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPdfInfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Periode',
                          value:
                              '${itinerary.durationDays} Hari (${AppDateUtils.formatDate(itinerary.startDate)} - ${AppDateUtils.formatDate(endDate)})',
                        ),
                        const SizedBox(height: 8),
                        _buildPdfInfoRow(
                          icon: Icons.people_outline_rounded,
                          label: 'Jumlah Tamu',
                          value: '${itinerary.numberOfPeople} Orang',
                        ),
                        const SizedBox(height: 8),
                        _buildPdfInfoRow(
                          icon: Icons.place_outlined,
                          label: 'Destinasi',
                          value: '${itinerary.items.length} Tempat Wisata Terjadwal',
                        ),
                        const SizedBox(height: 8),
                        _buildPdfInfoRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Estimasi Biaya',
                          value: formattedBudget,
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fitur Dokumen PDF
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Keunggulan Dokumen PDF',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureBullet('Tabel rincian tiket, transportasi, kuliner, dan logistik'),
                        _buildFeatureBullet('Jadwal harian rapi per destinasi lengkap beserta catatan'),
                        _buildFeatureBullet('Format dokumen standar A4 bersih dan siap cetak atau arsip'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_share_pdf'),
              onPressed: _isSharingPdf ? null : () => _sharePdf(itinerary),
              icon: _isSharingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(
                _isSharingPdf ? 'Menyiapkan PDF...' : 'Bagikan PDF',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
    );
  }

  Widget _buildPdfInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isHighlight ? AppColors.primary : Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AppColors.primary : AppColors.getTextPrimary(context),
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
