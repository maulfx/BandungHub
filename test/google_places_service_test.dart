import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/services/google_places_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GooglePlacesService Tests', () {
    final placesService = GooglePlacesService();

    test('isWithinBandung strictly enforces Bandung geographic boundaries', () {
      // Valid Bandung coordinates
      expect(GooglePlacesService.isWithinBandung(-6.917464, 107.619123), isTrue); // Alun-alun Bandung
      expect(GooglePlacesService.isWithinBandung(-6.902476, 107.618774), isTrue); // Gedung Sate
      expect(GooglePlacesService.isWithinBandung(-6.759637, 107.609780), isTrue); // Tangkuban Parahu Lembang
      expect(GooglePlacesService.isWithinBandung(-7.166203, 107.402123), isTrue); // Kawah Putih Ciwidey
      expect(GooglePlacesService.isWithinBandung(-7.228100, 107.562100), isTrue); // Pangalengan

      // Invalid coordinates (Outside Bandung)
      expect(GooglePlacesService.isWithinBandung(-6.2088, 106.8456), isFalse); // Monas Jakarta
      expect(GooglePlacesService.isWithinBandung(-8.4095, 115.1889), isFalse); // Bali
      expect(GooglePlacesService.isWithinBandung(-7.7956, 110.3695), isFalse); // Malioboro Yogyakarta
      expect(GooglePlacesService.isWithinBandung(-7.2575, 112.7521), isFalse); // Surabaya
    });

    test('API Key management works with SharedPreferences', () async {
      expect(await placesService.hasApiKey(), isFalse);

      await placesService.saveApiKey('AIzaSy_fake_test_key_123');
      expect(await placesService.hasApiKey(), isTrue);
      expect(await placesService.getApiKey(), 'AIzaSy_fake_test_key_123');

      await placesService.clearApiKey();
      expect(await placesService.hasApiKey(), isFalse);
    });

    test('Search fallback strictly returns destinations inside Bandung', () async {
      final results = await placesService.searchBandungDestinations('Lembang');
      expect(results, isNotEmpty);

      for (final dest in results) {
        expect(
          GooglePlacesService.isWithinBandung(dest.latitude, dest.longitude),
          isTrue,
        );
      }
    });
  });
}
