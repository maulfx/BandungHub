import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/dummy/dummy_destinations.dart';
import 'package:projek_akhir/features/recommendations/screens/preference_form_screen.dart';
import 'package:projek_akhir/features/recommendations/screens/recommendation_results_screen.dart';
import 'package:projek_akhir/models/travel_preference.dart';
import 'package:projek_akhir/services/recommendation_engine.dart';

void main() {
  group('Phase 4 - Recommendation Engine Unit Tests', () {
    final destinations = DummyDestinations.list;

    test('Engine calculates scores, reasons, and sorts results descending', () {
      const pref = TravelPreference(
        preferredCategories: ['Alam'],
        maxBudgetPerPerson: 50000.0,
        numberOfPeople: 2,
        interests: ['Petualangan Alam'],
      );

      final results = RecommendationEngine.getRecommendations(
        destinations: destinations,
        preference: pref,
      );

      expect(results.isNotEmpty, true);

      // Verify sorted descending by score
      for (int i = 0; i < results.length - 1; i++) {
        expect(results[i].score, greaterThanOrEqualTo(results[i + 1].score));
      }

      // Top result must be an Alam destination
      final topResult = results.first;
      expect(topResult.destination.category, 'Alam');
      expect(topResult.reasons.isNotEmpty, true);
      expect(topResult.scorePercentage, greaterThan(70));
    });

    test('Changing preferences changes recommendations and top destination', () {
      // Preference A: Nature & Adventure
      const prefNature = TravelPreference(
        preferredCategories: ['Alam'],
        maxBudgetPerPerson: 40000.0,
        numberOfPeople: 1,
        interests: ['Petualangan Alam'],
      );
      final resultsNature = RecommendationEngine.getRecommendations(
        destinations: destinations,
        preference: prefNature,
      );

      // Preference B: Culinary
      const prefCulinary = TravelPreference(
        preferredCategories: ['Kuliner'],
        maxBudgetPerPerson: 50000.0,
        numberOfPeople: 1,
        interests: ['Kuliner Legendaris'],
      );
      final resultsCulinary = RecommendationEngine.getRecommendations(
        destinations: destinations,
        preference: prefCulinary,
      );

      // The top destination must differ between Nature and Culinary preferences
      expect(
        resultsNature.first.destination.id,
        isNot(equals(resultsCulinary.first.destination.id)),
      );
      expect(resultsNature.first.destination.category, 'Alam');
      expect(resultsCulinary.first.destination.category, 'Kuliner');
    });

    test(
      'Group budget calculation accurately scales with number of people',
      () {
        const pref1 = TravelPreference(
          preferredCategories: ['Alam'],
          maxBudgetPerPerson: 50000.0,
          numberOfPeople: 1,
        );
        final results1 = RecommendationEngine.getRecommendations(
          destinations: destinations,
          preference: pref1,
        );

        const pref4 = TravelPreference(
          preferredCategories: ['Alam'],
          maxBudgetPerPerson: 50000.0,
          numberOfPeople: 4,
        );
        final results4 = RecommendationEngine.getRecommendations(
          destinations: destinations,
          preference: pref4,
        );

        // For Tangkuban Parahu (35.000) or any priced destination
        final destWithPrice1 = results1.firstWhere(
          (r) => r.destination.estimatedPrice > 0,
        );
        final destWithPrice4 = results4.firstWhere(
          (r) => r.destination.id == destWithPrice1.destination.id,
        );

        expect(
          destWithPrice4.totalEstimatedBudget,
          equals(destWithPrice1.totalEstimatedBudget * 4),
        );
      },
    );

    test(
      'Explainable reasons are generated for each recommended destination',
      () {
        const pref = TravelPreference(
          preferredCategories: ['Sejarah'],
          maxBudgetPerPerson: 20000.0,
          numberOfPeople: 2,
          interests: ['Edukasi & Budaya'],
        );

        final results = RecommendationEngine.getRecommendations(
          destinations: destinations,
          preference: pref,
        );

        final topSejarah = results.firstWhere(
          (r) => r.destination.category == 'Sejarah',
        );
        expect(topSejarah.reasons.isNotEmpty, true);
        // Contains mention of category
        expect(topSejarah.reasons.any((r) => r.contains('Sejarah')), true);
      },
    );
  });

  group('Phase 4 - UI Widget Tests', () {
    testWidgets(
      'PreferenceFormScreen renders and allows selecting categories',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: PreferenceFormScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Preferensi Rekomendasi'), findsOneWidget);
        expect(find.text('Hitung Rekomendasi Destinasi'), findsOneWidget);
        expect(find.text('1. Kategori Wisata Favorit'), findsOneWidget);
        expect(find.text('2. Anggaran Tiket per Orang'), findsOneWidget);
        expect(find.text('3. Rencana Durasi Perjalanan'), findsOneWidget);
        expect(find.text('4. Jumlah Peserta / Orang'), findsOneWidget);
      },
    );

    testWidgets(
      'RecommendationResultsScreen displays recommendations with match percentage',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const samplePref = TravelPreference(
          preferredCategories: ['Alam'],
          maxBudgetPerPerson: 50000.0,
          durationDays: 1,
          numberOfPeople: 2,
          interests: ['Petualangan Alam'],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: RecommendationResultsScreen(preference: samplePref),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hasil Rekomendasi'), findsOneWidget);
        expect(find.textContaining('Kategori: Alam'), findsOneWidget);
        expect(find.textContaining('Cocok'), findsWidgets);
        expect(find.text('Alasan Rekomendasi:'), findsWidgets);
      },
    );
  });
}
