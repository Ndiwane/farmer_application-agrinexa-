import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/admin_config.dart';
import 'product_detail_screen.dart';
import '../utils/app_router.dart';

class MyListingScreen extends StatefulWidget {
  const MyListingScreen({super.key});

  @override
  State<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends State<MyListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;
  bool get _isAdmin => AdminConfig.isAdmin(currentUser?.uid);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_isAdmin ? 'Manage Listings' : 'My Space'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          tabs: _isAdmin
              ? const [
                  Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Listings'),
                  Tab(icon: Icon(Icons.inbox_rounded), text: 'Requests'),
                ]
              : const [
                  Tab(icon: Icon(Icons.favorite_rounded), text: 'Saved'),
                  Tab(icon: Icon(Icons.list_alt_rounded), text: 'My Requests'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _isAdmin
            ? [
                _AdminListingsTab(adminId: currentUser?.uid ?? ''),
                _AdminRequestsTab(),
              ]
            : [
                _UserSavedTab(userId: currentUser?.uid ?? ''),
                _UserRequestsTab(userId: currentUser?.uid ?? ''),
              ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ADMIN — Listings Tab
// ════════════════════════════════════════════════════════════════════════════
class _AdminListingsTab extends StatelessWidget {
  final String adminId;
  const _AdminListingsTab({required this.adminId});

  Future<void> _deleteProduct(
      BuildContext context, String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This product will be removed from the marketplace permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _toggleSoldOut(
      String productId, bool currentSoldOut) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({'soldOut': !currentSoldOut});
  }

  void _showEditSheet(
      BuildContext context, String productId, Map<String, dynamic> data) {
    final priceController =
        TextEditingController(text: data['priceValue']?.toString() ?? '');
    final quantityController =
        TextEditingController(text: data['quantity']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16, right: 16, top: 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit ${data['name']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (FCFA)',
                prefixText: 'FCFA ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: data['unit'] ?? 'kg',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final price =
                    double.tryParse(priceController.text.trim()) ?? 0;
                final unit = data['unit'] ?? 'kg';
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .update({
                  'priceValue': price,
                  'price': '$price FCFA/$unit',
                  'quantity': quantityController.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product updated! ✅'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 60, color: AppColors.textLight),
                const SizedBox(height: 12),
                const Text('No products listed yet',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 6),
                Text('Go to the Sell tab to list products',
                    style: TextStyle(
                        color: AppColors.textMedium, fontSize: 13)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final soldOut = data['soldOut'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: soldOut
                      ? AppColors.danger.withValues(alpha: 0.3)
                      : AppColors.divider,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Product image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['imageUrl'] ?? '',
                            width: 70, height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 70, height: 70,
                              color: AppColors.primaryLighter,
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        if (soldOut)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('SOLD OUT',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(data['price'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            '${data['quantity']} ${data['unit']} • ${data['location']}',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    Column(
                      children: [
                        // Edit
                        GestureDetector(
                          onTap: () =>
                              _showEditSheet(context, doc.id, data),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLighter,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Sold out toggle
                        GestureDetector(
                          onTap: () =>
                              _toggleSoldOut(doc.id, soldOut),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: soldOut
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              soldOut
                                  ? Icons.check_circle_rounded
                                  : Icons.block_rounded,
                              color: soldOut
                                  ? AppColors.success
                                  : Colors.orange,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Delete
                        GestureDetector(
                          onTap: () =>
                              _deleteProduct(context, doc.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: AppColors.danger, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ADMIN — Requests Tab
// ════════════════════════════════════════════════════════════════════════════
class _AdminRequestsTab extends StatelessWidget {
  const _AdminRequestsTab();

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('MMM d, yyyy • HH:mm').format(timestamp.toDate());
  }

  Future<void> _markFulfilled(
      BuildContext context, String requestId) async {
    await FirebaseFirestore.instance
        .collection('product_requests')
        .doc(requestId)
        .update({'status': 'fulfilled'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request marked as fulfilled ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('product_requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 60, color: AppColors.textLight),
                const SizedBox(height: 12),
                const Text('No product requests yet',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 6),
                Text('User requests will appear here',
                    style: TextStyle(
                        color: AppColors.textMedium, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isFulfilled = data['status'] == 'fulfilled';
            final timestamp = data['createdAt'] as Timestamp?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFulfilled
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isFulfilled
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.primaryLighter,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFulfilled
                                ? Icons.check_circle_rounded
                                : Icons.shopping_basket_rounded,
                            color: isFulfilled
                                ? AppColors.success
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['productName'] ?? 'Unknown product',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                              ),
                              Text(data['userName'] ?? 'User',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFulfilled
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isFulfilled ? 'Fulfilled' : 'Pending',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isFulfilled
                                    ? AppColors.success
                                    : AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Details
                    _RequestDetail(
                        icon: Icons.scale_rounded,
                        label: 'Quantity',
                        value: data['quantity'] ?? 'Not specified'),
                    const SizedBox(height: 6),
                    _RequestDetail(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        value: data['location'] ?? 'Not specified'),
                    if ((data['note'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _RequestDetail(
                          icon: Icons.notes_rounded,
                          label: 'Note',
                          value: data['note']),
                    ],
                    const SizedBox(height: 6),
                    _RequestDetail(
                        icon: Icons.access_time_rounded,
                        label: 'Requested',
                        value: _formatDate(timestamp)),
                    if (!isFulfilled) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _markFulfilled(context, doc.id),
                        icon: const Icon(Icons.check_circle_rounded,
                            size: 16),
                        label: const Text('Mark as Fulfilled'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RequestDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textLight)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// USER — Saved Products Tab
// ════════════════════════════════════════════════════════════════════════════
class _UserSavedTab extends StatelessWidget {
  final String userId;
  const _UserSavedTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('saved_products')
          .where('userId', isEqualTo: userId)
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded,
                    size: 60, color: AppColors.textLight),
                const SizedBox(height: 12),
                const Text('No saved products yet',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  'Tap the ❤️ on any product\nto save it here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textMedium, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final savedId = docs[index].id;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                AppRouter.slide(ProductDetailScreen(
                  productId: data['productId'] ?? '',
                  data: data,
                )),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                          child: Image.network(
                            data['imageUrl'] ?? '',
                            height: 120, width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 120,
                              color: AppColors.primaryLighter,
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.primary, size: 40),
                            ),
                          ),
                        ),
                        // Remove from saved
                        Positioned(
                          top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('saved_products')
                                  .doc(savedId)
                                  .delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Removed from saved'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded,
                                  color: AppColors.danger, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(data['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(data['price'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// USER — My Requests Tab
// ════════════════════════════════════════════════════════════════════════════
class _UserRequestsTab extends StatelessWidget {
  final String userId;
  const _UserRequestsTab({required this.userId});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('product_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_outlined,
                    size: 60, color: AppColors.textLight),
                const SizedBox(height: 12),
                const Text('No requests yet',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  'Request products from the Sell tab\nand track them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textMedium, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isFulfilled = data['status'] == 'fulfilled';
            final timestamp = data['createdAt'] as Timestamp?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFulfilled
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isFulfilled
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primaryLighter,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFulfilled
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      color: isFulfilled
                          ? AppColors.success
                          : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['productName'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        if ((data['quantity'] ?? '').isNotEmpty)
                          Text('Qty: ${data['quantity']}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMedium)),
                        if ((data['location'] ?? '').isNotEmpty)
                          Text('📍 ${data['location']}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMedium)),
                        const SizedBox(height: 4),
                        Text(_formatDate(timestamp),
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFulfilled
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFulfilled ? '✅ Available' : '⏳ Pending',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isFulfilled
                              ? AppColors.success
                              : AppColors.warning),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}