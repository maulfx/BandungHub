import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/features/converter/screens/travel_converter_screen.dart';
import 'package:projek_akhir/services/travel_converter_service.dart';

void main() {
  group('TravelConverterService - Currency Unit Tests', () {
    test('Supported currencies list includes major tourist currencies', () {
      final codes = TravelConverterService.supportedCurrencies.map((c) => c.code).toList();
      expect(codes, contains('IDR'));
      expect(codes, contains('USD'));
      expect(codes, contains('EUR'));
      expect(codes, contains('SGD'));
      expect(codes, contains('MYR'));
      expect(codes, contains('JPY'));
      expect(codes, contains('SAR'));
    });

    test('convertCurrency calculates accurate conversion between IDR and foreign currencies', () {
      // 1 USD = 16,250 IDR
      final inIdr = TravelConverterService.convertCurrency(
        amount: 1.0,
        fromCode: 'USD',
        toCode: 'IDR',
      );
      expect(inIdr, equals(16250.0));

      // 16,250 IDR = 1 USD
      final inUsd = TravelConverterService.convertCurrency(
        amount: 16250.0,
        fromCode: 'IDR',
        toCode: 'USD',
      );
      expect(inUsd, closeTo(1.0, 0.001));

      // 0 or negative amount returns 0.0
      expect(
        TravelConverterService.convertCurrency(amount: 0, fromCode: 'IDR', toCode: 'USD'),
        equals(0.0),
      );
      expect(
        TravelConverterService.convertCurrency(amount: -100, fromCode: 'IDR', toCode: 'USD'),
        equals(0.0),
      );
    });

    test('formatCurrency outputs expected formatted string', () {
      final idrFormatted = TravelConverterService.formatCurrency(50000, 'IDR');
      expect(idrFormatted, contains('Rp'));
      expect(idrFormatted, contains('50.000'));

      final usdFormatted = TravelConverterService.formatCurrency(12.50, 'USD');
      expect(usdFormatted, contains('\$'));
      expect(usdFormatted, contains('12.50'));
    });
  });

  group('TravelConverterService - Timezone Unit Tests', () {
    test('Supported timezones list contains Indonesian and global hubs', () {
      final codes = TravelConverterService.supportedTimezones.map((t) => t.code).toList();
      expect(codes, contains('WIB'));
      expect(codes, contains('WITA'));
      expect(codes, contains('WIT'));
      expect(codes, contains('SGT'));
      expect(codes, contains('JST'));
      expect(codes, contains('GMT'));
    });

    test('convertBandungTimeToTarget computes correct offsets', () {
      // Bandung 10:00 WIB
      final wita = TravelConverterService.supportedTimezones.firstWhere((t) => t.code == 'WITA');
      expect(
        TravelConverterService.convertBandungTimeToTarget(
          bandungHour: 10,
          bandungMinute: 0,
          targetTz: wita,
        ),
        equals('11:00'),
      );

      final jst = TravelConverterService.supportedTimezones.firstWhere((t) => t.code == 'JST');
      expect(
        TravelConverterService.convertBandungTimeToTarget(
          bandungHour: 10,
          bandungMinute: 0,
          targetTz: jst,
        ),
        equals('12:00'),
      );

      final gmt = TravelConverterService.supportedTimezones.firstWhere((t) => t.code == 'GMT');
      expect(
        TravelConverterService.convertBandungTimeToTarget(
          bandungHour: 10,
          bandungMinute: 0,
          targetTz: gmt,
        ),
        equals('03:00'),
      );
    });

    test('getOperationalHoursInTimezone formats correct opening hours', () {
      final wita = TravelConverterService.supportedTimezones.firstWhere((t) => t.code == 'WITA');
      final opHours = TravelConverterService.getOperationalHoursInTimezone(targetTz: wita);
      expect(opHours, contains('09:00 - 18:00 WITA'));
    });
  });

  group('TravelConverterScreen - Widget Tests', () {
    testWidgets('TravelConverterScreen renders both tabs and allows interaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: TravelConverterScreen()),
      );
      await tester.pumpAndSettle();

      // Title & Tabs
      expect(find.text('Konverter Wisatawan'), findsOneWidget);
      expect(find.text('Kurs Mata Uang'), findsOneWidget);
      expect(find.text('Zona Waktu'), findsOneWidget);

      // Verify Currency Tab content
      expect(find.text('Estimasi Cepat Tiket & Budget Wisata Bandung'), findsOneWidget);
      expect(find.text('Tabel Kurs Acuan Valas Wisatawan (ke IDR)'), findsOneWidget);

      // Tap preset chip
      final presetChip = find.text('Rp 30.000 (Tangkuban / Kawah)');
      expect(presetChip, findsOneWidget);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();

      // Switch to Timezone tab
      await tester.tap(find.text('Zona Waktu'));
      await tester.pumpAndSettle();

      // Verify Timezone Tab content
      expect(find.text('Waktu Resmi Bandung (WIB / UTC+7)'), findsOneWidget);
      expect(find.text('Kalkulator Selisih Jam Kunjungan'), findsOneWidget);
      expect(find.text('Daftar Jam Live Dunia & Kota Wisatawan'), findsOneWidget);
    });
  });
}
