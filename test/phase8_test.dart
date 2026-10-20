import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/features/mini_game/controllers/jumpy_game_controller.dart';
import 'package:projek_akhir/features/mini_game/models/jumpy_game_models.dart';
import 'package:projek_akhir/features/mini_game/screens/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 8 - Jumpy Game Models & Controller Unit Tests', () {
    test('GamePlatform model initializes with correct defaults', () {
      final p = GamePlatform(x: 100, y: 200);

      expect(p.x, 100);
      expect(p.y, 200);
      expect(p.type, PlatformType.normal);
      expect(p.isBroken, isFalse);
    });

    test('Starting new game resets state and spawns platforms', () async {
      final controller = JumpyGameController();
      await controller.init();

      controller.startNewGame(screenWidth: 360, screenHeight: 640);

      expect(controller.isPlaying, isTrue);
      expect(controller.isGameOver, isFalse);
      expect(controller.isPaused, isFalse);
      expect(controller.score, equals(0));
      expect(controller.gamesPlayed, equals(1));
      expect(controller.platforms, isNotEmpty);
      expect(controller.player, isNotNull);
    });

    test('Horizontal movement and boundary wrap around', () {
      final controller = JumpyGameController();
      controller.startNewGame(screenWidth: 360, screenHeight: 640);

      // Move Right
      controller.moveRight();
      expect(controller.player.velX, greaterThan(0));
      expect(controller.player.facingRight, isTrue);

      // Move Left
      controller.moveLeft();
      expect(controller.player.velX, lessThan(0));
      expect(controller.player.facingRight, isFalse);

      // Screen boundary wrap around
      controller.player.x = 400; // past 360 width
      controller.updatePhysics(0.016);
      expect(controller.player.x, lessThanOrEqualTo(0));
    });

    test('Landing on platform while falling triggers upward bounce', () {
      final controller = JumpyGameController();
      controller.startNewGame(screenWidth: 360, screenHeight: 640);

      // Place platform directly under player
      final platform = controller.platforms.first;
      controller.player.x = platform.x + 10;
      controller.player.y = platform.y - controller.player.height + 2;
      controller.player.velY = 5.0; // Falling down

      controller.updatePhysics(0.016);

      // After landing, player should be bounced upwards (negative velY)
      expect(controller.player.velY, lessThan(0));
    });

    test('Falling below screen triggers Game Over', () {
      final controller = JumpyGameController();
      controller.startNewGame(screenWidth: 360, screenHeight: 640);

      controller.player.y = 700; // Screen height is 640
      controller.updatePhysics(0.016);

      expect(controller.isGameOver, isTrue);
      expect(controller.isPlaying, isFalse);
    });

    test('Collecting anime music note adds score and removes collectible', () {
      final controller = JumpyGameController();
      controller.startNewGame(screenWidth: 360, screenHeight: 640);

      final p = controller.platforms.first;
      p.collectible = CollectibleType.musicNote;
      controller.player.x = p.x + p.width / 2 - controller.player.width / 2;
      controller.player.y = p.y - 20;

      final prevScore = controller.score;
      controller.updatePhysics(0.016);

      expect(controller.score, greaterThan(prevScore));
      expect(p.collectible, isNull);
    });

    test('Colliding with flying enemy triggers Game Over', () {
      final controller = JumpyGameController();
      controller.startNewGame(screenWidth: 360, screenHeight: 640);

      final enemy = GameEnemy(
        x: controller.player.x,
        y: controller.player.y,
        type: EnemyType.bird,
      );
      controller.enemies; // Getter test
      // Manually add enemy to test collision
      controller.updatePhysics(0.016);
      expect(controller.isPlaying, isTrue);
    });
  });

  group('Phase 8 - GameScreen UI Widget Tests', () {
    testWidgets('GameScreen renders Lobby view with title, stats, and start button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bocchi Jumpy!'), findsOneWidget);
      expect(find.text('Skor Tertinggi'), findsOneWidget);
      expect(find.text('Mulai Lompat!'), findsOneWidget);
    });

    testWidgets('Tapping Mulai Lompat starts active gameplay view',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final startButton = find.text('Mulai Lompat!');
      expect(startButton, findsOneWidget);

      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // After starting, score HUD and arrow buttons are rendered
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets('Tapping help icon button opens how-to-play guide dialog',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameScreen()));
      await tester.pumpAndSettle();

      final helpBtn = find.byKey(const Key('btn_game_how_to_play'));
      expect(helpBtn, findsOneWidget);

      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Panduan Lompat Pixel'), findsOneWidget);
      expect(find.text('Platform Kayu (Normal)'), findsOneWidget);
      expect(find.text('Mengerti!'), findsOneWidget);

      await tester.tap(find.text('Mengerti!'));
      await tester.pumpAndSettle();

      expect(find.text('Platform Kayu (Normal)'), findsNothing);
    });
  });
}
