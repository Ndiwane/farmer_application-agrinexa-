import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';
import 'order_confirmed_screen.dart';
import '../utils/app_router.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final String productName;
  final String sellerName;
  final String sellerId;
  final double total;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.productName,
    required this.sellerName,
    required this.sellerId,
    required this.total,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  String _selectedNetwork = 'mtn';
  bool _isProcessing = false;
  bool _isLoadingSellerInfo = true;
  String? _sellerPhone;
  String? _sellerNetwork;
  bool _sellerHasPayment = false;

  final String _publicKey =
      'pk.uwjbNofcQJKSkxnGGy3U765lwyXZVv4uSMMUiZ79bcfuPxrnCn9e42dDpZSoo66Z1XMNM9nGigzVjxtt5vbo3RcGYoH7bVqgkJtjlnyHO8eGyZDI9vMqE5k9rTLL4';
  final String _privateKey =
      'sk.JUuM6bpBuAFg3ZDoMnBrEqdGcagtS31IldwGzGBeUGw8Gif4Gapn8tVadIUUFhwigHnzQgY9TpzFaTBJJhmNZzAnezlIbTz4zCZ0Af7GlejC5spCWzEeY4Ilt1fYJ';

  @override
  void initState() {
    super.initState();
    _loadSellerPaymentInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerPaymentInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.sellerId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _sellerPhone = data['paymentPhone'];
          _sellerNetwork = data['paymentNetwork'] ?? 'mtn';
          _sellerHasPayment = data['paymentSetup'] == true &&
              _sellerPhone != null &&
              _sellerPhone!.isNotEmpty;
          _isLoadingSellerInfo = false;
        });
      } else {
        setState(() => _isLoadingSellerInfo = false);
      }
    } catch (e) {
      setState(() => _isLoadingSellerInfo = false);
    }
  }

  // Poll Notchpay until payment reaches a terminal status
  Future<String> _verifyPayment(String reference) async {
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final res = await http.get(
          Uri.parse('https://api.notchpay.co/payments/$reference'),
          headers: {
            'Authorization': _publicKey,
            'Accept': 'application/json',
          },
        );
        final data = json.decode(res.body);
        final status =
            (data['transaction']?['status'] ?? '').toString().toLowerCase();
        debugPrint('Poll $i: $status');
        if (status == 'complete') return 'complete';
        if (status == 'failed') return 'failed';
        if (status == 'canceled') return 'canceled';
        if (status == 'expired') return 'expired';
        final msg = (data['message'] ?? '').toString().toLowerCase();
        if (msg.contains('insufficient') ||
            msg.contains('solde') ||
            msg.contains('balance')) {
          return 'insufficient_funds';
        }
      } catch (e) {
        debugPrint('Poll error: $e');
      }
    }
    return 'timeout';
  }

  // Transfer money from Notchpay balance to seller's mobile money
  Future<bool> _transferToSeller(String sellerPhone, int amount) async {
  try {
    final phone = sellerPhone.startsWith('237')
        ? sellerPhone
        : '237$sellerPhone';
    final res = await http.post(
      Uri.parse('https://api.notchpay.co/transfers'),
      headers: {
        'Authorization': _publicKey,
        'X-Grant': _privateKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'amount': amount,
        'currency': 'XAF',
        'description': 'Payment for ${widget.productName} - AgriNexa',
        'reference': 'transfer_${DateTime.now().millisecondsSinceEpoch}',
        'destination': phone,
        'channel': _sellerNetwork == 'mtn' ? 'cm.mtn' : 'cm.orange',
      }),
    );

    // ← ADD THIS
    debugPrint('=== TRANSFER RESPONSE ===');
    debugPrint('Status: ${res.statusCode}');
    debugPrint('Body: ${res.body}');
    debugPrint('=========================');

    final data = json.decode(res.body);
    return res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 202;
  } catch (e) {
    debugPrint('Transfer error: $e');
    return false;
  }
}

  Future<void> _initiatePayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: AppColors.danger));
      return;
    }
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: AppColors.danger));
      return;
    }
    if (!_sellerHasPayment) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Seller has not set up payment yet.'),
          backgroundColor: AppColors.warning));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final buyerPhone = phone.startsWith('237') ? phone : '237$phone';
      final sellerPhone = _sellerPhone!.startsWith('237')
          ? _sellerPhone!
          : '237$_sellerPhone';
      final reference = 'agrinexa_${DateTime.now().millisecondsSinceEpoch}';

      // ── 1. Initialize ────────────────────────────────────────────
      final initRes = await http.post(
        Uri.parse('https://api.notchpay.co/payments/initialize'),
        headers: {
          'Authorization': _publicKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': user?.email ?? 'customer@agrinexa.com',
          'amount': widget.total.toInt(),
          'currency': 'XAF',
          'description':
              'Payment for ${widget.productName} to ${widget.sellerName}',
          'reference': reference,
        }),
      );
      final initData = json.decode(initRes.body);
      if (initRes.statusCode != 200 && initRes.statusCode != 201) {
        throw Exception(initData['message'] ?? 'Failed to initialize');
      }
      final payRef = initData['transaction']['reference'] ?? reference;

      // ── 2. Charge buyer ──────────────────────────────────────────
      final payRes = await http.post(
        Uri.parse('https://api.notchpay.co/payments/$payRef'),
        headers: {
          'Authorization': _publicKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'channel': _selectedNetwork == 'mtn' ? 'cm.mtn' : 'cm.orange',
          'data': {'phone': buyerPhone},
        }),
      );
      final payData = json.decode(payRes.body);
      final payMsg = (payData['message'] ?? '').toString().toLowerCase();

      if (payMsg.contains('insufficient') ||
          payMsg.contains('solde') ||
          payMsg.contains('balance') ||
          payMsg.contains('not enough')) {
        throw Exception(
            '❌ Insufficient balance. Top up your ${_selectedNetwork.toUpperCase()} Mobile Money and try again.');
      }
      if (payRes.statusCode != 200 &&
          payRes.statusCode != 201 &&
          payRes.statusCode != 202) {
        throw Exception(payData['message'] ?? 'Payment request failed');
      }

      // ── 3. Wait for buyer to confirm on phone ────────────────────
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _WaitingDialog(),
        );
      }

      final finalStatus = await _verifyPayment(payRef);
      if (mounted) Navigator.pop(context);

      if (finalStatus == 'insufficient_funds' || finalStatus == 'failed') {
        throw Exception(
            '❌ Payment failed. Check your ${_selectedNetwork.toUpperCase()} balance and try again.');
      }
      if (finalStatus == 'canceled') {
        throw Exception('Payment was cancelled. Please try again.');
      }

      // ── 4. Transfer to seller ────────────────────────────────────
      bool transferred = false;
      if (finalStatus == 'complete') {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _TransferringDialog(),
          );
        }
        transferred = await _transferToSeller(sellerPhone, widget.total.toInt());
        if (mounted) Navigator.pop(context);
      }

      // ── 5. Save to Firestore ─────────────────────────────────────
      await FirebaseFirestore.instance.collection('payments').add({
        'orderId': widget.orderId,
        'buyerId': user?.uid,
        'sellerId': widget.sellerId,
        'sellerPhone': sellerPhone,
        'sellerNetwork': _sellerNetwork,
        'buyerPhone': buyerPhone,
        'buyerNetwork': _selectedNetwork,
        'amount': widget.total,
        'currency': 'XAF',
        'reference': payRef,
        'paymentStatus': finalStatus,
        'transferStatus': transferred ? 'transferred' : 'pending_transfer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'paymentStatus': finalStatus == 'complete' ? 'paid' : 'pending',
        'paymentReference': payRef,
        'status': finalStatus == 'complete' ? 'Confirmed' : 'Pending',
        'transferToSeller': transferred,
      });

      if (mounted) {
        if (finalStatus == 'complete') {
          _showResult(
            success: true,
            message: transferred
                ? '✅ Payment successful!\n\n${widget.sellerName} has received ${widget.total.toStringAsFixed(0)} FCFA to their mobile money.'
                : '✅ Payment received!\n\nTransfer to ${widget.sellerName} is being processed.',
          );
        } else {
          _showResult(
            success: true,
            message:
                '⏳ Payment is being processed.\nConfirm on your phone to complete.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
        _showResult(
          success: false,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResult({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: success
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: success ? AppColors.success : AppColors.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Payment Successful!' : 'Payment Failed',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMedium)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (success) {
                Navigator.pushAndRemoveUntil(
                  context,
                  AppRouter.slide(const OrderConfirmedScreen()),
                  (route) => route.isFirst,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  success ? AppColors.success : AppColors.primary,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(success ? 'Done' : 'Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Payment'),
      ),
      body: _isLoadingSellerInfo
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).appBarTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Product',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMedium)),
                          Text(widget.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Seller',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMedium)),
                          Text(widget.sellerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('${widget.total.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Seller status
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _sellerHasPayment
                          ? AppColors.primaryLighter
                          : AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(
                        _sellerHasPayment
                            ? Icons.check_circle_outline_rounded
                            : Icons.warning_amber_rounded,
                        color: _sellerHasPayment
                            ? AppColors.primary
                            : AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _sellerHasPayment
                              ? '✅ Payment goes directly to ${widget.sellerName}'
                              : '⚠️ Seller has not set up payment yet.',
                          style: TextStyle(
                              fontSize: 13,
                              color: _sellerHasPayment
                                  ? AppColors.primary
                                  : AppColors.danger,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Network
                  const Text('Your Payment Network',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedNetwork = 'mtn'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedNetwork == 'mtn'
                                ? const Color(0xFFFFF9C4)
                                : Theme.of(context)
                                    .appBarTheme
                                    .backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedNetwork == 'mtn'
                                  ? const Color(0xFFFFCC00)
                                  : AppColors.divider,
                              width: _selectedNetwork == 'mtn' ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCC00),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('MTN',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Colors.black)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('MTN Mobile\nMoney',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedNetwork = 'orange'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedNetwork == 'orange'
                                ? const Color(0xFFFFECE0)
                                : Theme.of(context)
                                    .appBarTheme
                                    .backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedNetwork == 'orange'
                                  ? const Color(0xFFFF6600)
                                  : AppColors.divider,
                              width:
                                  _selectedNetwork == 'orange' ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6600),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('OM',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Orange\nMoney',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Phone
                  const Text('Your Mobile Money Number',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. 677000000',
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: const Text('+237',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ensure your ${_selectedNetwork.toUpperCase()} Mobile Money has sufficient balance.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _isProcessing ? null : _initiatePayment,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Pay ${widget.total.toStringAsFixed(0)} FCFA'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text('Secured by Notchpay',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────
class _WaitingDialog extends StatefulWidget {
  const _WaitingDialog();
  @override
  State<_WaitingDialog> createState() => _WaitingDialogState();
}

class _WaitingDialogState extends State<_WaitingDialog> {
  int _seconds = 0;
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) { if (mounted) setState(() => _seconds++); });
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 20),
        const Text('Waiting for Confirmation',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('Check your phone and enter\nyour PIN to confirm payment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
        const SizedBox(height: 12),
        Text('${_seconds}s',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
      ]),
    );
  }
}

class _TransferringDialog extends StatelessWidget {
  const _TransferringDialog();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 20),
        Text('Sending to Seller...',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        SizedBox(height: 8),
        Text('Transferring payment to\nthe seller\'s mobile money.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
      ]),
    );
  }
}
