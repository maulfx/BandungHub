import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/user_profile.dart';

class AuthStorage {
  static const String _keyCurrentUser = 'bandunghub_current_user';
  static const String _keyRegisteredUsers = 'bandunghub_registered_users';
  static const String _keySessionToken = 'bandunghub_session_token';
  static const String _keyPassHashPrefix = 'bandunghub_pwd_';
  static const String _keyBiometricUserEmail = 'bandunghub_biometric_user_email';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _useSecureStorage = true;
  Database? _db;

  // Initialize SQLite database table for user_profiles
  Future<Database?> _getDatabase() async {
    if (kIsWeb) return null;
    if (_db != null && _db!.isOpen) return _db;
    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, 'bandunghub.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_profiles (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL,
              avatar_url TEXT,
              pin_hash TEXT,
              is_biometric_enabled INTEGER NOT NULL,
              is_guest INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              last_login_at TEXT NOT NULL
            )
          ''');
        },
        onOpen: (db) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_profiles (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL,
              avatar_url TEXT,
              pin_hash TEXT,
              is_biometric_enabled INTEGER NOT NULL,
              is_guest INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              last_login_at TEXT NOT NULL
            )
          ''');
        },
      );
      return _db;
    } catch (e) {
      debugPrint('SQLite database connection in AuthStorage ($e). Using secure storage fallback.');
      return null;
    }
  }

  // Safe write into secure storage with SharedPreferences fallback
  Future<void> _safeWrite(String key, String value) async {
    if (_useSecureStorage) {
      try {
        await _secureStorage.write(key: key, value: value);
        return;
      } catch (e) {
        debugPrint(
          'SecureStorage write error, falling back to SharedPreferences: $e',
        );
        _useSecureStorage = false;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Safe read
  Future<String?> _safeRead(String key) async {
    if (_useSecureStorage) {
      try {
        final val = await _secureStorage.read(key: key);
        if (val != null) return val;
      } catch (e) {
        debugPrint(
          'SecureStorage read error, falling back to SharedPreferences: $e',
        );
        _useSecureStorage = false;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Safe delete
  Future<void> _safeDelete(String key) async {
    if (_useSecureStorage) {
      try {
        await _secureStorage.delete(key: key);
      } catch (e) {
        _useSecureStorage = false;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Save current active session
  Future<void> saveCurrentUser(UserProfile user) async {
    await _safeWrite(_keyCurrentUser, user.toJson());
    await _safeWrite(
      _keySessionToken,
      'token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Save to SQLite database table user_profiles
    try {
      final db = await _getDatabase();
      if (db != null) {
        await db.insert(
          'user_profiles',
          {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'avatar_url': user.avatarUrl,
            'pin_hash': user.pinHash,
            'is_biometric_enabled': user.isBiometricEnabled ? 1 : 0,
            'is_guest': user.isGuest ? 1 : 0,
            'created_at': user.createdAt.toIso8601String(),
            'last_login_at': user.lastLoginAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('Failed to save user into SQLite user_profiles: $e');
    }

    // Also persist or update in registered users map if not guest
    if (!user.isGuest) {
      final users = await getRegisteredUsers();
      users[user.email.toLowerCase()] = user;
      final encoded = jsonEncode(users.map((k, v) => MapEntry(k, v.toMap())));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRegisteredUsers, encoded);
    }
  }

  // Load current active user
  Future<UserProfile?> getCurrentUser() async {
    final raw = await _safeRead(_keyCurrentUser);
    if (raw != null && raw.isNotEmpty) {
      try {
        final cached = UserProfile.fromJson(raw);
        // Also check if SQLite has the latest profile
        try {
          final db = await _getDatabase();
          if (db != null) {
            final maps = await db.query(
              'user_profiles',
              where: 'id = ?',
              whereArgs: [cached.id],
            );
            if (maps.isNotEmpty) {
              final row = maps.first;
              return cached.copyWith(
                name: row['name'] as String?,
                avatarUrl: row['avatar_url'] as String?,
              );
            }
          }
        } catch (_) {}
        return cached;
      } catch (e) {
        debugPrint('Error parsing current user: $e');
      }
    }

    // Fallback: check SQLite database directly
    try {
      final db = await _getDatabase();
      if (db != null) {
        final maps = await db.query(
          'user_profiles',
          orderBy: 'last_login_at DESC',
          limit: 1,
        );
        if (maps.isNotEmpty) {
          final row = maps.first;
          return UserProfile(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            avatarUrl: row['avatar_url'] as String?,
            pinHash: row['pin_hash'] as String?,
            isBiometricEnabled: (row['is_biometric_enabled'] as int? ?? 0) == 1,
            isGuest: (row['is_guest'] as int? ?? 0) == 1,
            createdAt:
                DateTime.tryParse(row['created_at'] as String? ?? '') ??
                    DateTime.now(),
            lastLoginAt:
                DateTime.tryParse(row['last_login_at'] as String? ?? '') ??
                    DateTime.now(),
          );
        }
      }
    } catch (_) {}

    return null;
  }

  // Clear session (Logout)
  Future<void> clearSession() async {
    await _safeDelete(_keyCurrentUser);
    await _safeDelete(_keySessionToken);
  }

  // Store password hash for an email
  Future<void> savePasswordHash(String email, String passwordHash) async {
    await _safeWrite('$_keyPassHashPrefix${email.toLowerCase()}', passwordHash);
  }

  // Biometric authorization tracking for returning users
  Future<void> saveBiometricUserEmail(String email) async {
    await _safeWrite(_keyBiometricUserEmail, email.toLowerCase());
  }

  Future<String?> getBiometricUserEmail() async {
    return await _safeRead(_keyBiometricUserEmail);
  }

  Future<void> clearBiometricUserEmail() async {
    await _safeDelete(_keyBiometricUserEmail);
  }

  // Verify email password
  Future<bool> verifyPassword(String email, String passwordHash) async {
    final cleanEmail = email.toLowerCase().trim();
    final stored = await _safeRead('$_keyPassHashPrefix$cleanEmail');
    if (stored == null) {
      // Default Admin account: admin@bandunghub.id / admin123
      if (cleanEmail == 'admin@bandunghub.id' ||
          cleanEmail == 'admin@gmail.com') {
        return passwordHash == UserProfile.hashSecret('admin123');
      }
      // Demo user email
      if (cleanEmail == 'traveler@bandunghub.id') {
        return passwordHash == UserProfile.hashSecret('bandung123') ||
            passwordHash == UserProfile.hashSecret('123456');
      }
      return false;
    }
    return stored == passwordHash;
  }

  // Get all registered users map
  Future<Map<String, UserProfile>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRegisteredUsers);
    if (raw == null || raw.isEmpty) {
      // Seed with admin and demo user
      final admin = UserProfile.admin();
      final demo = UserProfile.demoUser();
      return {
        admin.email.toLowerCase(): admin,
        demo.email.toLowerCase(): demo,
      };
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, UserProfile>{};
      decoded.forEach((key, value) {
        map[key] = UserProfile.fromMap(value as Map<String, dynamic>);
      });
      // Ensure admin user is present
      if (!map.containsKey('admin@bandunghub.id')) {
        map['admin@bandunghub.id'] = UserProfile.admin();
      }
      // Ensure demo user is present
      if (!map.containsKey('traveler@bandunghub.id')) {
        map['traveler@bandunghub.id'] = UserProfile.demoUser();
      }
      return map;
    } catch (e) {
      debugPrint('Error parsing registered users: $e');
      final admin = UserProfile.admin();
      final demo = UserProfile.demoUser();
      return {
        admin.email.toLowerCase(): admin,
        demo.email.toLowerCase(): demo,
      };
    }
  }
}
