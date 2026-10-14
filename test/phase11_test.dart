import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:projek_akhir/data/repositories/itinerary_repository.dart';
import 'package:projek_akhir/features/itinerary/screens/itinerary_detail_screen.dart';
import 'package:projek_akhir/features/itinerary/widgets/itinerary_export_sheet.dart';
import 'package:projek_akhir/models/itinerary.dart';
import 'package:projek_akhir/services/itinerary_export_service.dart';

void main() {
  String? mockClipboardText;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);

    mockClipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        mockClipboardText =
            (methodCall.arguments as Map<dynamic, dynamic>)['text'] as String?;
        return null;
      }
      if (methodCall.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': mockClipboardText};
      }
      return null;
    });
  });

  Itinerary createSampleItinerary({String? hash}) {
    final now = DateTime(2026, 11, 10);
    return Itinerary(
      id: 'itinerary_test_01',
      title: 'Liburan Romantis Lembang 2 Hari',
      startDate: now,
      durationDays: 2,
      numberOfPeople: 2,
      transportationCost: 150000.0,
      foodCost: 200000.0,
      additionalCost: 50000.0,
      savedHash: hash ??
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      createdAt: now,
      updatedAt: now,
      items: const [
        ItineraryItem(
          id: 'item_1',
          destinationId: 'dest_1',
          destinationName: 'Tangkuban Perahu',
          destinationCategory: 'Alam',
          imageUrl: 'https://example.com/tangkuban.jpg',
          ticketPrice: 35000.0,
          dayNumber: 1,
          visitOrder: 1,
          notes: 'Bawa jaket tebal dan masker belerang',
        ),
        ItineraryItem(
          id: 'item_2',
          destinationId: 'dest_2',
          destinationName: 'Floating Market Lembang',
          destinationCategory: 'Kuliner',
          imageUrl: 'https://example.com/floating.jpg',
          ticketPrice: 30000.0,
          dayNumber: 1,
          visitOrder: 2,
          notes: 'Tukarkan koin floating market',
        ),
        ItineraryItem(
          id: 'item_3',
          destinationId: 'dest_3',
          destinationName: 'Orchid Forest Cikole',
          destinationCategory: 'Alam',
          imageUrl: 'https://example.com/orchid.jpg',
          ticketPrice: 40000.0,
          dayNumber: 2,
          visitOrder: 1,
          notes: 'Foto di jembatan kayu gantung',
        ),
      ],
    );
  }

  group('Phase 11 - ItineraryExportService Logic Tests', () {
    test('generatePlainText produces well-formatted message with details', () {
      final itinerary = createSampleItinerary();
      final text = ItineraryExportService.generatePlainText(itinerary);

      expect(text, contains('BANDUNGHUB'));
      expect(text, contains('LIBURAN ROMANTIS LEMBANG 2 HARI'));
      expect(text, contains('2 Hari'));
      expect(text, contains('2 Orang'));
      expect(text, contains('Tangkuban Perahu'));
      expect(text, contains('Floating Market Lembang'));
      expect(text, contains('Orchid Forest Cikole'));
      expect(text, contains('Bawa jaket tebal dan masker belerang'));
      expect(text, contains('TOTAL ESTIMASI'));
      expect(text, contains(itinerary.savedHash!));
      expect(text, contains('Disusun menggunakan BandungHub'));
    });

    test('generateJsonExport produces valid parseable JSON with metadata', () {
      final itinerary = createSampleItinerary();
      final jsonStr = ItineraryExportService.generateJsonExport(itinerary);

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      expect(decoded['id'], 'itinerary_test_01');
      expect(decoded['title'], 'Liburan Romantis Lembang 2 Hari');
      expect(decoded['duration_days'], 2);
      expect(decoded['export_source'], 'BandungHub App');
      expect(decoded['exported_at'], isNotNull);
      expect(decoded['items'], isA<List>());
      expect((decoded['items'] as List).length, 3);
    });

    test(
        'generateHtmlDocument produces valid HTML page with styles and tables',
        () {
      final itinerary = createSampleItinerary();
      final html = ItineraryExportService.generateHtmlDocument(itinerary);

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<html lang="id">'));
      expect(html, contains('BandungHub Travel Itinerary'));
      expect(html, contains('Liburan Romantis Lembang 2 Hari'));
      expect(html, contains('Ringkasan Estimasi Anggaran'));
      expect(html, contains('Tangkuban Perahu'));
      expect(html, contains('Floating Market Lembang'));
      expect(html, contains('Orchid Forest Cikole'));
      expect(html, contains(itinerary.savedHash!));
      expect(html, contains('</html>'));
    });

    test('copyToClipboard copies string to system clipboard', () async {
      await ItineraryExportService.copyToClipboard('Test Itinerary Text');
      expect(mockClipboardText, 'Test Itinerary Text');
    });
  });

  group('Phase 11 - ItineraryExportSheet UI Widget Tests', () {
    testWidgets('ItineraryExportSheet renders header, tabs, and plain text tab',
        (WidgetTester tester) async {
      final itinerary = createSampleItinerary();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItineraryExportSheet(itinerary: itinerary),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ekspor & Bagikan Itinerary'), findsOneWidget);
      expect(find.text(itinerary.title), findsOneWidget);
      expect(find.text('WhatsApp / Teks'), findsOneWidget);
      expect(find.text('Dokumen'), findsOneWidget);
      expect(find.text('JSON Backup'), findsOneWidget);

      // Buttons on Plain Text Tab
      expect(find.byKey(const Key('btn_copy_plain_text')), findsOneWidget);
      expect(
          find.byKey(const Key('btn_share_itinerary_sheet')), findsOneWidget);
    });

    testWidgets(
        'Tapping Dokumen tab displays document view and HTML copy button',
        (WidgetTester tester) async {
      final itinerary = createSampleItinerary();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItineraryExportSheet(itinerary: itinerary),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final docTab = find.text('Dokumen');
      expect(docTab, findsOneWidget);
      await tester.tap(docTab);
      await tester.pumpAndSettle();

      expect(find.text('Dokumen Ringkas Siap Cetak & Simpan'), findsOneWidget);
      expect(find.byKey(const Key('btn_copy_html_document')), findsOneWidget);
    });

    testWidgets('Tapping JSON Backup tab displays JSON and hash copy buttons',
        (WidgetTester tester) async {
      final itinerary = createSampleItinerary();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItineraryExportSheet(itinerary: itinerary),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final jsonTab = find.text('JSON Backup');
      expect(jsonTab, findsOneWidget);
      await tester.tap(jsonTab);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_copy_json_data')), findsOneWidget);
      expect(find.byKey(const Key('btn_copy_hash')), findsOneWidget);
    });

    testWidgets('Copying plain text shows SnackBar feedback',
        (WidgetTester tester) async {
      final itinerary = createSampleItinerary();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItineraryExportSheet(itinerary: itinerary),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final copyBtn = find.byKey(const Key('btn_copy_plain_text'));
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('berhasil disalin ke clipboard!'),
          findsOneWidget);
      expect(mockClipboardText, isNotNull);
    });
  });

  group('Phase 11 - ItineraryDetailScreen Export Action Integration', () {
    testWidgets('ItineraryDetailScreen opens export bottom sheet on action tap',
        (WidgetTester tester) async {
      final repo = ItineraryRepository();
      await repo.init();

      final itinerary = await repo.createItinerary(
        title: 'Trip Ciwidey Keluarga',
        startDate: DateTime.now().add(const Duration(days: 5)),
        durationDays: 2,
        numberOfPeople: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itineraryId: itinerary.id),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Find AppBar export action button
      final exportBtn = find.byKey(const Key('btn_itinerary_export_action'));
      expect(exportBtn, findsOneWidget);

      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Export sheet should now be displayed
      expect(find.text('Ekspor & Bagikan Itinerary'), findsOneWidget);
      expect(find.text('Trip Ciwidey Keluarga'), findsWidgets);
    });
  });
}
