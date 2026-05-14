import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';  
import '../utils/app_router.dart';

/// Main marketplace screen showing all available products
/// Users can search products, view details, and navigate to chat/notifications
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  // Controller for the search text field
  final _searchController = TextEditingController();
  
  // Current search query entered by user
  String _searchQuery = '';

  @override
  void dispose() {
    // Clean up the controller when widget is removed
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get currently logged in user
    final user = FirebaseAuth.instance.currentUser;
    
    // Extract first name from display name for personalized greeting
    final firstName = (user?.displayName ?? 'Farmer').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // HEADER SECTION: Greeting + Notifications + Chat + Profile
            // ═══════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Personalized greeting
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $firstName 👋',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark),
                      ),
                      Text(
                        'Find fresh farm products',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                  
                  // Right side: Notifications + Chat + Profile icons
                  Row(
                    children: [
                      // ─────────────────────────────────────────────────────
                      // NOTIFICATIONS ICON with unread badge
                      // ─────────────────────────────────────────────────────
                      StreamBuilder<QuerySnapshot>(
                        // Listen for unread notifications in real-time
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('toUserId', isEqualTo: user?.uid)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Count unread notifications
                          final unreadCount = snapshot.hasData 
                              ? snapshot.data!.docs.length 
                              : 0;
                          
                          return GestureDetector(
                            // Navigate to notifications screen when tapped
                            onTap: () => Navigator.push(
                              context,
                              AppRouter.slide(const NotificationsScreen()),
                            ),
                            child: Stack(
                              children: [
                                // Notification bell icon
                                Container(
                                  width: 42,
                                  height: 42,
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
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                // Red badge showing unread count
                                if (unreadCount > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        // Show "99+" if more than 99 notifications
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      
                      // ─────────────────────────────────────────────────────
                      // CHAT ICON with unread messages badge
                      // ─────────────────────────────────────────────────────
                      StreamBuilder<QuerySnapshot>(
                        // Listen for chats where current user is a participant
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .where('participants', arrayContains: user?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Calculate total unread messages across all chats
                          int totalUnread = 0;
                          if (snapshot.hasData) {
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              // Each chat stores unread count per user
                              totalUnread +=
                                  (data['unread_${user?.uid}'] ?? 0) as int;
                            }
                          }
                          
                          return GestureDetector(
                            // Navigate to chat list screen
                            onTap: () => Navigator.push(
                              context,
                              AppRouter.slide(const ChatScreen()),
                            ),
                            child: Stack(
                              children: [
                                // Chat bubble icon
                                Container(
                                  width: 42,
                                  height: 42,
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
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                // Red badge showing unread message count
                                if (totalUnread > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$totalUnread',
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      
                      // ─────────────────────────────────────────────────────
                      // PROFILE AVATAR
                      // ─────────────────────────────────────────────────────
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLighter,
                        // Show user's profile photo if available
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        // Show first letter of name if no photo
                        child: user?.photoURL == null
                            ? Text(
                                firstName[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            
            // ═══════════════════════════════════════════════════════════════
            // SEARCH BAR: Filter products by name or location
            // ═══════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _searchController,
                // Update search query in real-time as user types
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textLight),
                  // Show clear button when user has typed something
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ═══════════════════════════════════════════════════════════════
            // PRODUCTS GRID: Display all products from Firestore
            // ═══════════════════════════════════════════════════════════════
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Listen to products collection in real-time
                // Ordered by newest first
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Show loading spinner while fetching data
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }

                  // Show empty state if no products exist
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                    );
                  }

                  // Filter products based on search query
                  // Search matches product name or location
                  final docs = snapshot.data!.docs.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final name = (doc['name'] as String).toLowerCase();
                    final location =
                        (doc['location'] as String).toLowerCase();
                    return name.contains(_searchQuery) ||
                        location.contains(_searchQuery);
                  }).toList();

                  // Show message if search returns no results
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                          'No products found for "$_searchQuery"',
                          style:
                              TextStyle(color: AppColors.textMedium)),
                    );
                  }

                  // Display products in a 2-column grid
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two products per row
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.70, // Card height ratio
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _ProductCard(
                          productId: doc.id,
                          data: data,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual product card widget displayed in the marketplace grid
/// Shows product image, name, location, and price
class _ProductCard extends StatelessWidget {
  final String productId; // Firestore document ID
  final Map<String, dynamic> data; // Product data from Firestore

  const _ProductCard({required this.productId, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Navigate to product detail screen when card is tapped
      onTap: () => Navigator.push(
        context,
        AppRouter.slide(ProductDetailScreen(
            productId: productId,
            data: data,
          ),
        ),
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
            // ─────────────────────────────────────────────────────────────
            // PRODUCT IMAGE: Show product photo from Cloudinary
            // ─────────────────────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                data['imageUrl'] ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                // Show placeholder icon if image fails to load
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: AppColors.primaryLighter,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 40),
                ),
                // Show loading indicator while image loads
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
            
            // ─────────────────────────────────────────────────────────────
            // PRODUCT DETAILS: Name, Location, Price
            // ─────────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  
                  // Location with icon
                  Row(
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Price in green (format: "500 FCFA/kg")
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