import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:projek_akhir/services/bandung_places_search_service.dart';
import 'package:projek_akhir/services/map_service.dart';

void main() {
  group('BandungPlacesSearchService Unit Tests', () {
    late BandungPlacesSearchService service;

    setUp(() {
      service = BandungPlacesSearchService();
    });

    test('service is a singleton', () {
      final s1 = BandungPlacesSearchService();
      final s2 = BandungPlacesSearchService();
      expect(identical(s1, s2), isTrue);
    });

    test('empty or short query (<2 chars) returns empty list immediately', () async {
      final resEmpty = await service.searchPlaces('');
      final resSingle = await service.searchPlaces('a');
      expect(resEmpty, isEmpty);
      expect(resSingle, isEmpty);
    });

    test('Bandung bounding box properly envelopes Bandung coordinates', () {
      // Gedung Sate (Kota Bandung)
      expect(
        MapService.bandungBounds.contains(const LatLng(-6.9025, 107.6186)),
        isTrue,
      );

      // Tangkuban Parahu (Bandung Barat / Lembang)
      expect(
        MapService.bandungBounds.contains(const LatLng(-6.7596, 107.6098)),
        isTrue,
      );

      // Kawah Putih Ciwidey (Kab. Bandung)
      expect(
        MapService.bandungBounds.contains(const LatLng(-7.1662, 107.4021)),
        isTrue,
      );

      // Jakarta (Monas) - MUST be strictly rejected
      expect(
        MapService.bandungBounds.contains(const LatLng(-6.1754, 106.8272)),
        isFalse,
      );

      // Surabaya - MUST be strictly rejected
      expect(
        MapService.bandungBounds.contains(const LatLng(-7.2575, 112.7521)),
        isFalse,
      );
    });
  });
}
