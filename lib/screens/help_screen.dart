import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _whatsappNumber = '237 674238006'; 
  static const String _supportEmail = 'agrinexa.app@gmail.com';

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I list a product for sale?',
      'a': 'Tap the "Sell" tab at the bottom of the screen. Fill in your product details including name, category, quantity, price and location. Add a clear photo and tap "List Product".',
    },
    {
      'q': 'How do I pay for a product?',
      'a': 'When you find a product you want, tap it and press "Buy Now". Select your quantity and delivery option, then proceed to payment using your MTN Mobile Money or Orange Money number.',
    },
    {
      'q': 'How long does delivery take?',
      'a': 'Delivery time depends on the seller and your location. For pickup orders, coordinate directly with the seller via the in-app chat. Delivery orders typically take 1-3 days.',
    },
    {
      'q': 'What if I don\'t receive my order?',
      'a': 'Go to your Order History and tap on the order. You will find the seller\'s phone number and a chat button to contact them directly. If unresolved, contact our support team.',
    },
    {
      'q': 'How do I contact a seller?',
      'a': 'Open any product and tap the chat icon to message the seller. You can also find the seller\'s phone number in your order details after making a payment.',
    },
    {
      'q': 'How do I change my password?',
      'a': 'Go to Profile → Change Password. Enter your current password and then your new password. Make sure it is at least 6 characters long.',
    },
    {
      'q': 'What payment methods are supported?',
      'a': 'AgriNexa currently supports MTN Mobile Money and Orange Money — the most widely used mobile payment methods in Cameroon.',
    },
    {
      'q': 'How do I update my profile photo?',
      'a': 'Go to Profile and tap the camera icon on your avatar. You can take a new photo or choose one from your gallery.',
    },
    {
      'q': 'Is AgriNexa free to use?',
      'a': 'Yes! AgriNexa is currently free for all buyers and sellers. A small platform fee may be introduced in the future to support continued development.',
    },
    {
      'q': 'How do I delete a product listing?',
      'a': 'Go to Profile → My Listings. Find the product you want to remove and tap the delete option.',
    },
  ];

  /// Open WhatsApp with pre-filled message
  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
      'Hello AgriNexa Support team! I need help with the app.',
    );
    final directUrl =
        Uri.parse('whatsapp://send?phone=$_whatsappNumber&text=$message');
    final webUrl =
        Uri.parse('https://wa.me/$_whatsappNumber?text=$message');

    if (await canLaunchUrl(directUrl)) {
      await launchUrl(directUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Number: +237 674238006'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Open email app with pre-filled recipient and subject
  Future<void> _openEmail(BuildContext context) async {
    final url = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'AgriNexa Support Request',
        'body': 'Hello AgriNexa Support team,\n\nI need help with:\n\n',
      },
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email us at: agrinexa.app@gmail.com'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Need Help?'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('How can we help you?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Find answers to common questions\nor contact our support team',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13),
                  ),
                ],
              ),
            ),

            // Contact options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Support',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.message_rounded,
                        color: const Color(0xFF25D366),
                        title: 'WhatsApp',
                        subtitle: 'Chat with us directly',
                        onTap: () => _openWhatsApp(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.email_rounded,
                        color: AppColors.primary,
                        title: 'Email',
                        subtitle: _supportEmail,
                        onTap: () => _openEmail(context),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Our support team responds within 24 hours. '
                          'For faster help, use WhatsApp.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),

            // FAQ section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Frequently Asked Questions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              itemBuilder: (context, index) => _FAQItem(
                question: _faqs[index]['q']!,
                answer: _faqs[index]['a']!,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMedium)),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _isExpanded
                        ? AppColors.primary
                        : AppColors.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('Q',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isExpanded
                                ? Colors.white
                                : AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.question,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isExpanded
                              ? AppColors.primary
                              : AppColors.textDark)),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _isExpanded
                      ? AppColors.primary
                      : AppColors.textLight,
                ),
              ]),
              SizeTransition(
                sizeFactor: _animation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('A',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(widget.answer,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMedium,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}