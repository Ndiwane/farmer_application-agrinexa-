import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'payment_screen.dart';
import '../utils/app_router.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String productName;
  final String productPrice;
  final String productImage;
  final String productLocation;
  final String sellerName;
  final String? sellerId;
  final String? productId;
  final String unit;

  const OrderSummaryScreen({
    super.key,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.productLocation,
    required this.sellerName,
    this.sellerId,
    this.productId,
    this.unit = 'kg',
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  int _quantity = 1;
  String _selectedDelivery = 'Pickup';
  bool _isConfirming = false;

  double get _basePrice {
    final priceStr = widget.productPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(priceStr) ?? 0;
  }

  double get _deliveryFee => _selectedDelivery == 'Delivery' ? 500 : 0;
  double get _subtotal => _basePrice * _quantity;
  double get _total => _subtotal + _deliveryFee;

  Future<void> _proceedToPayment() async {
    setState(() => _isConfirming = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final orderRef =
          await FirebaseFirestore.instance.collection('orders').add({
        'buyerId': user?.uid,
        'buyerName': user?.displayName ?? 'Unknown',
        'buyerEmail': user?.email ?? '',
        'sellerId': widget.sellerId ?? '',
        'sellerName': widget.sellerName,
        'productId': widget.productId ?? '',
        'productName': widget.productName,
        'productImage': widget.productImage,
        'productLocation': widget.productLocation,
        'quantity': _quantity,
        'unit': widget.unit,
        'pricePerUnit': _basePrice,
        'deliveryOption': _selectedDelivery,
        'deliveryFee': _deliveryFee,
        'subtotal': _subtotal,
        'total': _total,
        'status': 'Pending',
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (widget.sellerId != null && widget.sellerId!.isNotEmpty) {
        await NotificationService.sendNotificationToUser(
          userId: widget.sellerId!,
          title: '🛒 New Order Received!',
          body:
              '${user?.displayName ?? 'Someone'} ordered $_quantity ${widget.unit}(s) of ${widget.productName}',
          data: {'type': 'order', 'productName': widget.productName},
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          AppRouter.slide(PaymentScreen(
              orderId: orderRef.id,
              productName: widget.productName,
              sellerName: widget.sellerName,
              sellerId: widget.sellerId ?? '',
              total: _total,
            ),
          ),
        );
      }
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
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Order Summary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Product card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.productImage,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 70,
                        height: 70,
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
                        Text(widget.productName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(widget.sellerName,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMedium)),
                        const SizedBox(height: 4),
                        Text(widget.productPrice,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Quantity selector with dynamic unit
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantity',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Unit: ${widget.unit}',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_quantity',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        onTap: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Delivery option
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Option',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DeliveryOption(
                        label: 'Pickup',
                        subtitle: 'Free',
                        icon: Icons.store_outlined,
                        selected: _selectedDelivery == 'Pickup',
                        onTap: () =>
                            setState(() => _selectedDelivery = 'Pickup'),
                      ),
                      const SizedBox(width: 10),
                      _DeliveryOption(
                        label: 'Delivery',
                        subtitle: '500 FCFA',
                        icon: Icons.delivery_dining_outlined,
                        selected: _selectedDelivery == 'Delivery',
                        onTap: () =>
                            setState(() => _selectedDelivery = 'Delivery'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Price breakdown
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _PriceRow(
                      label:
                          '$_quantity ${widget.unit}(s) × ${_basePrice.toStringAsFixed(0)} FCFA',
                      value: '${_subtotal.toStringAsFixed(0)} FCFA'),
                  const SizedBox(height: 8),
                  _PriceRow(
                      label: 'Delivery fee',
                      value: _deliveryFee == 0
                          ? 'Free'
                          : '${_deliveryFee.toStringAsFixed(0)} FCFA'),
                  const Divider(height: 20),
                  _PriceRow(
                    label: 'Total',
                    value: '${_total.toStringAsFixed(0)} FCFA',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isConfirming ? null : _proceedToPayment,
              child: _isConfirming
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryLighter,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.primaryLighter : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textLight),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected ? AppColors.primary : null)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textLight)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _PriceRow(
      {required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                  color: isBold ? null : AppColors.textMedium)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: isBold ? AppColors.primary : null)),
      ],
    );
  }
}
