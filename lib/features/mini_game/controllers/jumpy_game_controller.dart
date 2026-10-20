import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/jumpy_game_models.dart';

class JumpyGameController extends ChangeNotifier {
  static const String _keyHighScore = 'bandunghub_jumpy_high_score';
  static const String _keyGamesPlayed = 'bandunghub_jumpy_games_played';

  // Game constants (calibrated for 60 FPS responsive arcade feel)
  static const double gravity = 0.44;
  static const double normalJumpForce = -13.0;
  static const double superJumpForce = -18.5;
  static const double horizontalMoveSpeed = 7.0;
  static const int maxPlatforms = 8;

  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;
  int _highScore = 0;
  int _gamesPlayed = 0;
  bool _isNewRecord = false;
  double _bgScroll = 0;

  late JumperPlayer _player;
  final List<GamePlatform> _platforms = [];
  final List<GameEnemy> _enemies = [];
  final Random _random = Random();

  double _screenWidth = 360;
  double _screenHeight = 640;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isGameOver => _isGameOver;
  bool get isPaused => _isPaused;
  int get score => _score;
  int get highScore => _highScore;
  int get gamesPlayed => _gamesPlayed;
  bool get isNewRecord => _isNewRecord;
  double get bgScroll => _bgScroll;
  JumperPlayer get player => _player;
  List<GamePlatform> get platforms => List.unmodifiable(_platforms);
  List<GameEnemy> get enemies => List.unmodifiable(_enemies);

