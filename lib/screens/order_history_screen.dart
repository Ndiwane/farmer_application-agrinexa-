import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/admin_config.dart';
import '../services/notification_service.dart';

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
        leading: const BackButton(),
        title: const Text('My Orders'),
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
          _OrdersTab(
            userId: currentUser?.uid ?? '',
            isBuyer: true,
          ),
          _OrdersTab(
            userId: currentUser?.uid ?? '',
            isBuyer: false,
          ),
        ],
      ),
    );
  }
}

// ── Orders Tab with Search ────────────────────────────────────────────────────
class _OrdersTab extends StatefulWidget {
  final String userId;
  final bool isBuyer;

  const _OrdersTab({required this.userId, required this.isBuyer});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
    });
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    // Search by product name
    if (_searchQuery.isNotEmpty) {
      final name = (data['productName'] as String? ?? '').toLowerCase();
      if (!name.contains(_searchQuery.toLowerCase())) return false;
    }

    // Filter by date
    if (_selectedDate != null) {
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) return false;
      final orderDate = ts.toDate();
      final selected = _selectedDate!;
      if (orderDate.year != selected.year ||
          orderDate.month != selected.month ||
          orderDate.day != selected.day) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.isBuyer
        ? FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .snapshots();

    return Column(
      children: [
        // ── Search + Date filter bar ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search by product name
              TextFormField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by product name...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textLight, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textLight, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Date filter row
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedDate != null
                            ? AppColors.primaryLighter
                            : Theme.of(context).appBarTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedDate != null
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16,
                            color: _selectedDate != null
                                ? AppColors.primary
                                : AppColors.textLight),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(_selectedDate!)
                              : 'Filter by date',
                          style: TextStyle(
                              fontSize: 13,
                              color: _selectedDate != null
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              fontWeight: _selectedDate != null
                                  ? FontWeight.w600
                                  : FontWeight.w400),
                        ),
                      ]),
                    ),
                  ),
                ),
                if (_selectedDate != null || _searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: const Text('Clear',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),

        // ── Orders list ─────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _EmptyOrders(isBuyer: widget.isBuyer);
              }

              // Apply filters
              final filtered = snapshot.data!.docs.where((doc) {
                return _matchesFilters(
                    doc.data() as Map<String, dynamic>);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('😕',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('No orders match your search',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _OrderCard(
                    orderId: doc.id,
                    data: data,
                    isBuyer: widget.isBuyer,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
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
      case 'Confirmed': return Colors.blue;
      case 'Shipped':   return Colors.orange;
      case 'Delivered': return AppColors.success;
      case 'Cancelled': return AppColors.danger;
      default:          return AppColors.warning;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }

  Future<void> _deleteOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Order?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This order will be removed from your history. This action cannot be undone.'),
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
          .collection('orders')
          .doc(orderId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delivery',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you received your order in good condition?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('Yes, Received!'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
      'status': 'Delivered',
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'deliveredAt': FieldValue.serverTimestamp(),
    });

    final sellerId = data['sellerId'] as String?;
    if (sellerId != null && sellerId.isNotEmpty) {
      await NotificationService.sendNotificationToUser(
        userId: sellerId,
        title: '✅ Order Delivered!',
        body:
            '${data['buyerName']} confirmed receiving ${data['productName']}.',
        data: {'type': 'order'},
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for confirming! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Pending';
    final timestamp = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data['productImage'] ?? '',
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 60, height: 60,
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
                              fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 13),
                        const SizedBox(width: 4),
                        Text(AdminConfig.verifiedLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 4),
                      Text(_formatDate(timestamp),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(status))),
                    ),
                    const SizedBox(height: 6),
                    // ✅ Delete button
                    GestureDetector(
                      onTap: () => _deleteOrder(context),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order details
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DetailItem(
                      label: 'Quantity',
                      value:
                          '${data['quantity'] ?? 0} ${data['unit'] ?? 'kg'}',
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
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Status tracker
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: _StatusTracker(status: status),
          ),

          // Buyer actions
          if (isBuyer) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const _AgriNexaSupportCard(),
                  if (status == 'Shipped') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelivery(context),
                        icon: const Icon(Icons.check_circle_rounded,
                            size: 18),
                        label: const Text('I Received My Order ✅'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Admin actions
          if (!isBuyer)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _SellerStatusButtons(
                orderId: orderId,
                currentStatus: status,
                data: data,
              ),
            ),
        ],
      ),
    );
  }
}

