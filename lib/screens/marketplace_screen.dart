import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import '../utils/app_router.dart';

/// Main marketplace screen with:
/// - Product recommendations based on past purchases
/// - Category filter chips
/// - Search bar
/// - Products grid
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All'; // Active category filter

  // ── Categories list ─────────────────────────────────────────────────────
  static const List<Map<String, String>> _categories = [
    {'name': 'All',        'emoji': '🌿'},
    {'name': 'Vegetables', 'emoji': '🥬'},
    {'name': 'Fruits',     'emoji': '🍎'},
    {'name': 'Grains',     'emoji': '🌽'},
    {'name': 'Legumes',    'emoji': '🫘'},
    {'name': 'Tubers',     'emoji': '🍠'},
    {'name': 'Nuts',       'emoji': '🌰'},
    {'name': 'Spices',     'emoji': '🌶️'},
    {'name': 'Other',      'emoji': '🌾'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load recommended products based on user's past purchases
  /// Steps:
  /// 1. Get user's past orders
  /// 2. Extract categories from those orders
  /// 3. Return products from those categories (excluding own products)
  Future<List<Map<String, dynamic>>> _loadRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Get user's past orders (limit to recent 20)
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .limit(20)
          .get();

      if (ordersSnapshot.docs.isEmpty) return [];

      // Extract unique categories from past orders
      final Set<String> purchasedCategories = {};
      for (var order in ordersSnapshot.docs) {
        final data = order.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          purchasedCategories.add(category);
        }
      }

      if (purchasedCategories.isEmpty) return [];

      // Get products from those categories
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', whereIn: purchasedCategories.take(10).toList())
          .limit(10)
          .get();

      // Filter out user's own products
      return productsSnapshot.docs
          .where((doc) => doc['sellerId'] != user.uid)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName ?? 'Farmer').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ══════════════════════════════════════════════════════════════
            // HEADER: Greeting + Notifications + Chat + Avatar
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Greeting
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $firstName 👋',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text('Find fresh farm products',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMedium)),
                      ],
                    ),

                    // Action icons
                    Row(
                      children: [
                        // Notifications icon with badge
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('notifications')
                              .where('toUserId', isEqualTo: user?.uid)
                              .where('isRead', isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final unreadCount = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;
                            return GestureDetector(
                              onTap: () => Navigator.push(context,
                                  AppRouter.slide(const NotificationsScreen())),
                              child: Stack(children: [
                                _IconButton(icon: Icons.notifications_outlined),
                                if (unreadCount > 0)
                                  _Badge(count: unreadCount),
                              ]),
                            );
                          },
                        ),
                        const SizedBox(width: 10),

                        // Chat icon with badge
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .where('participants', arrayContains: user?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int totalUnread = 0;
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                totalUnread +=
                                    (data['unread_${user?.uid}'] ?? 0) as int;
                              }
                            }
                            return GestureDetector(
                              onTap: () => Navigator.push(context,
                                  AppRouter.slide(const ChatScreen())),
                              child: Stack(children: [
                                _IconButton(
                                    icon: Icons.chat_bubble_outline_rounded),
                                if (totalUnread > 0)
                                  _Badge(count: totalUnread),
                              ]),
                            );
                          },
                        ),
                        const SizedBox(width: 10),

                        // Profile avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLighter,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Text(firstName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16))
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            // SEARCH BAR
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: TextFormField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textLight),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textLight),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            // RECOMMENDED FOR YOU (only shown when user has past purchases)
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadRecommendations(),
                builder: (context, snapshot) {
                  // Hide section if loading, error, or no recommendations
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final recommendations = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Row(
                          children: [
                            const Text('🔥 ',
                                style: TextStyle(fontSize: 16)),
                            const Text('Recommended For You',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark)),
                          ],
                        ),
                      ),

                      // Horizontal scrollable product cards
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            final product = recommendations[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  AppRouter.slide(ProductDetailScreen(
                                    productId: product['id'],
                                    data: product,
                                  )),
                                ),
                                child: Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Product image
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(14)),
                                        child: Image.network(
                                          product['imageUrl'] ?? '',
                                          height: 110,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Container(
                                            height: 110,
                                            color: AppColors.primaryLighter,
                                            child: const Icon(
                                                Icons.image_outlined,
                                                color: AppColors.primary,
                                                size: 36),
                                          ),
                                          loadingBuilder: (_, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              height: 110,
                                              color: AppColors.primaryLighter,
                                              child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: AppColors
                                                              .primary,
                                                          strokeWidth: 2)),
                                            );
                                          },
                                        ),
                                      ),
                                      // Product info
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  color: AppColors.textDark),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product['price'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  color: AppColors.primary),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            // CATEGORY FILTER CHIPS
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Categories',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                  ),
                  // Horizontal scrollable category chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected =
                            _selectedCategory == category['name'];

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                _selectedCategory = category['name']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                '${category['emoji']} ${category['name']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            // PRODUCTS GRID (filtered by category + search)
            // ══════════════════════════════════════════════════════════════
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator(
                          color: AppColors.primary)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.storefront_outlined,
                              size: 60, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          const Text('No products yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          Text('Be the first to list a product!',
                              style: TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                // Filter by search query AND selected category
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['name'] as String? ?? '').toLowerCase();
                  final location =
                      (data['location'] as String? ?? '').toLowerCase();
                  final category =
                      (data['category'] as String? ?? '');

                  // Search filter
                  final matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      location.contains(_searchQuery);

                  // Category filter
                  final matchesCategory = _selectedCategory == 'All' ||
                      category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Text('😕',
                                style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No products found for "$_searchQuery"'
                                  : 'No $_selectedCategory products yet',
                              style: TextStyle(color: AppColors.textMedium),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Display as 2-column grid
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _ProductCard(
                          productId: doc.id,
                          data: data,
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable circular icon button for header actions
class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

/// Reusable notification/message count badge
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Individual product card in the grid
class _ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;
  const _ProductCard({required this.productId, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppRouter.slide(ProductDetailScreen(productId: productId, data: data)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                data['imageUrl'] ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: AppColors.primaryLighter,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 40),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 120,
                    color: AppColors.primaryLighter,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),

            // Product details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (data['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['category'],
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                  // Product name
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textLight),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        data['location'] ?? '',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),

                  // Price
                  Text(
                    data['price'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary),
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
}