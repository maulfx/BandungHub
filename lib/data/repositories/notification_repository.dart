import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

class NotificationRepository extends ChangeNotifier {
  static final NotificationRepository _instance =
      NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();

  final _service = NotificationService();
  static const String _storageKey = 'bandunghub_notifications_v1';

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> get activeReminders => _notifications
      .where((n) => !n.isDelivered && n.scheduledTime.isAfter(DateTime.now()))
      .toList();

  List<AppNotification> get historyNotifications => _notifications
      .where((n) => n.isDelivered || n.scheduledTime.isBefore(DateTime.now()))
      .toList();

  Future<void> init() async {
    try {
      await initializeDateFormatting('id_ID', null);
      await initializeDateFormatting('id', null);
    } catch (_) {}
    await _service.init();
    await _service.requestPermissions();
    await _loadFromStorage();

    // Default welcome notification if empty
    if (_notifications.isEmpty) {
      _seedDefaultWelcome();
      await _saveToStorage();
    }
    notifyListeners();
  }

  void _seedDefaultWelcome() {
    final now = DateTime.now();
    _notifications.add(
      AppNotification(
        id: 'notif_welcome_initial',
        title: 'Wilujeng Sumping di Bandung! 🎉',
        body:
            'Selamat datang di BandungHub! Temukan rekomendasi wisata terbaik, susun itinerary hemat, dan nikmati pesona Paris van Java.',
        scheduledTime: now,
        createdTime: now,
        type: NotificationType.welcome,
        isRead: false,
        isDelivered: true,
      ),
    );
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        _notifications.clear();
        for (final item in decoded) {
          _notifications.add(
            AppNotification.fromMap(Map<String, dynamic>.from(item as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('NotificationRepository _loadFromStorage error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = _notifications.map((n) => n.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(mapped));
    } catch (e) {
      debugPrint('NotificationRepository _saveToStorage error: $e');
    }
  }

  /// Kirim notifikasi instan sekarang juga
  Future<AppNotification> sendInstantNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? payload,
  }) async {
    final now = DateTime.now();
    final notifId = 'notif_${now.millisecondsSinceEpoch}';
    final int numericId = now.millisecondsSinceEpoch.remainder(100000);

    final notification = AppNotification(
      id: notifId,
      title: title,
      body: body,
      scheduledTime: now,
      createdTime: now,
      type: type,
      isRead: false,
      isDelivered: true,
      payload: payload,
    );

    _notifications.insert(0, notification);
    notifyListeners();
    await _saveToStorage();

    // Trigger via system notifications
    await _service.showNotification(
      id: numericId,
      title: title,
      body: body,
      payload: notifId,
    );

    return notification;
  }

  /// Jadwalkan pengingat perjalanan di waktu tertentu
  Future<AppNotification> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    NotificationType type = NotificationType.itineraryReminder,
    Map<String, dynamic>? payload,
  }) async {
    final now = DateTime.now();
    final notifId = 'reminder_${now.millisecondsSinceEpoch}';
    final int numericId = now.millisecondsSinceEpoch.remainder(100000);

    final isImmediate = scheduledTime.isBefore(
      now.add(const Duration(seconds: 2)),
    );

    final notification = AppNotification(
      id: notifId,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      createdTime: now,
      type: type,
      isRead: false,
      isDelivered: isImmediate,
      payload: payload,
    );

    _notifications.insert(0, notification);
    notifyListeners();
    await _saveToStorage();

    if (isImmediate) {
      await _service.showNotification(
        id: numericId,
        title: title,
        body: body,
        payload: notifId,
      );
    } else {
      await _service.scheduleNotification(
        id: numericId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        payload: notifId,
      );
    }

    return notification;
  }

  /// Tandai notifikasi sebagai telah dibaca
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Tandai seluruh notifikasi sebagai telah dibaca
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
    await _saveToStorage();
  }

  /// Hapus satu notifikasi
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  /// Batalkan dan hapus pengingat aktif
  Future<void> cancelReminder(String id) async {
    final notif = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => _notifications.first,
    );
    final numericId = notif.createdTime.millisecondsSinceEpoch.remainder(
      100000,
    );
    await _service.cancelNotification(numericId);
    await deleteNotification(id);
  }

  /// Bersihkan seluruh notifikasi
  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveToStorage();
    await _service.cancelAll();
  }

  // --- DEMO PRESET TRIGGERS (Untuk Presentasi & Penilaian Dosen) ---

  Future<void> triggerWelcomeNotification() async {
    await sendInstantNotification(
      title: 'Wilujeng Sumping di Bandung! 🌿',
      body:
          'Nikmati udara sejuk pegunungan dan aneka ragam kuliner legendaris bersama BandungHub.',
      type: NotificationType.welcome,
    );
  }

  Future<void> triggerItineraryDemoReminder() async {
    await sendInstantNotification(
      title: 'Pengingat Perjalanan: Kawah Putih 🌋',
      body:
          '1 jam lagi jadwal keberangkatan ke Kawah Putih Ciwidey. Pastikan jaket hangat dan kamera Anda siap!',
      type: NotificationType.itineraryReminder,
      payload: {'destinationId': 'dest_02', 'category': 'Alam'},
    );
  }

  Future<void> triggerQuizReminder() async {
    await sendInstantNotification(
      title: 'Tantangan Bocchi Jumpy! 🎸🧗',
      body:
          'Ayo bantu Bocchi melompat setinggi mungkin melintasi platform kayu dan pecahkan rekor baru!',
      type: NotificationType.quizReminder,
    );
  }

  /// Reset untuk unit testing
  void resetForTesting() {
    _notifications.clear();
    notifyListeners();
  }
}
