import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:projek_akhir/data/dummy/dummy_destinations.dart';
import 'package:projek_akhir/data/repositories/offline_sync_repository.dart';
import 'package:projek_akhir/data/repositories/review_repository.dart';
import 'package:projek_akhir/features/offline/screens/offline_sync_screen.dart';
import 'package:projek_akhir/features/offline/widgets/offline_banner_widget.dart';
import 'package:projek_akhir/models/sync_queue_item.dart';
import 'package:projek_akhir/services/network_connectivity_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
    SharedPreferences.setMockInitialValues({});
    NetworkConnectivityService.instance.reset();
  });

  group('Phase 13 - SyncQueueItem Model Tests', () {
    test('SyncQueueItem serializes to and from Map accurately', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final item = SyncQueueItem(
        id: 'sync_test_01',
        actionType: SyncActionType.createReview,
        targetId: 'dest_02',
        payload: {
          'destinationId': 'dest_02',
          'destinationName': 'Kawah Putih',
          'userName': 'Budi Traveler',
          'rating': 5.0,
          'comment': 'Pemandangan kawah sangat indah!',
        },
        queuedAt: now,
        status: SyncStatus.pending,
      );

      final map = item.toMap();
      expect(map['id'], 'sync_test_01');
      expect(map['actionType'], 'createReview');
      expect(map['targetId'], 'dest_02');
      expect(map['status'], 'pending');

      final reconstructed = SyncQueueItem.fromMap(map);
      expect(reconstructed.id, item.id);
      expect(reconstructed.actionType, SyncActionType.createReview);
      expect(reconstructed.targetId, 'dest_02');
      expect(reconstructed.displayTitle, 'Ulasan Baru: Kawah Putih');
      expect(reconstructed.statusLabel, 'Menunggu Sinyal');
      expect(reconstructed.status, SyncStatus.pending);
    });

    test('SyncQueueItem displays appropriate titles for different actions', () {
      final now = DateTime(2026, 10, 14, 12, 0);

      final validReviewItem = SyncQueueItem(
        id: 's1',
        actionType: SyncActionType.createReview,
        targetId: 'dest_01',
        payload: const {'destinationName': 'Gedung Sate'},
        queuedAt: now,
      );
      expect(validReviewItem.displayTitle, 'Ulasan Baru: Gedung Sate');

      final itinItem = SyncQueueItem(
        id: 's2',
        actionType: SyncActionType.createItinerary,
        targetId: 'itin_01',
        payload: {'title': 'Wisata Sejarah Bandung'},
        queuedAt: now,
      );
      expect(itinItem.displayTitle, 'Buat Rencana: Wisata Sejarah Bandung');

      final likeItem = SyncQueueItem(
        id: 's3',
        actionType: SyncActionType.likeReview,
        targetId: 'rev_100',
        payload: {},
        queuedAt: now,
      );
      expect(likeItem.displayTitle, 'Sukai Ulasan (rev_100)');
    });

    test('SyncQueueItem copyWith creates modified instance', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final item = SyncQueueItem(
        id: 's1',
        actionType: SyncActionType.createReview,
        targetId: 'dest_01',
        payload: {},
        queuedAt: now,
        status: SyncStatus.pending,
      );

      final modified = item.copyWith(
        status: SyncStatus.synced,
        retryCount: 2,
        errorMessage: 'Network timeout',
      );

      expect(modified.id, 's1');
      expect(modified.status, SyncStatus.synced);
      expect(modified.retryCount, 2);
      expect(modified.errorMessage, 'Network timeout');
    });
  });

  group('Phase 13 - NetworkConnectivityService Tests', () {
    test('Default state is online', () {
      final service = NetworkConnectivityService.instance;
      expect(service.isOnline, true);
      expect(service.isSimulatedOffline, false);
      expect(service.isOnlineNotifier.value, true);
    });

    test('Toggling simulated offline updates isOnline and notifies listeners', () {
      final service = NetworkConnectivityService.instance;
      bool? latestNotifiedState;

      service.isOnlineNotifier.addListener(() {
        latestNotifiedState = service.isOnlineNotifier.value;
      });

      service.setSimulatedOffline(true);
      expect(service.isOnline, false);
      expect(service.isSimulatedOffline, true);
      expect(latestNotifiedState, false);

      service.setSimulatedOffline(false);
      expect(service.isOnline, true);
      expect(service.isSimulatedOffline, false);
      expect(latestNotifiedState, true);
    });

    test('checkConnectivity returns accurate state', () async {
      final service = NetworkConnectivityService.instance;
      service.reset();
      expect(await service.checkConnectivity(), true);

      service.setSimulatedOffline(true);
      expect(await service.checkConnectivity(), false);
    });
  });

  group('Phase 13 - OfflineSyncRepository Logic & Persistence Tests', () {
    late OfflineSyncRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      NetworkConnectivityService.instance.reset();
      repo = OfflineSyncRepository.instance;
      await repo.init();
      await repo.clearAllQueue();
    });

    test('enqueueAction adds item to pending queue', () async {
      // Put in offline mode so it does not immediately auto-sync
      NetworkConnectivityService.instance.setSimulatedOffline(true);

      final item = await repo.enqueueAction(
        actionType: SyncActionType.createReview,
        targetId: 'dest_01',
        payload: {
          'destinationId': 'dest_01',
          'destinationName': 'Gedung Sate',
          'userName': 'Andi',
          'rating': 5.0,
          'comment': 'Sangat bersejarah!',
        },
      );

      expect(repo.queue.length, 1);
      expect(repo.pendingCount, 1);
      expect(repo.pendingItems.first.id, item.id);
      expect(repo.pendingItems.first.status, SyncStatus.pending);
    });

    test('syncAll processes pending items and marks them synced', () async {
      NetworkConnectivityService.instance.setSimulatedOffline(true);
      await ReviewRepository().init();

      await repo.enqueueAction(
        actionType: SyncActionType.createReview,
        targetId: 'dest_03',
        payload: {
          'destinationId': 'dest_03',
          'destinationName': 'Tangkuban Perahu',
          'userName': 'Dedi',
          'rating': 4.5,
          'comment': 'Kawahnya megah dan sejuk.',
        },
      );

      expect(repo.pendingCount, 1);

      // Now restore network connection and sync
      NetworkConnectivityService.instance.setSimulatedOffline(false);
      final result = await repo.syncAll();

      expect(result.success, true);
      expect(result.totalProcessed, 1);
      expect(result.successCount, 1);
      expect(repo.pendingCount, 0);
      expect(repo.syncedItems.length, 1);
      expect(repo.lastSyncTime, isNotNull);
    });

    test('clearSyncedItems removes synced items from queue', () async {
      NetworkConnectivityService.instance.setSimulatedOffline(true);

      await repo.enqueueAction(
        actionType: SyncActionType.toggleBookmark,
        targetId: 'dest_04',
        payload: {'isFavorite': true},
      );

      NetworkConnectivityService.instance.setSimulatedOffline(false);
      await repo.syncAll();
      expect(repo.syncedItems.length, 1);

      final removedCount = await repo.clearSyncedItems();
      expect(removedCount, 1);
      expect(repo.queue.length, 0);
    });

    test('getCacheStats and clearTemporaryCache return valid figures', () async {
      final stats = repo.getCacheStats();
      expect(stats['destinationsCount'], DummyDestinations.list.length);
      expect(stats['totalBytes'], isNonZero);
      expect(stats['formattedSize'].toString().contains('MB'), true);

      final freed = await repo.clearTemporaryCache();
      expect(freed, isNonNegative);
    });
  });

  group('Phase 13 - Offline UI Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      NetworkConnectivityService.instance.reset();
      await OfflineSyncRepository.instance.init();
      await OfflineSyncRepository.instance.clearAllQueue();
    });

    testWidgets('OfflineBannerWidget appears when simulated offline is active',
        (tester) async {
      final netService = NetworkConnectivityService.instance;
      netService.reset();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfflineBannerWidget(),
                Text('Konten Utama'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Online: banner is not rendered
      expect(find.byKey(const Key('offline_banner_container')), findsNothing);

      // Switch to offline
      netService.setSimulatedOffline(true);
      await tester.pump();

      // Offline banner is now rendered
      expect(find.byKey(const Key('offline_banner_container')), findsOneWidget);
      expect(find.text('Mode Offline Aktif'), findsOneWidget);
      expect(find.byKey(const Key('btn_offline_banner_details')), findsOneWidget);
    });

    testWidgets('OfflineSyncScreen renders status card, switch, and sync button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineSyncScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sinkronisasi & Cache Offline'), findsOneWidget);
      expect(find.byKey(const Key('switch_simulated_offline')), findsOneWidget);
      expect(find.byKey(const Key('btn_sync_now')), findsOneWidget);
      expect(find.byKey(const Key('btn_clear_cache')), findsOneWidget);

      // Tap simulated offline switch
      await tester.tap(find.byKey(const Key('switch_simulated_offline')));
      await tester.pumpAndSettle();

      expect(NetworkConnectivityService.instance.isSimulatedOffline, true);
      expect(find.text('Mode Offline Aktif'), findsOneWidget);

      // Tap clear cache button
      await tester.tap(find.byKey(const Key('btn_clear_cache')));
      await tester.pump();

      expect(find.textContaining('Cache sementara berhasil dibersihkan'), findsOneWidget);
    });
  });
}
