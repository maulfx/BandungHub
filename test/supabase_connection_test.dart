import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projek_akhir/core/config/env_config.dart';
import 'package:projek_akhir/data/sources/bandung_destinations.dart';
import 'package:projek_akhir/services/supabase_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  SharedPreferences.setMockInitialValues({});

  test('Test Live Supabase Connection and Tables', () async {
    print('Testing Supabase credentials:');
    print('URL: ${EnvConfig.supabaseUrl}');
    print('Anon Key: ${EnvConfig.supabaseAnonKey.substring(0, 10)}...');
    print('isSupabaseConfigured: ${EnvConfig.isSupabaseConfigured}');

    expect(EnvConfig.isSupabaseConfigured, isTrue);

    final service = SupabaseService();
    await service.init();

    expect(service.isInitialized, isTrue,
        reason: 'Supabase should initialize successfully with the provided credentials');

    final client = service.client;
    expect(client, isNotNull);

    print('\n[1] Testing query to "destinations" table...');
    try {
      final destinations = await service.fetchDestinations();
      print('Current destinations in Supabase: ${destinations.length}');

      if (destinations.isEmpty) {
        print('[2] Table "destinations" is empty.');
      } else {
        print('✅ Successfully fetched ${destinations.length} destinations from Supabase Cloud!');
      }
      expect(destinations, isNotEmpty);
    } catch (e) {
      print('Error querying destinations table: $e');
      rethrow;
    }

    print('\n[3] Testing query to "destination_reviews" table...');
    try {
      final reviews = await service.fetchReviews('dest_01');
      print('Current reviews for dest_01: ${reviews.length}');
      print('✅ Reviews table is accessible!');
    } catch (e) {
      print('Error querying destination_reviews table: $e');
      rethrow;
    }

    print('\n🎉 SEMUA KONEKSI SUPABASE BERHASIL 100%!');
  });
}
