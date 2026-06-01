import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// ── Admin UIDs ────────────────────────────────────────────────────────────────
// Add your Firebase UID here to get admin delete privileges
const List<String> _adminUids = [
  'YOUR_ADMIN_UID_HERE', // Replace with your actual Firebase UID
];

class CommentScreen extends StatefulWidget {
  const CommentScreen({super.key});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Community Comments'),
        actions: [
          // Comment count badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$count reviews',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback')
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
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_rounded,
                        size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No comments yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Be the first to share your experience!',
                      style: TextStyle(
                          color: AppColors.textMedium, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showWriteCommentSheet(context),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Write a Comment'),
                  ),
                ],
              ),
            );
          }

          // Calculate average rating
          final docs = snapshot.data!.docs;
          final avgRating = docs.isEmpty
              ? 0.0
              : docs
                      .map((d) =>
                          (d.data() as Map<String, dynamic>)['rating'] ?? 0)
                      .reduce((a, b) => a + b) /
                  docs.length;

          return Column(
            children: [
              // ── Rating summary ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).appBarTheme.backgroundColor,
                child: Row(
                  children: [
                    // Big rating number
                    Column(
                      children: [
                        Text(avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${docs.length} reviews',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // Rating bars
                    Expanded(
                      child: Column(
                        children: List.generate(5, (i) {
                          final star = 5 - i;
                          final count = docs
                              .where((d) =>
                                  (d.data() as Map<String, dynamic>)[
                                      'rating'] ==
                                  star)
                              .length;
                          final percent =
                              docs.isEmpty ? 0.0 : count / docs.length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(children: [
                              Text('$star',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 12),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: AppColors.divider,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.amber),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('$count',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight)),
                            ]),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Comments list ──────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _CommentCard(
                      commentId: doc.id,
                      data: data,
                      currentUser: currentUser,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // ── Write comment FAB ────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWriteCommentSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Write Comment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// Bottom sheet to write a new comment
  void _showWriteCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteCommentSheet(currentUser: currentUser),
    );
  }
}

// ── Comment Card ──────────────────────────────────────────────────────────────
class _CommentCard extends StatefulWidget {
  final String commentId;
  final Map<String, dynamic> data;
  final User? currentUser;

  const _CommentCard({
    required this.commentId,
    required this.data,
    required this.currentUser,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showReplies = false;
  bool _showReplyInput = false;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  bool get _isOwner => widget.data['userId'] == widget.currentUser?.uid;
  bool get _isAdmin => _adminUids.contains(widget.currentUser?.uid);
  bool get _canDelete => _isOwner || _isAdmin;

  List<String> get _likes =>
      List<String>.from(widget.data['likes'] ?? []);

  bool get _hasLiked =>
      _likes.contains(widget.currentUser?.uid);

  /// Toggle like on comment
  Future<void> _toggleLike() async {
    final uid = widget.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('feedback')
        .doc(widget.commentId);

    if (_hasLiked) {
      await ref.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  /// Delete comment
  Future<void> _deleteComment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Comment?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textLight)),
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
          .collection('feedback')
          .doc(widget.commentId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  /// Submit a reply
  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    _replyController.clear();

    await FirebaseFirestore.instance
        .collection('feedback')
        .doc(widget.commentId)
        .collection('replies')
        .add({
      'userId': widget.currentUser?.uid,
      'userName': widget.currentUser?.displayName ?? 'User',
      'userPhoto': widget.currentUser?.photoURL ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _showReplies = true;
      _showReplyInput = false;
    });
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.data['userName'] ?? 'User';
    final userPhoto = widget.data['userPhoto'] ?? '';
    final rating = widget.data['rating'] ?? 0;
    final comment = widget.data['comment'] ?? '';
    final category = widget.data['category'] ?? '';
    final timestamp = widget.data['createdAt'] as Timestamp?;
    final likesCount = _likes.length;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: avatar, name, date, delete ──────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryLighter,
                      backgroundImage: userPhoto.isNotEmpty
                          ? NetworkImage(userPhoto)
                          : null,
                      child: userPhoto.isEmpty
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
                          Row(children: [
                            Text(userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            if (_isAdmin && !_isOwner) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('ADMIN',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ]),
                          Text(_formatDate(timestamp),
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    // Delete button (owner or admin only)
                    if (_canDelete)
                      IconButton(
                        onPressed: _deleteComment,
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Stars + category ─────────────────────────────────────
                Row(children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(category,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
                const SizedBox(height: 8),

                // ── Comment text ─────────────────────────────────────────
                Text(comment,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 12),

                // ── Action buttons: Like, Reply ───────────────────────────
                Row(children: [
                  // Like button
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _hasLiked
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hasLiked
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          _hasLiked
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          size: 14,
                          color: _hasLiked
                              ? AppColors.primary
                              : AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          likesCount > 0 ? '$likesCount Helpful' : 'Helpful',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _hasLiked
                                  ? AppColors.primary
                                  : AppColors.textLight),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Reply button
                  GestureDetector(
                    onTap: () => setState(() {
                      _showReplyInput = !_showReplyInput;
                      _showReplies = true;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Row(children: [
                        Icon(Icons.reply_rounded,
                            size: 14, color: AppColors.textLight),
                        SizedBox(width: 4),
                        Text('Reply',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textLight)),
                      ]),
                    ),
                  ),
                  const Spacer(),

                  // View replies button
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('feedback')
                        .doc(widget.commentId)
                        .collection('replies')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final replyCount =
                          snapshot.data?.docs.length ?? 0;
                      if (replyCount == 0) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => setState(
                            () => _showReplies = !_showReplies),
                        child: Text(
                          _showReplies
                              ? 'Hide replies'
                              : '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ]),
              ],
            ),
          ),

          // ── Reply input ────────────────────────────────────────────────
          if (_showReplyInput)
            Container(
              padding:
                  const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLighter,
                  backgroundImage:
                      widget.currentUser?.photoURL != null
                          ? NetworkImage(widget.currentUser!.photoURL!)
                          : null,
                  child: widget.currentUser?.photoURL == null
                      ? Text(
                          (widget.currentUser?.displayName ?? 'U')[0]
                              .toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _submitReply(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitReply,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),

          // ── Replies list ───────────────────────────────────────────────
          if (_showReplies)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feedback')
                  .doc(widget.commentId)
                  .collection('replies')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: snapshot.data!.docs.map((replyDoc) {
                      final reply =
                          replyDoc.data() as Map<String, dynamic>;
                      final replyUserId = reply['userId'] as String?;
                      final isReplyOwner =
                          replyUserId == widget.currentUser?.uid;
                      final canDeleteReply =
                          isReplyOwner || _isAdmin;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryLighter,
                              backgroundImage:
                                  (reply['userPhoto'] ?? '').isNotEmpty
                                      ? NetworkImage(reply['userPhoto'])
                                      : null,
                              child: (reply['userPhoto'] ?? '').isEmpty
                                  ? Text(
                                      (reply['userName'] ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(reply['userName'] ?? 'User',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(reply['text'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13, height: 1.4)),
                                ],
                              ),
                            ),
                            // Delete reply (owner or admin)
                            if (canDeleteReply)
                              GestureDetector(
                                onTap: () async {
                                  await FirebaseFirestore.instance
                                      .collection('feedback')
                                      .doc(widget.commentId)
                                      .collection('replies')
                                      .doc(replyDoc.id)
                                      .delete();
                                },
                                child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.textLight),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Write Comment Bottom Sheet ────────────────────────────────────────────────
class _WriteCommentSheet extends StatefulWidget {
  final User? currentUser;
  const _WriteCommentSheet({required this.currentUser});

  @override
  State<_WriteCommentSheet> createState() => _WriteCommentSheetState();
}

class _WriteCommentSheetState extends State<_WriteCommentSheet> {
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General', 'App Performance', 'Payment',
    'Delivery', 'Sellers', 'Customer Support',
  ];

  final List<Map<String, dynamic>> _ratingLabels = [
    {'label': 'Terrible',  'color': Colors.red},
    {'label': 'Bad',       'color': Colors.orange},
    {'label': 'Okay',      'color': Colors.amber},
    {'label': 'Good',      'color': Colors.lightGreen},
    {'label': 'Excellent', 'color': AppColors.success},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': widget.currentUser?.uid,
        'userName': widget.currentUser?.displayName ?? 'Anonymous',
        'userEmail': widget.currentUser?.email ?? '',
        'userPhoto': widget.currentUser?.photoURL ?? '',
        'rating': _selectedRating,
        'category': _selectedCategory,
        'comment': _commentController.text.trim(),
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: ${e.toString()}'),
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Write a Comment',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Star rating
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedRating = starIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6),
                          child: Icon(
                            starIndex <= _selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 40,
                            color: starIndex <= _selectedRating
                                ? Colors.amber
                                : AppColors.textLight,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_selectedRating > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_ratingLabels[_selectedRating - 1]
                                    ['color'] as Color)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _ratingLabels[_selectedRating - 1]['label'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ratingLabels[_selectedRating - 1]
                              ['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category
            const Text('Category',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDark)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Comment text
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitComment,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Post Comment'),
            ),
          ],
        ),
      ),
    );
  }
}