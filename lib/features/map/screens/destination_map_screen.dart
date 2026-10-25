import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/destination_repository.dart';
import '../../../models/destination.dart';
import '../../../services/bandung_places_search_service.dart';
import '../../../services/location_service.dart';
import '../../../services/map_service.dart';
import '../../../services/routing_service.dart';
import '../../../services/sensor_service.dart';
import '../../destinations/screens/destination_detail_screen.dart';
import '../widgets/compass_dial_widget.dart';

class DestinationMapScreen extends StatefulWidget {
  final Destination? initialDestination;
  final bool isNavigating;

  const DestinationMapScreen({
    super.key,
    this.initialDestination,
    this.isNavigating = false,
  });

  @override
  State<DestinationMapScreen> createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final DestinationRepository _repository = DestinationRepository();
  final SensorService _sensorService = SensorService();
  final BandungPlacesSearchService _placesService = BandungPlacesSearchService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  LatLng? _userLocation;
  bool _isLocating = false;
  String _selectedCategory = 'Semua';
  Destination? _selectedDestination;
  bool _isNavigating = false;

  // Search state
  List<Destination> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  // Additional dynamic markers found via search
  final List<Destination> _customSearchedMarkers = [];

  // Routing & Transportation Mode State
  final RoutingService _routingService = RoutingService();
  TransportMode _selectedTransportMode = TransportMode.car;
  List<LatLng> _currentRoutePoints = [];
  RouteDetails? _currentRouteDetails;
  bool _isLoadingRoute = false;

  // Compass & Accelerometer State
  StreamSubscription<CompassOrientation>? _compassSub;
  CompassOrientation _orientation = CompassOrientation.initial;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _selectedDestination = widget.initialDestination;
    _isNavigating = widget.isNavigating;
    _fetchUserLocation(showNotice: false);

