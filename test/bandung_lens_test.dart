import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/features/lens/screens/bandung_lens_screen.dart';
import 'package:projek_akhir/services/ai_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Bandung AI Lens Service & Landmark Scanner Tests', () {
    test('analyzeLandmarkImage returns accurate fallback data for Gedung Sate', () async {
      final service = AiAssistantService();
      final result = await service.analyzeLandmarkImage(
        imageBytes: Uint8List(0),
        hintName: 'Gedung Sate',
      );

      expect(result.isBandungLandmark, isTrue);
      expect(result.landmarkName, contains('Gedung Sate'));
      expect(result.category, contains('Sejarah'));
      expect(result.confidencePercent, greaterThanOrEqualTo(90));
      expect(result.shortDescription, contains('1920'));
      expect(result.historyFact, contains('Gerber'));
      expect(result.interestingTrivia, contains('Gulden'));
      expect(result.recommendedThingsToDo, isNotEmpty);
      expect(result.matchedDestination, isNotNull);
      expect(result.matchedDestination?.name, equals('Gedung Sate'));
    });

    test('analyzeLandmarkImage returns accurate fallback data for Kawah Putih', () async {
      final service = AiAssistantService();
      final result = await service.analyzeLandmarkImage(
        imageBytes: Uint8List(0),
        hintName: 'Kawah Putih',
      );

      expect(result.isBandungLandmark, isTrue);
      expect(result.landmarkName, contains('Kawah Putih'));
      expect(result.category, contains('Alam'));
      expect(result.historyFact, contains('Junghuhn'));
      expect(result.matchedDestination?.id, equals('dest_02'));
    });

    test('analyzeLandmarkImage returns accurate fallback data for Jalan Braga', () async {
      final service = AiAssistantService();
      final result = await service.analyzeLandmarkImage(
        imageBytes: Uint8List(0),
        hintName: 'Jalan Braga',
      );

      expect(result.isBandungLandmark, isTrue);
      expect(result.landmarkName, contains('Braga'));
      expect(result.matchedDestination?.id, equals('dest_04'));
    });
  });

  group('BandungLensScreen Widget Tests', () {
    testWidgets('Renders BandungLensScreen with viewfinder, sample landmarks, and buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BandungLensScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check AppBar Title
      expect(find.text('Bandung AI Lens'), findsOneWidget);
      expect(find.text('Pemindai Cagar Budaya & Landmark'), findsOneWidget);

      // Check Viewfinder instructions
      expect(find.text('Arahkan Kamera ke Objek Wisata'), findsOneWidget);

      // Check Controls
      expect(find.byKey(const Key('btn_lens_camera')), findsOneWidget);
      expect(find.byKey(const Key('btn_lens_gallery')), findsOneWidget);

      // Check Sample Landmarks Carousel
      expect(find.text('Uji Coba Cepat (Sampel Foto Landmark):'), findsOneWidget);
      expect(find.text('Gedung Sate'), findsOneWidget);
      expect(find.text('Kawah Putih Ciwidey'), findsOneWidget);
      expect(find.text('Jalan Braga'), findsOneWidget);
    });
  });
}
