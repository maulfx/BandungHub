import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:projek_akhir/services/routing_service.dart';

void main() {
  group('RoutingService & Multi-Modal Transport Tests', () {
    late RoutingService routingService;

    setUp(() {
      routingService = RoutingService();
    });

    test('TransportMode properties and Google Maps travelmode mappings are correct', () {
      expect(TransportMode.car.googleMapsTravelMode, equals('driving'));
      expect(TransportMode.motorcycle.googleMapsTravelMode, equals('two_wheeler'));
      expect(TransportMode.walking.googleMapsTravelMode, equals('walking'));
      expect(TransportMode.transit.googleMapsTravelMode, equals('transit'));

      expect(TransportMode.car.label, equals('Mobil'));
      expect(TransportMode.motorcycle.label, equals('Motor'));
      expect(TransportMode.walking.label, equals('Jalan Kaki'));
      expect(TransportMode.transit.label, equals('Kereta / Transit'));

      expect(TransportMode.car.vehicleConstraintNote, contains('tol'));
      expect(TransportMode.motorcycle.vehicleConstraintNote, contains('Non-tol'));
      expect(TransportMode.walking.vehicleConstraintNote, contains('Trotoar'));
      expect(TransportMode.transit.vehicleConstraintNote, contains('Multimoda'));
    });

    test('findNearestStation correctly identifies Bandung train stations', () {
      // Coordinate near Alun-Alun / Stasiun Bandung (-6.9126, 107.6025)
      final nearBandungStation = const LatLng(-6.9150, 107.6040);
      final station = RoutingService.findNearestStation(nearBandungStation);
      expect(station.name, contains('Bandung Hall'));

      // Coordinate in Cimahi
      final nearCimahi = const LatLng(-6.8860, 107.5430);
      final cimahiStation = RoutingService.findNearestStation(nearCimahi);
      expect(cimahiStation.name, contains('Cimahi'));

      // Coordinate in Padalarang near Whoosh
      final nearPadalarang = const LatLng(-6.8400, 107.4920);
      final whooshStation = RoutingService.findNearestStation(nearPadalarang);
      expect(whooshStation.name, contains('Whoosh Padalarang'));
    });

    test('RouteDetails formats duration and distance gracefully', () {
      final shortRoute = RouteDetails(
        points: const [LatLng(-6.9175, 107.6098), LatLng(-6.9025, 107.6186)],
        distanceKm: 0.85,
        durationMinutes: 12,
        mode: TransportMode.walking,
        summary: 'Rute trotoar',
      );
      expect(shortRoute.formattedDistance, equals('850 m'));
      expect(shortRoute.formattedDuration, equals('12 mnt'));

      final longRoute = RouteDetails(
        points: const [LatLng(-6.9175, 107.6098), LatLng(-6.8330, 107.5950)],
        distanceKm: 14.2,
        durationMinutes: 75,
        mode: TransportMode.car,
        summary: 'Rute mobil',
      );
      expect(longRoute.formattedDistance, equals('14.2 km'));
      expect(longRoute.formattedDuration, equals('1 jam 15 mnt'));
    });

    test('getRoute returns route coordinates and valid metrics for all modes', () async {
      final start = const LatLng(-6.9175, 107.6098); // Alun-alun Bandung
      final dest = const LatLng(-6.9025, 107.6186); // Gedung Sate

      // Test driving route
      final carRoute = await routingService.getRoute(
        start: start,
        destination: dest,
        mode: TransportMode.car,
      );
      expect(carRoute.points.length, greaterThanOrEqualTo(2));
      expect(carRoute.distanceKm, greaterThan(0));
      expect(carRoute.durationMinutes, greaterThan(0));
      expect(carRoute.mode, equals(TransportMode.car));

      // Test motorcycle route
      final motoRoute = await routingService.getRoute(
        start: start,
        destination: dest,
        mode: TransportMode.motorcycle,
      );
      expect(motoRoute.mode, equals(TransportMode.motorcycle));
      expect(motoRoute.durationMinutes, greaterThan(0));

      // Test transit route with nearest stations attached
      final transitRoute = await routingService.getRoute(
        start: start,
        destination: dest,
        mode: TransportMode.transit,
      );
      expect(transitRoute.mode, equals(TransportMode.transit));
      expect(transitRoute.nearestOriginStation, isNotNull);
      expect(transitRoute.nearestDestStation, isNotNull);
      expect(transitRoute.transitDetails, isNotNull);
      expect(transitRoute.transitDetails!.firstMilePoints, isNotEmpty);
      expect(transitRoute.transitDetails!.trainTrackPoints, isNotEmpty);
      expect(transitRoute.transitDetails!.lastMilePoints, isNotEmpty);
    });
  });
}
