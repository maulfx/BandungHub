import 'package:flutter/foundation.dart';

import '../dummy/dummy_destinations.dart';
import '../../models/destination.dart';
import '../../services/supabase_service.dart';

enum DestinationSortBy {
  popular, // Rating highest
  priceLowest,
  priceHighest,
  nameAZ,
}

class DestinationRepository extends ChangeNotifier {
  // Singleton pattern for easy global state access
  static final DestinationRepository _instance =
      DestinationRepository._internal();
  factory DestinationRepository() => _instance;
  DestinationRepository._internal();

  final List<Destination> _allDestinations = List.from(DummyDestinations.list);
  final Set<String> _favoriteIds = {};

  List<Destination> get allDestinations => List.unmodifiable(_allDestinations);
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  Future<void> init() async {
    final sb = SupabaseService();
    if (sb.isInitialized) {
      try {
        final cloud = await sb.fetchDestinations();
        if (cloud.isNotEmpty) {
          final Map<String, Destination> merged = {
            for (final d in DummyDestinations.list) d.id: d,
          };
          for (final c in cloud) {
            merged[c.id] = c;
          }
          _allDestinations.clear();
          _allDestinations.addAll(merged.values);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Fetch cloud destinations error: $e');
      }
    }
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  Destination? getDestinationById(String id) {
    try {
      return _allDestinations.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Destination> filterDestinations({
    String query = '',
    String category = 'Semua',
    double? maxBudget,
    bool onlyFavorites = false,
    DestinationSortBy sortBy = DestinationSortBy.popular,
  }) {
    var result = _allDestinations.where((item) {
      // Category filter
      if (category != 'Semua' &&
          item.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }

      // Budget filter
      if (maxBudget != null && item.estimatedPrice > maxBudget) {
        return false;
      }

      // Favorite filter
      if (onlyFavorites && !_favoriteIds.contains(item.id)) {
        return false;
      }

      // Query filter
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesAddress = item.address.toLowerCase().contains(q);
        final matchesDesc = item.description.toLowerCase().contains(q);
        final matchesTag = item.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchesName && !matchesAddress && !matchesDesc && !matchesTag) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    switch (sortBy) {
      case DestinationSortBy.popular:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case DestinationSortBy.priceLowest:
        result.sort((a, b) => a.estimatedPrice.compareTo(b.estimatedPrice));
        break;
      case DestinationSortBy.priceHighest:
        result.sort((a, b) => b.estimatedPrice.compareTo(a.estimatedPrice));
        break;
      case DestinationSortBy.nameAZ:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return result;
  }
}