  JumpyGameController() {
    _player = JumperPlayer(x: 180, y: 500);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_keyHighScore) ?? 0;
    _gamesPlayed = prefs.getInt(_keyGamesPlayed) ?? 0;
    notifyListeners();
  }

  void startNewGame({double? screenWidth, double? screenHeight}) {
    if (screenWidth != null && screenWidth > 50) _screenWidth = screenWidth;
    if (screenHeight != null && screenHeight > 50) _screenHeight = screenHeight;

    _score = 0;
    _isNewRecord = false;
    _isGameOver = false;
    _isPaused = false;
    _isPlaying = true;
    _bgScroll = 0;

    // Reset player position
    _player.reset(_screenWidth / 2 - 22, _screenHeight - 130);

    // Clear platforms and enemies
    _platforms.clear();
    _enemies.clear();

    // 1. Starting platform right below the player
    _platforms.add(
      GamePlatform(
        x: _screenWidth / 2 - 45,
        y: _screenHeight - 70,
        width: 90,
        type: PlatformType.normal,
      ),
    );

    // 2. Generate initial climbable platforms up to the top of screen
    double curY = _screenHeight - 150;
    while (_platforms.length < maxPlatforms && curY > -100) {
      _spawnPlatformAt(curY);
      curY -= 65 + _random.nextDouble() * 35;
    }

    _gamesPlayed++;
    _saveGamesPlayed();

    notifyListeners();
  }

  void _spawnPlatformAt(double y) {
    final pWidth = 60.0 + _random.nextDouble() * 20.0;
    final pX = _random.nextDouble() * (_screenWidth - pWidth);

    // Determine platform type based on score progression
    PlatformType pType = PlatformType.normal;
    final typeRoll = _random.nextDouble();

    if (_score > 800 && typeRoll < 0.28) {
      pType = PlatformType.moving;
    } else if (typeRoll > 0.84) {
      pType = PlatformType.spring;
    } else if (_score > 1500 && typeRoll < 0.42) {
      pType = PlatformType.fragile;
    }

    // Determine collectible (anime music notes, guitar picks, stars, drinks)
    CollectibleType? col;
    if (_random.nextDouble() < 0.28) {
      final colRoll = _random.nextInt(6);
      switch (colRoll) {
        case 0:
          col = CollectibleType.musicNote;
          break;
        case 1:
          col = CollectibleType.guitarPick;
          break;
        case 2:
          col = CollectibleType.drink;
          break;
        case 3:
          col = CollectibleType.star;
          break;
        case 4:
          col = CollectibleType.batagor;
          break;
        default:
          col = CollectibleType.coffee;
          break;
      }
    }

    _platforms.add(
      GamePlatform(
        x: pX,
        y: y,
        width: pWidth,
        type: pType,
        speed: 1.2 + _random.nextDouble() * 1.5,
        direction: _random.nextBool() ? 1 : -1,
        collectible: col,
      ),
    );
  }

  /// Single tick physics update
  void updatePhysics(double dt) {
    if (!_isPlaying || _isGameOver || _isPaused) return;

    // 1. Horizontal movement
    _player.x += _player.velX;

    // Screen wrap around (like original Bocchi game & Doodle Jump)
    if (_player.x < -_player.width) {
      _player.x = _screenWidth;
    } else if (_player.x > _screenWidth) {
      _player.x = -_player.width;
    }

    // 2. Vertical movement & Gravity
    _player.velY += gravity;
    _player.y += _player.velY;

    // 3. Platform collisions (only when player is falling down)
    if (_player.velY > 0) {
      final playerBottom = _player.y + _player.height;
      final playerCenterX = _player.x + _player.width / 2;

      for (final p in _platforms) {
        if (p.isBroken) continue;

        // Check feet collision with platform top
        final pTop = p.y;
        final pBottom = p.y + p.height;
        final pLeft = p.x;
        final pRight = p.x + p.width;

        final isVerticallyIntersecting =
            playerBottom >= pTop && playerBottom <= pBottom + 14;
        final isHorizontallyIntersecting =
            playerCenterX >= pLeft - 12 && playerCenterX <= pRight + 12;

        if (isVerticallyIntersecting && isHorizontallyIntersecting) {
          if (p.type == PlatformType.spring) {
            _player.velY = superJumpForce;
            _score += 60;
          } else if (p.type == PlatformType.fragile) {
            p.isBroken = true;
            _player.velY = normalJumpForce * 0.85;
          } else {
            _player.velY = normalJumpForce;
          }
          break;
        }
      }
    }

    // 4. Collectibles collection
    for (final p in _platforms) {
      if (p.collectible != null) {
        final colX = p.x + p.width / 2;
        final colY = p.y - 20;

        final distSq = pow((_player.x + _player.width / 2) - colX, 2) +
            pow((_player.y + _player.height / 2) - colY, 2);

        if (distSq < 1200) {
          // Collected item bonus
          int bonus = 100;
          switch (p.collectible!) {
            case CollectibleType.guitarPick:
              bonus = 250;
              break;
            case CollectibleType.musicNote:
              bonus = 150;
              break;
            case CollectibleType.star:
              bonus = 200;
              break;
            case CollectibleType.drink:
              bonus = 180;
              break;
            case CollectibleType.batagor:
            case CollectibleType.coffee:
              bonus = 100;
              break;
          }
          _score += bonus;
          p.collectible = null;
        }
      }
    }

    // 5. Update moving platforms
    for (final p in _platforms) {
      if (p.type == PlatformType.moving) {
        p.x += p.direction * p.speed;
        if (p.x <= 0) {
          p.x = 0;
          p.direction = 1;
        } else if (p.x + p.width >= _screenWidth) {
          p.x = _screenWidth - p.width;
          p.direction = -1;
        }
      }
    }

    // 6. Spawn & Update Enemies (Bird / Ghost like in GitHub repo)
    if (_score > 1000 && _enemies.isEmpty && _random.nextDouble() < 0.02) {
      final dir = _random.nextBool() ? 1 : -1;
      _enemies.add(
        GameEnemy(
          x: dir == 1 ? -45.0 : _screenWidth + 15.0,
          y: _random.nextDouble() * (_screenHeight * 0.3) + 70,
          type: _random.nextBool() ? EnemyType.bird : EnemyType.ghost,
          direction: dir,
          speed: 1.8 + _random.nextDouble() * 1.2,
        ),
      );
    }

    for (final enemy in _enemies) {
      enemy.x += enemy.direction * enemy.speed;
      enemy.animTimer += dt;
      if (enemy.animTimer > 0.08) {
        enemy.animFrame = (enemy.animFrame + 1) % 8;
        enemy.animTimer = 0;
      }
    }

    // Check collision between player and enemies
    final playerHitBox = Rect.fromLTWH(
      _player.x + 8,
      _player.y + 6,
      _player.width - 16,
      _player.height - 12,
    );

    for (final enemy in _enemies) {
      final enemyHitBox = Rect.fromLTWH(
        enemy.x + 6,
        enemy.y + 6,
        enemy.width - 12,
        enemy.height - 12,
      );

      if (playerHitBox.overlaps(enemyHitBox)) {
        _triggerGameOver();
        notifyListeners();
        return;
      }
    }

    // 7. Camera scroll when player rises past scroll threshold
    final scrollThreshold = _screenHeight * 0.44;
    if (_player.y < scrollThreshold) {
      final scroll = scrollThreshold - _player.y;
      _player.y = scrollThreshold;

      // Scroll platforms down
      for (final p in _platforms) {
        p.y += scroll;
      }

      // Scroll enemies down
      for (final enemy in _enemies) {
        enemy.y += scroll;
      }

      // Update background parallax scroll
      _bgScroll = (_bgScroll + scroll * 0.45) % _screenHeight;

      // Add to score
      _score += scroll.toInt();

      // Check high score
      if (_score > _highScore) {
        _highScore = _score;
        _isNewRecord = true;
        _saveHighScore();
      }
    }

    // 8. Recycle off-screen platforms and generate new ones above
    _platforms.removeWhere((p) => p.y > _screenHeight + 50);
    _enemies.removeWhere(
      (e) =>
          e.y > _screenHeight + 50 ||
          (e.direction == 1 && e.x > _screenWidth + 80) ||
          (e.direction == -1 && e.x < -80),
    );

    // Find highest platform
    double highestY = 0;
    if (_platforms.isNotEmpty) {
      highestY = _platforms.map((p) => p.y).reduce(min);
    }

    while (_platforms.length < maxPlatforms) {
      highestY -= (70.0 + _random.nextDouble() * 32.0);
      _spawnPlatformAt(highestY);
    }

    // 9. Check Game Over (falling off bottom of screen)
    if (_player.y > _screenHeight + 35) {
      _triggerGameOver();
    }

    notifyListeners();
  }

  void moveLeft() {
    _player.velX = -horizontalMoveSpeed;
    _player.facingRight = false;
  }

  void moveRight() {
    _player.velX = horizontalMoveSpeed;
    _player.facingRight = true;
  }

  void stopMoving() {
    _player.velX = 0;
  }

  void setHorizontalMovement(double normalizedDelta) {
    _player.velX = normalizedDelta.clamp(-1.0, 1.0) * horizontalMoveSpeed;
    if (_player.velX > 0.4) {
      _player.facingRight = true;
    } else if (_player.velX < -0.4) {
      _player.facingRight = false;
    }
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void _triggerGameOver() {
    _isPlaying = false;
    _isGameOver = true;
    if (_score > _highScore) {
      _highScore = _score;
      _isNewRecord = true;
      _saveHighScore();
    }
  }

  void resetToLobby() {
    _isPlaying = false;
    _isGameOver = false;
    _isPaused = false;
    _score = 0;
    _isNewRecord = false;
    _enemies.clear();
    notifyListeners();
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHighScore, _highScore);
  }

  Future<void> _saveGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGamesPlayed, _gamesPlayed);
  }
}
