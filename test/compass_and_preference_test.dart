import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/data/sources/bandung_destinations.dart';
import 'package:projek_akhir/data/repositories/preference_repository.dart';
import 'package:projek_akhir/models/travel_preference.dart';
import 'package:projek_akhir/services/recommendation_engine.dart';
import 'package:projek_akhir/services/sensor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferenceRepository & RecommendationEngine Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('PreferenceRepository loads default preferences and saves updates', () async {
      final repo = PreferenceRepository();
      final initial = await repo.getPreference();
      expect(initial.preferredCategories, contains('Alam'));
      expect(initial.maxBudgetPerPerson, equals(50000.0));

      // Save custom preference
      final custom = const TravelPreference(
        preferredCategories: ['Kuliner', 'Belanja'],
        maxBudgetPerPerson: 100000.0,
        durationDays: 2,
        numberOfPeople: 4,
        interests: ['Kuliner Legendaris', 'Santai'],
      );

      await repo.savePreference(custom);
      expect(repo.currentPreference.preferredCategories, contains('Kuliner'));
      expect(repo.currentPreference.preferredCategories, contains('Belanja'));
      expect(repo.currentPreference.maxBudgetPerPerson, equals(100000.0));
      expect(repo.currentPreference.numberOfPeople, equals(4));

      // Re-fetch from repo
      final reloaded = await repo.getPreference();
      expect(reloaded.preferredCategories, equals(['Kuliner', 'Belanja']));
      expect(reloaded.maxBudgetPerPerson, equals(100000.0));
      expect(reloaded.interests, contains('Kuliner Legendaris'));
    });

    test('RecommendationEngine produces personalized scored rankings based on preferences', () {
      const pref = TravelPreference(
        preferredCategories: ['Kuliner'],
        maxBudgetPerPerson: 75000.0,
        interests: ['Kuliner Legendaris'],
      );

      final destinations = BandungDestinations.list;
      final results = RecommendationEngine.getRecommendations(
        destinations: destinations,
        preference: pref,
      );

      expect(results, isNotEmpty);
      expect(results.first.score, greaterThan(0));
      expect(results.first.scorePercentage, inInclusiveRange(0, 100));

      // Culinary destinations matching the preferences should rank at top with high match percentage
      final topResult = results.first;
      expect(topResult.destination.category, equals('Kuliner'));
      expect(topResult.scorePercentage, greaterThanOrEqualTo(70));
    });
  });

  group('Compass 3D Sensor Fusion Tests', () {
    test('3D vector sensor fusion avoids 180-degree flip under pitch tilt in Southern Hemisphere', () {
      // Testing sensor fusion algorithm identical to SensorService
      for (final dir in [
        {'name': 'NORTH', 'bN': 35.0, 'bE': 0.0, 'expected': 0.0},
        {'name': 'EAST', 'bN': 0.0, 'bE': -35.0, 'expected': 90.0},
        {'name': 'SOUTH', 'bN': -35.0, 'bE': 0.0, 'expected': 180.0},
        {'name': 'WEST', 'bN': 0.0, 'bE': 35.0, 'expected': 270.0},
      ]) {
        final expected = dir['expected'] as double;
        final bNorth = dir['bN'] as double;
        final bEast = dir['bE'] as double;

        // Test at flat (0°) and steep hand-held pitch (65°)
        for (final pitchDeg in [0, 30, 60, 75]) {
          final pitchRad = pitchDeg * math.pi / 180;
          const bDown = -22.0; // Southern hemisphere inclination

          final ax = 0.0;
          final ay = 9.8 * math.sin(pitchRad);
          final az = 9.8 * math.cos(pitchRad);

          final mx = -bEast;
          final my = bNorth * math.cos(pitchRad) + bDown * math.sin(pitchRad);
          final mz = -bNorth * math.sin(pitchRad) + bDown * math.cos(pitchRad);

          final normG = math.sqrt(ax * ax + ay * ay + az * az);
          final gx = ax / normG;
          final gy = ay / normG;
          final gz = az / normG;

          final ex = my * gz - mz * gy;
          final ey = mz * gx - mx * gz;
          final ez = mx * gy - my * gx;
          final normE = math.sqrt(ex * ex + ey * ey + ez * ez);
          final uEx = ex / normE;
          final uEy = ey / normE;
          final uEz = ez / normE;

          final ny = gz * uEx - gx * uEz;
          final heading = (math.atan2(-uEy, ny) * 180 / math.pi + 360) % 360;

          // Heading should stay strictly within 1 degree of expected across all pitch angles
          expect(
            (heading - expected).abs(),
            lessThan(1.0),
            reason: '${dir['name']} at pitch $pitchDeg° should equal $expected°, got $heading°',
          );
        }
      }
    });

    test('Compass cardinal directions mapping is correct', () {
      expect(SensorService.getCardinalDirection(0).code, equals('U'));
      expect(SensorService.getCardinalDirection(90).code, equals('T'));
      expect(SensorService.getCardinalDirection(180).code, equals('S'));
      expect(SensorService.getCardinalDirection(270).code, equals('B'));
      expect(SensorService.getCardinalDirection(45).code, equals('TL'));
      expect(SensorService.getCardinalDirection(135).code, equals('TG'));
      expect(SensorService.getCardinalDirection(225).code, equals('BD'));
      expect(SensorService.getCardinalDirection(315).code, equals('BL'));
    });
  });
}
