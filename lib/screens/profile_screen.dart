import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'authenticate_screen.dart';
import 'login_screen.dart';
import '../screens/help_screen.dart';
import '../screens/comment_screen.dart';
import 'order_history_screen.dart';
import 'payment_settings_screen.dart';
import '../utils/app_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _cloudName = 'drhscazuw';
  final String _uploadPreset = 'agrinexa_upload';
  bool _isUploadingPhoto = false;

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      if (response.statusCode == 200) return jsonData['secure_url'];
      return null;
    } catch (e) {
      return null;
    }
  }

  void _changeProfilePhoto(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.changePhoto,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (pickedFile == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final imageUrl = await _uploadImage(File(pickedFile.path));
      if (imageUrl == null) throw Exception('Upload failed');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.updatePhotoURL(imageUrl);
      await user.reload();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoUrl': imageUrl},
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update photo. Try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  /// Show language picker bottom sheet
  void _showLanguagePicker(AppLocalizations l10n) {
    final appState = AgriNexaApp.of(context);
    final currentLang = appState?.language ?? 'en';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.selectLanguage,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // English option
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: currentLang == 'en'
                      ? AppColors.primaryLighter
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🇬🇧', style: TextStyle(fontSize: 22)),
                ),
              ),
              title: Text(
                l10n.english,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: currentLang == 'en'
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () {
                appState?.setLanguage('en');
                Navigator.pop(context);
              },
            ),

            // French option
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: currentLang == 'fr'
                      ? AppColors.primaryLighter
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🇫🇷', style: TextStyle(fontSize: 22)),
                ),
              ),
              title: Text(
                l10n.french,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: currentLang == 'fr'
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () {
                appState?.setLanguage('fr');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'AgriNexa User';
    final String email = user?.email ?? '';
    final String? photoUrl = user?.photoURL;
    final String initials = displayName.isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .take(2)
              .join()
        : 'A';

    final appState = AgriNexaApp.of(context);
    final isDark = appState?.isDarkMode ?? false;
    final currentLang = appState?.language ?? 'en';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Stack(
                    children: [
                      _isUploadingPhoto
                          ? Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLighter,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primaryLighter,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _changeProfilePhoto(l10n),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _changeProfilePhoto(l10n),
                          child: Text(
                            l10n.changePhoto,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // General section
            _Section(
              title: l10n.general,
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.orderHistory,
                  onTap: () => Navigator.push(
                    context,
                    AppRouter.slide(const OrderHistoryScreen()),
                  ),
                ),

                _MenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.paymentSettings,
                  onTap: () => Navigator.push(
                    context,
                    AppRouter.slide(const PaymentSettingsScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: l10n.pickupLocation,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.verified_user_outlined,
                  label: l10n.authenticate,
                  onTap: () => Navigator.push(
                    context,
                    AppRouter.slide(const AuthenticateScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.changePassword,
                  onTap: () => _showChangePassword(context, l10n),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Appearance section
            _Section(
              title: l10n.appearance,
              items: [
                // Dark mode toggle
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.darkMode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: isDark,
                        onChanged: (_) => appState?.toggleTheme(),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                // Language selector
                InkWell(
                  onTap: () => _showLanguagePicker(l10n),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            l10n.language,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Show current language
                        Text(
                          currentLang == 'en'
                              ? '🇬🇧 English'
                              : '🇫🇷 Français',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.textLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Support section
            _Section(
              title: l10n.support,
              items: [
                _MenuItem(
                  icon: Icons.comment_outlined,
                  label: l10n.writeComment,
                  onTap: () => Navigator.push(
                    context,
                    AppRouter.slide(const CommentScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: l10n.logOut,
                  labelColor: AppColors.danger,
                  onTap: () => _confirmLogout(context, l10n),
                ),
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: l10n.needHelp,
                  onTap: () => Navigator.push(
                    context,
                    AppRouter.slide(const HelpScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context, AppLocalizations l10n) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.changePassword,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                hintText: '••••••••',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                hintText: '••••••••',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              try {
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPasswordController.text.trim(),
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPasswordController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.passwordChanged),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                String message = l10n.passwordFailed;
                if (e.code == 'wrong-password') {
                  message = l10n.wrongPassword;
                } else if (e.code == 'weak-password')
                  message = l10n.passwordWeak;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
            child: Text(l10n.update),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.logoutTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(l10n.logoutConfirm, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  AppRouter.slide(const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 42),
            ),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: labelColor ?? AppColors.textMedium),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      labelColor ??
                      Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
