import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class StatusComposerScreen extends StatefulWidget {
  final StatusComposerType type;
  const StatusComposerScreen({super.key, required this.type});

  @override
  State<StatusComposerScreen> createState() => _StatusComposerScreenState();
}

enum StatusComposerType { text, image }

class _StatusComposerScreenState extends State<StatusComposerScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _textController = TextEditingController();
  final String _cloudName = 'drhscazuw';
  final String _uploadPreset = 'agrinexa_upload';

  File? _selectedImage;
  bool _isPosting = false;
  Color _bgColor = const Color(0xFF2E7D32);
  String _caption = '';

  final List<Color> _bgColors = [
    const Color(0xFF2E7D32),
    const Color(0xFF1565C0),
    const Color(0xFF6A1B9A),
    const Color(0xFFC62828),
    const Color(0xFFE65100),
    const Color(0xFF00695C),
    const Color(0xFF37474F),
    const Color(0xFF000000),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.type == StatusComposerType.image) {
      _pickImage();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _selectedImage = File(picked.path));
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final data = json.decode(await response.stream.bytesToString());
      if (response.statusCode == 200) return data['secure_url'];
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _postStatus() async {
    if (widget.type == StatusComposerType.text &&
        _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text')),
      );
      return;
    }
    if (widget.type == StatusComposerType.image && _selectedImage == null) {
      return;
    }

    setState(() => _isPosting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final userName =
          userData['name'] ?? currentUser!.displayName ?? 'User';
      final userPhoto = userData['photoUrl'] ?? currentUser!.photoURL ?? '';

      String? imageUrl;
      if (widget.type == StatusComposerType.image && _selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) throw Exception('Image upload failed');
      }

      await FirebaseFirestore.instance
          .collection('statuses')
          .doc(currentUser!.uid)
          .collection('userStatuses')
          .add({
        'type': widget.type == StatusComposerType.text ? 'text' : 'image',
        'imageUrl': imageUrl ?? '',
        'text': widget.type == StatusComposerType.text
            ? _textController.text.trim()
            : _caption,
        'bgColor': _bgColor.value,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24))),
        'userId': currentUser!.uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'seenBy': [],
      });

      // Update parent doc so other users can discover this user has a status
      await FirebaseFirestore.instance
          .collection('statuses')
          .doc(currentUser!.uid)
          .set({
        'userId': currentUser!.uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Status posted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.type == StatusComposerType.text
          ? _buildTextComposer()
          : _buildImageComposer(),
    );
  }

  Widget _buildTextComposer() {
    return Stack(
      children: [
        // Colored background
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _bgColor,
          width: double.infinity,
          height: double.infinity,
        ),
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _isPosting
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : TextButton(
                            onPressed: _postStatus,
                            child: const Text('Post',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                  ],
                ),
              ),
              // Text input
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      maxLines: null,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Type a status...',
                        hintStyle: TextStyle(
                            color: Colors.white60, fontSize: 28),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),
              // Color picker
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _bgColors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final color = _bgColors[i];
                    final isSelected = color == _bgColor;
                    return GestureDetector(
                      onTap: () => setState(() => _bgColor = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isSelected ? 40 : 34,
                        height: isSelected ? 40 : 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageComposer() {
    if (_selectedImage == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Stack(
      children: [
        // Image preview
        Positioned.fill(
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        ),
        // Dark overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _isPosting
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : TextButton(
                            onPressed: _postStatus,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text('Post',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                  ],
                ),
              ),
              const Spacer(),
              // Caption input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onChanged: (v) => _caption = v,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
