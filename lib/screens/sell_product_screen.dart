import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/admin_config.dart';
import '../services/notification_service.dart';
import 'agribot_screen.dart';
import '../utils/app_router.dart';

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});

  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  bool get _isAdmin =>
      AdminConfig.isAdmin(FirebaseAuth.instance.currentUser?.uid);

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) return const _AdminSellScreen();
    return const _UserDashboardScreen();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// USER DASHBOARD — AgriBot + Request Product + Order Tracker
// ════════════════════════════════════════════════════════════════════════════
class _UserDashboardScreen extends StatefulWidget {
  const _UserDashboardScreen();

  @override
  State<_UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<_UserDashboardScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final firstName = (currentUser?.displayName ?? 'Farmer').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi $firstName! 👋',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              Text('What can we help you with today?',
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
              const SizedBox(height: 20),

              // AgriBot Card
              _SectionCard(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AgriBot AI Assistant',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          Text('Ask anything about farming',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        '🌿 Best crops to grow?',
                        '💰 Tomato prices?',
                        '🌱 Treat leaf blight?',
                      ].map((q) => GestureDetector(
                        onTap: () => Navigator.push(context,
                            AppRouter.slide(AgriBotScreen(initialMessage: q))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(q,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context,
                          AppRouter.slide(const AgriBotScreen())),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('Chat with AgriBot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Request a Product
              const Text('📝 Request a Product',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('Tell us what you need and we\'ll source it for you!',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
              const SizedBox(height: 10),
              _RequestProductForm(userId: currentUser?.uid ?? ''),
              const SizedBox(height: 20),

              // Order Tracker
              const Text('📦 Track My Orders',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 10),
              _OrdersTracker(userId: currentUser?.uid ?? ''),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Request Product Form ──────────────────────────────────────────────────────
class _RequestProductForm extends StatefulWidget {
  final String userId;
  const _RequestProductForm({required this.userId});

  @override
  State<_RequestProductForm> createState() => _RequestProductFormState();
}

class _RequestProductFormState extends State<_RequestProductForm> {
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_productController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a product name'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final productName = _productController.text.trim();

      // Save request to Firestore
      await FirebaseFirestore.instance.collection('product_requests').add({
        'userId': widget.userId,
        'userName': currentUser?.displayName ?? 'User',
        'userEmail': currentUser?.email ?? '',
        'productName': productName,
        'quantity': _quantityController.text.trim(),
        'location': _locationController.text.trim(),
        'note': _noteController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Notify admin about new product request
      if (AdminConfig.adminUids.isNotEmpty) {
        await NotificationService.sendNotificationToUser(
          userId: AdminConfig.adminUids.first,
          title: '📝 New Product Request!',
          body:
              '${currentUser?.displayName ?? 'A user'} requested: $productName',
          data: {'type': 'request'},
        );
      }

      setState(() => _submitted = true);
      _productController.clear();
      _quantityController.clear();
      _locationController.clear();
      _noteController.clear();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _submitted = false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            const Text('Request Sent! 🎉',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
            const SizedBox(height: 6),
            Text(
              'Our team will source your product and notify you when it\'s available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          TextField(
            controller: _productController,
            decoration: InputDecoration(
              hintText: 'Product name (e.g. Tomatoes, Maize)',
              prefixIcon: const Icon(Icons.grass_rounded,
                  color: AppColors.primary, size: 20),
              filled: true,
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
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  hintText: 'Quantity (e.g. 10kg)',
                  filled: true,
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
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Your location',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary, size: 18),
                  filled: true,
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
            ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any additional notes? (optional)',
              filled: true,
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
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send Request'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
          ),
        ],
      ),
    );
  }
}

// ── Visual Order Tracker ──────────────────────────────────────────────────────
class _OrdersTracker extends StatelessWidget {
  final String userId;
  const _OrdersTracker({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 48, color: AppColors.textLight),
                const SizedBox(height: 12),
                const Text('No orders yet',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Your order tracking will appear here',
                    style: TextStyle(
                        color: AppColors.textMedium, fontSize: 12)),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _OrderTrackCard(orderId: doc.id, data: data);
          }).toList(),
        );
      },
    );
  }
}

// ── Single Order Track Card ───────────────────────────────────────────────────
class _OrderTrackCard extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _OrderTrackCard({required this.orderId, required this.data});

  @override
  State<_OrderTrackCard> createState() => _OrderTrackCardState();
}

class _OrderTrackCardState extends State<_OrderTrackCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  static const List<_TrackStep> _steps = [
    _TrackStep(icon: Icons.shopping_bag_rounded, label: 'Order Placed',
        description: 'Your order has been received by AgriNexa', status: 'Pending'),
    _TrackStep(icon: Icons.verified_rounded, label: 'Confirmed',
        description: 'AgriNexa confirmed and is preparing your order', status: 'Confirmed'),
    _TrackStep(icon: Icons.local_shipping_rounded, label: 'On the Way',
        description: 'Your order is out for delivery', status: 'Shipped'),
    _TrackStep(icon: Icons.home_rounded, label: 'Delivered',
        description: 'Order successfully delivered to you', status: 'Delivered'),
  ];

