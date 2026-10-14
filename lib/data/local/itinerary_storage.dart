import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/itinerary.dart';

class ItineraryStorage {
  static final ItineraryStorage _instance = ItineraryStorage._internal();
  factory ItineraryStorage() => _instance;
  ItineraryStorage._internal();

  static const String _prefKey = 'bandunghub_itineraries_cache';
  Database? _database;
  bool _useSqlite = true;

  Future<void> init() async {
    // Check if sqflite is supported in this runtime
    if (kIsWeb) {
      _useSqlite = false;
      return;
    }

    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, 'bandunghub.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS itineraries (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              start_date TEXT NOT NULL,
              duration_days INTEGER NOT NULL,
              number_of_people INTEGER NOT NULL,
              transportation_cost REAL NOT NULL,
              food_cost REAL NOT NULL,
              additional_cost REAL NOT NULL,
              sync_status TEXT NOT NULL,
              saved_hash TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              items TEXT NOT NULL
            )
          ''');
        },
      );
      _useSqlite = true;
    } catch (e) {
      // Fallback to SharedPreferences if native SQLite driver is unavailable
      debugPrint('SQLite init failed ($e). Using SharedPreferences fallback.');
      _useSqlite = false;
    }
  }

  Future<List<Itinerary>> getAllItineraries() async {
    if (_useSqlite && _database != null) {
      try {
        final List<Map<String, dynamic>> maps = await _database!.query(
          'itineraries',
          orderBy: 'updated_at DESC',
        );
        return maps.map((m) => Itinerary.fromMap(m)).toList();
      } catch (e) {
        debugPrint('SQLite query failed ($e). Trying fallback.');
      }
    }

    // Fallback via SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => Itinerary.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveItinerary(Itinerary itinerary) async {
    if (_useSqlite && _database != null) {
      try {
        await _database!.insert(
          'itineraries',
          itinerary.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('SQLite insert failed ($e). Saving to fallback.');
      }
    }

    // Always keep SharedPreferences synced as resilient backup
    final prefs = await SharedPreferences.getInstance();
    final current = await getAllItineraries();
    final index = current.indexWhere((i) => i.id == itinerary.id);
    if (index >= 0) {
      current[index] = itinerary;
    } else {
      current.insert(0, itinerary);
    }
    await prefs.setString(
      _prefKey,
      jsonEncode(current.map((i) => i.toMap()).toList()),
    );
  }

  Future<void> deleteItinerary(String id) async {
    if (_useSqlite && _database != null) {
      try {
        await _database!.delete(
          'itineraries',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await getAllItineraries();
    current.removeWhere((i) => i.id == id);
    await prefs.setString(
      _prefKey,
      jsonEncode(current.map((i) => i.toMap()).toList()),
    );
  }
}
