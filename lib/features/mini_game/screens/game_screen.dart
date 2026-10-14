import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../models/quiz_question.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _quizRepo = QuizRepository();

  @override
  void initState() {
    super.initState();
    _quizRepo.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _quizRepo,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kuis Jelajah Bandung'),
            actions: [
              if (_quizRepo.isPlaying)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Akhiri Kuis?'),
                          content: const Text(
                            'Progres kuis saat ini tidak akan disimpan.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Lanjutkan Kuis'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _quizRepo.resetToLobby();
                              },
                              child: const Text(
                                'Akhiri',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
          body: SafeArea(child: _buildCurrentStateView()),
        );
      },
    );
  }

  Widget _buildCurrentStateView() {
    if (_quizRepo.isGameOver || _quizRepo.isQuizFinished) {
      return _buildResultView();
    } else if (_quizRepo.isPlaying) {
      return _buildQuizPlayView();
    } else {
      return _buildLobbyView();
    }
  }

  // 1. Lobby View
  Widget _buildLobbyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Banner Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 54,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Kuis Wisata & Budaya Bandung',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Uji wawasan Anda seputar ikon wisata, kuliner legendaris, sejarah kemerdekaan, dan budaya khas Parijs van Java!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

          // High Score Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Skor Tertinggi',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_quizRepo.highScore} pts',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: AppColors.borderLight),
                Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Total Main',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_quizRepo.gamesPlayed} Kali',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Game Rules Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Aturan Permainan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '• 8 pertanyaan pilihan ganda acak dari bank soal wisata Bandung.',
                ),
                SizedBox(height: 4),
                Text(
                  '• Waktu 15 detik per soal. Semakin cepat menjawab, semakin besar bonus poin!',
                ),
                SizedBox(height: 4),
                Text(
                  '• Anda memiliki 3 nyawa (kesempatan). Jawaban salah atau waktu habis mengurangi 1 nyawa.',
                ),
                SizedBox(height: 4),
                Text(
                  '• Pertahankan streak jawaban benar untuk bonus multiplier beruntun.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _quizRepo.startNewGame(totalQuestions: 8),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                'Mulai Kuis Sekarang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 2. Play View
  Widget _buildQuizPlayView() {
    final question = _quizRepo.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final timerFraction = _quizRepo.remainingSeconds / 15.0;

    Color timerColor = AppColors.success;
    if (_quizRepo.remainingSeconds <= 5) {
      timerColor = AppColors.error;
    } else if (_quizRepo.remainingSeconds <= 9) {
      timerColor = Colors.amber;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Status Bar (Question index, Lives, Score & Streak)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Question Progress
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Soal ${_quizRepo.currentIndex + 1} / ${_quizRepo.questions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Lives (Hearts)
              Row(
                children: List.generate(3, (index) {
                  final isAlive = index < _quizRepo.lives;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      isAlive
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isAlive ? Colors.redAccent : Colors.grey.shade400,
                      size: 22,
                    ),
                  );
                }),
              ),

              // Score with Streak Badge
              Row(
                children: [
                  if (_quizRepo.streak > 1)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${_quizRepo.streak} 🔥',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    '${_quizRepo.score} pts',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timer Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Waktu Berpikir:',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '${_quizRepo.remainingSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: timerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timerFraction,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    if (question.hint.isNotEmpty &&
                        !_quizRepo.hintUsed &&
                        !_quizRepo.isAnswerSubmitted)
                      TextButton.icon(
                        onPressed: _quizRepo.useHint,
                        icon: const Icon(Icons.help_outline_rounded, size: 14),
                        label: const Text(
                          'Bantuan',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                if (_quizRepo.hintUsed) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Petunjuk: ${question.hint}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Options
          ...List.generate(question.options.length, (index) {
            final option = question.options[index];
            return _buildOptionButton(
              optionText: option,
              optionIndex: index,
              question: question,
            );
          }),

          // Educational Explanation Card (Appears after answer submission)
          if (_quizRepo.isAnswerSubmitted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _quizRepo.selectedAnswerIndex == question.correctIndex
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color:
                            _quizRepo.selectedAnswerIndex ==
                                question.correctIndex
                            ? AppColors.success
                            : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _quizRepo.selectedAnswerIndex == question.correctIndex
                            ? 'Jawaban Benar! 🎉'
                            : 'Fakta Menarik & Edukasi:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Next Question Button
            ElevatedButton(
              onPressed: () => _quizRepo.nextQuestion(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _quizRepo.currentIndex + 1 < _quizRepo.questions.length &&
                        !_quizRepo.isGameOver
                    ? 'Lanjut ke Soal Berikutnya'
                    : 'Lihat Hasil Akhir',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String optionText,
    required int optionIndex,
    required QuizQuestion question,
  }) {
    Color cardColor = Colors.white;
    Color textColor = AppColors.textPrimaryLight;
    BorderSide borderSide = const BorderSide(color: AppColors.borderLight);
    Widget? trailingIcon;

    if (_quizRepo.isAnswerSubmitted) {
      if (optionIndex == question.correctIndex) {
        // Correct answer highlighted green
        cardColor = AppColors.success.withValues(alpha: 0.12);
        textColor = AppColors.success;
        borderSide = const BorderSide(color: AppColors.success, width: 2);
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 20,
        );
      } else if (optionIndex == _quizRepo.selectedAnswerIndex) {
        // Chosen wrong answer highlighted red
        cardColor = AppColors.error.withValues(alpha: 0.12);
        textColor = AppColors.error;
        borderSide = const BorderSide(color: AppColors.error, width: 2);
        trailingIcon = const Icon(
          Icons.cancel_rounded,
          color: AppColors.error,
          size: 20,
        );
      } else {
        // Faded options
        textColor = Colors.grey.shade400;
      }
    }

    final optionLabels = ['A', 'B', 'C', 'D'];
    final label = optionIndex < 4 ? optionLabels[optionIndex] : '$optionIndex';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _quizRepo.isAnswerSubmitted
            ? null
            : () => _quizRepo.submitAnswer(optionIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(borderSide),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              ?trailingIcon,
            ],
          ),
        ),
      ),
    );
  }

  // 3. Result View (Game Over / Finished)
  Widget _buildResultView() {
    final isWin = !_quizRepo.isGameOver && _quizRepo.isQuizFinished;
    final badgeTitle = _quizRepo.getBadgeTitle();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isWin ? Colors.amber : Colors.redAccent).withValues(
                  alpha: 0.15,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWin ? Icons.emoji_events_rounded : Icons.heart_broken_rounded,
                size: 64,
                color: isWin ? Colors.amber : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            isWin ? 'Selamat! Kuis Selesai! 🎉' : 'Nyawa Habis! Game Over 💔',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            isWin
                ? 'Anda telah menyelesaikan seluruh pertanyaan kuis Bandung.'
                : 'Jangan berkecil hati, ayo coba lagi untuk meningkatkan skor wawasan Anda!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

          // Earned Badge Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Gelar Wisatawan:',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badgeTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Score and Accuracy Metrics
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Skor Akhir',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_quizRepo.score}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 36, color: AppColors.borderLight),
                Column(
                  children: [
                    const Text(
                      'Benar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_quizRepo.correctCount} / ${_quizRepo.questions.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 36, color: AppColors.borderLight),
                Column(
                  children: [
                    const Text(
                      'Rekor Terbaik',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_quizRepo.highScore}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _quizRepo.startNewGame(totalQuestions: 8),
              icon: const Icon(Icons.replay_rounded),
              label: const Text(
                'Main Lagi (Kuis Baru)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _quizRepo.resetToLobby,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Kembali ke Menu Kuis'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
