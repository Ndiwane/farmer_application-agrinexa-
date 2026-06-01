import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/admin_config.dart';
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

  bool get _isAdmin =>
      AdminConfig.isAdmin(FirebaseAuth.instance.currentUser?.uid);

  @override
  Widget build(BuildContext context) {
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
            // ── Home / Market ──────────────────────────────────────
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_outlined),
              activeIcon: const Icon(Icons.storefront_rounded),
              label: 'Market',
            ),

            // ── Sell / Discover ────────────────────────────────────
            BottomNavigationBarItem(
              icon: Icon(_isAdmin
                  ? Icons.add_circle_outline_rounded
                  : Icons.explore_outlined),
              activeIcon: Icon(_isAdmin
                  ? Icons.add_circle_rounded
                  : Icons.explore_rounded),
              label: _isAdmin ? 'List' : 'Discover',
            ),

            // ── Listing / My Space ─────────────────────────────────
            BottomNavigationBarItem(
              icon: Icon(_isAdmin
                  ? Icons.inventory_2_outlined
                  : Icons.favorite_outline_rounded),
              activeIcon: Icon(_isAdmin
                  ? Icons.inventory_2_rounded
                  : Icons.favorite_rounded),
              label: _isAdmin ? 'Manage' : 'My Space',
            ),

            // ── Profile ────────────────────────────────────────────
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}