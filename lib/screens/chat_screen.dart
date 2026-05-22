import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'message_screen.dart';
import 'status_composer_screen.dart';
import 'status_viewer_screen.dart';
import '../utils/app_router.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  String _getChatId(String otherUserId) {
    final ids = [currentUser!.uid, otherUserId]..sort();
    return ids.join('_');
  }

  void _showAddStatusOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Add Status',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    shape: BoxShape.circle),
                child: const Icon(Icons.image_outlined,
                    color: AppColors.primary),
              ),
              title: const Text('Photo Status'),
              subtitle: const Text('Share a photo from your gallery'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    AppRouter.slideUp(const StatusComposerScreen(
                        type: StatusComposerType.image)));
              },
            ),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    shape: BoxShape.circle),
                child: const Icon(Icons.text_fields_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Text Status'),
              subtitle: const Text('Share a text with colored background'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    AppRouter.slideUp(const StatusComposerScreen(
                        type: StatusComposerType.text)));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _viewMyStatus() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('statuses')
        .doc(currentUser!.uid)
        .collection('userStatuses')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .limit(1)
        .get();

    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      _showAddStatusOptions();
    } else {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final userName =
          userData['name'] ?? currentUser!.displayName ?? 'Me';
      final userPhoto =
          userData['photoUrl'] ?? currentUser!.photoURL ?? '';

      if (!mounted) return;
      Navigator.push(
        context,
        AppRouter.slideUp(StatusViewerScreen(
          userId: currentUser!.uid,
          userName: userName,
          userPhoto: userPhoto,
          isMyStatus: true,
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Status',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textDark)),
                ),
                SizedBox(
                  height: 90,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('statuses')
                        .snapshots(),
                    builder: (context, snapshot) {
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _MyStatusBubble(
                            userId: currentUser!.uid,
                            onAdd: _showAddStatusOptions,
                            onView: _viewMyStatus,
                          ),
                          const SizedBox(width: 12),
                          if (snapshot.hasData)
                            ...snapshot.data!.docs
                                .where((doc) => doc.id != currentUser!.uid)
                                .map((doc) => _OtherStatusBubble(
                                      userId: doc.id,
                                      onView: (userId, userName, userPhoto) {
                                        Navigator.push(
                                          context,
                                          AppRouter.slideUp(StatusViewerScreen(
                                            userId: userId,
                                            userName: userName,
                                            userPhoto: userPhoto,
                                          )),
                                        );
                                      },
                                    )),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Chat list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUser!.uid)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 60, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        const Text('No conversations yet',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        Text(
                          'Contact a seller from the marketplace\nto start chatting!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textMedium, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final participants =
                        List<String>.from(data['participants']);
                    final otherUserId = participants
                        .firstWhere((id) => id != currentUser!.uid);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox.shrink();
                        final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>? ?? {};
                        final userName = userData['name'] ?? 'User';
                        final userPhoto = userData['photoUrl'] ?? '';
                        final lastMessage = data['lastMessage'] ?? 'Say hello!';
                        final lastTime = data['lastMessageTime'] as Timestamp?;
                        final unreadCount =
                            data['unread_${currentUser!.uid}'] ?? 0;

                        return _ChatTile(
                          name: userName,
                          photoUrl: userPhoto,
                          lastMessage: lastMessage,
                          time: lastTime,
                          unreadCount: unreadCount,
                          onTap: () => Navigator.push(
                            context,
                            AppRouter.slide(MessageScreen(
                              chatId: _getChatId(otherUserId),
                              otherUserId: otherUserId,
                              otherUserName: userName,
                              otherUserPhoto: userPhoto,
                            )),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MyStatusBubble extends StatelessWidget {
  final String userId;
  final VoidCallback onAdd;
  final VoidCallback onView;

  const _MyStatusBubble({
    required this.userId,
    required this.onAdd,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('statuses')
          .doc(userId)
          .collection('userStatuses')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final hasStatus = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return GestureDetector(
          onTap: hasStatus ? onView : onAdd,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: hasStatus
                          ? Border.all(color: AppColors.primary, width: 2.5)
                          : null,
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLighter,
                      child: Icon(Icons.person,
                          color: AppColors.primary, size: 28),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.add,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const SizedBox(
                width: 60,
                child: Text('My Status',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMedium)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtherStatusBubble extends StatelessWidget {
  final String userId;
  final Function(String, String, String) onView;

  const _OtherStatusBubble({required this.userId, required this.onView});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('statuses')
          .doc(userId)
          .collection('userStatuses')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt', descending: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final userName = data['userName'] ?? 'User';
        final userPhoto = data['userPhoto'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => onView(userId, userName, userPhoto),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryLighter,
                    backgroundImage: userPhoto.isNotEmpty
                        ? NetworkImage(userPhoto) : null,
                    child: userPhoto.isEmpty
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: Text(userName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMedium)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String lastMessage;
  final Timestamp? time;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
  });

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryLighter,
          backgroundImage:
              photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18))
              : null,
        ),
        title: Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textDark)),
        subtitle: Text(lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0
                    ? AppColors.textDark
                    : AppColors.textLight)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatTime(time),
                style: TextStyle(
                    fontSize: 11,
                    color: unreadCount > 0
                        ? AppColors.primary
                        : AppColors.textLight)),
            const SizedBox(height: 4),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: Text('$unreadCount',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}