import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dummy/dummy_quiz_questions.dart';
import '../../models/quiz_question.dart';

class QuizRepository extends ChangeNotifier {
  static final QuizRepository _instance = QuizRepository._internal();
  factory QuizRepository() => _instance;
  QuizRepository._internal();

  static const String _keyHighScore = 'bandunghub_quiz_high_score';
  static const String _keyGamesPlayed = 'bandunghub_quiz_games_played';
  static const int _questionDurationSeconds = 15;

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _lives = 3;
  int _remainingSeconds = _questionDurationSeconds;
  int? _selectedAnswerIndex;
  bool _isAnswerSubmitted = false;
  bool _isGameOver = false;
  bool _isQuizFinished = false;
  bool _isPlaying = false;
  bool _hintUsed = false;
  int _correctCount = 0;

  Timer? _timer;
  int _highScore = 0;
  int _gamesPlayed = 0;
  bool _isInitialized = false;

  // Getters
  List<QuizQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get streak => _streak;
  int get lives => _lives;
  int get remainingSeconds => _remainingSeconds;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswerSubmitted => _isAnswerSubmitted;
  bool get isGameOver => _isGameOver;
  bool get isQuizFinished => _isQuizFinished;
  bool get isPlaying => _isPlaying;
  bool get hintUsed => _hintUsed;
  int get correctCount => _correctCount;
  int get highScore => _highScore;
  int get gamesPlayed => _gamesPlayed;

  QuizQuestion? get currentQuestion {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return null;
    return _questions[_currentIndex];
  }

  // Initialize and load saved high scores
  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_keyHighScore) ?? 0;
    _gamesPlayed = prefs.getInt(_keyGamesPlayed) ?? 0;
    _isInitialized = true;
    notifyListeners();
  }

  // Start new game session
  void startNewGame({int totalQuestions = 8, bool enableTimer = true}) {
    _timer?.cancel();

    // Shuffle and pick subset of questions
    final all = List<QuizQuestion>.from(DummyQuizQuestions.list)..shuffle();
    final count = totalQuestions.clamp(1, all.length);
    _questions = all.take(count).toList();

    _currentIndex = 0;
    _score = 0;
    _streak = 0;
    _lives = 3;
    _remainingSeconds = _questionDurationSeconds;
    _selectedAnswerIndex = null;
    _isAnswerSubmitted = false;
    _isGameOver = false;
    _isQuizFinished = false;
    _isPlaying = true;
    _hintUsed = false;
    _correctCount = 0;

    _gamesPlayed++;
    _persistStats();

    if (enableTimer) {
      _startTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _questionDurationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    _timer?.cancel();
    if (_isAnswerSubmitted) return;

    _isAnswerSubmitted = true;
    _selectedAnswerIndex = -1; // timed out
    _streak = 0;
    _lives--;

    if (_lives <= 0) {
      _isGameOver = true;
      _isPlaying = false;
    }
    notifyListeners();
  }

  // Submit Answer
  void submitAnswer(int optionIndex) {
    if (_isAnswerSubmitted || !_isPlaying) return;

    _timer?.cancel();
    _selectedAnswerIndex = optionIndex;
    _isAnswerSubmitted = true;

    final question = currentQuestion;
    if (question != null && optionIndex == question.correctIndex) {
      // Calculate score with speed bonus and streak multiplier
      final speedBonus = _remainingSeconds * 6;
      final streakBonus = _streak * 25;
      final earned = question.points + speedBonus + streakBonus;

      _score += earned;
      _streak++;
      _correctCount++;

      if (_score > _highScore) {
        _highScore = _score;
        _persistStats();
      }
    } else {
      // Wrong answer
      _lives--;
      _streak = 0;

      if (_lives <= 0) {
        _isGameOver = true;
        _isPlaying = false;
      }
    }

    notifyListeners();
  }

  // Advance to next question
  void nextQuestion({bool enableTimer = true}) {
    if (_currentIndex + 1 < _questions.length && !_isGameOver) {
      _currentIndex++;
      _selectedAnswerIndex = null;
      _isAnswerSubmitted = false;
      _hintUsed = false;
      if (enableTimer) {
        _startTimer();
      }
    } else {
      // Finish quiz
      _timer?.cancel();
      _isQuizFinished = true;
      _isPlaying = false;

      if (_score > _highScore) {
        _highScore = _score;
        _persistStats();
      }
    }
    notifyListeners();
  }

  // Use hint
  void useHint() {
    if (!_hintUsed && !_isAnswerSubmitted) {
      _hintUsed = true;
      notifyListeners();
    }
  }

  // Badge based on performance
  String getBadgeTitle() {
    if (_questions.isEmpty) return 'Wisatawan Bandung';
    final accuracy = _correctCount / _questions.length;

    if (accuracy >= 0.8 || _score >= 900) {
      return 'Kuncen Bandung (Ahli Wisata Sejati) 🏆';
    } else if (accuracy >= 0.5 || _score >= 500) {
      return 'Penjelajah Parijs van Java 🌟';
    } else {
      return 'Wisatawan Pemula Bandung 🎒';
    }
  }

  Future<void> _persistStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHighScore, _highScore);
    await prefs.setInt(_keyGamesPlayed, _gamesPlayed);
  }

  // Reset to lobby
  void resetToLobby() {
    _timer?.cancel();
    _isPlaying = false;
    _isGameOver = false;
    _isQuizFinished = false;
    _currentIndex = 0;
    _score = 0;
    _streak = 0;
    _lives = 3;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
