import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/offline_sync_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../models/destination.dart';
import '../../../models/sync_queue_item.dart';
import '../../../services/network_connectivity_service.dart';

class DestinationReviewsSection extends StatefulWidget {
  final Destination destination;

  const DestinationReviewsSection({super.key, required this.destination});

  @override
  State<DestinationReviewsSection> createState() =>
      _DestinationReviewsSectionState();
}

class _DestinationReviewsSectionState extends State<DestinationReviewsSection> {
  final _reviewRepo = ReviewRepository();

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
