import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:projek_akhir/data/sources/bandung_destinations.dart';
import 'package:projek_akhir/data/repositories/review_repository.dart';
import 'package:projek_akhir/features/destinations/widgets/destination_reviews_section.dart';
import 'package:projek_akhir/models/destination_review.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);
  });

  group('Phase 12 - DestinationReview Model Tests', () {
    test('DestinationReview serializes to and from Map accurately', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final review = DestinationReview(
        id: 'rev_test_01',
        destinationId: 'dest_01',
        userName: 'Ahmad Fauzi',
        rating: 4.8,
        comment: 'Pemandangan luar biasa dan sejuk!',
        createdAt: now,
        photoUrls: ['https://example.com/photo1.jpg'],
        likesCount: 5,
        isLikedByMe: true,
      );

      final map = review.toMap();
      expect(map['id'], 'rev_test_01');
      expect(map['destinationId'], 'dest_01');
      expect(map['userName'], 'Ahmad Fauzi');
      expect(map['rating'], 4.8);
      expect(map['comment'], 'Pemandangan luar biasa dan sejuk!');
      expect(map['photoUrls'], ['https://example.com/photo1.jpg']);
      expect(map['likesCount'], 5);
      expect(map['isLikedByMe'], true);

      final reconstructed = DestinationReview.fromMap(map);
      expect(reconstructed.id, review.id);
      expect(reconstructed.userName, review.userName);
      expect(reconstructed.rating, review.rating);
      expect(reconstructed.comment, review.comment);
      expect(reconstructed.photoUrls.length, 1);
      expect(reconstructed.likesCount, 5);
      expect(reconstructed.isLikedByMe, true);
    });

    test('DestinationReview copyWith creates modified instance', () {
      final original = DestinationReview(
        id: 'rev_orig',
        destinationId: 'dest_01',
        userName: 'User A',
        rating: 4.0,
        comment: 'Bagus',
        createdAt: DateTime(2026, 1, 1),
      );

      final modified = original.copyWith(
        rating: 5.0,
        likesCount: 10,
        isLikedByMe: true,
      );

      expect(modified.id, 'rev_orig');
      expect(modified.rating, 5.0);
      expect(modified.likesCount, 10);
      expect(modified.isLikedByMe, true);
    });
  });

  group('Phase 12 - ReviewRepository Logic & Persistence Tests', () {
    late ReviewRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = ReviewRepository();
      await repo.init();
      await repo.resetToDefaults();
    });

    test('Initial seeding loads realistic reviews for Bandung destinations', () {
      expect(repo.allReviews.isNotEmpty, isTrue);

      final tangkubanReviews = repo.getReviewsForDestination('dest_01');
      expect(tangkubanReviews.isNotEmpty, isTrue);

      final bragaReviews = repo.getReviewsForDestination('dest_03');
      expect(bragaReviews.isNotEmpty, isTrue);
    });

    test('getAverageRating calculates average rating accurately', () {
      final avg = repo.getAverageRating('dest_01');
      expect(avg, inInclusiveRange(1.0, 5.0));
    });

    test('getRatingBreakdown returns count per star rating', () {
      final breakdown = repo.getRatingBreakdown('dest_01');
      expect(breakdown.containsKey(5), isTrue);
      expect(breakdown.containsKey(4), isTrue);
      expect(breakdown.containsKey(1), isTrue);
    });

    test('addReview adds new review and updates ratings', () async {
      final initialCount = repo.getReviewsForDestination('dest_01').length;

      final review = await repo.addReview(
        destinationId: 'dest_01',
        userName: 'Wisatawan Baru',
        rating: 5.0,
        comment: 'Sangat recommended untuk liburan keluarga!',
        photoUrls: ['https://example.com/new.jpg'],
      );

      final updatedReviews = repo.getReviewsForDestination('dest_01');
      expect(updatedReviews.length, initialCount + 1);
      expect(updatedReviews.first.id, review.id);
      expect(updatedReviews.first.userName, 'Wisatawan Baru');
      expect(updatedReviews.first.rating, 5.0);
      expect(updatedReviews.first.photoUrls.length, 1);
    });

    test('toggleLikeReview increments and decrements likes count', () async {
      final review = repo.allReviews.first;
      final initialLikes = review.likesCount;
      final initialLiked = review.isLikedByMe;

      await repo.toggleLikeReview(review.id);
      final updated = repo.allReviews.firstWhere((r) => r.id == review.id);

      expect(updated.isLikedByMe, !initialLiked);
      expect(updated.likesCount, initialLiked ? initialLikes - 1 : initialLikes + 1);
    });
  });

  group('Phase 12 - DestinationReviewsSection UI Widget Tests', () {
    late ReviewRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = ReviewRepository();
      await repo.init();
      await repo.resetToDefaults();
    });

    testWidgets('DestinationReviewsSection renders rating header, score, and write button',
        (WidgetTester tester) async {
      final destination = BandungDestinations.list.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DestinationReviewsSection(destination: destination),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ulasan & Rating Pengunjung'), findsOneWidget);
      expect(find.byKey(const Key('btn_write_review')), findsOneWidget);
      expect(find.text('Ulasan Terbaru'), findsOneWidget);
      expect(find.text('5★'), findsOneWidget);
      expect(find.text('1★'), findsOneWidget);
    });

    testWidgets('Tapping Tulis Ulasan opens review sheet and submits new review',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final destination = BandungDestinations.list.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DestinationReviewsSection(destination: destination),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final writeBtn = find.byKey(const Key('btn_write_review'));
      expect(writeBtn, findsOneWidget);
      await tester.tap(writeBtn);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Tulis Ulasan & Rating'), findsOneWidget);
      expect(find.byKey(const Key('btn_submit_review')), findsOneWidget);

      // Tap 5 star rating
      final star5 = find.byKey(const Key('star_rating_5'));
      expect(star5, findsOneWidget);
      await tester.ensureVisible(star5);
      await tester.tap(star5, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      // Enter review comment
      final commentField = find.widgetWithText(
        TextField,
        'Ceritakan Pengalaman Wisata Anda',
      );
      expect(commentField, findsOneWidget);
      await tester.enterText(
        commentField,
        'Pemandangannya sangat indah dan udaranya sejuk!',
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Submit review
      final submitBtn = find.byKey(const Key('btn_submit_review'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify review now exists in repository
      final reviews = repo.getReviewsForDestination(destination.id);
      expect(
        reviews.any((r) => r.comment.contains('Pemandangannya sangat indah')),
        isTrue,
      );
    });
  });
}