    if (_isNavigating && _selectedDestination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchRoute();
      });
    }

    // Initialize with cached sensor reading
    _orientation = _sensorService.currentOrientation;

    // Listen to accelerometer / orientation compass stream
    _sensorService.startListening();
    _compassSub = _sensorService.orientationStream.listen((data) {
      if (mounted) {
        final headingDiff = (data.heading - _orientation.heading).abs();
        final isSignificant = headingDiff > 0.4 ||
            data.cardinalDirection != _orientation.cardinalDirection;

        if (isSignificant) {
          setState(() => _orientation = data);
        }
      }
    });
  }

  Future<void> _fetchRoute() async {
    if (_selectedDestination == null) return;
    final start = _userLocation ?? LocationService.defaultBandungCenter;
    final dest = _selectedDestination!.coordinates;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final details = await _routingService.getRoute(
        start: start,
        destination: dest,
        mode: _selectedTransportMode,
      );

      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          _currentRouteDetails = details;
          _currentRoutePoints = details.points;
        });
        _fitRouteBounds(start, dest);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          _currentRoutePoints = [start, dest];
        });
        _fitRouteBounds(start, dest);
      }
    }
  }

  void _onTransportModeChanged(TransportMode mode) {
    if (_selectedTransportMode == mode && _currentRoutePoints.isNotEmpty) return;
    setState(() {
      _selectedTransportMode = mode;
    });
    if (_isNavigating && _selectedDestination != null) {
      _fetchRoute();
    }
  }

  void _fitRouteBounds(LatLng start, LatLng dest) {
    if (_currentRoutePoints.length > 2) {
      // Calculate true bounding box encompassing all road turn points
      double minLat = start.latitude;
      double maxLat = start.latitude;
      double minLng = start.longitude;
      double maxLng = start.longitude;

      for (final p in _currentRoutePoints) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final distKm = _locationService.calculateDistanceInKm(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      double zoom;
      if (distKm > 600) {
        zoom = 5.8;
      } else if (distKm > 350) {
        zoom = 6.8;
      } else if (distKm > 200) {
        zoom = 7.6;
      } else if (distKm > 100) {
        zoom = 8.4;
      } else if (distKm > 60) {
        zoom = 9.2;
      } else if (distKm > 35) {
        zoom = 10.2;
      } else if (distKm > 20) {
        zoom = 11.2;
      } else if (distKm > 10) {
        zoom = 12.0;
      } else if (distKm > 4) {
        zoom = 12.8;
      } else {
        zoom = 13.8;
      }
      _mapController.move(LatLng(centerLat, centerLng), zoom);
      return;
    }

    final centerLat = (start.latitude + dest.latitude) / 2;
    final centerLng = (start.longitude + dest.longitude) / 2;
    final distKm = _locationService.calculateDistanceInKm(start, dest);

    double zoom;
    if (distKm > 600) {
      zoom = 5.8;
    } else if (distKm > 350) {
      zoom = 6.8;
    } else if (distKm > 200) {
      zoom = 7.6;
    } else if (distKm > 100) {
      zoom = 8.4;
    } else if (distKm > 60) {
      zoom = 9.2;
    } else if (distKm > 35) {
      zoom = 10.2;
    } else if (distKm > 20) {
      zoom = 11.2;
    } else if (distKm > 10) {
      zoom = 12.0;
    } else if (distKm > 4) {
      zoom = 12.8;
    } else {
      zoom = 13.8;
    }
    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _sensorService.stopListening();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserLocation({bool showNotice = true}) async {
    setState(() => _isLocating = true);

    final position = await _locationService.getCurrentPosition();

    if (mounted) {
      setState(() => _isLocating = false);

      if (position != null) {
        final userPos = LatLng(position.latitude, position.longitude);
        final isInsideBandung = MapService.bandungBounds.contains(userPos);

        setState(() {
          _userLocation = userPos;
        });

        if (_isNavigating && _selectedDestination != null) {
          // If navigating, always fit route from user's current location to destination
          _fetchRoute();
          if (showNotice) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isInsideBandung
                      ? 'Lokasi Anda ditemukan. Menampilkan rute ke ${_selectedDestination!.name}!'
                      : 'Lokasi Anda (di luar Bandung) terdeteksi. Menampilkan rute perjalanan ke ${_selectedDestination!.name}!',
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (isInsideBandung) {
          _mapController.move(userPos, 14.5);
          if (showNotice) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lokasi Anda di Bandung berhasil ditemukan!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } else {
          // User is outside Bandung and not currently navigating
          _mapController.move(userPos, 12.0);
          if (showNotice) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Lokasi Anda terdeteksi di luar Bandung. Pilih destinasi wisata untuk melihat rute perjalanan.',
                ),
                backgroundColor: AppColors.secondary,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else if (showNotice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi belum diberikan atau GPS dimatikan. Peta tetap menampilkan wilayah Bandung.',
            ),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final q = query.trim();

    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    // 1. Instantly match curated local destinations in memory
    final localMatches = _repository.allDestinations.where((d) {
      final queryLower = q.toLowerCase();
      return d.name.toLowerCase().contains(queryLower) ||
          d.address.toLowerCase().contains(queryLower) ||
          d.category.toLowerCase().contains(queryLower) ||
          d.tags.any((t) => t.toLowerCase().contains(queryLower));
    }).take(8).toList();

    setState(() {
      _searchResults = localMatches;
      _isSearching = true;
      _showSearchResults = true;
    });

    // 2. Debounced live OpenStreetMap search strictly inside Bandung Raya
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final liveMatches = await _placesService.searchPlaces(q);

        if (mounted && _searchController.text.trim() == q) {
          final combined = [...localMatches];

          for (final place in liveMatches) {
            final alreadyPresent = combined.any((m) =>
                m.id == place.id ||
                m.name.toLowerCase().trim() == place.name.toLowerCase().trim());

            if (!alreadyPresent) {
              combined.add(place);
            }
          }

          setState(() {
            _searchResults = combined;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _selectSearchedDestination(Destination dest) {
    FocusScope.of(context).unfocus();
    _searchController.text = dest.name;

    setState(() {
      _showSearchResults = false;
      _selectedDestination = dest;
      // Ensure custom searched marker is pinned to map
      if (!_customSearchedMarkers.any((m) => m.id == dest.id) &&
          !_repository.allDestinations.any((d) => d.id == dest.id)) {
        _customSearchedMarkers.add(dest);
      }
    });

    _mapController.move(dest.coordinates, 15.0);
  }

  void _openNearestDestinationsSheet() {
    final center = _userLocation ?? LocationService.defaultBandungCenter;
    final allDests = [
      ..._repository.allDestinations,
      ..._customSearchedMarkers,
    ];
    final nearest = _locationService.getNearestDestinations(
      userLocation: center,
      destinations: allDests,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Destinasi Terdekat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _userLocation != null
                          ? 'Dari Lokasi Anda'
                          : 'Dari Pusat Bandung',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Perhitungan jarak menggunakan kalkulasi garis lurus koordinat geografis.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: nearest.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = nearest[index].key;
                    final distanceKm = nearest[index].value;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 50,
                            height: 50,
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.place_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${item.category} • ${currencyFormatter.format(item.estimatedPrice)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _locationService.formatDistance(distanceKm),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Jarak',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedDestination = item;
                        });
                        _mapController.move(item.coordinates, 15.0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combine all destinations (local 37+ + dynamic searched map markers)
    final allDestinations = [
      ..._repository.allDestinations,
      ..._customSearchedMarkers,
    ];

    final filteredDestinations = allDestinations.where((d) {
      return _selectedCategory == 'Semua' ||
          d.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Wisata Bandung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.near_me_rounded, color: AppColors.primary),
            tooltip: 'Destinasi Terdekat',
            onPressed: _openNearestDestinationsSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Fleaflet OpenStreetMap Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialDestination != null
                  ? widget.initialDestination!.coordinates
                  : LocationService.defaultBandungCenter,
              initialZoom: widget.initialDestination != null ? 14.5 : 12.0,
              minZoom: 4.0,
              maxZoom: 18.0,
              cameraConstraint: const CameraConstraint.unconstrained(),
              onTap: (tapPosition, point) {
                FocusScope.of(context).unfocus();
                setState(() {
                  _selectedDestination = null;
                  _showSearchResults = false;
                });
              },
            ),
            children: [
              // OpenStreetMap Tile Layer
              TileLayer(
                urlTemplate: MapService.osmTileUrl,
                userAgentPackageName: MapService.userAgentPackageName,
              ),

              // In-App Navigation Route Polyline Layer (Following real road network)
              if (_isNavigating && _selectedDestination != null)
                PolylineLayer(
                  polylines: _buildNavigationPolylines(),
                ),

              // Marker Layer
              MarkerLayer(
                markers: [
                  // Start Point Marker if GPS is default Bandung center
                  if (_isNavigating &&
                      _selectedDestination != null &&
                      _userLocation == null)
                    Marker(
                      point: LocationService.defaultBandungCenter,
                      width: 38,
                      height: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.trip_origin_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                  // Transit Station Markers (Stasiun Keberangkatan & Kedatangan)
                  if (_isNavigating &&
                      _selectedTransportMode == TransportMode.transit &&
                      _currentRouteDetails?.transitDetails != null) ...[
                    _buildStationMarker(
                      _currentRouteDetails!.transitDetails!.originStation,
                      'Stasiun Keberangkatan',
                      Colors.orange.shade800,
                    ),
                    _buildStationMarker(
                      _currentRouteDetails!.transitDetails!.destStation,
                      'Stasiun Kedatangan',
                      const Color(0xFF6A1B9A),
                    ),
                  ],
                  // Destination Markers
                  ...filteredDestinations.map((dest) {
                    final isSelected = _selectedDestination?.id == dest.id;
                    final catColor = AppColors.getCategoryColor(dest.category);
                    final catIcon = AppColors.getCategoryIcon(dest.category);

                    return Marker(
                      point: dest.coordinates,
                      width: isSelected ? 52 : 38,
                      height: isSelected ? 52 : 38,
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selectedDestination = dest;
                            _showSearchResults = false;
                          });
                          _mapController.move(dest.coordinates, 14.5);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryDark
                                : catColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3.5 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            catIcon,
                            color: Colors.white,
                            size: isSelected ? 24 : 18,
                          ),
                        ),
                      ),
                    );
                  }),

                  // User GPS Location Marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Map Attribution
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
              ),
            ],
          ),

          // 2. In-App Navigation Guidance Bar OR Google Maps-Style Floating Search Bar on Top
          if (_isNavigating && _selectedDestination != null)
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: _buildNavigationGuidanceHeader(context),
            )
          else ...[
            Positioned(
            top: 10,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.getBorderColor(context),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Cari destinasi wisata di Bandung...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                    ],
                  ),
                ),

                // Live Search Dropdown Sheet
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: AppColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.getBorderColor(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final isLivePlace = item.id.startsWith('osm_');

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.getCategoryColor(item.category)
                                .withValues(alpha: 0.15),
                            child: Icon(
                              AppColors.getCategoryIcon(item.category),
                              size: 14,
                              color: AppColors.getCategoryColor(item.category),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLivePlace)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Peta Live',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            item.address,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                          onTap: () => _selectSearchedDestination(item),
                        );
                      },
                    ),
                  )
                else if (_showSearchResults && _searchResults.isEmpty && !_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getCardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.getBorderColor(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          size: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tidak ditemukan tempat "${_searchController.text.trim()}" di wilayah Bandung.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 3. Category Filter Pills on Top (Positioned below Search Bar)
          Positioned(
            top: 66,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = AppConstants.categories[index];
                  final isSelected = _selectedCategory == cat;

                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimaryLight,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black26,
                  );
                },
              ),
            ),
          ),
        ],

          // 4. Compass Heading Badge (Top Left)
          Positioned(
            top: _isNavigating && _selectedDestination != null ? 96 : 114,
            left: 14,
            child: GestureDetector(
              onTap: _showCompassInfoDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      AppColors.getCardColor(context).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.getBorderColor(context),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: _orientation.heading),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      builder: (context, angle, _) {
                        return Transform.rotate(
                          angle: angle * (math.pi / 180),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.redAccent,
                            size: 15,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_orientation.heading.toInt()}° ${_orientation.cardinalDirection}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Floating Map Controls (Right Side)
          Positioned(
            right: 14,
            bottom: _selectedDestination != null
                ? (_isNavigating ? 84 : 148)
                : 24,
            child: Column(
              children: [
                // Compass Bearing (Accelerometer & Magnetometer)
                FloatingActionButton.small(
                  heroTag: 'compass_bearing',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  tooltip:
                      'Kompas (${_orientation.heading.toInt()}° ${_orientation.cardinalDirection})',
                  onPressed: _showCompassInfoDialog,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: -_orientation.heading),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    builder: (context, angle, _) {
                      return Transform.rotate(
                        angle: angle * (math.pi / 180),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.navigation_rounded, size: 20),
                            Positioned(
                              top: 2,
                              child: Container(
                                width: 3.5,
                                height: 3.5,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Zoom in
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                // Zoom out
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                // Center Bandung
                FloatingActionButton.small(
                  heroTag: 'center_bandung',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.secondary,
                  tooltip: 'Pusat Kota Bandung',
                  onPressed: () {
                    _mapController.move(
                      LocationService.defaultBandungCenter,
                      12.5,
                    );
                  },
                  child: const Icon(Icons.location_city_rounded),
                ),
                const SizedBox(height: 8),
                // My Location GPS
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  tooltip: 'Lokasi Saya',
                  onPressed: () => _fetchUserLocation(showNotice: true),
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // 5. Selected Destination Bottom Card (Compact Navigation Bar or Place Preview)
          if (_selectedDestination != null)
            _isNavigating
                ? _buildCompactNavigationBottomBar(context)
                : _buildDestinationPreviewCard(context),
        ],
      ),
    );
  }

  /// Compact, low-profile navigation bar shown at the bottom during active route navigation.
  /// Prevents covering the map while keeping essential controls and ETA accessible.
  Widget _buildCompactNavigationBottomBar(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 12,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _selectedTransportMode.routeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedTransportMode.icon,
                  size: 18,
                  color: _selectedTransportMode.routeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedDestination!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _currentRouteDetails != null
                          ? '${_currentRouteDetails!.formattedDistance} • ${_currentRouteDetails!.formattedDuration}'
                          : 'Menghitung rute...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _selectedTransportMode.routeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DestinationDetailScreen(
                        destination: _selectedDestination!,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Detail', style: TextStyle(fontSize: 11.5)),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isNavigating = false;
                    _currentRoutePoints = [];
                    _currentRouteDetails = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 14),
                    SizedBox(width: 3),
                    Text('Selesai', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                tooltip: 'Opsi Peta Luar',
                onSelected: (val) {
                  if (val == 'external') {
                    MapService.openExternalMapNavigation(
                      latitude: _selectedDestination!.latitude,
                      longitude: _selectedDestination!.longitude,
                      destinationName: _selectedDestination!.name,
                      mode: _selectedTransportMode,
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'external',
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Buka di Google Maps Eksternal',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact destination preview card shown when a pin is selected before navigating.
  Widget _buildDestinationPreviewCard(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _selectedDestination!.imageUrl,
                      width: 66,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 66,
                        height: 66,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.place_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.getCategoryColor(
                                  _selectedDestination!.category,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedDestination!.category,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getCategoryColor(
                                    _selectedDestination!.category,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _selectedDestination!.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                              ),
                              onPressed: () => setState(
                                () => _selectedDestination = null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedDestination!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_userLocation != null)
                          Text(
                            'Jarak Garis Lurus: ${_locationService.formatDistance(_locationService.calculateDistanceInKm(_userLocation!, _selectedDestination!.coordinates))}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            _selectedDestination!.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedDestination!.estimatedPrice <= 0
                              ? 'Gratis / Tanpa Tiket'
                              : currencyFormatter.format(
                                  _selectedDestination!.estimatedPrice,
                                ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DestinationDetailScreen(
                              destination: _selectedDestination!,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Buka Detail',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isNavigating = true;
                        });
                        _fetchRoute();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Panduan rute ${_selectedTransportMode.label} aktif menuju ${_selectedDestination!.name}',
                            ),
                            backgroundColor: _selectedTransportMode.routeColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text(
                        'Petunjuk Rute',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Opsi Peta Luar',
                    onSelected: (val) {
                      if (val == 'external') {
                        MapService.openExternalMapNavigation(
                          latitude: _selectedDestination!.latitude,
                          longitude: _selectedDestination!.longitude,
                          destinationName: _selectedDestination!.name,
                          mode: _selectedTransportMode,
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'external',
                        child: Row(
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Buka di Google Maps Eksternal',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationGuidanceHeader(BuildContext context) {
    final start = _userLocation ?? LocationService.defaultBandungCenter;
    final dest = _selectedDestination!.coordinates;
    final details = _currentRouteDetails;
    final mode = _selectedTransportMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: mode.routeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Guidance Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: mode.routeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    mode.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: mode.routeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NAVIGASI ${mode.label.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: mode.routeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (details != null)
                            Text(
                              details.formattedDistance,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: mode.routeColor,
                              ),
                            ),
                          if (_isLoadingRoute) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menuju ${_selectedDestination!.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.getTextPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        details != null
                            ? '~ ${details.formattedDuration} (${details.summary})'
                            : 'Menghitung rute terbaik...',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                  tooltip: 'Pusatkan Rute',
                  onPressed: () => _fitRouteBounds(start, dest),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Tutup Rute Navigasi',
                  onPressed: () {
                    setState(() {
                      _isNavigating = false;
                      _currentRoutePoints = [];
                      _currentRouteDetails = null;
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Google Maps-Style Transport Mode Selector Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: TransportMode.values.map((m) {
                final isSelected = m == _selectedTransportMode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _onTransportModeChanged(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? m.routeColor
                              : m.routeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? m.routeColor
                                : m.routeColor.withValues(alpha: 0.25),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              m.icon,
                              size: 16,
                              color: isSelected ? Colors.white : m.routeColor,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected ? Colors.white : m.routeColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Vehicle restriction / constraint badge
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: mode.routeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: mode.routeColor.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  mode.icon,
                  size: 13,
                  color: mode.routeColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    details?.routeFeatureNote.isNotEmpty == true
                        ? details!.routeFeatureNote
                        : mode.vehicleConstraintNote,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: mode.routeColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Transit 3-stage multimodal itinerary breakdown
          if (_selectedTransportMode == TransportMode.transit &&
              details?.transitDetails != null)
            _buildTransitItineraryCard(details!.transitDetails!),
        ],
      ),
    );
  }

  /// Builds a visual itinerary card showing the 3 distinct stages of transit travel.
  Widget _buildTransitItineraryCard(TransitTripDetails transit) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6A1B9A).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 15,
                color: Color(0xFF6A1B9A),
              ),
              const SizedBox(width: 6),
              const Text(
                'Perjalanan Multimoda 3 Tahap',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  MapService.openExternalMapNavigation(
                    latitude: _selectedDestination!.latitude,
                    longitude: _selectedDestination!.longitude,
                    destinationName: _selectedDestination!.name,
                    mode: TransportMode.transit,
                  );
                },
                child: const Text(
                  'Jadwal KAI ➔',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tahap 1: Akses ke Stasiun Asal
          _buildTransitStepRow(
            icon: Icons.directions_bike_rounded,
            iconColor: Colors.orange.shade800,
            title: 'Ke ${transit.originStation.name}',
            subtitle:
                'Kendaraan/jalan kaki (${transit.firstMileKm.toStringAsFixed(1)} km • ${transit.firstMileMinutes} mnt)',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: SizedBox(
              height: 10,
              child: VerticalDivider(
                width: 1,
                thickness: 1.5,
                color: Colors.grey,
              ),
            ),
          ),
          // Tahap 2: Naik Kereta Api (Rel)
          _buildTransitStepRow(
            icon: Icons.train_rounded,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Naik KA (${transit.originStation.line})',
            subtitle:
                'Menyusuri rel KA: ${transit.originStation.name} ➔ ${transit.destStation.name} (${transit.trainKm.toStringAsFixed(1)} km • ${transit.trainMinutes} mnt)',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: SizedBox(
              height: 10,
              child: VerticalDivider(
                width: 1,
                thickness: 1.5,
                color: Colors.grey,
              ),
            ),
          ),
          // Tahap 3: Dari Stasiun Tujuan ke Tempat Wisata
          _buildTransitStepRow(
            icon: Icons.place_rounded,
            iconColor: Colors.teal.shade800,
            title: 'Ke ${_selectedDestination!.name}',
            subtitle:
                'Dari ${transit.destStation.name} (${transit.lastMileKm.toStringAsFixed(1)} km • ${transit.lastMileMinutes} mnt)',
          ),
        ],
      ),
    );
  }

  Widget _buildTransitStepRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds distinct polylines customized by transport mode and vehicle constraints.
  List<Polyline> _buildNavigationPolylines() {
    if (_selectedDestination == null) return [];
    final fallbackPoints = [
      _userLocation ?? LocationService.defaultBandungCenter,
      _selectedDestination!.coordinates,
    ];

    final transit = _currentRouteDetails?.transitDetails;
    if (_selectedTransportMode == TransportMode.transit && transit != null) {
      final list = <Polyline>[];

      // 1. First mile: Akses kendaraan / jalan kaki ke stasiun keberangkatan
      if (transit.firstMilePoints.isNotEmpty) {
        list.add(
          Polyline(
            points: transit.firstMilePoints,
            color: Colors.orange.shade700.withValues(alpha: 0.35),
            strokeWidth: 8.0,
          ),
        );
        list.add(
          Polyline(
            points: transit.firstMilePoints,
            color: Colors.orange.shade800,
            strokeWidth: 4.5,
          ),
        );
      }

      // 2. Train segment: Menyusuri rel kereta api antar stasiun
      if (transit.trainTrackPoints.isNotEmpty) {
        list.add(
          Polyline(
            points: transit.trainTrackPoints,
            color: const Color(0xFF311B92).withValues(alpha: 0.45),
            strokeWidth: 10.0,
          ),
        );
        list.add(
          Polyline(
            points: transit.trainTrackPoints,
            color: const Color(0xFF6A1B9A),
            strokeWidth: 6.0,
          ),
        );
        list.add(
          Polyline(
            points: transit.trainTrackPoints,
            color: Colors.white.withValues(alpha: 0.8),
            strokeWidth: 2.0,
          ),
        );
      }

      // 3. Last mile: Akses kendaraan / jalan kaki dari stasiun kedatangan ke tempat wisata
      if (transit.lastMilePoints.isNotEmpty) {
        list.add(
          Polyline(
            points: transit.lastMilePoints,
            color: Colors.teal.shade700.withValues(alpha: 0.35),
            strokeWidth: 8.0,
          ),
        );
        list.add(
          Polyline(
            points: transit.lastMilePoints,
            color: Colors.teal.shade800,
            strokeWidth: 4.5,
          ),
        );
      }

      return list;
    }

    final points =
        _currentRoutePoints.isNotEmpty ? _currentRoutePoints : fallbackPoints;
    return [
      Polyline(
        points: points,
        color: _selectedTransportMode.routeColor.withValues(alpha: 0.35),
        strokeWidth: 8.5,
      ),
      Polyline(
        points: points,
        color: _selectedTransportMode.routeColor,
        strokeWidth: 5.0,
      ),
    ];
  }

  /// Marker for train stations during transit navigation.
  Marker _buildStationMarker(
    TrainStationInfo station,
    String role,
    Color color,
  ) {
    return Marker(
      point: station.coordinates,
      width: 140,
      height: 46,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.train_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    station.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompassInfoDialog() {
    double? destBearing;
    if (_selectedDestination != null && _userLocation != null) {
      destBearing = SensorService.calculateBearing(
        _userLocation!,
        _selectedDestination!.coordinates,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StreamBuilder<CompassOrientation>(
          stream: _sensorService.orientationStream,
          initialData: _sensorService.currentOrientation,
          builder: (context, snapshot) {
            final orientation =
                snapshot.data ?? _sensorService.currentOrientation;

            return Material(
              color: AppColors.getCardColor(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Cukup Kompas saja
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Kompas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Kompas Dial Sederhana & Mulus
                      CompassDialWidget(
                        heading: orientation.heading,
                        destBearing: destBearing,
                        size: 190,
                      ),
                      const SizedBox(height: 16),

                      // Derajat & Arah Mata Angin
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${orientation.heading.toInt()}°',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '${orientation.cardinalLabel} (${orientation.cardinalDirection})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Panduan arah destinasi terpilih (jika ada)
                      if (_selectedDestination != null &&
                          destBearing != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.secondary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.near_me_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Arah Menuju ${_selectedDestination!.name}:',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Azimuth ${destBearing.toInt()}° (${SensorService.getCardinalDirection(destBearing).label})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.getTextSecondary(
                                            context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
