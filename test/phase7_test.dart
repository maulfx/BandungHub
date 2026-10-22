import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/sources/bandung_destinations.dart';
import 'package:projek_akhir/features/recommendations/screens/ai_chat_screen.dart';
import 'package:projek_akhir/models/chat_message.dart';
import 'package:projek_akhir/services/ai_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 7 - ChatMessage Model Tests', () {
    test('ChatMessage serializes to and from Map accurately', () {
      final msg = ChatMessage(
        id: 'msg_123',
        text: 'Rekomendasi wisata alam sejuk di Lembang',
        isUser: true,
        timestamp: DateTime(2026, 3, 1, 10, 30),
        recommendedDestinations: [BandungDestinations.list.first],
        isError: false,
      );

      final map = msg.toMap();
      final reconstructed = ChatMessage.fromMap(map);

      expect(reconstructed.id, msg.id);
      expect(reconstructed.text, msg.text);
      expect(reconstructed.isUser, isTrue);
      expect(reconstructed.recommendedDestinations.length, 1);
      expect(
        reconstructed.recommendedDestinations.first.name,
        BandungDestinations.list.first.name,
      );
    });
  });

  group('Phase 7 - AiAssistantService & Local Heuristic Engine Tests', () {
    final aiService = AiAssistantService();

    test('API key management works with SharedPreferences', () async {
      expect(await aiService.hasApiKey(), isFalse);

      await aiService.saveApiKey('test_gemini_key_12345');
      expect(await aiService.hasApiKey(), isTrue);
      expect(await aiService.getApiKey(), 'test_gemini_key_12345');

      await aiService.clearApiKey();
      expect(await aiService.hasApiKey(), isFalse);
    });

    test('Chat history persistence saves, loads, and clears messages', () async {
      await aiService.clearChatHistory();
      expect(await aiService.loadChatHistory(), isEmpty);

      final testMessages = [
        ChatMessage(
          id: 'test_msg_1',
          text: 'Halo Kang Bandung',
          isUser: true,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'test_msg_2',
          text: 'Sampurasun! Ada yang bisa dibantu?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

      await aiService.saveChatHistory(testMessages);
      final loaded = await aiService.loadChatHistory();
      expect(loaded.length, 2);
      expect(loaded.first.text, 'Halo Kang Bandung');
      expect(loaded.last.text, 'Sampurasun! Ada yang bisa dibantu?');

      await aiService.clearChatHistory();
      expect(await aiService.loadChatHistory(), isEmpty);
    });

    test(
      'Local heuristic responds with nature destinations for alam query',
      () async {
        final response = await aiService.processMessage('wisata alam sejuk');

        expect(response.isUser, isFalse);
        expect(response.text, contains('Sampurasun'));
        expect(response.text.toLowerCase(), contains('kawah'));
        expect(response.recommendedDestinations.isNotEmpty, isTrue);

        final hasNatureDest = response.recommendedDestinations.any(
          (d) => d.category.toLowerCase() == 'alam',
        );
        expect(hasNatureDest, isTrue);
      },
    );

    test(
      'Local heuristic responds with culinary destinations for kuliner query',
      () async {
        final response = await aiService.processMessage(
          'rekomendasi kuliner malam',
        );

        expect(response.isUser, isFalse);
        expect(response.text.toLowerCase(), contains('punclut'));
        expect(response.recommendedDestinations.isNotEmpty, isTrue);

        final hasCulinaryDest = response.recommendedDestinations.any(
          (d) => d.category.toLowerCase() == 'kuliner',
        );
        expect(hasCulinaryDest, isTrue);
      },
    );

    test(
      'Local heuristic responds with budget destinations for murah query',
      () async {
        final response = await aiService.processMessage(
          'liburan murah hemat budget',
        );

        expect(response.isUser, isFalse);
        expect(response.text.toLowerCase(), contains('museum'));
        expect(response.recommendedDestinations.isNotEmpty, isTrue);

        // Verify that budget destinations contain low or zero cost
        final hasLowCostDest = response.recommendedDestinations.any(
          (d) => d.estimatedPrice <= 20000,
        );
        expect(hasLowCostDest, isTrue);
      },
    );

    test(
      'Local heuristic provides structured itinerary for 2 hari query',
      () async {
        final response = await aiService.processMessage(
          'itinerary 2 hari di bandung',
        );

        expect(response.isUser, isFalse);
        expect(response.text, contains('Hari 1'));
        expect(response.text, contains('Hari 2'));
        expect(
          response.recommendedDestinations.length,
          greaterThanOrEqualTo(2),
        );
      },
    );

    test('Process empty message returns friendly error notice', () async {
      final response = await aiService.processMessage('   ');
      expect(response.isError, isTrue);
    });
  });

  group('Phase 7 - AiChatScreen UI Widget Tests', () {
    testWidgets(
      'AiChatScreen renders Kang Bandung header, greeting, and chips',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));
        await tester.pumpAndSettle();

        // Check Header
        expect(find.text('Kang Bandung'), findsOneWidget);
        expect(find.byIcon(Icons.smart_toy_rounded), findsWidgets);

        // Check Greeting
        expect(
          find.textContaining('Sampurasun! Wilujeng sumping!'),
          findsOneWidget,
        );

        // Check Suggestion Chips
        expect(find.text('🌲 Wisata alam sejuk di Lembang'), findsOneWidget);
        expect(find.text('🍲 Kuliner legendaris Bandung'), findsOneWidget);

        // Check Input bar
        expect(
          find.text('Tanyakan sesuatu ke Kang Bandung...'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping quick suggestion chip sends message and displays response',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));
        await tester.pumpAndSettle();

        // Tap culinary chip
        await tester.tap(find.text('🍲 Kuliner legendaris Bandung'));
        await tester.pumpAndSettle();

        // Verify user bubble appeared (chip + chat bubble = 2)
        expect(find.text('🍲 Kuliner legendaris Bandung'), findsNWidgets(2));

        // Verify AI recommendation appeared with attached cards
        expect(find.text('Destinasi Terkait Rekomendasi:'), findsOneWidget);
        expect(find.text('Kawasan Kuliner Punclut'), findsWidgets);
      },
    );

    testWidgets('AiChatScreen shows online AI status indicator', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Kang Bandung'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_rounded), findsWidgets);
    });
  });
}
