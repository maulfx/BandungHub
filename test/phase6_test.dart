import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:projek_akhir/data/dummy/dummy_destinations.dart';
import 'package:projek_akhir/features/map/screens/destination_map_screen.dart';
import 'package:projek_akhir/services/location_service.dart';
import 'package:projek_akhir/services/map_service.dart';

void main() {
  group('Phase 6 - LocationService Unit Tests', () {
    final locationService = LocationService();

    test(
      'calculateDistanceInKm calculates realistic straight-line distances',
      () {
        // Gedung Sate to Alun-alun Bandung (~2.5 km)
        const gedungSate = LatLng(-6.902484, 107.618684);
        const alunAlun = LatLng(-6.921857, 107.606950);

        final distance = locationService.calculateDistanceInKm(
          gedungSate,
          alunAlun,
        );
        expect(distance, greaterThan(2.0));
        expect(distance, lessThan(3.5));
      },
    );

    test('calculateDistanceInKm returns 0 for identical coordinates', () {
      const point = LatLng(-6.902484, 107.618684);
      final distance = locationService.calculateDistanceInKm(point, point);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('formatDistance properly formats meters and kilometers', () {
      expect(locationService.formatDistance(0.45), '450 m');
      expect(locationService.formatDistance(0.05), '50 m');
      expect(locationService.formatDistance(1.234), '1.2 km');
      expect(locationService.formatDistance(12.5), '12.5 km');
    });

    test(
      'getNearestDestinations returns list sorted ascending by distance',
      () {
        const bandungCenter = LocationService.defaultBandungCenter;
        final nearestList = locationService.getNearestDestinations(
          userLocation: bandungCenter,
          destinations: DummyDestinations.list,
        );

        expect(nearestList.isNotEmpty, isTrue);
        expect(nearestList.length, DummyDestinations.list.length);

        // Verify ascending order
        for (int i = 0; i < nearestList.length - 1; i++) {
          expect(
            nearestList[i].value,
            lessThanOrEqualTo(nearestList[i + 1].value),
            reason: 'Item at $i should be closer or equal to item at ${i + 1}',
          );
        }
      },
    );
  });

  group('Phase 6 - MapService Unit Tests', () {
    test('MapService provides valid OSM tile URL and user agent', () {
      expect(MapService.osmTileUrl, contains('tile.openstreetmap.org'));
      expect(MapService.userAgentPackageName.isNotEmpty, isTrue);
      expect(MapService.osmAttribution, contains('OpenStreetMap'));
    });

    test('MapService restricts bounds strictly to Bandung Raya', () {
      final bounds = MapService.bandungBounds;
      // Valid Bandung coordinates
      expect(bounds.contains(const LatLng(-6.917464, 107.619123)), isTrue); // Alun-alun
      expect(bounds.contains(const LatLng(-6.902476, 107.618774)), isTrue); // Gedung Sate
      expect(bounds.contains(const LatLng(-6.759637, 107.609780)), isTrue); // Tangkuban Parahu
      expect(bounds.contains(const LatLng(-7.166203, 107.402123)), isTrue); // Kawah Putih

      // Outside Bandung coordinates
      expect(bounds.contains(const LatLng(-6.2088, 106.8456)), isFalse); // Monas Jakarta
      expect(bounds.contains(const LatLng(-8.4095, 115.1889)), isFalse); // Bali
      expect(bounds.contains(const LatLng(-7.7956, 110.3695)), isFalse); // Malioboro Yogyakarta
      expect(bounds.contains(const LatLng(-7.2575, 112.7521)), isFalse); // Surabaya
    });
  });

  group('Phase 6 - DestinationMapScreen Widget Tests', () {
    testWidgets(
      'DestinationMapScreen renders FlutterMap, controls and attribution',
      (tester) async {
        // Set test screen size large enough for map
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(home: DestinationMapScreen()),
        );
        await tester.pump();

        // Verify Title and AppBar
        expect(find.text('Peta Wisata Bandung'), findsOneWidget);

        // Verify FlutterMap exists
        expect(find.byType(FlutterMap), findsOneWidget);

        // Verify Attribution
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

        // Verify Zoom buttons and Center buttons
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.remove), findsOneWidget);
        expect(find.byTooltip('Pusat Kota Bandung'), findsOneWidget);
        expect(find.byTooltip('Lokasi Saya'), findsOneWidget);

        // Verify category filter chips
        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Alam'), findsOneWidget);
      },
    );

    testWidgets('DestinationMapScreen opens with initialDestination', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final destination = DummyDestinations.list.first;

      await tester.pumpWidget(
        MaterialApp(
          home: DestinationMapScreen(initialDestination: destination),
        ),
      );
      await tester.pump();

      // Card for initialDestination should be displayed
      expect(find.text(destination.name), findsOneWidget);
      expect(find.text('Buka Detail'), findsOneWidget);
      expect(find.text('Navigasi Peta'), findsOneWidget);
    });
  });
}
