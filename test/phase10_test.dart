import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:projek_akhir/data/sources/bandung_destinations.dart';
import 'package:projek_akhir/data/repositories/notification_repository.dart';
import 'package:projek_akhir/features/destinations/screens/destination_detail_screen.dart';
import 'package:projek_akhir/features/notifications/screens/notification_center_screen.dart';
import 'package:projek_akhir/models/app_notification.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);
  });

  group('Phase 10 - AppNotification Model Serialization Tests', () {
    test('AppNotification serializes to and from Map accurately', () {
      final now = DateTime(2026, 10, 14, 10, 30);
      final notif = AppNotification(
        id: 'test_notif_1',
        title: 'Pengingat Wisata',
        body: 'Kunjungi Tangkuban Perahu jam 09:00',
        scheduledTime: now,
        createdTime: now,
        type: NotificationType.destinationReminder,
        isRead: false,
        isDelivered: true,
        payload: {'destinationId': 'dest_01', 'customKey': 'abc'},
      );

      final map = notif.toMap();
      expect(map['id'], 'test_notif_1');
      expect(map['title'], 'Pengingat Wisata');
      expect(map['body'], 'Kunjungi Tangkuban Perahu jam 09:00');
      expect(map['type'], 'destinationReminder');
      expect(map['isRead'], false);
      expect(map['isDelivered'], true);
      expect(map['payload']['destinationId'], 'dest_01');

      final reconstructed = AppNotification.fromMap(map);
      expect(reconstructed.id, notif.id);
      expect(reconstructed.title, notif.title);
      expect(reconstructed.body, notif.body);
      expect(reconstructed.type, NotificationType.destinationReminder);
      expect(reconstructed.isRead, false);
      expect(reconstructed.isDelivered, true);
      expect(reconstructed.payload?['destinationId'], 'dest_01');
    });

    test('AppNotification copyWith creates modified instance', () {
      final now = DateTime.now();
      final original = AppNotification(
        id: 'copy_test',
        title: 'Original Title',
        body: 'Original Body',
        scheduledTime: now,
        createdTime: now,
        type: NotificationType.general,
        isRead: false,
        isDelivered: false,
      );

      final updated = original.copyWith(
        isRead: true,
        isDelivered: true,
        title: 'New Title',
      );

      expect(updated.id, 'copy_test');
      expect(updated.title, 'New Title');
      expect(updated.body, 'Original Body');
      expect(updated.isRead, true);
      expect(updated.isDelivered, true);
    });
  });

  group('Phase 10 - NotificationRepository Logic & State Tests', () {
    late NotificationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = NotificationRepository();
      await repo.init();
      await repo.clearAll();
    });

    test('sendInstantNotification delivers notification and updates unread count',
        () async {
      expect(repo.notifications.isEmpty, isTrue);

      final notif = await repo.sendInstantNotification(
        title: 'Promo Wisata Baru',
        body: 'Diskon tiket masuk Braga akhir pekan ini!',
        type: NotificationType.general,
      );

      expect(repo.notifications.length, 1);
      expect(repo.unreadCount, 1);
      expect(notif.isDelivered, isTrue);
      expect(notif.isRead, isFalse);
      expect(repo.notifications.first.title, 'Promo Wisata Baru');
    });

    test('scheduleReminder creates upcoming reminder in activeReminders',
        () async {
      final futureDate = DateTime.now().add(const Duration(days: 3));

      final reminder = await repo.scheduleReminder(
        title: 'Jadwal Trip Kawah Putih',
        body: 'Jangan lupa membawa jaket hangat!',
        scheduledTime: futureDate,
        type: NotificationType.itineraryReminder,
      );

      expect(repo.notifications.length, 1);
      expect(repo.activeReminders.length, 1);
      expect(reminder.isDelivered, isFalse);
      expect(reminder.scheduledTime.isAfter(DateTime.now()), isTrue);
    });

    test('markAsRead and markAllAsRead correctly update state', () async {
      final n1 = await repo.sendInstantNotification(
        title: 'Notif 1',
        body: 'Body 1',
      );
      await repo.sendInstantNotification(
        title: 'Notif 2',
        body: 'Body 2',
      );

      expect(repo.unreadCount, 2);

      await repo.markAsRead(n1.id);
      expect(repo.unreadCount, 1);

      await repo.markAllAsRead();
      expect(repo.unreadCount, 0);
    });

    test('deleteNotification removes specific notification', () async {
      final notif = await repo.sendInstantNotification(
        title: 'Hapus Saya',
        body: 'Notifikasi sementara',
      );
      expect(repo.notifications.length, 1);

      await repo.deleteNotification(notif.id);
      expect(repo.notifications.isEmpty, isTrue);
      expect(repo.unreadCount, 0);
    });

    test('demo triggers inject realistic sample notifications', () async {
      await repo.triggerWelcomeNotification();
      await repo.triggerItineraryDemoReminder();
      await repo.triggerQuizReminder();

      expect(repo.notifications.length, 3);
      expect(
        repo.notifications.any((n) => n.type == NotificationType.welcome),
        isTrue,
      );
      expect(
        repo.notifications
            .any((n) => n.type == NotificationType.itineraryReminder),
        isTrue,
      );
      expect(
        repo.notifications.any((n) => n.type == NotificationType.quizReminder),
        isTrue,
      );
    });
  });

  group('Phase 10 - UI Notification Center Screen Tests', () {
    late NotificationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = NotificationRepository();
      await repo.init();
      await repo.clearAll();
      await repo.sendInstantNotification(
        title: 'Selamat Datang di BandungHub',
        body: 'Aplikasi panduan wisata cerdas Kota Bandung.',
        type: NotificationType.welcome,
      );
    });

    testWidgets('NotificationCenterScreen renders header, chips, and notification card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationCenterScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifikasi & Pengingat'), findsOneWidget);
      expect(find.textContaining('Semua'), findsOneWidget);
      expect(find.textContaining('Aktif'), findsOneWidget);
      expect(find.textContaining('Riwayat'), findsOneWidget);
      expect(find.text('Selamat Datang di BandungHub'), findsOneWidget);
    });

    testWidgets('Filter chip switching toggles visible items correctly',
        (WidgetTester tester) async {
      // Add one future reminder
      await repo.scheduleReminder(
        title: 'Trip Ciwidey Besok',
        body: 'Kesiapan logistik perjalanan Ciwidey',
        scheduledTime: DateTime.now().add(const Duration(days: 2)),
        type: NotificationType.itineraryReminder,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationCenterScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on 'Aktif' chip
      final reminderChip = find.textContaining('Aktif');
      expect(reminderChip, findsOneWidget);
      await tester.tap(reminderChip);
      await tester.pump(const Duration(milliseconds: 300));

      // Should display 'Trip Ciwidey Besok'
      expect(find.text('Trip Ciwidey Besok'), findsOneWidget);
    });

    testWidgets('FAB Buat Pengingat opens schedule modal sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationCenterScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final fab = find.byKey(const Key('btn_create_reminder_fab'));
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Jadwalkan Pengingat Wisata'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_schedule_reminder')),
          findsOneWidget);
    });
  });

  group('Phase 10 - Destination & Itinerary Reminder Triggers Integration', () {
    testWidgets('DestinationDetailScreen opens reminder dialog and schedules reminder',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dest = BandungDestinations.list.first;

      await tester.pumpWidget(
        MaterialApp(
          home: DestinationDetailScreen(destination: dest),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Find the alarm icon button in the SliverAppBar
      final alarmButton = find.byKey(const Key('btn_detail_reminder_action'));
      expect(alarmButton, findsOneWidget);

      await tester.tap(alarmButton);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ingatkan Kunjungan'), findsWidgets);
      final confirmBtn = find.byKey(const Key('btn_confirm_schedule_reminder'));
      expect(confirmBtn, findsOneWidget);

      await tester.ensureVisible(confirmBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(confirmBtn);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify notification repository now has this reminder
      final repo = NotificationRepository();
      expect(
        repo.notifications.any((n) =>
            n.type == NotificationType.destinationReminder &&
            n.title.contains(dest.name)),
        isTrue,
      );
    });
  });
}
