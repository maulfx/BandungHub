import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/dummy/dummy_destinations.dart';
import '../models/destination.dart';

class GooglePlacesService {
  static final GooglePlacesService _instance =
      GooglePlacesService._internal();
  factory GooglePlacesService() => _instance;
  GooglePlacesService._internal();

  static const String _keyGoogleMapsApiKey = 'bandunghub_google_maps_api_key';

  // Bandung center and boundary restrictions
  static const double bandungCenterLat = AppConstants.bandungLatitude; // -6.917464
  static const double bandungCenterLng = AppConstants.bandungLongitude; // 107.619123
  static const int bandungSearchRadiusMeters = 32000; // 32 km radius

  // Strict Bounding Box for Bandung Raya (Kota Bandung, Cimahi, Kab Bandung, Bandung Barat)
  static const double minLat = -7.32;
  static const double maxLat = -6.65;
  static const double minLng = 107.30;
  static const double maxLng = 107.95;

  /// Check whether coordinates are strictly within the Bandung metropolitan area
  static bool isWithinBandung(double lat, double lng) {
    return lat >= minLat &&
        lat <= maxLat &&
        lng >= minLng &&
        lng <= maxLng;
  }

  // API Key management
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGoogleMapsApiKey);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoogleMapsApiKey, apiKey.trim());
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGoogleMapsApiKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Search tourist destinations and points of interest across the entire Bandung Map
  Future<List<Destination>> searchBandungDestinations(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return DummyDestinations.list
          .where((d) => isWithinBandung(d.latitude, d.longitude))
          .toList();
    }

    // 1. Gather local matching destinations first
    final localMatches = _searchLocalBandungFallback(cleanQuery);

    // 2. Try Google Places API if user has configured an API key
    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final googleResults = await _fetchFromGooglePlaces(cleanQuery, apiKey);
        if (googleResults.isNotEmpty) {
          return _mergeDestinations(localMatches, googleResults);
        }
      } catch (e) {
        debugPrint('Google Places API search error: $e');
      }
    }

    // 3. Live Maps Search via OpenStreetMap Nominatim (Free, No Key, covers ALL Bandung)
    try {
      final mapResults = await _fetchFromOpenStreetMap(cleanQuery);
      if (mapResults.isNotEmpty) {
        return _mergeDestinations(localMatches, mapResults);
      }
    } catch (e) {
      debugPrint('OpenStreetMap search error: $e');
    }

    return localMatches;
  }

  /// Query Google Places Text Search API with location restriction & photos
  Future<List<Destination>> _fetchFromGooglePlaces(
    String query,
    String apiKey,
  ) async {
    final searchQuery = query.toLowerCase().contains('bandung')
        ? query
        : '$query Bandung';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json?'
      'query=${Uri.encodeComponent(searchQuery)}'
      '&location=$bandungCenterLat,$bandungCenterLng'
      '&radius=$bandungSearchRadiusMeters'
      '&region=id'
      '&language=id'
      '&key=$apiKey',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      return [];
    }

    final results = data['results'] as List<dynamic>? ?? [];
    final List<Destination> destinations = [];

    for (final item in results) {
      final geometry = item['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) continue;

      final double lat = (location['lat'] as num).toDouble();
      final double lng = (location['lng'] as num).toDouble();

      if (!isWithinBandung(lat, lng)) continue;

      final placeId = item['place_id'] as String? ?? 'gp_${item['name']}';
      final name = item['name'] as String? ?? 'Destinasi Bandung';
      final address =
          item['formatted_address'] as String? ?? 'Bandung, Jawa Barat';
      final rating = (item['rating'] as num?)?.toDouble() ?? 4.6;
      final reviewCount = (item['user_ratings_total'] as num?)?.toInt() ?? 50;

      String imageUrl =
          'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?auto=format&fit=crop&w=800&q=80';
      final photos = item['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) {
        final photoRef = photos[0]['photo_reference'] as String?;
        if (photoRef != null && photoRef.isNotEmpty) {
          imageUrl =
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$photoRef&key=$apiKey';
        }
      }

      final types = (item['types'] as List<dynamic>?)?.cast<String>() ?? [];
      final category = _mapTypesToCategory(types);

      destinations.add(
        Destination(
          id: placeId,
          name: name,
          description:
              '$name adalah salah satu destinasi dan lokasi populer di area Bandung yang terdaftar di Google Maps dengan rating $rating ⭐.',
          category: category,
          address: address,
          latitude: lat,
          longitude: lng,
          estimatedPrice: category == 'Kuliner' ? 35000.0 : 25000.0,
          operationalHours: 'Setiap Hari: 08.00 - 18.00 WIB',
          imageUrl: imageUrl,
          rating: rating,
          reviewCount: reviewCount,
          isVerified: true,
          tags: ['Google Maps', 'Bandung', category],
        ),
      );
    }

    return destinations;
  }

  /// Live OpenStreetMap Nominatim search strictly bounded to Bandung Raya
  Future<List<Destination>> _fetchFromOpenStreetMap(String query) async {
    final cleanQuery = query.toLowerCase().contains('bandung')
        ? query
        : '$query Bandung';

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?'
      'q=${Uri.encodeComponent(cleanQuery)}'
      '&format=json'
      '&addressdetails=1'
      '&bounded=1'
      '&viewbox=$minLng,$maxLat,$maxLng,$minLat'
      '&limit=15',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'BandungHubApp/1.0 (Mobile Android Bandung)'},
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    final List<Destination> results = [];

    for (final item in list) {
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      if (!isWithinBandung(lat, lon)) continue;

      final displayName = item['display_name'] as String? ?? 'Lokasi Bandung';
      final parts = displayName.split(',');
      final name = item['name'] as String? ??
          (parts.isNotEmpty ? parts[0].trim() : 'Lokasi Bandung');
      final address = parts.length > 1
          ? parts.sublist(1).take(3).join(',').trim()
          : displayName;

      final type = item['type'] as String? ?? '';
      final category = _mapOsmTypeToCategory(type, name);

      results.add(
        Destination(
          id: 'osm_${item['place_id'] ?? results.length}',
          name: name,
          description:
              '$name merupakan lokasi di peta Bandung Raya dengan koordinat akurat ($lat, $lon) dan akses rute navigasi langsung.',
          category: category,
          address: address.isNotEmpty ? address : 'Bandung, Jawa Barat',
          latitude: lat,
          longitude: lon,
          estimatedPrice: category == 'Kuliner'
              ? 30000.0
              : (category == 'Alam' ? 20000.0 : 15000.0),
          operationalHours: 'Buka: 08.00 - 21.00 WIB',
          imageUrl: _getRelevantImage(category, name),
          rating: 4.6,
          reviewCount: 95,
          isVerified: true,
          tags: ['Peta Bandung', 'Maps', category],
        ),
      );
    }

    return results;
  }

  /// Deduplicate and merge results by matching names
  List<Destination> _mergeDestinations(
    List<Destination> primary,
    List<Destination> secondary,
  ) {
    final Map<String, Destination> map = {};
    for (final d in primary) {
      map[d.name.toLowerCase().trim()] = d;
    }
    for (final s in secondary) {
      final key = s.name.toLowerCase().trim();
      if (!map.containsKey(key)) {
        map[key] = s;
      }
    }
    return map.values.toList();
  }

  /// Map OSM types or name keywords to BandungHub categories
  String _mapOsmTypeToCategory(String type, String name) {
    final lower = '$type ${name.toLowerCase()}';
    if (lower.contains('kopi') ||
        lower.contains('cafe') ||
        lower.contains('restaurant') ||
        lower.contains('bakso') ||
        lower.contains('kuliner') ||
        lower.contains('warung') ||
        lower.contains('food')) {
      return 'Kuliner';
    }
    if (lower.contains('curug') ||
        lower.contains('kawah') ||
        lower.contains('gunung') ||
        lower.contains('park') ||
        lower.contains('taman') ||
        lower.contains('hutan') ||
        lower.contains('danau') ||
        lower.contains('nature') ||
        lower.contains('tebing')) {
      return 'Alam';
    }
    if (lower.contains('museum') ||
        lower.contains('gedung') ||
        lower.contains('sejarah') ||
        lower.contains('monumen') ||
        lower.contains('heritage') ||
        lower.contains('masjid')) {
      return 'Sejarah';
    }
    if (lower.contains('mall') ||
        lower.contains('bioskop') ||
        lower.contains('cinema') ||
        lower.contains('theater') ||
        lower.contains('game') ||
        lower.contains('hiburan')) {
      return 'Hiburan';
    }
    return 'Keluarga';
  }

  String _mapTypesToCategory(List<String> types) {
    if (types.any((t) => [
          'park',
          'campground',
          'natural_feature',
          'rv_park',
        ].contains(t))) {
      return 'Alam';
    }
    if (types.any((t) => [
          'restaurant',
          'food',
          'cafe',
          'bakery',
          'meal_takeaway',
        ].contains(t))) {
      return 'Kuliner';
    }
    if (types.any((t) => [
          'museum',
          'place_of_worship',
          'church',
          'hindu_temple',
          'mosque',
        ].contains(t))) {
      return 'Sejarah';
    }
    if (types.any((t) => [
          'amusement_park',
          'aquarium',
          'bowling_alley',
          'movie_theater',
          'night_club',
        ].contains(t))) {
      return 'Hiburan';
    }
    return 'Keluarga';
  }

  String _getRelevantImage(String category, String name) {
    final n = name.toLowerCase();
    if (n.contains('kopi') || n.contains('cafe')) {
      return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80';
    }
    if (n.contains('curug') || n.contains('air terjun')) {
      return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80';
    }
    if (n.contains('taman') || n.contains('park')) {
      return 'https://images.unsplash.com/photo-1513889961551-628c1e5e2ee9?auto=format&fit=crop&w=800&q=80';
    }
    if (n.contains('museum') || n.contains('sejarah')) {
      return 'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?auto=format&fit=crop&w=800&q=80';
    }
    if (category == 'Kuliner') {
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80';
    }
    if (category == 'Alam') {
      return 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?auto=format&fit=crop&w=800&q=80';
  }

  /// Filter local verified destinations if offline
  List<Destination> _searchLocalBandungFallback(String query) {
    if (query.isEmpty) {
      return DummyDestinations.list
          .where((d) => isWithinBandung(d.latitude, d.longitude))
          .toList();
    }
    final q = query.toLowerCase();
    return DummyDestinations.list.where((d) {
      if (!isWithinBandung(d.latitude, d.longitude)) return false;
      return d.name.toLowerCase().contains(q) ||
          d.address.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q) ||
          d.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }
}
