import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env_config.dart';
import '../models/destination.dart';
import '../models/destination_review.dart';
import '../models/itinerary.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inisialisasi Supabase client.
  /// Jika kredensial belum diisi di EnvConfig, fungsi ini tidak akan crash
  /// dan aplikasi tetap berjalan normal menggunakan database lokal (SQFlite).
  Future<void> init() async {
    if (!EnvConfig.isSupabaseConfigured) {
      debugPrint(
        'ℹ️ [SupabaseService] URL/Anon Key belum diisi di EnvConfig. Aplikasi berjalan dalam mode Offline/Lokal.',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: EnvConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('✅ [SupabaseService] Berhasil terhubung ke Supabase Cloud!');
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] Gagal inisialisasi Supabase ($e). Fallback ke Lokal.');
      _isInitialized = false;
    }
  }

  // ==========================================
  // 1. DESTINATIONS (KATALOG WISATA)
  // ==========================================

  /// Mengambil semua destinasi dari tabel Supabase 'destinations'
  Future<List<Destination>> fetchDestinations() async {
    final sb = client;
    if (sb == null) return [];

    try {
      final List<dynamic> response = await sb
          .from('destinations')
          .select()
          .order('name', ascending: true);

      return response.map((data) {
        final map = Map<String, dynamic>.from(data as Map);
        // Tangani format tags array dari postgres
        if (map['tags'] is List) {
          map['tags'] = (map['tags'] as List).join(',');
        }
        return Destination.fromMap(map);
      }).toList();
    } catch (e) {
      debugPrint('Error fetchDestinations: $e');
      return [];
    }
  }

  /// Upload/Seeding daftar destinasi resmi Bandung ke Supabase jika tabel masih kosong
  Future<void> seedDestinationsIfEmpty(List<Destination> destinations) async {
    final sb = client;
    if (sb == null) return;

    try {
      final countResponse = await sb
          .from('destinations')
          .select('id')
          .limit(1);

      if ((countResponse as List).isEmpty) {
        debugPrint('[SupabaseService] Mengunggah seed destinasi ke Supabase...');
        final data = destinations.map((d) {
          return {
            'id': d.id,
            'name': d.name,
            'description': d.description,
            'category': d.category,
            'address': d.address,
            'latitude': d.latitude,
            'longitude': d.longitude,
            'estimated_price': d.estimatedPrice,
            'operational_hours': d.operationalHours,
            'image_url': d.imageUrl,
            'rating': d.rating,
            'review_count': d.reviewCount,
            'is_verified': d.isVerified,
            'tags': d.tags,
          };
        }).toList();

        await sb.from('destinations').insert(data);
        debugPrint('✅ [SupabaseService] Seed destinasi berhasil diunggah.');
      }
    } catch (e) {
      debugPrint('⚠️ Error seeding destinations: $e');
    }
  }

  /// Sinkronisasi / Upsert daftar destinasi ke Supabase Cloud
  Future<void> upsertDestinations(List<Destination> destinations) async {
    final sb = client;
    if (sb == null) return;

    try {
      final data = destinations.map((d) {
        return {
          'id': d.id,
          'name': d.name,
          'description': d.description,
          'category': d.category,
          'address': d.address,
          'latitude': d.latitude,
          'longitude': d.longitude,
          'estimated_price': d.estimatedPrice,
          'operational_hours': d.operationalHours,
          'image_url': d.imageUrl,
          'rating': d.rating,
          'review_count': d.reviewCount,
          'is_verified': d.isVerified,
          'tags': d.tags,
        };
      }).toList();

      await sb.from('destinations').upsert(data);
      debugPrint('✅ [SupabaseService] Berhasil sinkronisasi ${destinations.length} destinasi ke cloud.');
    } catch (e) {
      debugPrint('⚠️ Error upsertDestinations: $e');
    }
  }

  // ==========================================
  // 2. ITINERARIES (RENCANA PERJALANAN)
  // ==========================================

  /// Mengambil semua itinerary milik user tertentu dari Supabase
  Future<List<Itinerary>> fetchUserItineraries(String userId) async {
    final sb = client;
    if (sb == null) return [];

    try {
      final List<dynamic> response = await sb
          .from('itineraries')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return response.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        // Supabase mengembalikan jsonb sebagai List/Map
        if (map['items'] is List) {
          map['items'] = jsonEncode(map['items']);
        }
        map['sync_status'] = 'synced';
        return Itinerary.fromMap(map);
      }).toList();
    } catch (e) {
      debugPrint('Error fetchUserItineraries: $e');
      return [];
    }
  }

  /// Simpan atau update itinerary ke Supabase
  Future<bool> upsertItinerary(Itinerary itinerary, {required String userId}) async {
    final sb = client;
    if (sb == null) return false;

    try {
      final payload = {
        'id': itinerary.id,
        'user_id': userId,
        'title': itinerary.title,
        'start_date': itinerary.startDate.toIso8601String().split('T').first,
        'duration_days': itinerary.durationDays,
        'number_of_people': itinerary.numberOfPeople,
        'transportation_cost': itinerary.transportationCost,
        'food_cost': itinerary.foodCost,
        'additional_cost': itinerary.additionalCost,
        'items': itinerary.items.map((i) => i.toMap()).toList(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await sb.from('itineraries').upsert(payload);
      return true;
    } catch (e) {
      debugPrint('Error upsertItinerary: $e');
      return false;
    }
  }

  /// Hapus itinerary di cloud Supabase
  Future<bool> deleteItinerary(String id) async {
    final sb = client;
    if (sb == null) return false;

    try {
      await sb.from('itineraries').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleteItinerary from cloud: $e');
      return false;
    }
  }

  // ==========================================
  // 3. REVIEWS (ULASAN & RATING)
  // ==========================================

  /// Mengambil ulasan untuk suatu destinasi wisata
  Future<List<DestinationReview>> fetchReviews(String destinationId) async {
    final sb = client;
    if (sb == null) return [];

    try {
      final dynamic query = destinationId.trim().isNotEmpty
          ? sb.from('destination_reviews').select().eq('destination_id', destinationId)
          : sb.from('destination_reviews').select();

      final List<dynamic> response = await query.order('created_at', ascending: false);

      return response.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return DestinationReview(
          id: map['id']?.toString() ?? '',
          destinationId: map['destination_id']?.toString() ?? '',
          userName: map['user_name'] ?? 'Pengunjung',
          userAvatarUrl: map['user_avatar_url'],
          rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
          comment: map['comment'] ?? '',
          createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
          photoUrls: (map['photo_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetchReviews: $e');
      return [];
    }
  }

  /// Mengirim ulasan baru ke Supabase
  Future<bool> submitReview(DestinationReview review, {String? userId}) async {
    final sb = client;
    if (sb == null) return false;

    try {
      final payload = <String, dynamic>{
        'id': review.id,
        'destination_id': review.destinationId,
        'user_name': review.userName,
        'user_avatar_url': review.userAvatarUrl,
        'rating': review.rating,
        'comment': review.comment,
        'photo_urls': review.photoUrls,
        'likes_count': review.likesCount,
      };
      if (userId != null) {
        payload['user_id'] = userId;
      }
      await sb.from('destination_reviews').insert(payload);
      return true;
    } catch (e) {
      debugPrint('Error submitReview to Supabase: $e');
      return false;
    }
  }

  // ==========================================
  // 4. FAVORITES (BOOKMARK DESTINASI)
  // ==========================================

  /// Ambil set ID destinasi favorit milik user
  Future<Set<String>> fetchFavorites(String userId) async {
    final sb = client;
    if (sb == null) return {};

    try {
      final List<dynamic> response = await sb
          .from('user_favorites')
          .select('destination_id')
          .eq('user_id', userId);

      return response
          .map((r) => r['destination_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('Error fetchFavorites: $e');
      return {};
    }
  }

  /// Tambah atau hapus favorit di Supabase
  Future<void> toggleFavorite({required String userId, required String destinationId, required bool isFav}) async {
    final sb = client;
    if (sb == null) return;

    try {
      if (isFav) {
        await sb.from('user_favorites').upsert({
          'user_id': userId,
          'destination_id': destinationId,
        });
      } else {
        await sb
            .from('user_favorites')
            .delete()
            .match({'user_id': userId, 'destination_id': destinationId});
      }
    } catch (e) {
      debugPrint('Error toggleFavorite: $e');
    }
  }
}