// ── AgriNexa Support Card ─────────────────────────────────────────────────────
class _AgriNexaSupportCard extends StatelessWidget {
  const _AgriNexaSupportCard();

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
        'Hello AgriNexa! I need help with my order.');
    final directUrl = Uri.parse(
        'whatsapp://send?phone=${AdminConfig.supportWhatsApp}&text=$message');
    final webUrl = Uri.parse(
        'https://wa.me/${AdminConfig.supportWhatsApp}?text=$message');
    if (await canLaunchUrl(directUrl)) {
      await launchUrl(directUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final url = Uri(
      scheme: 'mailto',
      path: AdminConfig.supportEmail,
      queryParameters: {
        'subject': 'AgriNexa Order Support',
        'body': 'Hello AgriNexa team,\n\nI need help with my order:\n\n',
      },
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.support_agent_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Need Help With Your Order?',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                SizedBox(width: 2),
                Text('AgriNexa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          const Text('Contact our support team for any order issues.',
              style: TextStyle(fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsApp(context),
                icon: const Icon(Icons.message_rounded, size: 16),
                label: const Text('WhatsApp',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openEmail(context),
                icon: const Icon(Icons.email_rounded, size: 16),
                label: const Text('Email',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Status Tracker ────────────────────────────────────────────────────────────
class _StatusTracker extends StatelessWidget {
  final String status;
  const _StatusTracker({required this.status});

  static const List<IconData> _icons = [
    Icons.shopping_cart_outlined,
    Icons.check_circle_outline_rounded,
    Icons.local_shipping_outlined,
    Icons.home_outlined,
  ];

  static const List<String> _labels = [
    'Placed', 'Confirmed', 'Shipped', 'Delivered'
  ];

  int get _currentStep {
    switch (status) {
      case 'Confirmed': return 1;
      case 'Shipped':   return 2;
      case 'Delivered': return 3;
      default:          return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index <= _currentStep;
          final isLast = index == 3;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icons[index],
                            size: 18,
                            color: isCompleted
                                ? Colors.white
                                : AppColors.textLight),
                      ),
                      const SizedBox(height: 4),
                      Text(_labels[index],
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: isCompleted
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isCompleted
                                  ? AppColors.primary
                                  : AppColors.textLight),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: index < _currentStep
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Seller Status Buttons (Admin) ─────────────────────────────────────────────
class _SellerStatusButtons extends StatefulWidget {
  final String orderId;
  final String currentStatus;
  final Map<String, dynamic> data;

  const _SellerStatusButtons({
    required this.orderId,
    required this.currentStatus,
    required this.data,
  });

  @override
  State<_SellerStatusButtons> createState() => _SellerStatusButtonsState();
}

class _SellerStatusButtonsState extends State<_SellerStatusButtons> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      final buyerId = widget.data['buyerId'] as String?;
      if (buyerId != null && buyerId.isNotEmpty) {
        String title = '';
        String body = '';
        if (newStatus == 'Confirmed') {
          title = '✅ Order Confirmed!';
          body =
              'AgriNexa confirmed your order for ${widget.data['productName']}.';
        } else if (newStatus == 'Shipped') {
          title = '🚚 Order Shipped!';
          body =
              'Your order of ${widget.data['productName']} is on its way!';
        }
        if (title.isNotEmpty) {
          await NotificationService.sendNotificationToUser(
            userId: buyerId,
            title: title,
            body: body,
            data: {'type': 'order'},
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as $newStatus!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentStatus == 'Pending') {
      return ElevatedButton.icon(
        onPressed: _isUpdating ? null : () => _updateStatus('Confirmed'),
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: _isUpdating
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Confirm Order'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (widget.currentStatus == 'Confirmed') {
      return ElevatedButton.icon(
        onPressed: _isUpdating ? null : () => _updateStatus('Shipped'),
        icon: const Icon(Icons.local_shipping_rounded, size: 18),
        label: _isUpdating
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Mark as Shipped 🚚'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (widget.currentStatus == 'Shipped') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLighter,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Waiting for buyer to confirm...',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    } else if (widget.currentStatus == 'Delivered') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text('Order completed successfully! 🎉',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Empty Orders ──────────────────────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  final bool isBuyer;
  const _EmptyOrders({required this.isBuyer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 60, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            isBuyer ? 'No orders yet' : 'No received orders yet',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            isBuyer
                ? 'Your orders will appear here'
                : 'Orders from buyers will appear here',
            style: TextStyle(color: AppColors.textMedium, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Detail Item ───────────────────────────────────────────────────────────────
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
            style: TextStyle(fontSize: 11, color: AppColors.textLight)),
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