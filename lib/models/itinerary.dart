import 'dart:convert';

import 'package:crypto/crypto.dart';

class ItineraryItem {
  final String id;
  final String destinationId;
  final String destinationName;
  final String destinationCategory;
  final String imageUrl;
  final double ticketPrice;
  final int dayNumber; // Hari 1, Hari 2, dst.
  final int visitOrder; // Urutan kunjungan: 1, 2, 3...
  final String notes;

  const ItineraryItem({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.destinationCategory,
    required this.imageUrl,
    required this.ticketPrice,
    required this.dayNumber,
    required this.visitOrder,
    this.notes = '',
  });

  ItineraryItem copyWith({
    String? id,
    String? destinationId,
    String? destinationName,
    String? destinationCategory,
    String? imageUrl,
    double? ticketPrice,
    int? dayNumber,
    int? visitOrder,
    String? notes,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      destinationCategory: destinationCategory ?? this.destinationCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      dayNumber: dayNumber ?? this.dayNumber,
      visitOrder: visitOrder ?? this.visitOrder,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination_id': destinationId,
      'destination_name': destinationName,
      'destination_category': destinationCategory,
      'image_url': imageUrl,
      'ticket_price': ticketPrice,
      'day_number': dayNumber,
      'visit_order': visitOrder,
      'notes': notes,
    };
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id']?.toString() ?? '',
      destinationId: map['destination_id']?.toString() ?? '',
      destinationName: map['destination_name'] ?? '',
      destinationCategory: map['destination_category'] ?? 'Alam',
      imageUrl: map['image_url'] ?? '',
      ticketPrice: (map['ticket_price'] as num?)?.toDouble() ?? 0.0,
      dayNumber: (map['day_number'] as num?)?.toInt() ?? 1,
      visitOrder: (map['visit_order'] as num?)?.toInt() ?? 1,
      notes: map['notes'] ?? '',
    );
  }
}

class Itinerary {
  final String id;
  final String title;
  final DateTime startDate;
  final int durationDays;
  final int numberOfPeople;
  final List<ItineraryItem> items;
  final double transportationCost;
  final double foodCost;
  final double additionalCost;
  final String syncStatus; // 'local_only', 'pending', 'synced'
  final String? savedHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Itinerary({
    required this.id,
    required this.title,
    required this.startDate,
    required this.durationDays,
    this.numberOfPeople = 1,
    this.items = const [],
    this.transportationCost = 0.0,
    this.foodCost = 0.0,
    this.additionalCost = 0.0,
    this.syncStatus = 'local_only',
    this.savedHash,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate ticket cost = sum of all destination tickets * number of people
  double get totalTicketCost {
    return items.fold<double>(
      0.0,
      (sum, item) => sum + (item.ticketPrice * numberOfPeople),
    );
  }

  // Total overall cost
  double get totalEstimatedBudget {
    return totalTicketCost + transportationCost + foodCost + additionalCost;
  }

  // Cost per person
  double get costPerPerson {
    final count = numberOfPeople > 0 ? numberOfPeople : 1;
    return totalEstimatedBudget / count;
  }

  // Group items by day number (e.g. Day 1 -> [items], Day 2 -> [items])
  Map<int, List<ItineraryItem>> get itemsByDay {
    final Map<int, List<ItineraryItem>> map = {};
    for (int d = 1; d <= durationDays; d++) {
      map[d] = [];
    }
    for (final item in items) {
      if (!map.containsKey(item.dayNumber)) {
        map[item.dayNumber] = [];
      }
      map[item.dayNumber]!.add(item);
    }
    // Sort each day's items by visitOrder
    map.forEach((day, list) {
      list.sort((a, b) => a.visitOrder.compareTo(b.visitOrder));
    });
    return map;
  }

  // SHA-256 Hash of deterministic serialized state for integrity verification (Phase 11)
  String computeHash() {
    final buffer = StringBuffer();
    buffer.write(
      '$id|$title|${startDate.toIso8601String()}|$durationDays|$numberOfPeople|',
    );
    buffer.write('$transportationCost|$foodCost|$additionalCost|');
    final sortedItems = List<ItineraryItem>.from(items)
      ..sort(
        (a, b) => a.dayNumber != b.dayNumber
            ? a.dayNumber.compareTo(b.dayNumber)
            : a.visitOrder.compareTo(b.visitOrder),
      );

    for (final item in sortedItems) {
      buffer.write(
        '${item.id}:${item.destinationId}:${item.dayNumber}:${item.visitOrder}:${item.ticketPrice}|',
      );
    }
    final bytes = utf8.encode(buffer.toString());
    return sha256.convert(bytes).toString();
  }

  bool get isHashValid => savedHash != null && savedHash == computeHash();

  Itinerary copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    int? durationDays,
    int? numberOfPeople,
    List<ItineraryItem>? items,
    double? transportationCost,
    double? foodCost,
    double? additionalCost,
    String? syncStatus,
    String? savedHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      items: items ?? this.items,
      transportationCost: transportationCost ?? this.transportationCost,
      foodCost: foodCost ?? this.foodCost,
      additionalCost: additionalCost ?? this.additionalCost,
      syncStatus: syncStatus ?? this.syncStatus,
      savedHash: savedHash ?? this.savedHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'duration_days': durationDays,
      'number_of_people': numberOfPeople,
      'transportation_cost': transportationCost,
      'food_cost': foodCost,
      'additional_cost': additionalCost,
      'sync_status': syncStatus,
      'saved_hash': savedHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory Itinerary.fromMap(Map<String, dynamic> map) {
    List<ItineraryItem> loadedItems = [];
    if (map['items'] != null) {
      try {
        final decoded = map['items'] is String
            ? jsonDecode(map['items']) as List<dynamic>
            : map['items'] as List<dynamic>;
        loadedItems = decoded
            .map((item) => ItineraryItem.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return Itinerary(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? 'Rencana Wisata Bandung',
      startDate:
          DateTime.tryParse(map['start_date']?.toString() ?? '') ??
          DateTime.now(),
      durationDays: (map['duration_days'] as num?)?.toInt() ?? 1,
      numberOfPeople: (map['number_of_people'] as num?)?.toInt() ?? 1,
      items: loadedItems,
      transportationCost:
          (map['transportation_cost'] as num?)?.toDouble() ?? 0.0,
      foodCost: (map['food_cost'] as num?)?.toDouble() ?? 0.0,
      additionalCost: (map['additional_cost'] as num?)?.toDouble() ?? 0.0,
      syncStatus: map['sync_status'] ?? 'local_only',
      savedHash: map['saved_hash'],
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
