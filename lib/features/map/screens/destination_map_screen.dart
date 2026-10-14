import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/dummy/dummy_destinations.dart';
import '../../../models/destination.dart';
import '../../../services/location_service.dart';
import '../../../services/map_service.dart';
import '../../destinations/screens/destination_detail_screen.dart';

class DestinationMapScreen extends StatefulWidget {
  final Destination? initialDestination;

  const DestinationMapScreen({super.key, this.initialDestination});

  @override
  State<DestinationMapScreen> createState() => _DestinationMapScreenState();
}

class _DestinationMapScreenState extends State<DestinationMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _userLocation;
  bool _isLocating = false;
  String _selectedCategory = 'Semua';
  Destination? _selectedDestination;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _selectedDestination = widget.initialDestination;
    _fetchUserLocation(showNotice: false);
  }

  Future<void> _fetchUserLocation({bool showNotice = true}) async {
    setState(() => _isLocating = true);

    final position = await _locationService.getCurrentPosition();

    if (mounted) {
      setState(() => _isLocating = false);

      if (position != null) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });

        if (showNotice) {
          _mapController.move(_userLocation!, 14.5);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi Anda berhasil ditemukan!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 1),
            ),
          );
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

  void _openNearestDestinationsSheet() {
    final center = _userLocation ?? LocationService.defaultBandungCenter;
    final nearest = _locationService.getNearestDestinations(
      userLocation: center,
      destinations: DummyDestinations.list,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey.shade300,
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
              const Divider(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: nearest.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = nearest[index].key;
                    final distKm = nearest[index].value;
                    final catColor = AppColors.getCategoryColor(item.category);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                                color: catColor.withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.place_rounded,
                                  color: catColor,
                                ),
                              ),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Jarak Garis Lurus: ${_locationService.formatDistance(distKm)} • ${item.category}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedDestination = item;
                        });
                        _mapController.move(item.coordinates, 14.5);
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
    final filteredDestinations = DummyDestinations.list.where((d) {
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
          // 1. Fleaflet Map Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialDestination != null
                  ? widget.initialDestination!.coordinates
                  : LocationService.defaultBandungCenter,
              initialZoom: widget.initialDestination != null ? 14.0 : 12.0,
              minZoom: 8.5,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                setState(() => _selectedDestination = null);
              },
            ),
            children: [
              // OpenStreetMap Tile Layer with User Agent
              TileLayer(
                urlTemplate: MapService.osmTileUrl,
                userAgentPackageName: MapService.userAgentPackageName,
              ),

              // Marker Layer
              MarkerLayer(
                markers: [
                  // Destination Markers
                  ...filteredDestinations.map((dest) {
                    final isSelected = _selectedDestination?.id == dest.id;
                    final catColor = AppColors.getCategoryColor(dest.category);
                    final catIcon = AppColors.getCategoryIcon(dest.category);

                    return Marker(
                      point: dest.coordinates,
                      width: isSelected ? 50 : 38,
                      height: isSelected ? 50 : 38,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDestination = dest;
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
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
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

          // 2. Category Filter Pills on Top
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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

          // 3. Floating Map Controls (Right Side)
          Positioned(
            right: 16,
            bottom: _selectedDestination != null ? 220 : 24,
            child: Column(
              children: [
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
                          width: 16,
                          height: 16,
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

          // 4. Selected Destination Bottom Preview Card
          if (_selectedDestination != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _selectedDestination!.imageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 72,
                                    height: 72,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: const Icon(
                                      Icons.place_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                          fontSize: 10,
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
                                      _selectedDestination!.rating
                                          .toStringAsFixed(1),
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
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDestination!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
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
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDestination!.estimatedPrice <= 0
                                      ? 'Gratis'
                                      : currencyFormatter.format(
                                          _selectedDestination!.estimatedPrice,
                                        ),
                                  style: const TextStyle(
                                    fontSize: 13,
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
                                    builder: (context) =>
                                        DestinationDetailScreen(
                                          destination: _selectedDestination!,
                                        ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                                MapService.openExternalMapNavigation(
                                  latitude: _selectedDestination!.latitude,
                                  longitude: _selectedDestination!.longitude,
                                  destinationName: _selectedDestination!.name,
                                );
                              },
                              icon: const Icon(
                                Icons.navigation_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Navigasi Peta',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
