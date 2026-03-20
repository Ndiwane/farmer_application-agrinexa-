import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class StatusViewerScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhoto;
  final bool isMyStatus;

  const StatusViewerScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    this.isMyStatus = false,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  late AnimationController _progressController;

  List<Map<String, dynamic>> _statuses = [];
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isLoading = true;
  final _replyController = TextEditingController();

  static const Duration _statusDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _statusDuration,
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStatus();
      }
    });
    _loadStatuses();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('statuses')
        .doc(widget.userId)
        .collection('userStatuses')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .get();

    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _statuses = snapshot.docs
          .map((d) => {...d.data(), 'id': d.id})
          .toList();
      _isLoading = false;
    });

    _startCurrent();
  }

  void _startCurrent() {
    _progressController.reset();
    _progressController.forward();
    _markAsSeen();
  }

  Future<void> _markAsSeen() async {
    if (widget.isMyStatus) return;
    if (_currentIndex >= _statuses.length) return;
    final statusId = _statuses[_currentIndex]['id'];
    await FirebaseFirestore.instance
        .collection('statuses')
        .doc(widget.userId)
        .collection('userStatuses')
        .doc(statusId)
        .update({
      'seenBy': FieldValue.arrayUnion([currentUser!.uid]),
    });
  }

  void _nextStatus() {
    if (_currentIndex < _statuses.length - 1) {
      setState(() => _currentIndex++);
      _startCurrent();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startCurrent();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _pause() {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _resume() {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  Future<void> _deleteStatus() async {
    final statusId = _statuses[_currentIndex]['id'];
    await FirebaseFirestore.instance
        .collection('statuses')
        .doc(widget.userId)
        .collection('userStatuses')
        .doc(statusId)
        .delete();

    if (_statuses.length == 1) {
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _statuses.removeAt(_currentIndex);
        if (_currentIndex >= _statuses.length) {
          _currentIndex = _statuses.length - 1;
        }
      });
      _startCurrent();
    }
  }

  void _showSeenBy() {
    final seenBy = List<String>.from(
        _statuses[_currentIndex]['seenBy'] ?? []);
    _pause();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text('${seenBy.length} views',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          if (seenBy.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No views yet',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: seenBy.length,
                itemBuilder: (_, i) => FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(seenBy[i])
                      .get(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final u =
                        snap.data!.data() as Map<String, dynamic>? ?? {};
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (u['photoUrl'] ?? '').isNotEmpty
                            ? NetworkImage(u['photoUrl'])
                            : null,
                        child: (u['photoUrl'] ?? '').isEmpty
                            ? Text((u['name'] ?? 'U')[0])
                            : null,
                      ),
                      title: Text(u['name'] ?? 'User',
                          style: const TextStyle(color: Colors.white)),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    ).whenComplete(_resume);
  }

  void _showReply() {
    _pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reply to ${widget.userName}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a reply...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final text = _replyController.text.trim();
                    if (text.isEmpty) return;
                    final chatId = ([currentUser!.uid, widget.userId]
                          ..sort())
                        .join('_');
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .add({
                      'senderId': currentUser!.uid,
                      'senderName':
                          currentUser!.displayName ?? 'User',
                      'text': '↩ ${widget.userName}\'s status: $text',
                      'imageUrl': '',
                      'isImage': false,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .set({
                      'participants': [
                        currentUser!.uid,
                        widget.userId
                      ],
                      'lastMessage': text,
                      'lastMessageTime': FieldValue.serverTimestamp(),
                      'lastSenderId': currentUser!.uid,
                      'unread_${widget.userId}':
                          FieldValue.increment(1),
                    }, SetOptions(merge: true));
                    _replyController.clear();
                    if (mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).whenComplete(_resume);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final status = _statuses[_currentIndex];
    final isText = status['type'] == 'text';
    final bgColor =
        Color(status['bgColor'] ?? AppColors.primary.value);
    final imageUrl = status['imageUrl'] ?? '';
    final text = status['text'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pause(),
        onTapUp: (details) {
          _resume();
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _prevStatus();
          } else if (details.globalPosition.dx > width * 2 / 3) {
            _nextStatus();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
            // ── Background ──────────────────────────────────────────
            if (isText)
              Container(color: bgColor)
            else if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) {
                    // Image fully loaded — schedule resume after build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_isPaused && mounted) _resume();
                    });
                    return child;
                  }
                  // Image still loading — schedule pause after build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_isPaused && mounted) _pause();
                  });
                  return Container(
                    color: Colors.black,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  );
                },
              )
            else
              Container(color: Colors.black),

            // ── Text overlay ────────────────────────────────────────
            if (isText && text.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 8)
                      ],
                    ),
                  ),
                ),
              ),

            // ── Caption on image ────────────────────────────────────
            if (!isText && text.isNotEmpty)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15)),
                ),
              ),

            // ── Top gradient ────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Progress bars ───────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(_statuses.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: i < _currentIndex
                              ? Container(height: 3,
                                  color: Colors.white)
                              : i == _currentIndex
                                  ? AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (_, _) =>
                                          LinearProgressIndicator(
                                        value:
                                            _progressController.value,
                                        backgroundColor:
                                            Colors.white38,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Colors.white),
                                        minHeight: 3,
                                      ),
                                    )
                                  : Container(
                                      height: 3,
                                      color: Colors.white38),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              ),
            ),

            // ── User info + close ────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 44, 8, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLighter,
                      backgroundImage: widget.userPhoto.isNotEmpty
                          ? NetworkImage(widget.userPhoto)
                          : null,
                      child: widget.userPhoto.isEmpty
                          ? Text(widget.userName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.primary))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text(
                            _timeAgo(status['createdAt']),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Delete (own status)
                    if (widget.isMyStatus)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white),
                        onPressed: () async {
                          _pause();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Status?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            _deleteStatus();
                          } else {
                            _resume();
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ),
            ),

            // ── Bottom actions ───────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    if (!widget.isMyStatus)
                      Expanded(
                        child: GestureDetector(
                          onTap: _showReply,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white60, width: 1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.reply,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                    'Reply to ${widget.userName}...',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (widget.isMyStatus) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: _showSeenBy,
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye_outlined,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '${(status['seenBy'] as List?)?.length ?? 0} views',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
