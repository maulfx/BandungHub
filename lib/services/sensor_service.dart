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

  CompassOrientation _currentOrientation = CompassOrientation.initial;
  CompassOrientation get currentOrientation => _currentOrientation;

  // Cached sensor states for orientation fusion
  double _lastAccelX = 0;
  double _lastAccelY = 0;
  double _lastAccelZ = 9.8;
  double _lastMagX = 0;
  double _lastMagY = 0;
  double _lastMagZ = 0;
  bool _hasMagnetometerData = false;
  bool _hasInitialHeading = false;
  double _fusionHeading = 0.0;
  double _gyroHeading = 0.0;
  DateTime? _lastGyroTime;

  double _currentTilt = 0.0;
  // Smoothed gyro velocity (EMA) for game tilt
  double _smoothedGyroRate = 0.0;
  bool _isListening = false;
  bool get isListening => _isListening;

  /// Start listening to device motion sensors
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    try {
      // 1. Gyroscope for rapid game tilt dynamics and instant compass response
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          final now = DateTime.now();
          if (_lastGyroTime != null) {
            final dt = now.difference(_lastGyroTime!).inMicroseconds / 1e6;
            if (dt > 0 && dt < 0.5) {
              // In portrait mode: turning clockwise (right) gives negative Z gyro rate
              // Rate in degrees/sec = -event.z * 180 / math.pi
              final dYaw = -event.z * (180 / math.pi) * dt;
              _gyroHeading = (_gyroHeading + dYaw) % 360;
              if (_gyroHeading < 0) _gyroHeading += 360;

              _fusionHeading = (_fusionHeading + dYaw) % 360;
              if (_fusionHeading < 0) _fusionHeading += 360;
            }
          }
          _lastGyroTime = now;

          // In portrait: event.y = roll rate, event.z = screen rotation
          final rawRate = (-event.y * 0.4 - event.z * 0.25).clamp(-1.0, 1.0);
          // EMA smoothing: alpha=0.2 → very smooth
          _smoothedGyroRate = _smoothedGyroRate * 0.8 + rawRate * 0.2;
          // Dead zone threshold to ignore micro-jitter
          if (_smoothedGyroRate.abs() > 0.08) {
            _currentTilt =
                (_currentTilt * 0.75 + _smoothedGyroRate * 0.25)
                    .clamp(-1.0, 1.0);
            _gameTiltController.add(_currentTilt);
          }

          // If no magnetometer hardware (e.g. emulator), compute orientation via gyro
          if (!_hasMagnetometerData) {
            _computeOrientation();
          }
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
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          _lastAccelX = event.x;
          _lastAccelY = event.y;
          _lastAccelZ = event.z;

          // Game steering: tilt left → positive, right → negative
          // Scaling by 3.5 for comfortable 20-degree tilt steering
          final rawTilt = (-event.x / 3.5).clamp(-1.0, 1.0);
          // Dead zone + stronger EMA smoothing for accelerometer
          final filteredTilt = (rawTilt.abs() < 0.06) ? 0.0 : rawTilt;
          // EMA: alpha=0.35 → smooth but responsive for steering
          _currentTilt =
              (_currentTilt * 0.65 + filteredTilt * 0.35).clamp(-1.0, 1.0);
          _gameTiltController.add(_currentTilt);

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
      _magSub = magnetometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _lastMagX = event.x;
          _lastMagY = event.y;
          _lastMagZ = event.z;
          _hasMagnetometerData = true;

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

  /// Compute tilt-compensated heading, pitch, roll and cardinal direction
  void _computeOrientation() {
    // Pitch and Roll in radians from Accelerometer
    final rollRad = math.atan2(
      _lastAccelX,
      math.sqrt(_lastAccelY * _lastAccelY + _lastAccelZ * _lastAccelZ),
    );
    final pitchRad = math.atan2(_lastAccelY, _lastAccelZ);

    final pitch = pitchRad * 180 / math.pi;
    final roll = rollRad * 180 / math.pi;

    // Heading calculation using 3D cross-product vector fusion (identical to Android AOSP SensorManager)
    if (_hasMagnetometerData &&
        (_lastMagX != 0 || _lastMagY != 0 || _lastMagZ != 0)) {
      // 1. Gravity unit vector (downwards)
      final normG = math.sqrt(_lastAccelX * _lastAccelX +
          _lastAccelY * _lastAccelY +
          _lastAccelZ * _lastAccelZ);
      if (normG > 0.1) {
        final gx = _lastAccelX / normG;
        final gy = _lastAccelY / normG;
        final gz = _lastAccelZ / normG;

        // 2. East vector: E = m x g
        final ex = _lastMagY * gz - _lastMagZ * gy;
        final ey = _lastMagZ * gx - _lastMagX * gz;
        final ez = _lastMagX * gy - _lastMagY * gx;
        final normE = math.sqrt(ex * ex + ey * ey + ez * ez);

        if (normE > 0.1) {
          final invE = 1.0 / normE;
          final uEx = ex * invE;
          final uEy = ey * invE;
          final uEz = ez * invE;

          // 3. North vector: N = g x E
          final ny = gz * uEx - gx * uEz;

          // Azimuth from North (0° = North, 90° = East, 180° = South, 270° = West)
          // Uses atan2(-uEy, ny) which matches Android AOSP getOrientation and never flips at hand-held tilt
          double magHeading = (math.atan2(-uEy, ny) * 180 / math.pi + 360) % 360;

          if (!_hasInitialHeading) {
            _fusionHeading = magHeading;
            _hasInitialHeading = true;
          } else {
            // Complementary filter: blend gyro responsiveness with absolute magnetic heading
            final diff = magHeading - _fusionHeading;
            final shortestDiff = ((diff + 180) % 360 + 360) % 360 - 180;
            _fusionHeading = (_fusionHeading + shortestDiff * 0.25) % 360;
            if (_fusionHeading < 0) _fusionHeading += 360;
          }
        }
      }
    } else {
      // Fallback if magnetometer is missing (e.g. emulator or sensor not ready)
      if (_lastGyroTime != null) {
        _fusionHeading = _gyroHeading;
      } else {
        // Fallback from accelerometer tilt
        _fusionHeading = ((_lastAccelX * 20) + 360) % 360;
      }
    }

    if (_fusionHeading.abs() < 0.001) _fusionHeading = 0.0;
    final cardinal = getCardinalDirection(_fusionHeading);

    _currentOrientation = CompassOrientation(
      heading: _fusionHeading,
      pitch: pitch,
      roll: roll,
      cardinalDirection: cardinal.code,
      cardinalLabel: cardinal.label,
    );

    _orientationController.add(_currentOrientation);
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
