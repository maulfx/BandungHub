import 'dart:convert';

import 'package:crypto/crypto.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? pinHash;
  final bool isBiometricEnabled;
  final bool isGuest;
  final String role; // 'admin', 'user', 'guest'
  final String authProvider; // 'email', 'google', 'guest', 'demo'
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.pinHash,
    this.isBiometricEnabled = false,
    this.isGuest = false,
    this.role = 'user',
    this.authProvider = 'email',
    required this.createdAt,
    required this.lastLoginAt,
  });

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;
  bool get isAdmin => role == 'admin';

  // Static helper to hash PIN or Password
  static String hashSecret(String secret) {
    final bytes = utf8.encode(secret);
    return sha256.convert(bytes).toString();
  }

  // Verify PIN against stored hash
  bool verifyPin(String pin) {
    if (!hasPin) return false;
    return hashSecret(pin) == pinHash;
  }

  // Factory for Admin User
  factory UserProfile.admin() {
    return UserProfile(
      id: 'admin_001',
      name: 'Administrator BandungHub',
      email: 'admin@bandunghub.id',
      avatarUrl: null,
      pinHash: hashSecret('123456'),
      role: 'admin',
      isBiometricEnabled: false,
      isGuest: false,
      authProvider: 'email',
      createdAt: DateTime(2026, 1, 1),
      lastLoginAt: DateTime.now(),
    );
  }

  // Factory for default Demo User
  factory UserProfile.demoUser() {
    return UserProfile(
      id: 'demo_user_001',
      name: 'Wisatawan Bandung',
      email: 'traveler@bandunghub.id',
      avatarUrl: null,
      pinHash: hashSecret('123456'),
      role: 'user',
      isBiometricEnabled: true,
      isGuest: false,
      authProvider: 'demo',
      createdAt: DateTime(2026, 1, 1),
      lastLoginAt: DateTime.now(),
    );
  }

  // Factory for Guest User
  factory UserProfile.guest() {
    return UserProfile(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Tamu BandungHub',
      email: 'tamu@bandunghub.local',
      avatarUrl: null,
      pinHash: null,
      isBiometricEnabled: false,
      isGuest: true,
      authProvider: 'guest',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  // Factory for Google User
  factory UserProfile.googleUser({
    required String name,
    required String email,
    String? avatarUrl,
  }) {
    final cleanEmail = email.toLowerCase().trim();
    final isAdmin = cleanEmail == 'admin@bandunghub.id' || cleanEmail == 'admin@gmail.com';
    return UserProfile(
      id: 'google_${DateTime.now().millisecondsSinceEpoch}',
      name: isAdmin ? 'Administrator BandungHub' : name,
      email: email,
      avatarUrl: avatarUrl ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      pinHash: isAdmin ? hashSecret('123456') : null,
      role: isAdmin ? 'admin' : 'user',
      isBiometricEnabled: false,
      isGuest: false,
      authProvider: 'google',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? pinHash,
    bool? isBiometricEnabled,
    bool? isGuest,
    String? role,
    String? authProvider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pinHash: pinHash ?? this.pinHash,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isGuest: isGuest ?? this.isGuest,
      role: role ?? this.role,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'pinHash': pinHash,
      'isBiometricEnabled': isBiometricEnabled ? 1 : 0,
      'isGuest': isGuest ? 1 : 0,
      'role': role,
      'authProvider': authProvider,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final isGuestVal = (map['isGuest'] == 1 || map['isGuest'] == true);
    return UserProfile(
      id: map['id'] as String? ??
          'user_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Pengguna BandungHub',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      pinHash: map['pinHash'] as String?,
      isBiometricEnabled:
          (map['isBiometricEnabled'] == 1 || map['isBiometricEnabled'] == true),
      isGuest: isGuestVal,
      role: map['role'] as String? ?? 'user',
      authProvider: map['authProvider'] as String? ??
          (isGuestVal ? 'guest' : 'email'),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.tryParse(map['lastLoginAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
