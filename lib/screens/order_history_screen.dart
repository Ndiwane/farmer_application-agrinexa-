import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../utils/app_router.dart';
import 'message_screen.dart';

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
          // My Orders (as buyer) — shows seller contact + status tracker
          _OrdersList(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('buyerId', isEqualTo: currentUser?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            emptyMessage: 'You have not placed any orders yet.',
            isBuyer: true,
          ),
          // Received Orders (as seller) — shows status update buttons
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

  // Map status to display color
  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed': return Colors.blue;
      case 'Shipped':   return Colors.orange;
      case 'Delivered': return AppColors.success;
      case 'Cancelled': return AppColors.danger;
      default:          return AppColors.warning; // Pending
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
      margin: const EdgeInsets.only(bottom: 16),
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
          // ── Order header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data['productImage'] ?? '',
                    width: 60, height: 60,
                    fit: BoxFit.cover,
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
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        isBuyer
                            ? 'Seller: ${data['sellerName'] ?? ''}'
                            : 'Buyer: ${data['buyerName'] ?? ''}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMedium),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatDate(timestamp),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
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

          // ── Order details row ──────────────────────────────────────────
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
                      value: '${data['quantity'] ?? 0} ${data['unit'] ?? 'kg'}',
                    ),
                    _DetailItem(
                      label: 'Delivery',
                      value: data['deliveryOption'] ?? 'Pickup',
                    ),
                    _DetailItem(
                      label: 'Total',
                      value: '${(data['total'] ?? 0).toStringAsFixed(0)} FCFA',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Status Tracker ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: _StatusTracker(status: status),
          ),

          // ── BUYER SECTION: Seller contact + Confirm received ───────────
          if (isBuyer) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  // Seller contact info
                  _SellerContactCard(
                    orderId: orderId,
                    data: data,
                  ),

                  // "I received my order" button — only when shipped
                  if (status == 'Shipped') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _confirmDelivery(context, orderId, data),
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

          // ── SELLER SECTION: Status update buttons ──────────────────────
          if (!isBuyer) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _SellerStatusButtons(
                orderId: orderId,
                currentStatus: status,
                data: data,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Buyer confirms they received the product
  Future<void> _confirmDelivery(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) async {
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
            child: const Text('No'),
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

    // Update order status to Delivered
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
      'status': 'Delivered',
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'deliveredAt': FieldValue.serverTimestamp(),
    });

    // Notify seller that order was delivered
    final sellerId = data['sellerId'] as String?;
    if (sellerId != null && sellerId.isNotEmpty) {
      await NotificationService.sendNotificationToUser(
        userId: sellerId,
        title: '✅ Order Delivered!',
        body:
            '${data['buyerName']} confirmed receiving ${data['productName']}. Payment will be processed.',
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
}

/// Shows the 4-step status progress tracker
class _StatusTracker extends StatelessWidget {
  final String status;
  const _StatusTracker({required this.status});

  // Order of statuses
  static const List<Map<String, dynamic>> _steps = [
    {'label': 'Placed',    'icon': Icons.shopping_cart_outlined},
    {'label': 'Confirmed', 'icon': Icons.check_circle_outline_rounded},
    {'label': 'Shipped',   'icon': Icons.local_shipping_outlined},
    {'label': 'Delivered', 'icon': Icons.home_outlined},
  ];

  // Get current step index
  int get _currentStep {
    switch (status) {
      case 'Confirmed': return 1;
      case 'Shipped':   return 2;
      case 'Delivered': return 3;
      default:          return 0; // Pending
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
        children: List.generate(_steps.length, (index) {
          final isCompleted = index <= _currentStep;
          final isLast = index == _steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                // Step circle
                Expanded(
                  child: Column(
                    children: [
                      // Circle with icon
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _steps[index]['icon'] as IconData,
                          size: 18,
                          color: isCompleted
                              ? Colors.white
                              : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Step label
                      Text(
                        _steps[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isCompleted
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Connecting line between steps
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

/// Shows seller contact info for buyer (phone + chat)
class _SellerContactCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _SellerContactCard({
    required this.orderId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final sellerPhone = data['sellerPhone'] as String? ?? '';
    final sellerId = data['sellerId'] as String? ?? '';
    final sellerName = data['sellerName'] as String? ?? 'Seller';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Icon(Icons.headset_mic_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            const Text('Contact Seller',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 8),

          // Phone number row
          if (sellerPhone.isNotEmpty)
            Row(children: [
              const Icon(Icons.phone_rounded,
                  size: 14, color: AppColors.textMedium),
              const SizedBox(width: 6),
              Text(sellerPhone,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              // Copy phone button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: sellerPhone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number copied!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Copy',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          if (sellerPhone.isEmpty)
            Text('Phone not available',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 10),

          // Action buttons — Chat + WhatsApp
          Row(children: [
            // In-app chat button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (sellerId.isEmpty) return;

                  // Get seller info for chat
                  final sellerDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(sellerId)
                      .get();

                  if (context.mounted && sellerDoc.exists) {
                    final currentUser =
                        FirebaseAuth.instance.currentUser!;
                    // Generate chat ID
                    final chatId = [currentUser.uid, sellerId]
                      ..sort();
                    Navigator.push(
                      context,
                      AppRouter.slide(MessageScreen(
                        chatId: chatId.join('_'),
                        otherUserId: sellerId,
                        otherUserName: sellerName,
                        otherUserPhoto:
                            sellerDoc.data()?['photoUrl'],
                      )),
                    );
                  }
                },
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text('Chat',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // WhatsApp button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: sellerPhone.isEmpty
                    ? null
                    : () {
                        // Copy number for WhatsApp
                        final phone = sellerPhone.startsWith('+')
                            ? sellerPhone
                            : '+$sellerPhone';
                        Clipboard.setData(
                            ClipboardData(text: phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Number copied! Open WhatsApp and paste to chat.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                icon: const Icon(Icons.message_rounded, size: 16),
                label: const Text('WhatsApp',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 8),
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

/// Seller's status update buttons with push notifications
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
      // Update order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Notify buyer of status update
      final buyerId = widget.data['buyerId'] as String?;
      if (buyerId != null && buyerId.isNotEmpty) {
        String notifTitle = '';
        String notifBody = '';

        if (newStatus == 'Confirmed') {
          notifTitle = '✅ Order Confirmed!';
          notifBody =
              '${widget.data['sellerName']} confirmed your order for ${widget.data['productName']}. Preparing for delivery!';
        } else if (newStatus == 'Shipped') {
          notifTitle = '🚚 Order Shipped!';
          notifBody =
              'Your order of ${widget.data['productName']} is on its way!';
        }

        if (notifTitle.isNotEmpty) {
          await NotificationService.sendNotificationToUser(
            userId: buyerId,
            title: notifTitle,
            body: notifBody,
            data: {'type': 'order'},
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as $newStatus! Buyer notified.'),
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
    // Determine what action seller can take
    Widget? actionButton;

    if (widget.currentStatus == 'Pending') {
      // Seller can confirm order
      actionButton = ElevatedButton.icon(
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
      // Seller can mark as shipped
      actionButton = ElevatedButton.icon(
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
      // Waiting for buyer to confirm receipt
      actionButton = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLighter,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Waiting for buyer to confirm delivery...',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    } else if (widget.currentStatus == 'Delivered') {
      // Order complete
      actionButton = Container(
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
            Text(
              'Order completed successfully! 🎉',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (actionButton == null) return const SizedBox.shrink();
    return actionButton;
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
