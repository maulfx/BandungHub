import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/destination_review.dart';
import '../../services/supabase_service.dart';

class ReviewRepository extends ChangeNotifier {
  static final ReviewRepository _instance = ReviewRepository._internal();
  factory ReviewRepository() => _instance;
  ReviewRepository._internal();

  static const String _storageKey = 'bandunghub_reviews_v1';
  final List<DestinationReview> _reviews = [];

  List<DestinationReview> get allReviews => List.unmodifiable(_reviews);
  List<DestinationReview> get reviews => allReviews;

  Future<void> init() async {
    await _loadFromStorage();
    if (_reviews.isEmpty) {
      _seedDefaultReviews();
      await _saveToStorage();
    }
    notifyListeners();
  }

  List<DestinationReview> getReviewsForDestination(String destinationId) {
    return _reviews
        .where((r) => r.destinationId == destinationId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  double getAverageRating(String destinationId, {double fallback = 4.5}) {
    final list = getReviewsForDestination(destinationId);
    if (list.isEmpty) return fallback;
    final total = list.fold<double>(0.0, (sum, r) => sum + r.rating);
    return double.parse((total / list.length).toStringAsFixed(1));
  }

  Map<int, int> getRatingBreakdown(String destinationId) {
    final map = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final list = getReviewsForDestination(destinationId);
    for (final r in list) {
      final star = r.rating.round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
  }

  List<String> getAllPhotosForDestination(String destinationId) {
    final list = getReviewsForDestination(destinationId);
    final photos = <String>[];
    for (final r in list) {
      photos.addAll(r.photoUrls);
    }
    return photos;
  }

  Future<DestinationReview> addReview({
    required String destinationId,
    required String userName,
    required double rating,
    required String comment,
    List<String> photoUrls = const [],
  }) async {
    final newReview = DestinationReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      destinationId: destinationId,
      userName: userName.trim().isEmpty ? 'Wisatawan Bandung' : userName.trim(),
      rating: rating.clamp(1.0, 5.0),
      comment: comment.trim(),
      createdAt: DateTime.now(),
      photoUrls: photoUrls,
      likesCount: 0,
      isLikedByMe: false,
    );

    _reviews.insert(0, newReview);
    notifyListeners();
    await _saveToStorage();

    // Kirim juga ke Supabase jika sedang terhubung
    final sb = SupabaseService();
    if (sb.isInitialized) {
      unawaited(sb.submitReview(newReview));
    }

    return newReview;
  }

  Future<void> toggleLikeReview(String reviewId) async {
    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      final current = _reviews[idx];
      final newLiked = !current.isLikedByMe;
      final newCount = (current.likesCount + (newLiked ? 1 : -1)).clamp(0, 9999);

      _reviews[idx] = current.copyWith(
        isLikedByMe: newLiked,
        likesCount: newCount,
      );
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        _reviews.clear();
        for (final item in decoded) {
          _reviews.add(
            DestinationReview.fromMap(Map<String, dynamic>.from(item as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('ReviewRepository _loadFromStorage error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = _reviews.map((r) => r.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(mapped));
    } catch (e) {
      debugPrint('ReviewRepository _saveToStorage error: $e');
    }
  }

  Future<void> resetToDefaults() async {
    _reviews.clear();
    _seedDefaultReviews();
    notifyListeners();
    await _saveToStorage();
  }

  void _seedDefaultReviews() {
    final now = DateTime.now();

    _reviews.addAll([
      DestinationReview(
        id: 'rev_seed_1',
        destinationId: 'dest_01', // Tangkuban Perahu
        userName: 'Siti Nurhaliza',
        rating: 5.0,
        comment:
            'Udara dingin banget dan pemandangan kawahnya megah! Saran: bawa masker karena bau belerang cukup kuat. Spot foto Kawah Ratu sangat memanjakan mata.',
        createdAt: now.subtract(const Duration(days: 2)),
        photoUrls: [
          'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop',
        ],
        likesCount: 14,
        isLikedByMe: false,
      ),
      DestinationReview(
        id: 'rev_seed_2',
        destinationId: 'dest_01',
        userName: 'Rian Pratama',
        rating: 4.5,
        comment:
            'Tempat wisata legendaris yang selalu bikin kangen. Akses jalan sudah mulus, banyak penjual suvenir dan ketan bakar hangat di sekitar kawah.',
        createdAt: now.subtract(const Duration(days: 5)),
        photoUrls: [],
        likesCount: 8,
        isLikedByMe: false,
      ),
      DestinationReview(
        id: 'rev_seed_3',
        destinationId: 'dest_02', // Kawah Putih
        userName: 'Budi Santoso',
        rating: 5.0,
        comment:
            'Danau vulkanik berwarna putih kehijauan yang luar biasa eksotis. Spot foto terbaik ada di dermaga apung dan jembatan kayu cantigi. Wajib dikunjungi!',
        createdAt: now.subtract(const Duration(days: 1)),
        photoUrls: [
          'https://images.unsplash.com/photo-1518457607834-6e8d80c183c5?w=800&auto=format&fit=crop',
        ],
        likesCount: 21,
        isLikedByMe: true,
      ),
      DestinationReview(
        id: 'rev_seed_4',
        destinationId: 'dest_03', // Jalan Braga
        userName: 'Alifia Putri',
        rating: 5.0,
        comment:
            'Suasana vintage kolonial Belanda yang syahdu saat sore menjelang malam. Banyak coffee shop estetik, lukisan jalanan, dan musisi akustik.',
        createdAt: now.subtract(const Duration(days: 3)),
        photoUrls: [
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&auto=format&fit=crop',
        ],
        likesCount: 19,
        isLikedByMe: false,
      ),
      DestinationReview(
        id: 'rev_seed_5',
        destinationId: 'dest_04', // Gedung Sate
        userName: 'Dimas Arya',
        rating: 4.8,
        comment:
            'Ikon kebanggaan kota Bandung. Arsitekturnya megah dan museum di bagian dalamnya sangat interaktif dengan teknologi VR dan augmented reality.',
        createdAt: now.subtract(const Duration(days: 7)),
        photoUrls: [],
        likesCount: 11,
        isLikedByMe: false,
      ),
      DestinationReview(
        id: 'rev_seed_6',
        destinationId: 'dest_05', // Saung Angklung Udjo
        userName: 'Maya Wulandari',
        rating: 5.0,
        comment:
            'Pertunjukan seni angklung yang luar biasa meriah dan edukatif! Penonton diajak bermain angklung bersama membentuk harmoni lagu nusantara.',
        createdAt: now.subtract(const Duration(days: 4)),
        photoUrls: [],
        likesCount: 25,
        isLikedByMe: true,
      ),
      DestinationReview(
        id: 'rev_seed_7',
        destinationId: 'dest_06', // Orchid Forest Cikole
        userName: 'Farhan Hidayat',
        rating: 5.0,
        comment:
            'Hutan pinus terindah di Lembang dengan koleksi anggrek langka dan jembatan gantung kayu (Wood Bridge) yang menyala syahdu saat senja.',
        createdAt: now.subtract(const Duration(days: 6)),
        photoUrls: [
          'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&auto=format&fit=crop',
        ],
        likesCount: 16,
        isLikedByMe: false,
      ),
    ]);
  }
}
