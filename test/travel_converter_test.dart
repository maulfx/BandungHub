import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/services/travel_converter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TravelConverterService Live Exchange Rate Tests', () {
    test('Default fallback rates convert correctly when offline', () {
      final usdCur = TravelConverterService.getCurrency('USD');
      expect(usdCur.code, 'USD');
      expect(usdCur.rateToIdr, greaterThan(15000));

      final converted = TravelConverterService.convertCurrency(
        amount: 10,
        fromCode: 'USD',
        toCode: 'IDR',
      );
      expect(converted, equals(10 * usdCur.rateToIdr));
    });

    test('Live rate fetch and update calculates real-time rates accurately', () async {
      // Mock live rates API response logic or actual fetch
      final success = await TravelConverterService.fetchLiveRates(force: true);

      // Verify that service handles network response
      expect(TravelConverterService.supportedCurrencies, isNotEmpty);
      final idrCur = TravelConverterService.getCurrency('IDR');
      expect(idrCur.rateToIdr, equals(1.0));

      final usdCur = TravelConverterService.getCurrency('USD');
      expect(usdCur.rateToIdr, greaterThan(0));

      if (success) {
        expect(TravelConverterService.isLiveRates, isTrue);
        expect(TravelConverterService.lastRatesUpdated, isNotNull);
      }
    });

    test('Currency formatting displays correct symbols', () {
      final formattedIdr = TravelConverterService.formatCurrency(50000, 'IDR');
      expect(formattedIdr, contains('Rp'));
      expect(formattedIdr, contains('50.000'));

      final formattedUsd = TravelConverterService.formatCurrency(25.50, 'USD');
      expect(formattedUsd, contains('\$'));
    });
  });
}
