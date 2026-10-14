import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/dummy/dummy_quiz_questions.dart';
import 'package:projek_akhir/data/repositories/quiz_repository.dart';
import 'package:projek_akhir/features/mini_game/screens/game_screen.dart';
import 'package:projek_akhir/models/quiz_question.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 8 - QuizQuestion & Question Bank Unit Tests', () {
    test('QuizQuestion model serializes to and from Map', () {
      const q = QuizQuestion(
        id: 'q_test',
        question: 'Apa julukan kota Bandung?',
        options: [
          'Kota Hujan',
          'Parijs van Java',
          'Kota Pahlawan',
          'Kota Pelajar',
        ],
        correctIndex: 1,
        explanation: 'Parijs van Java adalah julukan legendaris kota Bandung.',
        category: 'Ikon',
        hint: 'Mirip nama ibu kota Prancis',
        points: 100,
      );

      final map = q.toMap();
      final reconstructed = QuizQuestion.fromMap(map);

      expect(reconstructed.id, q.id);
      expect(reconstructed.correctIndex, 1);
      expect(reconstructed.correctAnswer, 'Parijs van Java');
      expect(reconstructed.options.length, 4);
    });

    test('DummyQuizQuestions dataset is comprehensive and valid', () {
      expect(DummyQuizQuestions.list.length, greaterThanOrEqualTo(15));

      for (final q in DummyQuizQuestions.list) {
        expect(q.id.isNotEmpty, isTrue);
        expect(q.question.isNotEmpty, isTrue);
        expect(q.options.length, equals(4));
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.explanation.isNotEmpty, isTrue);
        expect(q.category.isNotEmpty, isTrue);
      }
    });
  });

  group('Phase 8 - QuizRepository Game Flow Unit Tests', () {
    final repo = QuizRepository();

    test('Starting a new game sets up proper initial state', () async {
      await repo.init();
      repo.startNewGame(totalQuestions: 5, enableTimer: false);

      expect(repo.isPlaying, isTrue);
      expect(repo.isGameOver, isFalse);
      expect(repo.isQuizFinished, isFalse);
      expect(repo.lives, equals(3));
      expect(repo.score, equals(0));
      expect(repo.streak, equals(0));
      expect(repo.currentIndex, equals(0));
      expect(repo.questions.length, equals(5));
      expect(repo.currentQuestion, isNotNull);
    });

    test('Submitting correct answer increases score and streak', () {
      repo.startNewGame(totalQuestions: 5, enableTimer: false);
      final current = repo.currentQuestion!;

      repo.submitAnswer(current.correctIndex);

      expect(repo.isAnswerSubmitted, isTrue);
      expect(repo.score, greaterThan(0));
      expect(repo.streak, equals(1));
      expect(repo.lives, equals(3));
      expect(repo.correctCount, equals(1));
    });

    test('Submitting wrong answer reduces lives and resets streak', () {
      repo.startNewGame(totalQuestions: 5, enableTimer: false);
      final current = repo.currentQuestion!;
      final wrongIndex = (current.correctIndex + 1) % 4;

      repo.submitAnswer(wrongIndex);

      expect(repo.isAnswerSubmitted, isTrue);
      expect(repo.streak, equals(0));
      expect(repo.lives, equals(2));
    });

    test('Losing all 3 lives results in Game Over', () {
      repo.startNewGame(totalQuestions: 5, enableTimer: false);

      for (int i = 0; i < 3; i++) {
        final current = repo.currentQuestion!;
        final wrongIndex = (current.correctIndex + 1) % 4;
        repo.submitAnswer(wrongIndex);
        if (i < 2) {
          repo.nextQuestion(enableTimer: false);
        }
      }

      expect(repo.lives, equals(0));
      expect(repo.isGameOver, isTrue);
      expect(repo.isPlaying, isFalse);
    });

    test('Completing all questions marks quiz as finished with badge', () {
      repo.startNewGame(totalQuestions: 2, enableTimer: false);

      // Question 1 correct
      repo.submitAnswer(repo.currentQuestion!.correctIndex);
      repo.nextQuestion(enableTimer: false);

      // Question 2 correct
      repo.submitAnswer(repo.currentQuestion!.correctIndex);
      repo.nextQuestion(enableTimer: false);

      expect(repo.isQuizFinished, isTrue);
      expect(repo.isPlaying, isFalse);
      expect(repo.getBadgeTitle(), contains('Kuncen Bandung'));
    });
  });

  group('Phase 8 - GameScreen UI Widget Tests', () {
    testWidgets(
      'GameScreen renders Lobby view with title, stats, and start button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = QuizRepository();
        repo.resetToLobby();

        await tester.pumpWidget(const MaterialApp(home: GameScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Kuis Jelajah Bandung'), findsOneWidget);
        expect(find.text('Kuis Wisata & Budaya Bandung'), findsOneWidget);
        expect(find.text('Skor Tertinggi'), findsOneWidget);
        expect(find.text('Mulai Kuis Sekarang'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Mulai Kuis transitions to in-game play and displays question',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = QuizRepository();
        repo.resetToLobby();

        await tester.pumpWidget(const MaterialApp(home: GameScreen()));
        await tester.pumpAndSettle();

        // Tap start
        await tester.tap(find.text('Mulai Kuis Sekarang'));
        await tester.pump();

        // Should now show in-game view
        expect(find.textContaining('Soal 1 / 8'), findsOneWidget);
        expect(find.text('Waktu Berpikir:'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

        // Tap option A
        await tester.tap(find.text('A'));
        await tester.pump();

        // Explanation or success card and next button should appear
        expect(repo.isAnswerSubmitted, isTrue);
        expect(find.text('Lanjut ke Soal Berikutnya'), findsOneWidget);
      },
    );
  });
}
