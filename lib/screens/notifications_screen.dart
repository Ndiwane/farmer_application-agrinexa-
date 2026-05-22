import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'order_history_screen.dart';
import 'message_screen.dart';
import '../utils/app_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _clearAll(AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.clearAllNotifications),
        content: Text(l10n.clearNotificationsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );

    if (result == true) {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: _currentUserId)
          .get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allNotificationsCleared),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    await _markAsRead(notification['id']);
    final type = notification['type'] ?? '';

    if (type == 'order') {
      if (mounted) {
        Navigator.push(context,
            AppRouter.slide(const OrderHistoryScreen()));
      }
    } else if (type == 'message') {
      final chatId = notification['chatId'];
      final otherUserId = notification['fromUserId'];
      if (chatId != null && otherUserId != null && mounted) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();
        if (userDoc.exists && mounted) {
          final userData = userDoc.data()!;
          Navigator.push(
            context,
            AppRouter.slide(MessageScreen(
              chatId: chatId,
              otherUserId: otherUserId,
              otherUserName: userData['name'] ?? 'User',
              otherUserPhoto: userData['photoUrl'],
            )),
          );
        }
      }
    }
  }

  Widget _buildNotificationIcon(String type) {
    if (type == 'order') {
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shopping_bag_rounded,
            color: AppColors.primary, size: 24),
      );
    } else if (type == 'message') {
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.message_rounded,
            color: Colors.blue, size: 24),
      );
    } else {
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: AppColors.textLight.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.notifications_rounded,
            color: AppColors.textLight, size: 24),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l10n.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => _clearAll(l10n),
            tooltip: l10n.clearAll,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_rounded,
                        size: 60, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.noNotificationsYet,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(l10n.notificationsHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textMedium)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {...data, 'id': doc.id};
          }).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['isRead'] == true;
                final title = notification['title'] ?? 'Notification';
                final body = notification['body'] ?? '';
                final type = notification['type'] ?? '';
                final timestamp =
                    notification['createdAt'] as Timestamp?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: isRead
                        ? Theme.of(context).appBarTheme.backgroundColor
                        : AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () =>
                          _handleNotificationTap(notification),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNotificationIcon(type),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(title,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700)),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 10, height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(body,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMedium,
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Text(_formatTimestamp(timestamp),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textLight)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
