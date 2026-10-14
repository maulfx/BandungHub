import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/destination.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Distance _distanceCalculator = const Distance();

  // Bandung City Center default coordinates
  static const LatLng defaultBandungCenter = LatLng(-6.917464, 107.619123);

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // Calculate straight-line geographic distance in Kilometers
  double calculateDistanceInKm(LatLng start, LatLng end) {
    return _distanceCalculator.as(LengthUnit.Kilometer, start, end);
  }

  // Format distance cleanly
  String formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  // Sort and pair destinations with straight-line distance
  List<MapEntry<Destination, double>> getNearestDestinations({
    required LatLng userLocation,
    required List<Destination> destinations,
  }) {
    final list = destinations.map((d) {
      final dist = calculateDistanceInKm(userLocation, d.coordinates);
      return MapEntry(d, dist);
    }).toList();

    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }
}
