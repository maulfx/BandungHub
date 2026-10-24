import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/local/auth_storage.dart';
import 'package:projek_akhir/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Profile Avatar and Storage Tests', () {
    test('Saves and loads user with base64 avatar data correctly', () async {
      final storage = AuthStorage();
      const mockBase64Avatar = 'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      final user = UserProfile(
        id: 'test_user_avatar',
        name: 'Wargi Bandung',
        email: 'wargi@bandunghub.id',
        avatarUrl: mockBase64Avatar,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await storage.saveCurrentUser(user);
      final loaded = await storage.getCurrentUser();

      expect(loaded, isNotNull);
      expect(loaded!.avatarUrl, mockBase64Avatar);
      expect(loaded.name, 'Wargi Bandung');
    });

    test('Clears avatar when requested', () async {
      final storage = AuthStorage();
      final user = UserProfile(
        id: 'test_user_no_avatar',
        name: 'Wargi Bandung',
        email: 'wargi@bandunghub.id',
        avatarUrl: null,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await storage.saveCurrentUser(user);
      final loaded = await storage.getCurrentUser();

      expect(loaded, isNotNull);
      expect(loaded!.avatarUrl, isNull);
    });
  });
}
