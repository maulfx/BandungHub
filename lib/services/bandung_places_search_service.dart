import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/destination.dart';
import 'map_service.dart';

/// Service providing live OpenStreetMap search for any location strictly within Bandung Raya.
/// Bounded to Kota Bandung, Kab. Bandung, Kab. Bandung Barat, and Kota Cimahi.
class BandungPlacesSearchService {
  static final BandungPlacesSearchService _instance =
      BandungPlacesSearchService._internal();
  factory BandungPlacesSearchService() => _instance;
  BandungPlacesSearchService._internal();

  // In-memory query cache to reduce network calls
  final Map<String, List<Destination>> _cache = {};

  // Bandung Raya Bounding Box for Nominatim:
  // left (min lon), top (max lat), right (max lon), bottom (min lat)
  static const double _minLon = 107.05;
  static const double _maxLat = -6.60;
  static const double _maxLon = 107.95;
  static const double _minLat = -7.35;

  /// Search any place strictly located in Bandung Raya
  Future<List<Destination>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final cacheKey = q.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // Query bounded strictly to Bandung Raya box
      final queryParam = q.toLowerCase().contains('bandung') ? q : '$q Bandung';
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(queryParam)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=6'
        '&countrycodes=id'
        '&viewbox=$_minLon,$_maxLat,$_maxLon,$_minLat'
        '&bounded=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BandungHubApp/1.0 (mobile.app.bandunghub@gmail.com)',
          'Accept-Language': 'id,en',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        return [];
      }

      final List data = jsonDecode(response.body);
      final List<Destination> results = [];

      for (final item in data) {
        final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;

        // Strictly verify location is within Bandung Raya bounds
        if (!_isInsideBandungRaya(lat, lon)) {
          continue;
        }

        final rawName = item['name']?.toString() ?? '';
        final displayName = item['display_name']?.toString() ?? '';
        final name = rawName.isNotEmpty ? rawName : displayName.split(',')[0].trim();

        // Extract address components
        final addressMap = item['address'] as Map<String, dynamic>?;
        final cleanAddress = _formatAddress(addressMap, displayName);

        // Determine category based on OSM tags
        final type = (item['type']?.toString() ?? '').toLowerCase();
        final osmClass = (item['class']?.toString() ?? '').toLowerCase();
        final category = _determineCategory(type, osmClass, name);
        final imageUrl = _getCategoryPlaceholderImage(category);

        final osmId = item['osm_id']?.toString() ??
            '${DateTime.now().millisecondsSinceEpoch}_${results.length}';

        results.add(
          Destination(
            id: 'live_$osmId',
            name: name,
            description:
                'Lokasi nyata di wilayah Bandung ditemukan melalui peta live OpenStreetMap. Terverifikasi berada di area $cleanAddress.',
            category: category,
            address: cleanAddress,
            latitude: lat,
            longitude: lon,
            estimatedPrice: 0.0,
            operationalHours: 'Buka Sesuai Jam Operasional Setempat',
            imageUrl: imageUrl,
            rating: 4.6,
            reviewCount: 85,
            isVerified: false,
            tags: ['Peta Bandung Live', category, 'Wisata Terverifikasi'],
          ),
        );
      }

      _cache[cacheKey] = results;
      return results;
    } catch (e) {
      debugPrint('Bandung places search error: $e');
      return [];
    }
  }

  /// Verify coordinate strictly inside Bandung Raya
  static bool _isInsideBandungRaya(double lat, double lon) {
    if (lat < _minLat || lat > _maxLat) return false;
    if (lon < _minLon || lon > _maxLon) return false;
    return MapService.bandungBounds.contains(LatLng(lat, lon));
  }

  /// Clean readable Indonesian address formatting
  static String _formatAddress(
    Map<String, dynamic>? address,
    String defaultName,
  ) {
    if (address == null) {
      final parts = defaultName.split(',');
      if (parts.length > 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}, Bandung';
      }
      return defaultName;
    }

    final road = address['road'] ?? address['pedestrian'] ?? address['suburb'];
    final village = address['village'] ?? address['neighbourhood'] ?? address['quarter'];
    final city = address['city'] ?? address['county'] ?? address['state_district'] ?? 'Bandung';

    final buffer = StringBuffer();
    if (road != null) buffer.write('$road, ');
    if (village != null && village != road) buffer.write('$village, ');
    buffer.write(city);

    return buffer.toString();
  }

  /// Categorize location based on OSM types
  static String _determineCategory(String type, String osmClass, String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('curug') ||
        lowerName.contains('kawah') ||
        lowerName.contains('situ') ||
        lowerName.contains('danau') ||
        lowerName.contains('gunung') ||
        lowerName.contains('hutan') ||
        lowerName.contains('tebing') ||
        lowerName.contains('kebun') ||
        lowerName.contains('bukit') ||
        type.contains('waterfall') ||
        type.contains('viewpoint') ||
        type.contains('nature_reserve') ||
        type.contains('forest')) {
      return 'Alam';
    }

    if (lowerName.contains('kuliner') ||
        lowerName.contains('warung') ||
        lowerName.contains('resto') ||
        lowerName.contains('kafe') ||
        lowerName.contains('cafe') ||
        lowerName.contains('kopi') ||
        lowerName.contains('batagor') ||
        lowerName.contains('bakso') ||
        lowerName.contains('nasi') ||
        osmClass.contains('amenity') &&
            (type.contains('restaurant') ||
                type.contains('cafe') ||
                type.contains('fast_food'))) {
      return 'Kuliner';
    }

    if (lowerName.contains('museum') ||
        lowerName.contains('gedung') ||
        lowerName.contains('masjid') ||
        lowerName.contains('candi') ||
        lowerName.contains('monumen') ||
        lowerName.contains('alun-alun') ||
        type.contains('museum') ||
        type.contains('historic') ||
        type.contains('monument') ||
        type.contains('place_of_worship')) {
      return 'Sejarah';
    }

    return 'Hiburan';
  }

  /// High quality image URL for category
  static String _getCategoryPlaceholderImage(String category) {
    switch (category) {
      case 'Alam':
        return 'https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=800&q=80';
      case 'Kuliner':
        return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80';
      case 'Sejarah':
        return 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b3/Bandung%2C_Museum_Geologi.jpg/960px-Bandung%2C_Museum_Geologi.jpg?utm_source=id.wikipedia.org&utm_campaign=api&utm_content=thumbnail';
      default:
        return 'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=800&q=80';
    }
  }
}
