import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:projek_akhir/services/routing_service.dart';

void main() {
  group('RoutingService & Vehicle Navigation Tests (Motor & Mobil)', () {
    late RoutingService routingService;

    setUp(() {
      routingService = RoutingService();
    });

    test('TransportMode properties and Google Maps travelmode mappings are correct', () {
      expect(TransportMode.motorcycle.googleMapsTravelMode, equals('two_wheeler'));
      expect(TransportMode.car.googleMapsTravelMode, equals('driving'));

      expect(TransportMode.motorcycle.label, equals('Motor'));
      expect(TransportMode.car.label, equals('Mobil'));

      expect(TransportMode.motorcycle.vehicleConstraintNote, contains('Non-tol'));
      expect(TransportMode.car.vehicleConstraintNote, contains('tol'));
    });

    test('TransportMode values contains exactly motor and mobil', () {
      expect(TransportMode.values.length, equals(2));
      expect(TransportMode.values, contains(TransportMode.motorcycle));
      expect(TransportMode.values, contains(TransportMode.car));
    });

    test('RouteDetails formats duration and distance gracefully', () {
      final shortRoute = RouteDetails(
        points: const [LatLng(-6.9175, 107.6098), LatLng(-6.9025, 107.6186)],
        distanceKm: 0.85,
        durationMinutes: 12,
        mode: TransportMode.motorcycle,
        summary: 'Rute motor non-tol',
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

    test('getRoute returns route coordinates and valid metrics for motor and mobil', () async {
      final start = const LatLng(-6.9175, 107.6098); // Alun-alun Bandung
      final dest = const LatLng(-6.9025, 107.6186); // Gedung Sate

      // Test motorcycle route
      final motoRoute = await routingService.getRoute(
        start: start,
        destination: dest,
        mode: TransportMode.motorcycle,
      );
      expect(motoRoute.mode, equals(TransportMode.motorcycle));
      expect(motoRoute.points.length, greaterThanOrEqualTo(2));
      expect(motoRoute.distanceKm, greaterThan(0));
      expect(motoRoute.durationMinutes, greaterThan(0));

      // Test car route
      final carRoute = await routingService.getRoute(
        start: start,
        destination: dest,
        mode: TransportMode.car,
      );
      expect(carRoute.mode, equals(TransportMode.car));
      expect(carRoute.points.length, greaterThanOrEqualTo(2));
      expect(carRoute.distanceKm, greaterThan(0));
      expect(carRoute.durationMinutes, greaterThan(0));
    });
  });
}
