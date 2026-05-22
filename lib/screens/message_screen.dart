import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class MessageScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const MessageScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isSending = false;

  final String _cloudName = 'drhscazuw';
  final String _uploadPreset = 'agrinexa_upload';

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({'unread_${currentUser?.uid}': 0});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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

  void _showImageSourceDialog(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
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
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isSending = true);
    final imageUrl = await _uploadImage(File(pickedFile.path));
    if (imageUrl != null) {
      await _sendMessage(imageUrl: imageUrl);
    }
    setState(() => _isSending = false);
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final messageData = {
        'senderId': currentUser?.uid,
        'senderName': currentUser?.displayName ?? 'User',
        'text': imageUrl != null ? '' : text,
        'imageUrl': imageUrl ?? '',
        'isImage': imageUrl != null,
        'timestamp': FieldValue.serverTimestamp(),
        'deleted': false, // ← Track if message is deleted
      };

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({
        'participants': [currentUser?.uid, widget.otherUserId],
        'lastMessage': imageUrl != null ? '📷 Image' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUser?.uid,
        'unread_${widget.otherUserId}': FieldValue.increment(1),
        'unread_${currentUser?.uid}': 0,
      }, SetOptions(merge: true));

      await NotificationService.sendNotificationToUser(
        userId: widget.otherUserId,
        title: currentUser?.displayName ?? 'Someone',
        body: imageUrl != null ? '📷 Sent you an image' : text,
        data: {
          'type': 'message',
          'chatId': widget.chatId,
          'senderId': currentUser?.uid ?? '',
        },
      );

      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSend),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Delete a message — only sender can delete their own messages
  Future<void> _deleteMessage(
      String messageId, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteMessage,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l10n.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mark message as deleted (soft delete — keeps timestamp intact)
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deleted': true,
      'text': '',
      'imageUrl': '',
      'isImage': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messageDeleted),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLighter,
              backgroundImage:
                  (widget.otherUserPhoto?.isNotEmpty ?? false)
                      ? NetworkImage(widget.otherUserPhoto!)
                      : null,
              child: (widget.otherUserPhoto?.isEmpty ?? true)
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
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
                  Text(widget.otherUserName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.otherUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      bool isOnline = false;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data()
                            as Map<String, dynamic>;
                        isOnline = data['isOnline'] ?? false;
                      }
                      return Text(
                        isOnline ? l10n.online : l10n.offline,
                        style: TextStyle(
                          fontSize: 11,
                          color: isOnline
                              ? AppColors.success
                              : AppColors.textLight,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to ${widget.otherUserName}! 👋',
                      style: TextStyle(color: AppColors.textMedium),
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe =
                        data['senderId'] == currentUser?.uid;
                    final isDeleted = data['deleted'] == true;

                    return GestureDetector(
                      // Long press to delete (only sender can delete)
                      onLongPress: isMe && !isDeleted
                          ? () => _deleteMessage(doc.id, l10n)
                          : null,
                      child: _MessageBubble(
                        data: data,
                        isMe: isMe,
                        isDeleted: isDeleted,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image button
                IconButton(
                  onPressed: () => _showImageSourceDialog(l10n),
                  icon: const Icon(Icons.image_outlined,
                      color: AppColors.primary),
                ),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                GestureDetector(
                  onTap: _isSending ? null : () => _sendMessage(),
                  child: Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isDeleted;

  const _MessageBubble({
    required this.data,
    required this.isMe,
    required this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] as Timestamp?;
    final time = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          // Deleted messages have a muted style
          color: isDeleted
              ? AppColors.divider
              : isMe
                  ? AppColors.primary
                  : AppColors.primaryLighter,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: isDeleted
            // Show "This message was deleted" for deleted messages
            ? Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block_rounded,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(
                      isMe
                          ? 'You deleted this message'
                          : 'This message was deleted',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            : data['isImage'] == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      data['imageUrl'],
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          data['text'] ?? '',
                          style: TextStyle(
                              fontSize: 14,
                              color: isMe
                                  ? Colors.white
                                  : AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white70
                                  : AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
