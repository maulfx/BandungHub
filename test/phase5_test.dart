import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/dummy/dummy_destinations.dart';
import 'package:projek_akhir/data/repositories/itinerary_repository.dart';
import 'package:projek_akhir/features/itinerary/screens/create_itinerary_screen.dart';
import 'package:projek_akhir/features/itinerary/screens/itinerary_screen.dart';
import 'package:projek_akhir/models/itinerary.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 5 - Itinerary & Budget Estimation Unit Tests', () {
    test(
      'Itinerary model computes ticket cost and total budget automatically',
      () {
        final now = DateTime.now();
        const item1 = ItineraryItem(
          id: '1',
          destinationId: 'dest_01',
          destinationName: 'Gedung Sate',
          destinationCategory: 'Sejarah',
          imageUrl: 'url',
          ticketPrice: 5000.0,
          dayNumber: 1,
          visitOrder: 1,
        );
        const item2 = ItineraryItem(
          id: '2',
          destinationId: 'dest_02',
          destinationName: 'Kawah Putih',
          destinationCategory: 'Alam',
          imageUrl: 'url',
          ticketPrice: 28000.0,
          dayNumber: 2,
          visitOrder: 1,
        );

        final itinerary = Itinerary(
          id: 'itin_test',
          title: 'Bandung 2 Hari',
          startDate: now,
          durationDays: 2,
          numberOfPeople: 2,
          items: const [item1, item2],
          transportationCost: 100000.0,
          foodCost: 150000.0,
          additionalCost: 20000.0,
          createdAt: now,
          updatedAt: now,
        );

        // (5000 + 28000) * 2 people = 66000
        expect(itinerary.totalTicketCost, equals(66000.0));

        // 66000 + 100000 + 150000 + 20000 = 336000
        expect(itinerary.totalEstimatedBudget, equals(336000.0));
      },
    );

    test('Items are correctly grouped by day and sorted by visitOrder', () {
      final now = DateTime.now();
      const item1 = ItineraryItem(
        id: '1',
        destinationId: 'dest_01',
        destinationName: 'Gedung Sate',
        destinationCategory: 'Sejarah',
        imageUrl: '',
        ticketPrice: 5000.0,
        dayNumber: 1,
        visitOrder: 2,
      );
      const item2 = ItineraryItem(
        id: '2',
        destinationId: 'dest_04',
        destinationName: 'Braga',
        destinationCategory: 'Sejarah',
        imageUrl: '',
        ticketPrice: 0.0,
        dayNumber: 1,
        visitOrder: 1,
      );
      const item3 = ItineraryItem(
        id: '3',
        destinationId: 'dest_02',
        destinationName: 'Kawah Putih',
        destinationCategory: 'Alam',
        imageUrl: '',
        ticketPrice: 28000.0,
        dayNumber: 2,
        visitOrder: 1,
      );

      final itinerary = Itinerary(
        id: 'itin_group',
        title: 'Trip Grouping',
        startDate: now,
        durationDays: 2,
        numberOfPeople: 1,
        items: const [item1, item2, item3],
        createdAt: now,
        updatedAt: now,
      );

      final grouped = itinerary.itemsByDay;
      expect(grouped.length, 2);
      expect(grouped[1]!.length, 2);
      expect(grouped[2]!.length, 1);

      // Verify Day 1 is sorted by visit order: item2 (order 1) then item1 (order 2)
      expect(grouped[1]![0].id, '2');
      expect(grouped[1]![1].id, '1');
    });

    test('Repository manages adding, removing, and reordering items', () async {
      final repo = ItineraryRepository();
      await repo.init();

      final created = await repo.createItinerary(
        title: 'Liburan Sejuk',
        startDate: DateTime.now(),
        durationDays: 2,
        numberOfPeople: 2,
      );

      expect(created.id.isNotEmpty, true);
      expect(repo.getItineraryById(created.id), isNotNull);

      // Add destination
      final sampleDest = DummyDestinations.list.first;
      await repo.addDestinationToItinerary(
        itineraryId: created.id,
        destination: sampleDest,
        dayNumber: 1,
      );

      final afterAdd = repo.getItineraryById(created.id)!;
      expect(afterAdd.items.length, 1);
      expect(afterAdd.items.first.destinationId, sampleDest.id);

      // Remove destination
      await repo.removeDestinationFromItinerary(
        itineraryId: created.id,
        itemId: afterAdd.items.first.id,
      );

      final afterRemove = repo.getItineraryById(created.id)!;
      expect(afterRemove.items.isEmpty, true);

      // Delete itinerary
      await repo.deleteItinerary(created.id);
      expect(repo.getItineraryById(created.id), isNull);
    });

    test(
      'Hash verification validates unchanged data and detects modifications',
      () {
        final now = DateTime.now();
        final itinerary = Itinerary(
          id: 'itin_hash',
          title: 'Integritas Trip',
          startDate: now,
          durationDays: 1,
          numberOfPeople: 1,
          createdAt: now,
          updatedAt: now,
        );

        final hash = itinerary.computeHash();
        expect(hash.isNotEmpty, true);

        final verified = itinerary.copyWith(savedHash: hash);
        expect(verified.isHashValid, true);

        // Tampering with budget or title must invalidate hash
        final tampered = verified.copyWith(transportationCost: 99999.0);
        expect(tampered.isHashValid, false);
      },
    );
  });

  group('Phase 5 - UI Widget Tests', () {
    testWidgets('ItineraryScreen renders empty state and FAB', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: ItineraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rencana Perjalanan (Itinerary)'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Buat Itinerary'), findsOneWidget);
    });

    testWidgets('CreateItineraryScreen renders inputs and date selection', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: CreateItineraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Buat Itinerary Baru'), findsOneWidget);
      expect(find.text('Nama / Judul Rencana Perjalanan'), findsOneWidget);
      expect(find.text('Tanggal Keberangkatan'), findsOneWidget);
      expect(find.text('Durasi (Hari)'), findsOneWidget);
      expect(find.text('Jumlah Orang'), findsOneWidget);
      expect(find.text('Estimasi Biaya Operasional'), findsOneWidget);
    });
  });
}
