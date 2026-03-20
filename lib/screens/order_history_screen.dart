import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;

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
        leading: BackButton(),
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          tabs: const [
            Tab(text: 'My Orders'),
            Tab(text: 'Received Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Orders (as buyer)
          _OrdersList(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('buyerId', isEqualTo: currentUser?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            emptyMessage: 'You have not placed any orders yet.',
            isBuyer: true,
          ),
          // Received Orders (as seller)
          _OrdersList(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('sellerId', isEqualTo: currentUser?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            emptyMessage: 'No orders received yet.',
            isBuyer: false,
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyMessage;
  final bool isBuyer;

  const _OrdersList({
    required this.stream,
    required this.emptyMessage,
    required this.isBuyer,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading orders',
                style: TextStyle(color: AppColors.textMedium)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 60, color: AppColors.textLight),
                const SizedBox(height: 12),
                Text(emptyMessage,
                    style: TextStyle(
                        color: AppColors.textMedium, fontSize: 14)),
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
            return _OrderCard(
              orderId: doc.id,
              data: data,
              isBuyer: isBuyer,
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final bool isBuyer;

  const _OrderCard({
    required this.orderId,
    required this.data,
    required this.isBuyer,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return AppColors.success;
      case 'Delivered':
        return AppColors.primary;
      case 'Cancelled':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Pending';
    final timestamp = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data['productImage'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.primaryLighter,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.primary),
                    ),
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
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        isBuyer
                            ? 'Seller: ${data['sellerName'] ?? ''}'
                            : 'Buyer: ${data['buyerName'] ?? ''}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatDate(timestamp),
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status)),
                  ),
                ),
              ],
            ),
          ),
          // Order details
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DetailItem(
                      label: 'Quantity',
                      value: '${data['quantity'] ?? 0}kg',
                    ),
                    _DetailItem(
                      label: 'Delivery',
                      value: data['deliveryOption'] ?? 'Pickup',
                    ),
                    _DetailItem(
                      label: 'Total',
                      value:
                          '${(data['total'] ?? 0).toStringAsFixed(0)} FCFA',
                      isHighlighted: true,
                    ),
                  ],
                ),
                // Update status button (for sellers only)
                if (!isBuyer) ...[
                  const SizedBox(height: 10),
                  _StatusUpdateButton(
                    orderId: orderId,
                    currentStatus: status,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _DetailItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppColors.textLight)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? AppColors.primary : null)),
      ],
    );
  }
}

class _StatusUpdateButton extends StatelessWidget {
  final String orderId;
  final String currentStatus;

  const _StatusUpdateButton({
    required this.orderId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Determine next status
    String? nextStatus;
    if (currentStatus == 'Pending') nextStatus = 'Confirmed';
    if (currentStatus == 'Confirmed') nextStatus = 'Delivered';

    if (nextStatus == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .update({'status': nextStatus});

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order marked as $nextStatus!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('Mark as $nextStatus'),
      ),
    );
  }
}
