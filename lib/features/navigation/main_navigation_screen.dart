import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/screens/auth_gate.dart';
import '../destinations/screens/explore_screen.dart';
import '../home/screens/home_screen.dart';
import '../itinerary/screens/itinerary_screen.dart';
import '../mini_game/screens/game_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == 4) {
      _showLogoutDialog();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Keluar Akun'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun BandungHub?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthRepository().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const ExploreScreen(),
      const ItineraryScreen(),
      const GameScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: AppColors.primary),
            label: 'Eksplorasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
            label: 'Rencana',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(
              Icons.sports_esports_rounded,
              color: AppColors.primary,
            ),
            label: 'Game',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout_rounded, color: AppColors.error),
            selectedIcon: Icon(Icons.logout_rounded, color: AppColors.error),
            label: 'Keluar',
          ),
        ],
      ),
    );
  }
}
