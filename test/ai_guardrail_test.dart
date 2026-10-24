import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/services/ai_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiAssistantService Guardrail Tests', () {
    final aiService = AiAssistantService();

    test('Rejects calculator requests politely and stays within Bandung context', () async {
      final response = await aiService.processMessage('buatkan kalkulator sederhana dong');
      expect(response.isError, false);
      expect(response.text.toLowerCase().contains('punten'), true);
      expect(response.text.toLowerCase().contains('kalkulator'), true);
      expect(response.text.toLowerCase().contains('bandung'), true);
    });

    test('Rejects coding / programming requests politely', () async {
      final response = await aiService.processMessage('tolong bikinin kode script python');
      expect(response.isError, false);
      expect(response.text.toLowerCase().contains('punten'), true);
      expect(response.text.toLowerCase().contains('kode program'), true);
      expect(response.text.toLowerCase().contains('bandunghub'), true);
    });

    test('Answers legitimate Bandung tourism inquiries normally', () async {
      final response = await aiService.processMessage('rekomendasi kuliner khas bandung');
      expect(response.isError, false);
      expect(response.text.toLowerCase().contains('kuliner'), true);
      expect(response.recommendedDestinations.isNotEmpty, true);
    });
  });
}
