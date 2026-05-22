import 'package:flutter/material.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'marketplace_screen.dart';
import 'sell_product_screen.dart';
import 'my_listing_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MarketplaceScreen(),
    SellProductScreen(),
    MyListingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Get translations using official Flutter localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home_rounded),
                label: l10n.navHome),
            BottomNavigationBarItem(
                icon: const Icon(Icons.add_circle_outline_rounded),
                activeIcon: const Icon(Icons.add_circle_rounded),
                label: l10n.navSell),
            BottomNavigationBarItem(
                icon: const Icon(Icons.list_alt_outlined),
                activeIcon: const Icon(Icons.list_alt_rounded),
                label: l10n.navListing),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: l10n.navProfile),
          ],
        ),
      ),
    );
  }
}
