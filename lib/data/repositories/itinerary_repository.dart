import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/destination.dart';
import '../../models/itinerary.dart';
import '../../services/supabase_service.dart';
import '../local/itinerary_storage.dart';
import 'auth_repository.dart';

class ItineraryRepository extends ChangeNotifier {
  static final ItineraryRepository _instance = ItineraryRepository._internal();
  factory ItineraryRepository() => _instance;
  ItineraryRepository._internal();

  final ItineraryStorage _storage = ItineraryStorage();
  final List<Itinerary> _itineraries = [];
  bool _isInitialized = false;

  List<Itinerary> get itineraries => List.unmodifiable(_itineraries);

  Future<void> init() async {
    if (_isInitialized) return;
    await _storage.init();
    await loadItineraries();
    _isInitialized = true;
  }

  Future<void> loadItineraries() async {
    final sb = SupabaseService();
    final user = AuthRepository().currentUser;
    if (sb.isInitialized && user != null) {
      try {
        final cloudList = await sb.fetchUserItineraries(user.id);
        // Ketika terhubung ke Supabase, gunakan murni rencana perjalanan dari Cloud
        _itineraries.clear();
        _itineraries.addAll(cloudList);
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Fetch cloud itineraries error: $e');
      }
    }

    final list = await _storage.getAllItineraries();
    _itineraries.clear();
    _itineraries.addAll(list);
    notifyListeners();
  }

  /// Bersihkan database lokal rencana perjalanan agar murni memuat dari Cloud
  Future<void> clearLocalItineraries() async {
    await _storage.clearAll();
    _itineraries.clear();
    notifyListeners();
    await loadItineraries();
  }

  Itinerary? getItineraryById(String id) {
    try {
      return _itineraries.firstWhere((it) => it.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Itinerary> createItinerary({
    required String title,
    required DateTime startDate,
    required int durationDays,
    required int numberOfPeople,
    double transportationCost = 0.0,
    double foodCost = 0.0,
    double additionalCost = 0.0,
    List<ItineraryItem> initialItems = const [],
  }) async {
    final now = DateTime.now();
    final newItinerary = Itinerary(
      id: 'itin_${now.millisecondsSinceEpoch}',
      title: title,
      startDate: startDate,
      durationDays: durationDays,
      numberOfPeople: numberOfPeople,
      transportationCost: transportationCost,
      foodCost: foodCost,
      additionalCost: additionalCost,
      items: initialItems,
      createdAt: now,
      updatedAt: now,
    );

    _itineraries.insert(0, newItinerary);
    await _storage.saveItinerary(newItinerary);
    notifyListeners();

    // Sinkronisasi otomatis ke Supabase
    final sb = SupabaseService();
    if (sb.isInitialized) {
      final user = AuthRepository().currentUser;
      final userId = user?.id ?? 'user_local';
      unawaited(sb.upsertItinerary(newItinerary, userId: userId));
    }

    return newItinerary;
  }

  Future<void> updateItinerary(Itinerary itinerary) async {
    final index = _itineraries.indexWhere((it) => it.id == itinerary.id);
    final updated = itinerary.copyWith(updatedAt: DateTime.now());
    if (index >= 0) {
      _itineraries[index] = updated;
    } else {
      _itineraries.insert(0, updated);
    }
    await _storage.saveItinerary(updated);
    notifyListeners();

    final sb = SupabaseService();
    if (sb.isInitialized) {
      final user = AuthRepository().currentUser;
      final userId = user?.id ?? 'user_local';
      unawaited(sb.upsertItinerary(updated, userId: userId));
    }
  }

  Future<void> deleteItinerary(String id) async {
    _itineraries.removeWhere((it) => it.id == id);
    await _storage.deleteItinerary(id);
    notifyListeners();

    final sb = SupabaseService();
    if (sb.isInitialized) {
      unawaited(sb.deleteItinerary(id));
    }
  }

  Future<void> addDestinationToItinerary({
    required String itineraryId,
    required Destination destination,
    required int dayNumber,
  }) async {
    final itinerary = getItineraryById(itineraryId);
    if (itinerary == null) return;

    final existingForDay = itinerary.items
        .where((i) => i.dayNumber == dayNumber)
        .toList();
    final nextOrder = existingForDay.length + 1;

    final newItem = ItineraryItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      destinationId: destination.id,
      destinationName: destination.name,
      destinationCategory: destination.category,
      imageUrl: destination.imageUrl,
      ticketPrice: destination.estimatedPrice,
      dayNumber: dayNumber,
      visitOrder: nextOrder,
    );

    final updatedItems = List<ItineraryItem>.from(itinerary.items)
      ..add(newItem);
    await updateItinerary(itinerary.copyWith(items: updatedItems));
  }

  Future<void> removeDestinationFromItinerary({
    required String itineraryId,
    required String itemId,
  }) async {
    final itinerary = getItineraryById(itineraryId);
    if (itinerary == null) return;

    final updatedItems = itinerary.items
        .where((item) => item.id != itemId)
        .toList();
    await updateItinerary(itinerary.copyWith(items: updatedItems));
  }

  Future<void> reorderItineraryItem({
    required String itineraryId,
    required String itemId,
    required bool moveUp,
  }) async {
    final itinerary = getItineraryById(itineraryId);
    if (itinerary == null) return;

    final targetItem = itinerary.items.firstWhere((i) => i.id == itemId);
    final dayItems =
        itinerary.items
            .where((i) => i.dayNumber == targetItem.dayNumber)
            .toList()
          ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));

    final currentIndex = dayItems.indexWhere((i) => i.id == itemId);
    if (moveUp && currentIndex <= 0) return;
    if (!moveUp && currentIndex >= dayItems.length - 1) return;

    final swapIndex = moveUp ? currentIndex - 1 : currentIndex + 1;
    final otherItem = dayItems[swapIndex];

    // Swap orders
    final updatedList = itinerary.items.map((item) {
      if (item.id == targetItem.id) {
        return item.copyWith(visitOrder: otherItem.visitOrder);
      }
      if (item.id == otherItem.id) {
        return item.copyWith(visitOrder: targetItem.visitOrder);
      }
      return item;
    }).toList();

    await updateItinerary(itinerary.copyWith(items: updatedList));
  }

  Future<void> updateCosts({
    required String itineraryId,
    required double transportationCost,
    required double foodCost,
    required double additionalCost,
  }) async {
    final itinerary = getItineraryById(itineraryId);
    if (itinerary == null) return;

    final updated = itinerary.copyWith(
      transportationCost: transportationCost,
      foodCost: foodCost,
      additionalCost: additionalCost,
    );
    await updateItinerary(updated);
  }

  Future<void> saveHashVerification(String itineraryId) async {
    final itinerary = getItineraryById(itineraryId);
    if (itinerary == null) return;

    final hash = itinerary.computeHash();
    final updated = itinerary.copyWith(savedHash: hash);
    await updateItinerary(updated);
  }
}
