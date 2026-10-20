import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/dummy/dummy_destinations.dart';
import 'package:projek_akhir/data/repositories/destination_repository.dart';
import 'package:projek_akhir/features/destinations/screens/destination_detail_screen.dart';
import 'package:projek_akhir/features/destinations/screens/explore_screen.dart';

void main() {
  group('Phase 3 - Destination Catalog, Search & Filter Unit Tests', () {
    final repo = DestinationRepository();

    test('Search filter by query matches name, address, or description', () {
      // Search for Gedung Sate
      final result1 = repo.filterDestinations(query: 'Gedung Sate');
      expect(result1.isNotEmpty, true);
      expect(result1.first.name, 'Gedung Sate');

      // Search for Ciwidey
      final result2 = repo.filterDestinations(query: 'Ciwidey');
      expect(result2.isNotEmpty, true);
      expect(result2.any((d) => d.name.contains('Kawah Putih')), isTrue);

      // Non-existent search query
      final result3 = repo.filterDestinations(
        query: 'Tempat antah berantah xyz',
      );
      expect(result3.isEmpty, true);
    });

    test('Category filter isolates specific tourism categories', () {
      final alam = repo.filterDestinations(category: 'Alam');
      expect(alam.isNotEmpty, true);
      for (final d in alam) {
        expect(d.category.toLowerCase(), 'alam');
      }

      final kuliner = repo.filterDestinations(category: 'Kuliner');
      expect(kuliner.isNotEmpty, true);
      for (final d in kuliner) {
        expect(d.category.toLowerCase(), 'kuliner');
      }

      final sejarah = repo.filterDestinations(category: 'Sejarah');
      expect(sejarah.isNotEmpty, true);
      for (final d in sejarah) {
        expect(d.category.toLowerCase(), 'sejarah');
      }
    });

    test('Budget range filter correctly caps max ticket price', () {
      // Free destinations
      final freeList = repo.filterDestinations(maxBudget: 0);
      expect(freeList.isNotEmpty, true);
      for (final d in freeList) {
        expect(d.estimatedPrice, 0.0);
      }

      // Budget under Rp 35.000
      final cheapList = repo.filterDestinations(maxBudget: 35000);
      expect(cheapList.isNotEmpty, true);
      for (final d in cheapList) {
        expect(d.estimatedPrice, lessThanOrEqualTo(35000.0));
      }
    });

    test('Sorting orders destinations accurately', () {
      // Price lowest
      final priceLowest = repo.filterDestinations(
        sortBy: DestinationSortBy.priceLowest,
      );
      for (int i = 0; i < priceLowest.length - 1; i++) {
        expect(
          priceLowest[i].estimatedPrice,
          lessThanOrEqualTo(priceLowest[i + 1].estimatedPrice),
        );
      }

      // Price highest
      final priceHighest = repo.filterDestinations(
        sortBy: DestinationSortBy.priceHighest,
      );
      for (int i = 0; i < priceHighest.length - 1; i++) {
        expect(
          priceHighest[i].estimatedPrice,
          greaterThanOrEqualTo(priceHighest[i + 1].estimatedPrice),
        );
      }

      // Name A-Z
      final nameAZ = repo.filterDestinations(sortBy: DestinationSortBy.nameAZ);
      for (int i = 0; i < nameAZ.length - 1; i++) {
        expect(
          nameAZ[i].name.toLowerCase().compareTo(
            nameAZ[i + 1].name.toLowerCase(),
          ),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('Favorite toggle works and updates filter', () {
      final sampleId = DummyDestinations.list.first.id;

      // Initially not favorite
      if (repo.isFavorite(sampleId)) {
        repo.toggleFavorite(sampleId);
      }
      expect(repo.isFavorite(sampleId), false);

      // Toggle to favorite
      repo.toggleFavorite(sampleId);
      expect(repo.isFavorite(sampleId), true);

      // Filter only favorites
      final favList = repo.filterDestinations(onlyFavorites: true);
      expect(favList.any((d) => d.id == sampleId), true);

      // Toggle back
      repo.toggleFavorite(sampleId);
      expect(repo.isFavorite(sampleId), false);
    });
  });

  group('Phase 3 - UI Widget Tests', () {
    testWidgets(
      'DestinationDetailScreen renders destination info and coordinates',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final destination = DummyDestinations.list.first; // Gedung Sate

        await tester.pumpWidget(
          MaterialApp(home: DestinationDetailScreen(destination: destination)),
        );
        await tester.pumpAndSettle();

        // Verify destination name and category
        expect(find.text(destination.name), findsOneWidget);
        expect(find.text(destination.category), findsOneWidget);
        expect(find.text('Resmi Terverifikasi'), findsOneWidget);

        // Verify coordinate badge is visible
        expect(find.textContaining('Koordinat:'), findsOneWidget);
        expect(find.text('Fleaflet Map Ready'), findsOneWidget);

        // Verify action button
        expect(find.text('Tambahkan ke Rencana Perjalanan'), findsOneWidget);
      },
    );

    testWidgets('ExploreScreen allows searching and toggling filters', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Katalog & Eksplorasi'), findsOneWidget);

      // Search bar
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Type search
      await tester.enterText(searchField, 'Braga');
      await tester.pumpAndSettle();

      expect(find.textContaining('Jalan Braga'), findsOneWidget);
    });
  });
}