  int get _currentStep {
    switch (widget.data['status'] ?? 'Pending') {
      case 'Confirmed': return 1;
      case 'Shipped':   return 2;
      case 'Delivered': return 3;
      default:          return 0;
    }
  }

  Color get _statusColor {
    switch (widget.data['status'] ?? 'Pending') {
      case 'Confirmed': return Colors.blue;
      case 'Shipped':   return Colors.orange;
      case 'Delivered': return AppColors.success;
      default:          return AppColors.warning;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    return DateFormat('MMM d, HH:mm').format(ts.toDate());
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Yes, Received!'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'Delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

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

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] ?? 'Pending';
    final productName = widget.data['productName'] ?? 'Product';
    final total = widget.data['total'] ?? 0;
    final timestamp = widget.data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.data['productImage'] ?? '',
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 52, height: 52,
                        color: AppColors.primaryLighter,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.primary, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(productName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '${total.toStringAsFixed(0)} FCFA • ${_formatDate(timestamp)}',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable timeline
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Order Timeline',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),

                  ...List.generate(_steps.length, (index) {
                    final step = _steps[index];
                    final isCompleted = index <= _currentStep;
                    final isCurrent = index == _currentStep;
                    final isLast = index == _steps.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.primary
                                    : AppColors.divider,
                                shape: BoxShape.circle,
                                boxShadow: isCurrent
                                    ? [BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 8, spreadRadius: 2)]
                                    : [],
                              ),
                              child: Icon(step.icon, size: 22,
                                  color: isCompleted
                                      ? Colors.white
                                      : AppColors.textLight),
                            ),
                            if (!isLast)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 3, height: 50,
                                decoration: BoxDecoration(
                                  color: index < _currentStep
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 10, bottom: isLast ? 0 : 50),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(step.label,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isCompleted
                                              ? AppColors.primary
                                              : AppColors.textLight)),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('NOW',
                                          style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 4),
                                Text(step.description,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isCompleted
                                            ? AppColors.textMedium
                                            : AppColors.textLight)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  if (status == 'Shipped') ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDelivery(context),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('I Received My Order ✅'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackStep {
  final IconData icon;
  final String label;
  final String description;
  final String status;

  const _TrackStep({
    required this.icon, required this.label,
    required this.description, required this.status,
  });
}

class _SectionCard extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  const _SectionCard({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ADMIN SELL SCREEN
// ════════════════════════════════════════════════════════════════════════════
class _AdminSellScreen extends StatefulWidget {
  const _AdminSellScreen();

  @override
  State<_AdminSellScreen> createState() => _AdminSellScreenState();
}

class _AdminSellScreenState extends State<_AdminSellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _customUnitController = TextEditingController();

  final String _cloudName = 'drhscazuw';
  final String _uploadPreset = 'agrinexa_upload';

  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _unitOptions = [
    'kg', 'bucket', 'basket', 'bag', 'crate', 'Other',
  ];
  String _selectedUnit = 'kg';
  bool _isCustomUnit = false;

  static const List<Map<String, String>> _categories = [
    {'name': 'Vegetables', 'emoji': '🥬'},
    {'name': 'Fruits',     'emoji': '🍎'},
    {'name': 'Grains',     'emoji': '🌽'},
    {'name': 'Legumes',    'emoji': '🫘'},
    {'name': 'Tubers',     'emoji': '🍠'},
    {'name': 'Nuts',       'emoji': '🌰'},
    {'name': 'Spices',     'emoji': '🌶️'},
    {'name': 'Other',      'emoji': '🌾'},
  ];

  String? _selectedCategory;

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _cropNameController.clear();
    _quantityController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _customUnitController.clear();
    setState(() {
      _selectedImage = null;
      _selectedCategory = null;
      _selectedUnit = 'kg';
      _isCustomUnit = false;
    });
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Image Source',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      if (response.statusCode == 200) return jsonData['secure_url'];
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitProduct() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add a product image'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a product category'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final unit =
        _isCustomUnit ? _customUnitController.text.trim() : _selectedUnit;
    if (_isCustomUnit && unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your custom unit'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) throw Exception('Image upload failed');

      final user = FirebaseAuth.instance.currentUser;
      final price = _priceController.text.trim();
      final quantity = _quantityController.text.trim();

      await FirebaseFirestore.instance.collection('products').add({
        'name': _cropNameController.text.trim(),
        'category': _selectedCategory,
        'quantity': quantity,
        'unit': unit,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': '$price FCFA/$unit',
        'priceValue': double.tryParse(price) ?? 0,
        'imageUrl': imageUrl,
        'sellerId': user?.uid,
        'sellerName': AdminConfig.appName,
        'sellerVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'avgRating': 0.0,
        'reviewCount': 0,
      });

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 42),
                ),
                const SizedBox(height: 16),
                const Text('Product Listed! 🎉',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Your product is now live on the marketplace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMedium),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44)),
                  child: const Text('List Another Product'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('List Product',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.primary, size: 14),
              SizedBox(width: 4),
              Text('Admin',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity, height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _selectedImage != null
                      ? Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity),
                          ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ])
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 44, color: AppColors.textLight),
                            const SizedBox(height: 8),
                            Text('Tap to add product image',
                                style: TextStyle(
                                    color: AppColors.textLight, fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Crop Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Tomatoes, Maize, Cassava'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Crop name is required' : null,
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Category'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = category['name']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(category['emoji']!,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(category['name']!,
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textDark),
                              textAlign: TextAlign.center,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              const _FieldLabel('Available Quantity'),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 10'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid number';
                        if (double.parse(v.trim()) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
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
                      items: _unitOptions.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u, style: const TextStyle(fontSize: 14)),
                          )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                          _isCustomUnit = value == 'Other';
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_isCustomUnit) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customUnitController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your unit (e.g. bunch, tray)',
                    prefixIcon: Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                  validator: (v) {
                    if (_isCustomUnit && (v == null || v.trim().isEmpty)) {
                      return 'Please enter your custom unit';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),

              const _FieldLabel('Location'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Buea, Bamenda, Yaounde'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Location is required' : null,
              ),
              const SizedBox(height: 14),

              const _FieldLabel('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Describe product quality, freshness, etc.'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.trim().length < 10) return 'Description too short';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              const _FieldLabel('Price per Unit'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  prefixText: 'FCFA  ',
                  suffixText:
                      '/ ${_isCustomUnit && _customUnitController.text.isNotEmpty ? _customUnitController.text.trim() : _selectedUnit == 'Other' ? 'unit' : _selectedUnit}',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid price';
                  if (double.parse(v.trim()) <= 0) return 'Price must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                child: _isLoading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('List Product'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark));
  }
}