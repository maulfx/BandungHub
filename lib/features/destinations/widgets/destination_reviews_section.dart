import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/offline_sync_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../models/destination.dart';
import '../../../models/sync_queue_item.dart';
import '../../../services/network_connectivity_service.dart';
import '../../../services/review_blockchain_service.dart';
import '../../../services/sepolia_anchor_service.dart';

class DestinationReviewsSection extends StatefulWidget {
  final Destination destination;

  const DestinationReviewsSection({super.key, required this.destination});

  @override
  State<DestinationReviewsSection> createState() =>
      _DestinationReviewsSectionState();
}

class _DestinationReviewsSectionState extends State<DestinationReviewsSection> {
  final _reviewRepo = ReviewRepository();

  @override
  void initState() {
    super.initState();
    _reviewRepo.fetchDestinationReviewsFromCloud(widget.destination.id);
  }

  void _openSubmitReviewSheet(BuildContext context) {
    double selectedRating = 5.0;
    final nameController = TextEditingController(text: 'Wisatawan Bandung');
    final commentController = TextEditingController();
    final List<String> attachedPhotos = [];

    final ratingLabels = {
      1: 'Sangat Kecewa 😞',
      2: 'Kurang Memuaskan 🙁',
      3: 'Cukup Baik 😐',
      4: 'Sangat Bagus 😊',
      5: 'Luar Biasa! Rekomendasi Banget ⭐',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rate_review_rounded,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tulis Ulasan & Rating',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.destination.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.getTextSecondary(ctx),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Star Rating Picker
                    const Center(
                      child: Text(
                        'Bagaimana Pengalaman Kunjungan Anda?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isFilled = star <= selectedRating;
                        return IconButton(
                          key: Key('star_rating_$star'),
                          icon: Icon(
                            isFilled
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: isFilled ? Colors.amber : Colors.grey.shade400,
                            size: 38,
                          ),
                          onPressed: () {
                            setSheetState(() => selectedRating = star.toDouble());
                          },
                        );
                      }),
                    ),
                    Center(
                      child: Text(
                        ratingLabels[selectedRating.toInt()] ?? '',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Reviewer Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Anda',
                        hintText: 'Nama lengkap atau panggilan...',
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Review Comment Field
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Ceritakan Pengalaman Wisata Anda',
                        hintText:
                            'Contoh: Tempatnya sangat sejuk, spot foto bagus, dan parkiran luas...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sample Photo Attachment Simulation
                    Text(
                      'Sertakan Foto Wisata (Opsional):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextSecondary(ctx),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                          label: const Text('Spot Foto Indah'),
                          onPressed: () {
                            setSheetState(() {
                              attachedPhotos.add(
                                'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop',
                              );
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.photo_camera_rounded, size: 16),
                          label: const Text('Foto Suasana'),
                          onPressed: () {
                            setSheetState(() {
                              attachedPhotos.add(
                                'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&auto=format&fit=crop',
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    if (attachedPhotos.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${attachedPhotos.length} foto siap diunggah',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('btn_submit_review'),
                        onPressed: () async {
                          final comment = commentController.text.trim();
                          if (comment.isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan tulis ulasan singkat Anda.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }

                          await _reviewRepo.addReview(
                            destinationId: widget.destination.id,
                            userName: nameController.text.trim(),
                            rating: selectedRating,
                            comment: comment,
                            photoUrls: attachedPhotos,
                          );

                          final isOnline = NetworkConnectivityService.instance.isOnline;
                          if (!isOnline) {
                            await OfflineSyncRepository.instance.enqueueAction(
                              actionType: SyncActionType.createReview,
                              targetId: widget.destination.id,
                              payload: {
                                'destinationId': widget.destination.id,
                                'destinationName': widget.destination.name,
                                'userName': nameController.text.trim(),
                                'rating': selectedRating,
                                'comment': comment,
                                'photoUrls': attachedPhotos,
                              },
                            );
                          }

                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isOnline
                                      ? 'Ulasan & rating Anda berhasil dikirim! Terima kasih atas kontribusi Anda.'
                                      : 'Mode Offline: Ulasan disimpan di antrean lokal & akan disinkronkan saat terhubung.',
                                ),
                                backgroundColor: isOnline ? AppColors.success : Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Kirim Ulasan'),
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
            );
          },
        );
      },
    );
  }

  void _openPhotoLightbox(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black,
                  height: 300,
                  alignment: Alignment.center,
                  child: const Text(
                    'Gagal memuat foto',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _openBlockDetailDialog(BuildContext context, String reviewId) {
    bool isAnchoring = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final block = ReviewBlockchainService().getBlockForReview(reviewId);

            if (block == null) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Status Blockchain', style: TextStyle(fontSize: 16)),
                  ],
                ),
                content: const Text(
                  'Blok untuk ulasan ini sedang dalam proses antrean penambangan (mining) atau belum disinkronkan.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Colors.teal, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Blok #${block.index} Terverifikasi',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text(
                                  'Review Blockchain Ledger',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Integritas data ulasan tervalidasi secara kriptografis & bebas manipulasi.',
                                style: TextStyle(fontSize: 11.5, color: Colors.teal.shade900, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildDetailRow('Pengulas', block.userName),
                      _buildDetailRow('Rating', '${block.rating} ★'),
                      _buildDetailRow('Waktu Pencatatan', DateFormat('d MMMM yyyy HH:mm:ss', 'id_ID').format(block.timestamp)),
                      _buildDetailRow('Destinasi ID', block.destinationId),
                      const SizedBox(height: 10),
                      const Text('Current Block Hash (SHA-256):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _buildHashSnippet(context, block.hash),
                      const SizedBox(height: 10),
                      const Text('Previous Block Hash:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _buildHashSnippet(context, block.previousHash),
                      const SizedBox(height: 14),

                      // Bagian Ethereum Sepolia Anchoring
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (block.txHash != null)
                              ? Colors.indigo.withValues(alpha: 0.08)
                              : Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (block.txHash != null)
                                ? Colors.indigo.withValues(alpha: 0.3)
                                : Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  block.txHash != null
                                      ? Icons.public_rounded
                                      : Icons.cloud_queue_rounded,
                                  size: 18,
                                  color: block.txHash != null ? Colors.indigo : Colors.amber.shade800,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    block.txHash != null
                                        ? 'Ethereum Sepolia Testnet (On-Chain)'
                                        : 'Sepolia Anchoring Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: block.txHash != null ? Colors.indigo.shade900 : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (block.txHash != null) ...[
                              const Text(
                                'TxHash (Bukti Transaksi Publik):',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              _buildHashSnippet(context, block.txHash!),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final url = Uri.parse(SepoliaAnchorService.getEtherscanUrl(block.txHash!));
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                  label: const Text('Lihat di Sepolia Etherscan', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.indigo,
                                    side: const BorderSide(color: Colors.indigo),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Hash tersimpan di ledger lokal. Blok ini dapat ditambatkan ke Ethereum Sepolia untuk pembuktian publik.',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: isAnchoring
                                      ? null
                                      : () async {
                                          setDialogState(() => isAnchoring = true);
                                          final tx = await ReviewBlockchainService().anchorBlock(block);
                                          setDialogState(() => isAnchoring = false);
                                          if (tx == null && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Gagal menambatkan: Saldo Sepolia ETH 0 atau jaringan offline. Silakan klaim faucet terlebih dahulu.',
                                                ),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                        },
                                  icon: isAnchoring
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.anchor_rounded, size: 16),
                                  label: Text(
                                    isAnchoring ? 'Menambatkan ke Sepolia...' : 'Anchor ke Sepolia Sekarang',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal.shade800,
                                    side: BorderSide(color: Colors.teal.shade600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Tutup Verifikasi'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHashSnippet(BuildContext context, String hash) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hash,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Salin Hash',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: hash));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hash SHA-256 berhasil disalin!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openAuditBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: ReviewBlockchainService(),
          builder: (context, _) {
            final blockchain = ReviewBlockchainService();
            final audit = blockchain.auditChain();
            final isValid = audit['isValid'] as bool? ?? false;
            final errorMsg = audit['errorMessage'] as String?;
            final chain = blockchain.chain;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isValid ? Colors.teal : Colors.red).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isValid ? Icons.shield_rounded : Icons.gpp_bad_rounded,
                          color: isValid ? Colors.teal : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Audit Integritas Review Blockchain',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Ledger Konsensus ${chain.length} Blok Terverifikasi',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (isValid ? Colors.teal : Colors.red).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isValid ? Colors.teal : Colors.red).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isValid ? Icons.verified_rounded : Icons.warning_rounded,
                          color: isValid ? Colors.teal : Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isValid
                                    ? 'Status Rantai: 100% Valid & Otentik'
                                    : 'PERINGATAN: Integritas Rantai Rusak!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isValid ? Colors.teal.shade800 : Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isValid
                                    ? 'Seluruh hash SHA-256 dan previous hash tersambung sempurna tanpa pemalsuan.'
                                    : (errorMsg ?? 'Manipulasi data ulasan terdeteksi.'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isValid ? Colors.teal.shade900 : Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Daftar Rantai Blok (Block Ledger):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Blocks Scrollable List
                  Expanded(
                    child: ListView.separated(
                      itemCount: chain.length,
                      separatorBuilder: (context, index) => Center(
                        child: Icon(Icons.link_rounded, size: 16, color: Colors.teal.shade300),
                      ),
                      itemBuilder: (context, index) {
                        final b = chain[index];
                        final isGenesis = b.index == 0;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.getCardColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isGenesis ? Colors.amber.shade400 : AppColors.getBorderColor(context),
                              width: isGenesis ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isGenesis ? Icons.star_rounded : Icons.layers_rounded,
                                        size: 16,
                                        color: isGenesis ? Colors.amber.shade700 : Colors.teal,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isGenesis ? 'Blok #0 (Genesis)' : 'Blok #${b.index}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat('HH:mm:ss d/M/yy').format(b.timestamp),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${b.userName} (${b.rating} ★): "${b.comment}"',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hash: ${b.hash.substring(0, 20)}...',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.teal),
                              ),
                              Text(
                                'Prev: ${b.previousHash.substring(0, 20)}...',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: Colors.grey),
                              ),
                            ],
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reviewRepo,
      builder: (context, _) {
        final reviews = _reviewRepo.getReviewsForDestination(widget.destination.id);
        final avgRating = _reviewRepo.getAverageRating(
          widget.destination.id,
          fallback: widget.destination.rating,
        );
        final breakdown = _reviewRepo.getRatingBreakdown(widget.destination.id);
        final photos = _reviewRepo.getAllPhotosForDestination(widget.destination.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title & Write Review Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ulasan & Rating Pengunjung',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      Text(
                        '${reviews.length} ulasan dari wisatawan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: const Key('btn_write_review'),
                  onPressed: () => _openSubmitReviewSheet(context),
                  icon: const Icon(Icons.rate_review_rounded, size: 16),
                  label: const Text('Tulis Ulasan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rating Score & Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorderColor(context)),
              ),
              child: Row(
                children: [
                  // Left: Big Rating Number & Stars
                  Column(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < avgRating.floor()
                                ? Icons.star_rounded
                                : (index < avgRating
                                    ? Icons.star_half_rounded
                                    : Icons.star_border_rounded),
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reviews.length} ulasan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 16),

                  // Right: Star breakdown bars (5 down to 1)
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final count = breakdown[star] ?? 0;
                        final total = reviews.isEmpty ? 1 : reviews.length;
                        final pct = count / total;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                '$star★',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.amber,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User Photo Gallery Carousel
            if (photos.isNotEmpty) ...[
              Text(
                'Galeri Foto Pengunjung (${photos.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photoUrl = photos[index];
                    return InkWell(
                      onTap: () => _openPhotoLightbox(context, photoUrl),
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photoUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Reviews List
            Text(
              'Ulasan Terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 10),

            // Blockchain Audit & Integrity Banner
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ulasan Terverifikasi Blockchain',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Terenkripsi SHA-256 anti-manipulasi',
                          style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openAuditBottomSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.analytics_outlined, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Audit Ledger',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (reviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorderColor(context)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined, color: Colors.grey, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada ulasan untuk tempat ini.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => _openSubmitReviewSheet(context),
                      child: const Text('Jadilah yang pertama mengulas!'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final formattedDate =
                      DateFormat('d MMM yyyy', 'id_ID').format(review.createdAt);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.getBorderColor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Avatar & Name & Stars
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                review.userName.isNotEmpty
                                    ? review.userName[0].toUpperCase()
                                    : 'W',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            starIdx < review.rating.floor()
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            size: 13,
                                            color: Colors.amber,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.getTextSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Helpful Like Button
                            InkWell(
                              onTap: () => _reviewRepo.toggleLikeReview(review.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: review.isLikedByMe
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: review.isLikedByMe
                                        ? Colors.red.shade300
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      review.isLikedByMe
                                          ? Icons.thumb_up_rounded
                                          : Icons.thumb_up_outlined,
                                      size: 13,
                                      color: review.isLikedByMe
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${review.likesCount}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: review.isLikedByMe
                                            ? AppColors.primary
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // On-Chain Verified Chip
                            InkWell(
                              onTap: () => _openBlockDetailDialog(context, review.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.teal.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      size: 12,
                                      color: Colors.teal.shade700,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'On-Chain',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Review Comment Text
                        Text(
                          review.comment,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),

                        // Review Attached Photos
                        if (review.photoUrls.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: review.photoUrls.map((url) {
                              return InkWell(
                                onTap: () => _openPhotoLightbox(context, url),
                                borderRadius: BorderRadius.circular(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image, size: 20),
                                        ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
