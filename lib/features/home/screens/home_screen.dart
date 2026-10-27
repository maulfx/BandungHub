import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/destination_repository.dart';
import '../../../data/sources/bandung_destinations.dart';
import '../../../models/destination.dart';
import '../../../shared/widgets/destination_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../destinations/screens/destination_detail_screen.dart';
import '../../lens/screens/bandung_lens_screen.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../offline/widgets/offline_banner_widget.dart';
import '../../recommendations/screens/ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final DestinationRepository _destinationRepo = DestinationRepository();

  // Demonstration state toggles for testing criteria
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _destinationRepo.addListener(_onDestinationsChanged);
  }

  void _onDestinationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _destinationRepo.removeListener(_onDestinationsChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Destination> get _filteredDestinations {
    final source = _destinationRepo.allDestinations.isNotEmpty
        ? _destinationRepo.allDestinations
        : BandungDestinations.list;
    return source.where((item) {
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _showDestinationDetails(Destination destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationDetailScreen(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBannerWidget(),
            Expanded(
              child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _isLoading = true;
            });
            await Future.delayed(const Duration(milliseconds: 700));
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = false;
              });
            }
          },
          child: CustomScrollView(
            slivers: [
              // Header with BandungHub identity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.explore_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppConstants.appName,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        AppConstants.appTagline,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              // Notification Bell Icon with Badge
                              ListenableBuilder(
                                listenable: NotificationRepository(),
                                builder: (context, _) {
                                  final unread =
                                      NotificationRepository().unreadCount;
                                  return IconButton(
                                    tooltip: 'Pusat Notifikasi & Pengingat',
                                    icon: Badge(
                                      isLabelVisible: unread > 0,
                                      label: Text('$unread'),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.getCardColor(context),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.getBorderColor(
                                              context,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_outlined,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationCenterScreen(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              // Bandung AI Lens (Camera Landmark Scanner)
                              IconButton(
                                key: const Key('btn_home_ai_lens'),
                                tooltip: 'Bandung AI Lens (Pindai Landmark)',
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_enhance_rounded,
                                    size: 20,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BandungLensScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              // Demonstration State Toggle popup menu
                              PopupMenuButton<String>(
                            tooltip: 'Simulasi State (Loading/Error)',
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            onSelected: (value) {
                              setState(() {
                                if (value == 'normal') {
                                  _isLoading = false;
                                  _hasError = false;
                                } else if (value == 'loading') {
                                  _isLoading = true;
                                  _hasError = false;
                                } else if (value == 'error') {
                                  _isLoading = false;
                                  _hasError = true;
                                }
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'normal',
                                child: Text('State: Normal Data'),
                              ),
                              const PopupMenuItem(
                                value: 'loading',
                                child: Text('Simulasi: Loading State'),
                              ),
                              const PopupMenuItem(
                                value: 'error',
                                child: Text('Simulasi: Error State'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getCardColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.getBorderColor(context),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Cari wisata, kuliner, atau tempat di Bandung...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchQuery.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  ),
                                IconButton(
                                  tooltip: 'Pindai Landmark dengan Kamera (AI Lens)',
                                  icon: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BandungLensScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Pills
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AppConstants.categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = AppConstants.categories[index];
                            final isSelected = _selectedCategory == category;
                            return ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.getTextPrimary(context),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                              backgroundColor: AppColors.getCardColor(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.getBorderColor(context),
                                ),
                              ),
                              showCheckmark: false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Body depending on states
              if (_isLoading)
                const SliverFillRemaining(
                  child: LoadingView(
                    message: 'Memuat rekomendasi destinasi BandungHub...',
                  ),
                )
              else if (_hasError)
                SliverFillRemaining(
                  child: ErrorView(
                    onRetry: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = false;
                      });
                    },
                  ),
                )
              else if (_filteredDestinations.isEmpty)
                SliverFillRemaining(
                  child: EmptyView(
                    title: 'Tidak Ada Destinasi Ditemukan',
                    message:
                        'Tidak ada destinasi yang cocok dengan kata kunci "$_searchQuery" pada kategori "$_selectedCategory".',
                    buttonText: 'Reset Filter',
                    onButtonPressed: () {
                      setState(() {
                        _selectedCategory = 'Semua';
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                )
              else ...[
                // Banner Highlight if no search
                if (_searchQuery.isEmpty && _selectedCategory == 'Semua')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Parijs van Java',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Jelajahi Pesona Bandung',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Temukan wisata alam sejuk, kuliner legendaris, dan warisan sejarah.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          if (widget.onNavigateTab != null) {
                                            widget.onNavigateTab!(
                                              1,
                                            ); // Go to Explore
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Mulai Eksplorasi',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AiChatScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.smart_toy_rounded,
                                          size: 14,
                                          color: AppColors.primaryDark,
                                        ),
                                        label: const Text(
                                          'Tanya Kang Bandung (AI)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.amber.shade300,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        key: const Key('btn_banner_ai_lens'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const BandungLensScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.camera_enhance_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Bandung AI Lens',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.nature_people_rounded,
                              size: 72,
                              color: Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Popular Horizontal Section
                if (_searchQuery.isEmpty && _selectedCategory == 'Semua') ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paling Populer',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (widget.onNavigateTab != null) {
                                widget.onNavigateTab!(1);
                              }
                            },
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 250,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: (_destinationRepo.allDestinations.isNotEmpty
                                ? _destinationRepo.allDestinations
                                : BandungDestinations.list)
                            .take(5)
                            .length,
                        itemBuilder: (context, index) {
                          final popularList = (_destinationRepo.allDestinations.isNotEmpty
                                  ? _destinationRepo.allDestinations
                                  : BandungDestinations.list)
                              .take(5)
                              .toList();
                          final item = popularList[index];
                          return DestinationCard(
                            destination: item,
                            onTap: () => _showDestinationDetails(item),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // All Filtered Destinations Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategory == 'Semua'
                              ? 'Daftar Wisata Bandung (${_filteredDestinations.length})'
                              : 'Kategori: $_selectedCategory (${_filteredDestinations.length})',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _filteredDestinations[index];
                      return DestinationCard(
                        destination: item,
                        isHorizontal: true,
                        onTap: () => _showDestinationDetails(item),
                      );
                    }, childCount: _filteredDestinations.length),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_ai_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text(
          'Tanya AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatScreen()),
          );
        },
      ),
    );
  }
}
