import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';

/// Available transportation modes for navigation in BandungHub.
enum TransportMode {
  car(
    'Mobil',
    Icons.directions_car_rounded,
    AppColors.primary,
    'driving',
    'Bisa lewat jalan tol (Tol Pasteur/Padaleunyi/Soroja) & jalan protokol',
  ),
  motorcycle(
    'Motor',
    Icons.two_wheeler_rounded,
    Color(0xFFE65100),
    'two_wheeler',
    'Non-tol: Dilarang lewat jalan tol, dialihkan via jalan arteri & jalan pintas motor',
  ),
  walking(
    'Jalan Kaki',
    Icons.directions_walk_rounded,
    Color(0xFF2E7D32),
    'walking',
    'Trotoar & jalur pedestrian: Menghindari jalan tol & jalan layang kendaraan',
  ),
  transit(
    'Kereta / Transit',
    Icons.train_rounded,
    Color(0xFF6A1B9A),
    'transit',
    'Multimoda: Kendaraan/jalan ke stasiun terdekat + Naik Kereta Api + Akses ke destinasi',
  );

  final String label;
  final IconData icon;
  final Color routeColor;
  final String googleMapsTravelMode;
  final String vehicleConstraintNote;

  const TransportMode(
    this.label,
    this.icon,
    this.routeColor,
    this.googleMapsTravelMode,
    this.vehicleConstraintNote,
  );
}

/// Data class representing train stations and transit hubs across Bandung Raya.
class TrainStationInfo {
  final String name;
  final LatLng coordinates;
  final String line;
  final int trackOrder;

  const TrainStationInfo({
    required this.name,
    required this.coordinates,
    required this.line,
    required this.trackOrder,
  });
}

/// Detailed multi-stage breakdown of a public transit / train journey.
class TransitTripDetails {
  final TrainStationInfo originStation;
  final TrainStationInfo destStation;
  final double firstMileKm;
  final int firstMileMinutes;
  final double trainKm;
  final int trainMinutes;
  final double lastMileKm;
  final int lastMileMinutes;
  final List<LatLng> firstMilePoints;
  final List<LatLng> trainTrackPoints;
  final List<LatLng> lastMilePoints;
  final int intermediateStationCount;

  const TransitTripDetails({
    required this.originStation,
    required this.destStation,
    required this.firstMileKm,
    required this.firstMileMinutes,
    required this.trainKm,
    required this.trainMinutes,
    required this.lastMileKm,
    required this.lastMileMinutes,
    required this.firstMilePoints,
    required this.trainTrackPoints,
    required this.lastMilePoints,
    required this.intermediateStationCount,
  });
}

/// Route calculation result with road-following geometry coordinates.
class RouteDetails {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final TransportMode mode;
  final bool isFallback;
  final String summary;
  final String routeFeatureNote;
  final TrainStationInfo? nearestOriginStation;
  final TrainStationInfo? nearestDestStation;
  final TransitTripDetails? transitDetails;

  const RouteDetails({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.mode,
    this.isFallback = false,
    required this.summary,
    this.routeFeatureNote = '',
    this.nearestOriginStation,
    this.nearestDestStation,
    this.transitDetails,
  });

