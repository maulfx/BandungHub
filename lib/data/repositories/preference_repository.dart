import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/travel_preference.dart';

/// Repository managing persistence of user travel preferences for AI personalization.
class PreferenceRepository {
  static const String _keyPreference = 'user_travel_preference';
  static final PreferenceRepository _instance = PreferenceRepository._internal();
  factory PreferenceRepository() => _instance;
  PreferenceRepository._internal();

  TravelPreference _cachedPreference = const TravelPreference();
  TravelPreference get currentPreference => _cachedPreference;
  bool _isLoaded = false;

  /// Loads saved travel preference from SharedPreferences, or default if not set.
  Future<TravelPreference> getPreference() async {
    if (_isLoaded) return _cachedPreference;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyPreference);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cachedPreference = TravelPreference.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error loading travel preference: $e');
    }
    _isLoaded = true;
    return _cachedPreference;
  }

  /// Persists user travel preference to local storage.
  Future<void> savePreference(TravelPreference preference) async {
    _cachedPreference = preference;
    _isLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(preference.toMap());
      await prefs.setString(_keyPreference, encoded);
    } catch (e) {
      debugPrint('Error saving travel preference: $e');
    }
  }
}
