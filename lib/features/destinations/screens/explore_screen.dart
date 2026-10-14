import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/destination_repository.dart';
import '../../../models/destination.dart';
import '../../../shared/widgets/destination_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../map/screens/destination_map_screen.dart';
import 'destination_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;

  const ExploreScreen({super.key, this.initialCategory});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repository = DestinationRepository();
  final _searchController = TextEditingController();

  late String _selectedCategory;
  String _searchQuery = '';
  double? _maxBudget;
  bool _onlyFavorites = false;
  bool _isGridView = false;
  DestinationSortBy _sortBy = DestinationSortBy.popular;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Semua';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Semua';
      _searchQuery = '';
      _searchController.clear();
      _maxBudget = null;
      _onlyFavorites = false;
      _sortBy = DestinationSortBy.popular;
    });
  }

  void _openFilterBottomSheet() {
    double tempBudget = _maxBudget ?? 250000;
    bool hasBudgetLimit = _maxBudget != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currencyFormat = NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            );

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Destinasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            hasBudgetLimit = false;
                            tempBudget = 250000;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Budget Filter Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Batas Anggaran Tiket',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hasBudgetLimit
                            ? currencyFormat.format(tempBudget)
                            : 'Tanpa Batas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: hasBudgetLimit
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick budget chips
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua Budget'),
                        selected: !hasBudgetLimit,
                        onSelected: (selected) {
                          setModalState(() {
                            hasBudgetLimit = false;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Gratis'),
                        selected: hasBudgetLimit && tempBudget == 0,
                        onSelected: (selected) {
                          setModalState(() {
                            hasBudgetLimit = true;
                            tempBudget = 0;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('≤ Rp 35.000'),
                        selected: hasBudgetLimit && tempBudget == 35000,
                        onSelected: (selected) {
                          setModalState(() {
                            hasBudgetLimit = true;
                            tempBudget = 35000;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('≤ Rp 100.000'),
                        selected: hasBudgetLimit && tempBudget == 100000,
                        onSelected: (selected) {
                          setModalState(() {
                            hasBudgetLimit = true;
                            tempBudget = 100000;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Slider
                  Slider(
                    value: hasBudgetLimit ? tempBudget : 250000,
                    min: 0,
                    max: 250000,
                    divisions: 25,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.borderLight,
                    onChanged: (val) {
                      setModalState(() {
                        hasBudgetLimit = true;
                        tempBudget = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _maxBudget = hasBudgetLimit ? tempBudget : null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Terapkan Filter'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToDetail(Destination destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationDetailScreen(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final destinations = _repository.filterDestinations(
          query: _searchQuery,
          category: _selectedCategory,
          maxBudget: _maxBudget,
          onlyFavorites: _onlyFavorites,
          sortBy: _sortBy,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Katalog & Eksplorasi'),
            actions: [
              // Open Map Screen (Fleaflet)
              IconButton(
                icon: const Icon(Icons.map_rounded, color: AppColors.primary),
                tooltip: 'Peta Interaktif Fleaflet',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DestinationMapScreen(),
                    ),
                  );
                },
              ),
              // Grid vs List view toggle
              IconButton(
                icon: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  color: AppColors.primary,
                ),
                tooltip: _isGridView ? 'Tampilan List' : 'Tampilan Grid',
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              // Sort menu
              PopupMenuButton<DestinationSortBy>(
                icon: const Icon(Icons.sort_rounded, color: AppColors.primary),
                tooltip: 'Urutkan Destinasi',
                initialValue: _sortBy,
                onSelected: (val) {
                  setState(() {
                    _sortBy = val;
                  });
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: DestinationSortBy.popular,
                    child: Text('Paling Populer (Rating)'),
                  ),
                  PopupMenuItem(
                    value: DestinationSortBy.priceLowest,
                    child: Text('Harga Tiket: Termurah'),
                  ),
                  PopupMenuItem(
                    value: DestinationSortBy.priceHighest,
                    child: Text('Harga Tiket: Termahal'),
                  ),
                  PopupMenuItem(
                    value: DestinationSortBy.nameAZ,
                    child: Text('Nama: A - Z'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.getCardColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau tempat wisata...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter button
                    InkWell(
                      onTap: _openFilterBottomSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _maxBudget != null
                              ? AppColors.primary
                              : AppColors.getCardColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _maxBudget != null
                                ? AppColors.primary
                                : AppColors.getBorderColor(context),
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _maxBudget != null
                              ? Colors.white
                              : AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Pills & Favorite filter
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Favorite filter chip
                    FilterChip(
                      label: const Text('Favorit'),
                      avatar: Icon(
                        _onlyFavorites
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: _onlyFavorites
                            ? Colors.redAccent
                            : AppColors.textSecondaryLight,
                      ),
                      selected: _onlyFavorites,
                      onSelected: (val) {
                        setState(() {
                          _onlyFavorites = val;
                        });
                      },
                      selectedColor: Colors.redAccent.withValues(alpha: 0.15),
                      checkmarkColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _onlyFavorites
                              ? Colors.redAccent
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Categories
                    ...AppConstants.categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
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
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Results count and active filter indicators
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Text(
                      'Menampilkan ${destinations.length} destinasi',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    if (_maxBudget != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Budget ≤ Rp ${_maxBudget!.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _maxBudget = null;
                                });
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Destination list or grid
              Expanded(
                child: destinations.isEmpty
                    ? EmptyView(
                        title: 'Destinasi Tidak Ditemukan',
                        message: 'Tidak ada destinasi yang cocok dengan kriteria pencarian dan filter Anda.',
                        buttonText: 'Reset Filter',
                        onButtonPressed: _resetFilters,
                      )
                    : _isGridView
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final int columns = width > 900
                              ? 4
                              : (width > 600 ? 3 : 2);
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: destinations.length,
                            itemBuilder: (context, index) {
                              final item = destinations[index];
                              return DestinationCard(
                                destination: item,
                                isHorizontal: false,
                                onTap: () => _navigateToDetail(item),
                              );
                            },
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: destinations.length,
                        itemBuilder: (context, index) {
                          final item = destinations[index];
                          return DestinationCard(
                            destination: item,
                            isHorizontal: true,
                            onTap: () => _navigateToDetail(item),
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
}
