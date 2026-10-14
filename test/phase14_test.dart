import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:projek_akhir/features/academic/screens/course_feedback_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 14 - Academic Course Feedback & Evaluation Tests', () {
    testWidgets('CourseFeedbackScreen renders all form inputs, stars, and action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CourseFeedbackScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kesan & Pesan Kuliah'), findsOneWidget);
      expect(find.text('Evaluasi & Refleksi Akademik'), findsOneWidget);
      expect(find.text('Rating Pengalaman Perkuliahan'), findsOneWidget);
      expect(find.byKey(const Key('rating_star_5.0')), findsOneWidget);
      expect(find.byKey(const Key('input_impressions')), findsOneWidget);
      expect(find.byKey(const Key('input_suggestions')), findsOneWidget);
      expect(find.byKey(const Key('btn_save_feedback')), findsOneWidget);
    });

    testWidgets('Submitting feedback saves evaluation into SharedPreferences and shows SnackBar',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CourseFeedbackScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Change star rating to 4.0
      final star4 = find.byKey(const Key('rating_star_4.0'));
      expect(star4, findsOneWidget);
      await tester.tap(star4);
      await tester.pumpAndSettle();

      // Enter impressions
      final impressionsField = find.byKey(const Key('input_impressions'));
      await tester.enterText(
        impressionsField,
        'Materi perkuliahan Flutter sangat relevan dengan kebutuhan industri mobile saat ini.',
      );
      await tester.pumpAndSettle();

      // Scroll to ensure submit button is visible
      final saveBtn = find.byKey(const Key('btn_save_feedback'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      // SnackBar appears
      expect(
        find.textContaining('Kesan & pesan kuliah berhasil disimpan'),
        findsOneWidget,
      );

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('academic_course_feedback_v1');
      expect(savedJson, isNotNull);

      final decoded = jsonDecode(savedJson!) as Map<String, dynamic>;
      expect(decoded['rating'], 4.0);
      expect(
        decoded['impressions'],
        'Materi perkuliahan Flutter sangat relevan dengan kebutuhan industri mobile saat ini.',
      );
    });

    testWidgets('Tapping copy summary copies structured reflection to clipboard',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CourseFeedbackScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final copyBtn = find.byKey(const Key('btn_copy_feedback_summary'));
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pump();

      expect(
        find.textContaining('Ringkasan evaluasi kuliah disalin'),
        findsOneWidget,
      );
    });
  });
}
