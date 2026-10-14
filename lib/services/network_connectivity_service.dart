import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for monitoring and controlling network connectivity state.
/// Supports both real network monitoring and simulated offline mode for demonstrations.
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  static NetworkConnectivityService get instance => _instance;

  NetworkConnectivityService._internal();

  bool _isDeviceOnline = true;
  bool _isSimulatedOffline = false;

  /// Reactive notifier for current active connectivity state
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  /// Stream controller for connection restoration events
  final StreamController<bool> _connectionChangeController =
      StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectionChangeController.stream;

  /// Returns whether BandungHub currently has internet access
  bool get isOnline => !_isSimulatedOffline && _isDeviceOnline;

  /// Returns true if user manually enabled simulated offline mode
  bool get isSimulatedOffline => _isSimulatedOffline;

  /// Toggle simulated offline mode (useful for testing and demoing in mountain areas)
  void setSimulatedOffline(bool simulatedOffline) {
    if (_isSimulatedOffline == simulatedOffline) return;
    final previousState = isOnline;
    _isSimulatedOffline = simulatedOffline;
    final currentState = isOnline;

    if (previousState != currentState) {
      isOnlineNotifier.value = currentState;
      _connectionChangeController.add(currentState);
    }
  }

  /// Update hardware device online status
  void setDeviceOnline(bool online) {
    if (_isDeviceOnline == online) return;
    final previousState = isOnline;
    _isDeviceOnline = online;
    final currentState = isOnline;

    if (previousState != currentState) {
      isOnlineNotifier.value = currentState;
      _connectionChangeController.add(currentState);
    }
  }

  /// Check connectivity status (returns current effective connectivity)
  Future<bool> checkConnectivity() async {
    return isOnline;
  }

  /// Reset to default online state (useful for tests)
  void reset() {
    _isDeviceOnline = true;
    _isSimulatedOffline = false;
    isOnlineNotifier.value = true;
  }
}
