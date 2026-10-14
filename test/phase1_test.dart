import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/core/constants/app_constants.dart';
import 'package:projek_akhir/data/dummy/dummy_destinations.dart';
import 'package:projek_akhir/models/destination.dart';

void main() {
  group('Phase 1 - BandungHub Core & Data Tests', () {
    test('App constants should have correct app name and coordinates', () {
      expect(AppConstants.appName, 'BandungHub');
      expect(AppConstants.bandungLatitude, closeTo(-6.917, 0.01));
      expect(AppConstants.bandungLongitude, closeTo(107.619, 0.01));
      expect(AppConstants.categories, contains('Alam'));
      expect(AppConstants.categories, contains('Kuliner'));
      expect(AppConstants.categories, contains('Sejarah'));
    });

    test(
      'Initial destination list should contain verified and mock destinations',
      () {
        final list = DummyDestinations.list;
        expect(list.isNotEmpty, true);

        // Check verified destinations
        final verified = list.where((d) => d.isVerified).toList();
        final unverified = list.where((d) => !d.isVerified).toList();

        expect(verified.isNotEmpty, true);
        expect(
          unverified.isNotEmpty,
          true,
        ); // Differentiates dummy from verified

        // Check destination attributes
        for (final dest in list) {
          expect(dest.id.isNotEmpty, true);
          expect(dest.name.isNotEmpty, true);
          expect(dest.latitude, isNotNull);
          expect(dest.longitude, isNotNull);
          expect(dest.category.isNotEmpty, true);
          expect(dest.coordinates.latitude, equals(dest.latitude));
          expect(dest.coordinates.longitude, equals(dest.longitude));
        }
      },
    );

    test(
      'Destination model serialization toMap and fromMap works correctly',
      () {
        const sample = Destination(
          id: 'test_1',
          name: 'Gedung Sate',
          description: 'Kantor Gubernur',
          category: 'Sejarah',
          address: 'Jl. Diponegoro',
          latitude: -6.9024,
          longitude: 107.6187,
          estimatedPrice: 5000.0,
          operationalHours: '09.00 - 16.00',
          imageUrl: 'https://example.com/img.jpg',
          rating: 4.8,
          reviewCount: 1500,
          isVerified: true,
          tags: ['Heritage', 'Museum'],
        );

        final map = sample.toMap();
        final fromMap = Destination.fromMap(map);

        expect(fromMap.id, sample.id);
        expect(fromMap.name, sample.name);
        expect(fromMap.category, sample.category);
        expect(fromMap.isVerified, true);
        expect(fromMap.tags, contains('Heritage'));
      },
    );

    test('Category filtering isolates proper destinations', () {
      final alamDestinations = DummyDestinations.list
          .where((d) => d.category.toLowerCase() == 'alam')
          .toList();
      expect(alamDestinations.isNotEmpty, true);
      for (final d in alamDestinations) {
        expect(d.category.toLowerCase(), 'alam');
      }
    });
  });
}
