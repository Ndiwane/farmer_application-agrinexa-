import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../utils/admin_config.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() =>
      _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _phoneController = TextEditingController();
  String _selectedNetwork = 'mtn';
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isAdmin =>
      AdminConfig.isAdmin(FirebaseAuth.instance.currentUser?.uid);

  @override
  void initState() {
    super.initState();
    if (_isAdmin) {
      _loadPaymentSettings();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _phoneController.text = data['paymentPhone'] ?? '';
        _selectedNetwork = data['paymentNetwork'] ?? 'mtn';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Mobile Money number'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'paymentPhone': phone,
        'paymentNetwork': _selectedNetwork,
        'paymentSetup': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings saved!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings. Try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Payment Settings'),
        actions: _isAdmin
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
              ]
            : null,
      ),

      // ── Non-admin: show locked screen ────────────────────────────────────
      body: !_isAdmin
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text('Admin Only',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    const SizedBox(height: 10),
                    Text(
                      'Payment settings are managed by the AgriNexa team. Your payments are processed securely through Mobile Money.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                          height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _PaymentInfoRow(
                            icon: Icons.phone_android_rounded,
                            color: const Color(0xFFFFCC00),
                            label: 'MTN Mobile Money',
                            value: 'Supported ✅',
                          ),
                          const SizedBox(height: 12),
                          _PaymentInfoRow(
                            icon: Icons.phone_android_rounded,
                            color: const Color(0xFFFF6600),
                            label: 'Orange Money',
                            value: 'Supported ✅',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )

      // ── Admin: show full payment settings ────────────────────────────────
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLighter,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Add your Mobile Money number to receive payments directly when buyers purchase products.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Select network
                      const Text('Mobile Money Network',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // MTN
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
                                child: Column(
                                  children: [
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Orange Money
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
                                child: Column(
                                  children: [
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Phone number
                      const Text('Mobile Money Number',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 677000000',
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            child: Text('+237',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.primary)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedNetwork == 'mtn'
                            ? '💡 Enter your MTN number (e.g. 677000000)'
                            : '💡 Enter your Orange number (e.g. 699000000)',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMedium),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        child: _isSaving
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Save Payment Settings'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _PaymentInfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      Text(value,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w600)),
    ]);
  }
}