import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/sensor_service.dart';
import '../controllers/jumpy_game_controller.dart';
import '../models/jumpy_game_models.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final _controller = JumpyGameController();
  final _sensorService = SensorService();
  StreamSubscription<double>? _tiltSub;
  bool _isGyroEnabled = true;

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Cached Pixel Art Assets from Bocchi-Jumpy-Game
  ui.Image? _bocchiImage;
  ui.Image? _woodImage;
  ui.Image? _bgImage;
  ui.Image? _birdImage;
  ui.Image? _ghostImage;

  @override
  void initState() {
    super.initState();
    _controller.init();
    _ticker = createTicker(_onTick);
    _loadPixelAssets();

    // Listen to device motion/gyroscope for tilt-based steering during gameplay
    _sensorService.startListening();
    _tiltSub = _sensorService.gameTiltStream.listen((tilt) {
      if (_isGyroEnabled &&
          _controller.isPlaying &&
          !_controller.isPaused &&
          !_controller.isGameOver) {
        _controller.setHorizontalMovement(tilt);
      }
    });
  }

  Future<void> _loadPixelAssets() async {
    try {
      _bocchiImage = await _loadUiImage('assets/mini_game/bocchi.png');
      _woodImage = await _loadUiImage('assets/mini_game/wood.png');
      _bgImage = await _loadUiImage('assets/mini_game/background.png');
      _birdImage = await _loadUiImage('assets/mini_game/bird.png');
      _ghostImage = await _loadUiImage('assets/mini_game/ghost.png');
    } catch (_) {
      // Fallbacks will be used seamlessly
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<ui.Image?> _loadUiImage(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final codec =
          await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (_controller.isPlaying &&
        !_controller.isPaused &&
        !_controller.isGameOver) {
      _controller.updatePhysics(dt.clamp(0.001, 0.05));
    }
  }

  @override
  void dispose() {
    _tiltSub?.cancel();
    _sensorService.stopListening();
    _ticker.dispose();
    super.dispose();
  }

  void _startGame(Size size) {
    _controller.startNewGame(
      screenWidth: size.width,
      screenHeight: size.height,
    );
    _lastElapsed = Duration.zero;
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isPlaying = _controller.isPlaying;
        return Scaffold(
          backgroundColor: isPlaying
              ? const Color(0xFF16152B) // Retro Anime Night Slate during play
              : AppColors.getBackgroundColor(context), // App theme during Lobby
          appBar: AppBar(
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎸', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isPlaying ? 'Bocchi Jumpy' : 'Bocchi Jumpy Game',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isPlaying
                          ? Colors.white
                          : AppColors.getTextPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Logo Tanda Tanya (Panduan Lompat Pixel - hanya tampil di lobby agar tidak sesak saat main)
              if (!isPlaying)
                IconButton(
                  key: const Key('btn_game_how_to_play'),
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: 'Panduan Lompat Pixel',
                  onPressed: () => _showHowToPlayDialog(context),
                ),
              // Gyro Tilt Toggle Button
              IconButton(
                visualDensity: isPlaying ? VisualDensity.compact : null,
                icon: Icon(
                  _isGyroEnabled
                      ? Icons.screen_rotation_rounded
                      : Icons.screen_lock_rotation_rounded,
                  color: _isGyroEnabled
                      ? AppColors.primary
                      : AppColors.textSecondaryLight,
                ),
                tooltip: _isGyroEnabled
                    ? 'Sensor Gyro Aktif (Miringkan HP)'
                    : 'Sensor Gyro Nonaktif',
                onPressed: () {
                  setState(() => _isGyroEnabled = !_isGyroEnabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isGyroEnabled
                            ? 'Sensor Gyroscope Aktif: Miringkan HP ke kiri/kanan untuk mengarahkan Bocchi!'
                            : 'Sensor Gyroscope Nonaktif: Sentuh atau geser layar kiri/kanan untuk bergerak.',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: _isGyroEnabled
                          ? AppColors.primary
                          : Colors.grey.shade800,
                    ),
                  );
                },
              ),
              if (_controller.isPlaying)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _controller.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: AppColors.secondary,
                  ),
                  tooltip: _controller.isPaused ? 'Lanjutkan' : 'Jeda',
                  onPressed: _controller.togglePause,
                ),
              if (_controller.isPlaying)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.error),
                  tooltip: 'Keluar',
                  onPressed: () {
                    _controller.resetToLobby();
                  },
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              if (_controller.isGameOver) {
                return _buildGameOverView(size);
              } else if (_controller.isPlaying) {
                return _buildGamePlayView(size);
              } else {
                return _buildLobbyView(size);
              }
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. LOBBY VIEW (BandungHub Theme & Anime Elements)
  // ===========================================================================
  Widget _buildLobbyView(Size size) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Card matching App Theme (Teal & Amber Parahyangan)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Anime Character Avatar (Bocchi)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/mini_game/bocchi.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('🎸', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Pixel Edition Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: const Text(
                    '★ BOCCHI THE ROCK! MINI-GAME ★',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'Bocchi Jumpy!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bantu Bocchi (Hitori Gotoh) melompat setinggi mungkin! Miringkan HP Anda untuk mengarahkan lompatan atau gunakan tombol sentuh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.getTextSecondary(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // High Score & Stats matching App Theme
          Row(
            children: [
              Expanded(
                child: _buildPixelStatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Skor Tertinggi',
                  value: '${_controller.highScore} pts',
                  borderColor: AppColors.secondary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPixelStatCard(
                  icon: Icons.sports_esports_rounded,
                  iconColor: AppColors.primary,
                  title: 'Total Main',
                  value: '${_controller.gamesPlayed} Kali',
                  borderColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Power-Up & Tips Card (Pengganti tombol duplicate agar rapi & tidak kosong)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.getBorderColor(context),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Item & Power-Up Spesial',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPowerUpPill(
                      context,
                      '🎵',
                      'Not Musik',
                      '+10 Pts',
                      AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildPowerUpPill(
                      context,
                      '🎸',
                      'Pick Gitar',
                      '+50 Pts',
                      AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    _buildPowerUpPill(
                      context,
                      '🌀',
                      'Pegas Super',
                      'Lompat Jauh',
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Miringkan HP (Sensor Gyro) atau sentuh / geser layar kiri dan kanan.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.getTextSecondary(context),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Start Game Button matching App Theme
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            onPressed: () => _startGame(size),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, size: 28),
                SizedBox(width: 8),
                Text(
                  'Mulai Lompat!',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPowerUpPill(
    BuildContext context,
    String emoji,
    String label,
    String value,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🎮', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Panduan Lompat Pixel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kuasai cara bermain dan jenis rintangan untuk meraih rekor skor tertinggi bersama Bocchi!',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),
              _buildGuideDialogItem(
                '🪵',
                'Platform Kayu (Normal)',
                'Lompat ke atas kayu untuk memantul naik secara stabil.',
              ),
              const Divider(height: 16),
              _buildGuideDialogItem(
                '⚡',
                'Amplifier Spring (Super)',
                'Pegas amplifier musik melesatkan Bocchi tinggi ke langit!',
              ),
              const Divider(height: 16),
              _buildGuideDialogItem(
                '🕊️',
                'Burung & Ghost (Musuh)',
                'Hindari musuh terbang anime agar Bocchi tidak Game Over.',
              ),
              const Divider(height: 16),
              _buildGuideDialogItem(
                '🎸',
                'Pick Gitar & Nada Musik',
                'Koleksi item musik Bocchi the Rock untuk bonus skor ekstra!',
              ),
              const Divider(height: 16),
              _buildGuideDialogItem(
                '📱',
                'Kontrol Touchscreen & Gyroscope',
                'Sentuh / geser layar kiri dan kanan, atau aktifkan sensor Gyroscope untuk bermain dengan memiringkan HP.',
              ),
              const Divider(height: 16),
              _buildGuideDialogItem(
                '🔄',
                'Screen Wrap (Tembus Layar)',
                'Keluar melewati sisi kiri layar akan muncul otomatis di sisi kanan!',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Mengerti!'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideDialogItem(String icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPixelStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. ACTIVE GAMEPLAY VIEW (Pixel Canvas + Touch Controls)
  // ===========================================================================
  Widget _buildGamePlayView(Size size) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        if (details.localPosition.dx < size.width / 2) {
          _controller.moveLeft();
        } else {
          _controller.moveRight();
        }
      },
      onTapUp: (_) => _controller.stopMoving(),
      onTapCancel: () => _controller.stopMoving(),
      onHorizontalDragUpdate: (details) {
        final delta = details.primaryDelta ?? 0;
        _controller.setHorizontalMovement(delta * 0.25);
      },
      onHorizontalDragEnd: (_) {
        _controller.stopMoving();
      },
      child: Stack(
        children: [
          // The Custom Canvas Painter
          Positioned.fill(
            child: CustomPaint(
              size: size,
              painter: _BocchiGamePainter(
                player: _controller.player,
                platforms: _controller.platforms,
                enemies: _controller.enemies,
                highScore: _controller.highScore,
                currentScore: _controller.score,
                bgScroll: _controller.bgScroll,
                bocchiImage: _bocchiImage,
                woodImage: _woodImage,
                bgImage: _bgImage,
                birdImage: _birdImage,
                ghostImage: _ghostImage,
              ),
            ),
          ),

          // Top Retro HUD (Score & High Score)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: SafeArea(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: size.width - 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Score Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFF7EB3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎸', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Text(
                              '${_controller.score}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Gyro Indicator Pill
                      if (_isGyroEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D225A)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF7EB3),
                              width: 1.2,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.screen_rotation_rounded,
                                color: Color(0xFFFF7EB3),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'GYRO',
                                style: TextStyle(
                                  color: Color(0xFFFF7EB3),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // High Score Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFFFD54F), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'HI: ${_controller.highScore}',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. GAME OVER VIEW (Retro Arcade Style)
  // ===========================================================================
  Widget _buildGameOverView(Size size) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A38),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFF5252),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5252).withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Defeated anime chibi Bocchi icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCDD2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF5252), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/mini_game/bocchi.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('😵', style: TextStyle(fontSize: 42)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              '★ GAME OVER! ★',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF5252),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            if (_controller.isNewRecord)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'NEW HIGH SCORE! 🏆',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              'SKOR AKHIR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB0B3C7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_controller.score} pts',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF7EB3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rekor Terbaik: ${_controller.highScore} pts',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB0B3C7),
              ),
            ),
            const SizedBox(height: 24),

            // Play Again
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7EB3),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              onPressed: () => _startGame(size),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Main Lagi 🎸',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Back to Menu
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _controller.resetToLobby,
              child: const Text(
                'Kembali ke Menu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

// =============================================================================
// GAME CANVAS PAINTER (Anime Pixel Art: Bocchi, Wood Platforms, Enemies, Notes)
// =============================================================================
class _BocchiGamePainter extends CustomPainter {
  final JumperPlayer player;
  final List<GamePlatform> platforms;
  final List<GameEnemy> enemies;
  final int highScore;
  final int currentScore;
  final double bgScroll;

  final ui.Image? bocchiImage;
  final ui.Image? woodImage;
  final ui.Image? bgImage;
  final ui.Image? birdImage;
  final ui.Image? ghostImage;

  _BocchiGamePainter({
    required this.player,
    required this.platforms,
    required this.enemies,
    required this.highScore,
    required this.currentScore,
    required this.bgScroll,
    this.bocchiImage,
    this.woodImage,
    this.bgImage,
    this.birdImage,
    this.ghostImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background (Parallax Scrolling Pixel Anime Background or Gradient)
    if (bgImage != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        bgImage!.width.toDouble(),
        bgImage!.height.toDouble(),
      );
      final offset = bgScroll % size.height;

      // Draw two vertical slices to loop seamlessly
      canvas.drawImageRect(
        bgImage!,
        src,
        Rect.fromLTWH(0, offset, size.width, size.height),
        Paint()..filterQuality = FilterQuality.none,
      );
      canvas.drawImageRect(
        bgImage!,
        src,
        Rect.fromLTWH(0, offset - size.height, size.width, size.height),
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      // Anime Sky Gradient Fallback
      final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF4CA1AF),
            Color(0xFFC4E0E5),
          ],
        ).createShader(bgRect);
      canvas.drawRect(bgRect, bgPaint);
    }

    // 2. High Score Line Indicator (Just like Bocchi Jumpy Game)
    if (highScore > 0) {
      final scrollThreshold = size.height * 0.44;
      final lineY = currentScore - highScore + scrollThreshold;
      if (lineY >= 0 && lineY <= size.height) {
        final linePaint = Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(0, lineY),
          Offset(size.width, lineY),
          linePaint,
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: '★ HIGH SCORE: $highScore ★',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD54F),
              backgroundColor: Colors.black87,
              letterSpacing: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width - textPainter.width - 12, lineY - 14),
        );
      }
    }

    // 3. Draw Platforms (Pixel Wood Texture from GitHub repo)
    for (final p in platforms) {
      if (p.isBroken) continue;

      if (woodImage != null) {
        final src = Rect.fromLTWH(
          0,
          0,
          woodImage!.width.toDouble(),
          woodImage!.height.toDouble(),
        );
        final dst = Rect.fromLTWH(p.x, p.y, p.width, p.height);

        // Platform color tint for special types
        final paint = Paint()..filterQuality = FilterQuality.none;
        if (p.type == PlatformType.spring) {
          paint.colorFilter = const ColorFilter.mode(
            Color(0xFFFFD54F),
            BlendMode.modulate,
          );
        } else if (p.type == PlatformType.moving) {
          paint.colorFilter = const ColorFilter.mode(
            Color(0xFF80D8FF),
            BlendMode.modulate,
          );
        } else if (p.type == PlatformType.fragile) {
          paint.colorFilter = const ColorFilter.mode(
            Color(0xFFFF8A80),
            BlendMode.modulate,
          );
        }

        canvas.drawImageRect(woodImage!, src, dst, paint);
      } else {
        // Fallback wooden pixel platform
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(p.x, p.y, p.width, p.height),
          const Radius.circular(5),
        );

        Color pColor = const Color(0xFF8D6E63);
        if (p.type == PlatformType.moving) pColor = const Color(0xFF29B6F6);
        if (p.type == PlatformType.spring) pColor = const Color(0xFFFFB300);
        if (p.type == PlatformType.fragile) pColor = const Color(0xFFD7CCC8);

        canvas.drawRRect(rect, Paint()..color = pColor);
      }

      // Spring Amplifier Icon for Spring Platform
      if (p.type == PlatformType.spring) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '⚡',
            style: TextStyle(fontSize: 13),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(p.x + p.width / 2 - 6, p.y - 12),
        );
      }

      // Moving Platform Indicator
      if (p.type == PlatformType.moving) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '◀▶',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(p.x + p.width / 2 - 8, p.y + 1),
        );
      }

      // Draw Collectibles (Bocchi Theme: Notes, Guitar Pick, Stars, Drinks)
      if (p.collectible != null) {
        String emoji = '⭐';
        switch (p.collectible!) {
          case CollectibleType.musicNote:
            emoji = '🎵';
            break;
          case CollectibleType.guitarPick:
            emoji = '🎸';
            break;
          case CollectibleType.drink:
            emoji = '🧃';
            break;
          case CollectibleType.star:
            emoji = '⭐';
            break;
          case CollectibleType.batagor:
            emoji = '🥟';
            break;
          case CollectibleType.coffee:
            emoji = '☕';
            break;
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: emoji,
            style: const TextStyle(fontSize: 16),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(p.x + p.width / 2 - 8, p.y - 20),
        );
      }
    }

    // 4. Draw Flying Enemies (Bird / Ghost from GitHub repository)
    for (final enemy in enemies) {
      if (enemy.type == EnemyType.bird && birdImage != null) {
        // Bird Spritesheet: 32x32 frames
        final frame = enemy.animFrame % 8;
        final src = Rect.fromLTWH(frame * 32.0, 0, 32, 32);
        final dst = Rect.fromLTWH(
          -enemy.width / 2,
          -enemy.height / 2,
          enemy.width,
          enemy.height,
        );

        canvas.save();
        canvas.translate(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2);
        if (enemy.direction == 1) {
          canvas.scale(-1.0, 1.0); // Facing right
        }
        canvas.drawImageRect(
          birdImage!,
          src,
          dst,
          Paint()..filterQuality = FilterQuality.none,
        );
        canvas.restore();
      } else if (enemy.type == EnemyType.ghost && ghostImage != null) {
        final src = Rect.fromLTWH(
          0,
          0,
          ghostImage!.width.toDouble(),
          ghostImage!.height.toDouble(),
        );
        final dst = Rect.fromLTWH(
          enemy.x,
          enemy.y,
          enemy.width,
          enemy.height,
        );
        canvas.drawImageRect(
          ghostImage!,
          src,
          dst,
          Paint()..filterQuality = FilterQuality.none,
        );
      } else {
        // Fallback Enemy Emoji
        final textPainter = TextPainter(
          text: TextSpan(
            text: enemy.type == EnemyType.bird ? '🕊️' : '👻',
            style: const TextStyle(fontSize: 22),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(enemy.x, enemy.y));
      }
    }

    // 5. Draw Bocchi Character (Pixel Sprite with Horizontal Flip)
    if (bocchiImage != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        bocchiImage!.width.toDouble(),
        bocchiImage!.height.toDouble(),
      );

      canvas.save();
      canvas.translate(player.x + player.width / 2, player.y + player.height / 2);

      // Flip horizontally if facing left
      if (!player.facingRight) {
        canvas.scale(-1.0, 1.0);
      }

      // Squash and stretch bounce animation
      double scaleY = 1.0;
      double scaleX = 1.0;
      if (player.velY < -5) {
        scaleY = 1.15; // Stretched upward on jump
        scaleX = 0.88;
      } else if (player.velY > 5) {
        scaleY = 0.92;
        scaleX = 1.08;
      }
      canvas.scale(scaleX, scaleY);

      final dst = Rect.fromLTWH(
        -player.width / 2,
        -player.height / 2,
        player.width,
        player.height,
      );

      canvas.drawImageRect(
        bocchiImage!,
        src,
        dst,
        Paint()..filterQuality = FilterQuality.none,
      );

      canvas.restore();
    } else {
      // Fallback Adorable Anime Bocchi Chibi Vector
      _drawBocchiVectorFallback(canvas, player);
    }
  }

  void _drawBocchiVectorFallback(Canvas canvas, JumperPlayer player) {
    final centerX = player.x + player.width / 2;

    // Pink Tracksuit Body
    final bodyPaint = Paint()..color = const Color(0xFFFF6B97);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            player.x + 6, player.y + 16, player.width - 12, player.height - 18),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    // Pink Anime Hair & Head
    final headPaint = Paint()..color = const Color(0xFFFF85A2);
    canvas.drawCircle(Offset(centerX, player.y + 14), 14, headPaint);

    // Signature Blue & Yellow Hair Cubes of Bocchi
    final blueCube = Paint()..color = const Color(0xFF00E5FF);
    final yellowCube = Paint()..color = const Color(0xFFFFD54F);
    final cubeX = player.facingRight ? player.x + 2 : player.x + player.width - 10;
    canvas.drawRect(Rect.fromLTWH(cubeX, player.y + 2, 7, 7), blueCube);
    canvas.drawRect(Rect.fromLTWH(cubeX + 5, player.y + 6, 7, 7), yellowCube);

    // Anime Eyes
    final eyePaint = Paint()..color = const Color(0xFF1A1C29);
    final eyeX = player.facingRight ? centerX + 3 : centerX - 6;
    canvas.drawCircle(Offset(eyeX, player.y + 14), 2.5, eyePaint);
    canvas.drawCircle(Offset(eyeX + (player.facingRight ? 6 : -6), player.y + 14), 2.5, eyePaint);
  }

  @override
  bool shouldRepaint(covariant _BocchiGamePainter oldDelegate) => true;
}
