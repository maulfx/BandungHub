import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapService {
  // Tile Provider settings conforming to OSM usage policy
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.example.projek_akhir';
  static const String osmAttribution = '© OpenStreetMap contributors';

  // Opens external navigation app (Google Maps, Waze, etc.)
  static Future<bool> openExternalMapNavigation({
    required double latitude,
    required double longitude,
    required String destinationName,
  }) async {
    // 1. Google Maps direct URL intent
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    // 2. Generic geo scheme
    final geoUrl = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(destinationName)})',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunchUrl(geoUrl)) {
        return await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint(
          'Could not launch external map for coordinates: $latitude, $longitude',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error launching map navigation: $e');
      return false;
    }
  }
}
