import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Data model representing real-time compass & orientation readings.
class CompassOrientation {
  final double heading; // 0.0 - 360.0 degrees (0 = North, 90 = East)
  final double pitch; // tilt forward/backward in degrees
  final double roll; // tilt left/right in degrees
  final String cardinalDirection; // U, TL, T, TG, S, BD, B, BL
  final String cardinalLabel; // Utara, Timur Laut, Timur, etc.

  const CompassOrientation({
    required this.heading,
    required this.pitch,
    required this.roll,
    required this.cardinalDirection,
    required this.cardinalLabel,
  });

  static const CompassOrientation initial = CompassOrientation(
    heading: 0,
    pitch: 0,
    roll: 0,
    cardinalDirection: 'U',
    cardinalLabel: 'Utara',
  );
}

/// Service managing device motion sensors (Gyroscope, Accelerometer, Magnetometer).
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  final _orientationController =
      StreamController<CompassOrientation>.broadcast();
  Stream<CompassOrientation> get orientationStream =>
      _orientationController.stream;

  final _gameTiltController = StreamController<double>.broadcast();
  /// Stream of horizontal game tilt steering: -1.0 (max left) to +1.0 (max right)
  Stream<double> get gameTiltStream => _gameTiltController.stream;

  // Cached sensor states for orientation fusion
  double _lastAccelX = 0;
  double _lastAccelY = 0;
  double _lastAccelZ = 9.8;
  double _lastMagX = 0;
  double _lastMagY = 0;
  double _lastMagZ = 0;
  double _currentHeading = 0;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Start listening to device motion sensors
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    try {
      // 1. Gyroscope for rapid game tilt dynamics
      _gyroSub = gyroscopeEventStream().listen(
        (event) {
          // Gyroscope angular velocity
        },
        onError: (e) {
          debugPrint('Gyroscope stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Error starting gyroscope: $e');
    }

    try {
      // 2. Accelerometer for tilt angles (pitch, roll) and gravity vector
      _accelSub = accelerometerEventStream().listen(
        (event) {
          _lastAccelX = event.x;
          _lastAccelY = event.y;
          _lastAccelZ = event.z;

          // Game steering calculation:
          // In portrait: tilting phone left makes event.x positive; right makes event.x negative
          // Normalize to -1.0 .. +1.0 range with deadzone
          final rawTilt = -event.x / 5.0; // 5 m/s^2 is ~30 degree tilt
          final clampedTilt = rawTilt.clamp(-1.0, 1.0);
          final filteredTilt = (clampedTilt.abs() < 0.05) ? 0.0 : clampedTilt;
          _gameTiltController.add(filteredTilt);

          _computeOrientation();
        },
        onError: (e) {
          debugPrint('Accelerometer stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Error starting accelerometer: $e');
    }

    try {
      // 3. Magnetometer for true compass heading
      _magSub = magnetometerEventStream().listen(
        (event) {
          _lastMagX = event.x;
          _lastMagY = event.y;
          _lastMagZ = event.z;

          _computeOrientation();
        },
        onError: (e) {
          debugPrint('Magnetometer stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Error starting magnetometer: $e');
    }
  }

  /// Stop listening to hardware sensors to save battery
  void stopListening() {
    try {
      _gyroSub?.cancel();
    } catch (_) {}
    try {
      _accelSub?.cancel();
    } catch (_) {}
    try {
      _magSub?.cancel();
    } catch (_) {}
    _gyroSub = null;
    _accelSub = null;
    _magSub = null;
    _isListening = false;
  }

  /// Compute heading, pitch, roll and cardinal direction
  void _computeOrientation() {
    // Pitch and Roll in degrees from Accelerometer
    final pitch = math.atan2(
          -_lastAccelX,
          math.sqrt(_lastAccelY * _lastAccelY + _lastAccelZ * _lastAccelZ),
        ) *
        180 /
        math.pi;

    final roll = math.atan2(_lastAccelY, _lastAccelZ) * 180 / math.pi;

    // Heading from Magnetometer / Accelerometer
    double heading;
    if (_lastMagX != 0 || _lastMagY != 0) {
      // Calculate magnetic azimuth
      double rawHeading = math.atan2(_lastMagY, _lastMagX) * 180 / math.pi;
      if (rawHeading < 0) {
        rawHeading += 360;
      }
      heading = rawHeading;
    } else {
      // Fallback heading from accelerometer roll
      heading = (_lastAccelX * 18).clamp(-180.0, 180.0);
      if (heading < 0) heading += 360;
    }

    // Low-pass filter for smooth compass dial rotation
    final diff = heading - _currentHeading;
    final shortestDiff = ((diff + 180) % 360) - 180;
    _currentHeading = (_currentHeading + shortestDiff * 0.15) % 360;
    if (_currentHeading < 0) _currentHeading += 360;

    final cardinal = getCardinalDirection(_currentHeading);

    _orientationController.add(
      CompassOrientation(
        heading: _currentHeading,
        pitch: pitch,
        roll: roll,
        cardinalDirection: cardinal.code,
        cardinalLabel: cardinal.label,
      ),
    );
  }

  /// Helper to convert degrees (0-360) to cardinal directions (Indonesian)
  static ({String code, String label}) getCardinalDirection(double degrees) {
    final d = (degrees % 360 + 360) % 360;
    if (d >= 337.5 || d < 22.5) {
      return (code: 'U', label: 'Utara');
    } else if (d >= 22.5 && d < 67.5) {
      return (code: 'TL', label: 'Timur Laut');
    } else if (d >= 67.5 && d < 112.5) {
      return (code: 'T', label: 'Timur');
    } else if (d >= 112.5 && d < 157.5) {
      return (code: 'TG', label: 'Tenggara');
    } else if (d >= 157.5 && d < 202.5) {
      return (code: 'S', label: 'Selatan');
    } else if (d >= 202.5 && d < 247.5) {
      return (code: 'BD', label: 'Barat Daya');
    } else if (d >= 247.5 && d < 292.5) {
      return (code: 'B', label: 'Barat');
    } else {
      return (code: 'BL', label: 'Barat Laut');
    }
  }

  /// Calculate geographic bearing (azimuth angle) from user location to a destination
  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lon1 = from.longitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final lon2 = to.longitude * math.pi / 180;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }
}
