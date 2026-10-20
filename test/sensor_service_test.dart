import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:projek_akhir/services/sensor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SensorService Unit Tests', () {
    test('getCardinalDirection converts degrees accurately to Indonesian directions', () {
      expect(SensorService.getCardinalDirection(0).code, 'U');
      expect(SensorService.getCardinalDirection(0).label, 'Utara');

      expect(SensorService.getCardinalDirection(45).code, 'TL');
      expect(SensorService.getCardinalDirection(45).label, 'Timur Laut');

      expect(SensorService.getCardinalDirection(90).code, 'T');
      expect(SensorService.getCardinalDirection(90).label, 'Timur');

      expect(SensorService.getCardinalDirection(135).code, 'TG');
      expect(SensorService.getCardinalDirection(135).label, 'Tenggara');

      expect(SensorService.getCardinalDirection(180).code, 'S');
      expect(SensorService.getCardinalDirection(180).label, 'Selatan');

      expect(SensorService.getCardinalDirection(225).code, 'BD');
      expect(SensorService.getCardinalDirection(225).label, 'Barat Daya');

      expect(SensorService.getCardinalDirection(270).code, 'B');
      expect(SensorService.getCardinalDirection(270).label, 'Barat');

      expect(SensorService.getCardinalDirection(315).code, 'BL');
      expect(SensorService.getCardinalDirection(315).label, 'Barat Laut');

      expect(SensorService.getCardinalDirection(360).code, 'U');
      expect(SensorService.getCardinalDirection(-90).code, 'B');
    });

    test('calculateBearing calculates geographic angle correctly', () {
      // Point A: Alun-Alun Bandung (-6.9218, 107.6069)
      // Point B: Gedung Sate (-6.9024, 107.6186) -> North-North-East
      const alunAlun = LatLng(-6.9218, 107.6069);
      const gedungSate = LatLng(-6.9024, 107.6186);

      final bearing = SensorService.calculateBearing(alunAlun, gedungSate);
      expect(bearing, greaterThan(0));
      expect(bearing, lessThan(90)); // Should be in north-east quadrant (~30 degrees)
    });

    test('CompassOrientation initial defaults are valid', () {
      const orientation = CompassOrientation.initial;
      expect(orientation.heading, 0);
      expect(orientation.cardinalDirection, 'U');
      expect(orientation.cardinalLabel, 'Utara');
    });

    testWidgets('SensorService starts and stops listening gracefully', (tester) async {
      final service = SensorService();
      expect(service.isListening, isFalse);

      service.startListening();
      expect(service.isListening, isTrue);

      service.stopListening();
      expect(service.isListening, isFalse);
    });
  });
}
