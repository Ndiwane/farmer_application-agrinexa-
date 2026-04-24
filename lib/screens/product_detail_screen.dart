import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'order_summary_screen.dart';
import 'message_screen.dart';
import '../utils/app_router.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> data;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.data,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  int _userRating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasReviewed = false;
  Map<String, dynamic> _existingReview = {};

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .doc(currentUser!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _hasReviewed = true;
        _existingReview = data;
        _userRating = data['rating'] ?? 0;
        _reviewController.text = data['review'] ?? '';
      });
    }
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .doc(currentUser!.uid)
          .set({
        'rating': _userRating,
        'review': _reviewController.text.trim(),
        'userName': currentUser!.displayName ?? 'User',
        'userPhoto': currentUser!.photoURL ?? '',
        'userId': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateAverageRating();

      if (mounted) {
        setState(() {
          _hasReviewed = true;
          _existingReview = {
            'rating': _userRating,
            'review': _reviewController.text.trim(),
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateAverageRating() async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] ?? 0) as int;
    }

    final avgRating = totalRating / reviewsSnapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .update({
      'avgRating': avgRating,
      'reviewCount': reviewsSnapshot.docs.length,
    });
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  void _contactSeller(BuildContext context) async {
    final sellerId = widget.data['sellerId'];
    if (sellerId == null || sellerId == currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot chat with yourself!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final sellerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .get();

    final sellerData = sellerDoc.data() ?? {};
    final sellerName =
        sellerData['name'] ?? widget.data['sellerName'] ?? 'Seller';
    final sellerPhoto = sellerData['photoUrl'] ?? '';
    final chatId = _getChatId(currentUser!.uid, sellerId);

    if (context.mounted) {
      Navigator.push(
        context,
        AppRouter.slide(MessageScreen(
            chatId: chatId,
            otherUserId: sellerId,
            otherUserName: sellerName,
            otherUserPhoto: sellerPhoto,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUser?.uid == widget.data['sellerId'];
    final avgRating = (widget.data['avgRating'] ?? 0.0) as double;
    final reviewCount = widget.data['reviewCount'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back,
                    color: AppColors.textDark),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.data['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primaryLighter,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 60),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.primaryLighter,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(widget.data['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLighter,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(widget.data['price'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Average rating
                  if (reviewCount > 0)
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < avgRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFC107),
                            size: 18,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(widget.data['location'] ?? '',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                          'Available: ${widget.data['quantity'] ?? ''}kg',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                          'Seller: ${widget.data['sellerName'] ?? 'Unknown'}',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(
                    widget.data['description'] ??
                        'No description available.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  if (!isOwner) ...[
                    OutlinedButton.icon(
                      onPressed: () => _contactSeller(context),
                      icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: const Text('Contact Seller'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(
                            color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        AppRouter.slide(OrderSummaryScreen(
                            productName: widget.data['name'] ?? '',
                            productPrice: widget.data['price'] ?? '',
                            productImage: widget.data['imageUrl'] ?? '',
                            productLocation:
                                widget.data['location'] ?? '',
                            sellerName:
                                widget.data['sellerName'] ?? 'Unknown',
                            // ✅ NOW PASSING sellerId and productId
                            sellerId: widget.data['sellerId'] ?? '',
                            productId: widget.productId,
                          ),
                        ),
                      ),
                      child: const Text('Order Now'),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text('This is your listing',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      if (reviewCount > 0)
                        Text('$reviewCount total',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Write a review (only for buyers)
                  if (!isOwner) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasReviewed
                                ? 'Update your review'
                                : 'Write a review',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textDark),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _userRating = index + 1),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    index < _userRating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: const Color(0xFFFFC107),
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reviewController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Share your experience...',
                              filled: true,
                              fillColor: AppColors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: AppColors.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: AppColors.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _submitReview,
                              style: ElevatedButton.styleFrom(
                                  minimumSize:
                                      const Size.fromHeight(44)),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : Text(_hasReviewed
                                      ? 'Update Review'
                                      : 'Submit Review'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // All reviews list
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .doc(widget.productId)
                        .collection('reviews')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No reviews yet. Be the first to review!',
                              style: TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 13),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final reviewData =
                              doc.data() as Map<String, dynamic>;
                          return _ReviewCard(data: reviewData);
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final rating = data['rating'] ?? 0;
    final userName = data['userName'] ?? 'User';
    final photoUrl = data['userPhoto'] ?? '';
    final review = data['review'] ?? '';
    final timestamp = data['createdAt'] as Timestamp?;

    String timeAgo = '';
    if (timestamp != null) {
      final date = timestamp.toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = 'Just now';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLighter,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textDark)),
                    Row(
                      children: [
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < rating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: const Color(0xFFFFC107),
                                  size: 14,
                                )),
                        const SizedBox(width: 6),
                        Text(timeAgo,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }
}