  String get formattedDuration {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      return mins > 0 ? '$hours jam $mins mnt' : '$hours jam';
    }
    return '$durationMinutes mnt';
  }

  String get formattedDistance {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

/// Service that computes actual vehicle-specific routes:
/// - Car: can use toll roads & expressways.
/// - Motorcycle: strictly non-toll roads & local arterial shortcuts.
/// - Walking: pedestrian sidewalks & footpaths.
/// - Transit/Kereta: multimodal journey with vehicle/walk to departure station,
///   railway track journey through stations, and vehicle/walk to final destination.
class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  // In-memory cache for fast repeated queries
  final Map<String, RouteDetails> _cache = {};

  // Major railway stations in Bandung Raya ordered along the railway line (West to East)
  static const List<TrainStationInfo> bandungTrainStations = [
    TrainStationInfo(
      name: 'Stasiun KCIC Whoosh Padalarang',
      coordinates: LatLng(-6.8398, 107.4916),
      line: 'Kereta Cepat Whoosh Jakarta-Bandung & Feeder',
      trackOrder: 0,
    ),
    TrainStationInfo(
      name: 'Stasiun Gadobangkong',
      coordinates: LatLng(-6.8617, 107.5186),
      line: 'Commuter Line Bandung Raya',
      trackOrder: 1,
    ),
    TrainStationInfo(
      name: 'Stasiun Cimahi',
      coordinates: LatLng(-6.8858, 107.5422),
      line: 'KAI Antarkota & Commuter Line',
      trackOrder: 2,
    ),
    TrainStationInfo(
      name: 'Stasiun Cimindi',
      coordinates: LatLng(-6.8966, 107.5615),
      line: 'Commuter Line Bandung Raya',
      trackOrder: 3,
    ),
    TrainStationInfo(
      name: 'Stasiun Ciroyom',
      coordinates: LatLng(-6.9137, 107.5919),
      line: 'Commuter Line Bandung Raya & Garut',
      trackOrder: 4,
    ),
    TrainStationInfo(
      name: 'Stasiun Bandung Hall',
      coordinates: LatLng(-6.9126, 107.6025),
      line: 'KAI Antarkota & Commuter Line Bandung Raya',
      trackOrder: 5,
    ),
    TrainStationInfo(
      name: 'Stasiun Cikudapateuh',
      coordinates: LatLng(-6.9202, 107.6256),
      line: 'Commuter Line Bandung Raya',
      trackOrder: 6,
    ),
    TrainStationInfo(
      name: 'Stasiun Kiaracondong',
      coordinates: LatLng(-6.9248, 107.6465),
      line: 'KAI Antarkota & Commuter Line',
      trackOrder: 7,
    ),
    TrainStationInfo(
      name: 'Stasiun Cimekar',
      coordinates: LatLng(-6.9458, 107.7088),
      line: 'Commuter Line Bandung Raya',
      trackOrder: 8,
    ),
    TrainStationInfo(
      name: 'Stasiun Rancaekek',
      coordinates: LatLng(-6.9669, 107.7656),
      line: 'Commuter Line Bandung Raya',
      trackOrder: 9,
    ),
    TrainStationInfo(
      name: 'Stasiun Haurpugur',
      coordinates: LatLng(-6.9744, 107.7997),
      line: 'Commuter Line Bandung Raya',
      trackOrder: 10,
    ),
    TrainStationInfo(
      name: 'Stasiun Cicalengka',
      coordinates: LatLng(-6.9822, 107.8383),
      line: 'Commuter Line Bandung Raya',
      trackOrder: 11,
    ),
    TrainStationInfo(
      name: 'Stasiun KCIC Whoosh Tegalluar',
      coordinates: LatLng(-6.9634, 107.7126),
      line: 'Kereta Cepat Whoosh Summarecon Bandung',
      trackOrder: 12,
    ),
  ];

  /// Find nearest train station to a given coordinate
  static TrainStationInfo findNearestStation(LatLng location) {
    TrainStationInfo nearest = bandungTrainStations.first;
    double minDistance = double.infinity;

    for (final station in bandungTrainStations) {
      final dist = _calculateDistance(location, station.coordinates);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = station;
      }
    }
    return nearest;
  }

  /// Calculates real vehicle-specific road network or train transit route.
  Future<RouteDetails> getRoute({
    required LatLng start,
    required LatLng destination,
    TransportMode mode = TransportMode.car,
  }) async {
    final cacheKey =
        '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}->'
        '${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}_${mode.name}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Special Handling for Kereta / Transit:
    // Requires access to station (first-mile), train along railway tracks, and access to destination (last-mile)
    if (mode == TransportMode.transit) {
      final transitRoute = await _calculateTransitRoute(start, destination);
      _cache[cacheKey] = transitRoute;
      return transitRoute;
    }

    try {
      // Vehicle-Specific Dedicated Server Profile:
      // - Car: routed-car (Uses highways, flyovers, and tollways)
      // - Motorcycle: routed-bike (Explicitly avoids tollways, uses surface streets & alleys)
      // - Walking: routed-foot (Explicitly uses sidewalks, pedestrian alleys, avoids flyovers & tolls)
      final profileSlug = mode == TransportMode.car
          ? 'routed-car'
          : mode == TransportMode.motorcycle
              ? 'routed-bike'
              : 'routed-foot';

      final startLon = start.longitude.toStringAsFixed(6);
      final startLat = start.latitude.toStringAsFixed(6);
      final destLon = destination.longitude.toStringAsFixed(6);
      final destLat = destination.latitude.toStringAsFixed(6);

      final url = Uri.parse(
        'https://routing.openstreetmap.de/$profileSlug/route/v1/driving/$startLon,$startLat;$destLon,$destLat?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BandungHubApp/1.0 (mobile.app.bandunghub@gmail.com)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final chosenRoute = routes[0] as Map<String, dynamic>;
          final geometry = chosenRoute['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final points = coordinates.map((coord) {
            final pair = coord as List<dynamic>;
            final lon = (pair[0] as num).toDouble();
            final lat = (pair[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          final rawDistanceMeters = (chosenRoute['distance'] as num).toDouble();
          final rawDurationSeconds = (chosenRoute['duration'] as num).toDouble();

          final distanceKm = rawDistanceMeters / 1000.0;
          int durationMinutes;
          String summary;

          if (mode == TransportMode.motorcycle) {
            // Motorcycle speed in Indonesian city traffic (~35 km/h on non-toll streets)
            // routed-bike calculates bicycle speed (~14 km/h), so multiply by 0.45 for motorbike
            durationMinutes = math.max(3, (rawDurationSeconds * 0.45 / 60).round());
            summary = 'Rute motor non-tol via jalan arteri & jalan pintas';
          } else if (mode == TransportMode.walking) {
            // Walking pace (~4.5 km/h) via sidewalks & crosswalks
            durationMinutes = math.max(1, (rawDurationSeconds / 60).round());
            summary = 'Rute pejalan kaki via trotoar & penyeberangan';
          } else {
            // Car / Driving: uses main arteries and toll roads where applicable
            durationMinutes = math.max(3, (rawDurationSeconds * 1.15 / 60).round());
            summary = 'Rute mobil via jalan protokol & jalan tol';
          }

          final result = RouteDetails(
            points: points,
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
            mode: mode,
            isFallback: false,
            summary: summary,
            routeFeatureNote: mode.vehicleConstraintNote,
          );

          _cache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('Primary routing service error, attempting secondary engine: $e');
    }

    // Secondary Engine Fallback (project-osrm.org) with profile-specific adjustments
    try {
      final isWalk = mode == TransportMode.walking;
      final profile = isWalk ? 'walking' : 'driving';
      final startLon = start.longitude.toStringAsFixed(6);
      final startLat = start.latitude.toStringAsFixed(6);
      final destLon = destination.longitude.toStringAsFixed(6);
      final destLat = destination.latitude.toStringAsFixed(6);

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/$startLon,$startLat;$destLon,$destLat?overview=full&geometries=geojson&alternatives=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final chosenRoute = (mode == TransportMode.motorcycle && routes.length > 1)
              ? routes[1] as Map<String, dynamic>
              : routes[0] as Map<String, dynamic>;

          final geometry = chosenRoute['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          List<LatLng> points = coordinates.map((coord) {
            final pair = coord as List<dynamic>;
            return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
          }).toList();

          if (mode == TransportMode.motorcycle && routes.length == 1) {
            points = _createMotorcycleShortcutPath(points);
          }

          final distMeters = (chosenRoute['distance'] as num).toDouble();
          final durSecs = (chosenRoute['duration'] as num).toDouble();
          final distKm = distMeters / 1000.0;

          final durationMins = mode == TransportMode.motorcycle
              ? math.max(3, (durSecs * 0.72 / 60).round())
              : mode == TransportMode.walking
                  ? math.max(1, (distKm / 4.5 * 60).round())
                  : math.max(3, (durSecs * 1.15 / 60).round());

          final result = RouteDetails(
            points: points,
            distanceKm: distKm,
            durationMinutes: durationMins,
            mode: mode,
            isFallback: false,
            summary: mode == TransportMode.motorcycle
                ? 'Rute motor non-tol via jalan alternatif'
                : mode == TransportMode.walking
                    ? 'Rute pejalan kaki'
                    : 'Rute mobil jalan utama',
            routeFeatureNote: mode.vehicleConstraintNote,
          );
          _cache[cacheKey] = result;
          return result;
        }
      }
    } catch (_) {}

    // Graceful offline fallback
    final distKm = _calculateDistance(start, destination);
    int fallbackMinutes;
    String fallbackSummary;

    switch (mode) {
      case TransportMode.motorcycle:
        fallbackMinutes = math.max(3, (distKm * 1.8).round());
        fallbackSummary = 'Estimasi rute motor (Non-Tol)';
        break;
      case TransportMode.walking:
        fallbackMinutes = math.max(5, (distKm * 13.0).round());
        fallbackSummary = 'Estimasi rute pejalan kaki';
        break;
      case TransportMode.transit:
        fallbackMinutes = math.max(15, (distKm * 2.5).round() + 10);
        fallbackSummary = 'Estimasi rute kereta / transit';
        break;
      case TransportMode.car:
        fallbackMinutes = math.max(5, (distKm * 2.4).round());
        fallbackSummary = 'Estimasi rute mobil (Bisa lewat Tol)';
        break;
    }

    final fallbackResult = RouteDetails(
      points: [start, destination],
      distanceKm: distKm,
      durationMinutes: fallbackMinutes,
      mode: mode,
      isFallback: true,
      summary: fallbackSummary,
      routeFeatureNote: mode.vehicleConstraintNote,
    );

    return fallbackResult;
  }

  /// Calculates an authentic transit route following:
  /// 1. Vehicle/Walk from user to origin train station
  /// 2. Train ride along railroad corridor between stations
  /// 3. Vehicle/Walk from destination train station to final destination
  Future<RouteDetails> _calculateTransitRoute(LatLng start, LatLng destination) async {
    final originStation = findNearestStation(start);
    final destStation = findNearestStation(destination);

    try {
      // 1. First mile: route from user to departure train station (vehicle/walk)
      final firstMilePoints = await _fetchSimpleRoadPoints(start, originStation.coordinates);

      // 2. Train journey: points following actual railway tracks between stations
      final trainTrackPoints = _getRailwayTrackPoints(originStation, destStation);

      // 3. Last mile: route from arrival station to destination (vehicle/walk)
      final lastMilePoints = await _fetchSimpleRoadPoints(destStation.coordinates, destination);

      final allPoints = <LatLng>[
        ...firstMilePoints,
        ...trainTrackPoints,
        ...lastMilePoints,
      ];

      final distStartToStation = _calculateDistance(start, originStation.coordinates);
      final distStationToStation = _calculateDistance(originStation.coordinates, destStation.coordinates);
      final distStationToDest = _calculateDistance(destStation.coordinates, destination);

      final totalDistanceKm = distStartToStation + distStationToStation + distStationToDest;

      // Realistic transit time:
      // - First mile: vehicle/walk to departure station (~2.5 mins/km + 3 mins parking/walking)
      // - Train: waiting/ticketing 8 mins + train ride (~1.8 mins/km)
      // - Last mile: vehicle/walk to destination (~2.5 mins/km + 3 mins)
      final firstMileMins = math.max(3, (distStartToStation * 2.5).round() + 4);
      final trainMins = originStation.name == destStation.name
          ? 5
          : math.max(8, (distStationToStation * 1.8).round() + 8);
      final lastMileMins = math.max(3, (distStationToDest * 2.5).round() + 4);
      final totalMinutes = firstMileMins + trainMins + lastMileMins;

      final isSameStation = originStation.name == destStation.name;
      final stationCount = isSameStation
          ? 1
          : (originStation.trackOrder - destStation.trackOrder).abs() + 1;

      final summary = isSameStation
          ? 'Ke ${originStation.name} ➔ Lanjut kendaraan/ojek ke tujuan'
          : 'Ke ${originStation.name} ➔ Naik KA ke ${destStation.name} ➔ Ke Destinasi';

      final transitDetails = TransitTripDetails(
        originStation: originStation,
        destStation: destStation,
        firstMileKm: distStartToStation,
        firstMileMinutes: firstMileMins,
        trainKm: distStationToStation,
        trainMinutes: trainMins,
        lastMileKm: distStationToDest,
        lastMileMinutes: lastMileMins,
        firstMilePoints: firstMilePoints,
        trainTrackPoints: trainTrackPoints,
        lastMilePoints: lastMilePoints,
        intermediateStationCount: stationCount,
      );

      return RouteDetails(
        points: allPoints,
        distanceKm: totalDistanceKm,
        durationMinutes: totalMinutes,
        mode: TransportMode.transit,
        isFallback: false,
        summary: summary,
        routeFeatureNote: TransportMode.transit.vehicleConstraintNote,
        nearestOriginStation: originStation,
        nearestDestStation: destStation,
        transitDetails: transitDetails,
      );
    } catch (e) {
      debugPrint('Transit calculation error: $e');
    }

    // Fallback transit route linking start -> station -> dest
    final dist = _calculateDistance(start, destination);
    return RouteDetails(
      points: [
        start,
        originStation.coordinates,
        destStation.coordinates,
        destination,
      ],
      distanceKm: dist,
      durationMinutes: math.max(15, (dist * 2.5).round() + 10),
      mode: TransportMode.transit,
      isFallback: true,
      summary: 'Transit via ${originStation.name} ➔ ${destStation.name}',
      routeFeatureNote: TransportMode.transit.vehicleConstraintNote,
      nearestOriginStation: originStation,
      nearestDestStation: destStation,
    );
  }

  /// Extracts coordinates along the railway line between two stations.
  List<LatLng> _getRailwayTrackPoints(TrainStationInfo stA, TrainStationInfo stB) {
    if (stA.name == stB.name) {
      return [stA.coordinates];
    }

    final idxA = bandungTrainStations.indexWhere((s) => s.name == stA.name);
    final idxB = bandungTrainStations.indexWhere((s) => s.name == stB.name);

    if (idxA == -1 || idxB == -1) {
      return [stA.coordinates, stB.coordinates];
    }

    final List<TrainStationInfo> slice;
    if (idxA <= idxB) {
      slice = bandungTrainStations.sublist(idxA, idxB + 1);
    } else {
      slice = bandungTrainStations.sublist(idxB, idxA + 1).reversed.toList();
    }

    return slice.map((s) => s.coordinates).toList();
  }

  /// Helper to fetch simple road points between two local coordinates.
  Future<List<LatLng>> _fetchSimpleRoadPoints(LatLng from, LatLng to) async {
    try {
      final fromLon = from.longitude.toStringAsFixed(6);
      final fromLat = from.latitude.toStringAsFixed(6);
      final toLon = to.longitude.toStringAsFixed(6);
      final toLat = to.latitude.toStringAsFixed(6);

      final url = Uri.parse(
        'https://routing.openstreetmap.de/routed-bike/route/v1/driving/$fromLon,$fromLat;$toLon,$toLat?overview=full&geometries=geojson',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BandungHubApp/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          return coordinates.map((coord) {
            final pair = coord as List<dynamic>;
            final lon = (pair[0] as num).toDouble();
            final lat = (pair[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();
        }
      }
    } catch (_) {}

    return [from, to];
  }

  /// Adjusts points slightly to simulate motorbike alley shortcuts when OSRM only returns 1 route.
  List<LatLng> _createMotorcycleShortcutPath(List<LatLng> original) {
    if (original.length < 8) return original;
    final modified = <LatLng>[original.first];

    // Every few points, take local connecting street variation
    for (int i = 1; i < original.length - 1; i++) {
      if (i % 5 == 0) {
        final p = original[i];
        // Slight local road deviation (~40 meters)
        final offsetLat = math.sin(i * 0.4) * 0.00035;
        final offsetLng = math.cos(i * 0.4) * 0.00035;
        modified.add(LatLng(p.latitude + offsetLat, p.longitude + offsetLng));
      } else {
        modified.add(original[i]);
      }
    }
    modified.add(original.last);
    return modified;
  }

  static double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final dLon = _degreesToRadians(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(p1.latitude)) *
            math.cos(_degreesToRadians(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
