import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'home_screen.dart';
import '../utils/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  late AnimationController _swingController;
  late Animation<double> _swingAnim;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId:
        '956551233387-p82vbfmqmnaa8ju9roartsigqs8p70n3.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _swingAnim = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _swingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _swingController.dispose();
    super.dispose();
  }

  Future<void> _createUserProfile(User user, {String? phone}) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? 'AgriNexa User',
      'email': user.email ?? '',
      'phone': phone ?? '',
      'photoUrl': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    }, SetOptions(merge: true));
  }

  void _register(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final displayName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      final updatedUser = FirebaseAuth.instance.currentUser!;
      await _createUserProfile(updatedUser, phone: _phoneController.text.trim());
      if (mounted) {
        Navigator.pushReplacement(context, AppRouter.slide(const HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed. Please try again.';
      if (e.code == 'email-already-in-use') message = 'This email is already registered.';
      else if (e.code == 'weak-password') message = 'Password is too weak.';
      else if (e.code == 'invalid-email') message = 'The email address is not valid.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) { setState(() => _isGoogleLoading = false); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _createUserProfile(userCredential.user!);
      if (mounted) {
        Navigator.pushReplacement(context, AppRouter.slide(const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In failed. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Language selector toggle — EN / FR
  Widget _buildLanguageSelector() {
    final appState = AgriNexaApp.of(context);
    final currentLang = appState?.language ?? 'en';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['en', 'fr'].map((lang) {
        final isSelected = currentLang == lang;
        final isFirst = lang == 'en';
        return GestureDetector(
          onTap: () => appState?.setLanguage(lang),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.primaryLighter,
              borderRadius: BorderRadius.horizontal(
                left: isFirst ? const Radius.circular(20) : Radius.zero,
                right: !isFirst ? const Radius.circular(20) : Radius.zero,
              ),
            ),
            child: Text(
              lang == 'en' ? '🇬🇧 EN' : '🇫🇷 FR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Language selector
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildLanguageSelector(),
                ),
                const SizedBox(height: 12),

                // Swinging logo
                AnimatedBuilder(
                  animation: _swingAnim,
                  builder: (context, child) => Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.rotationZ(_swingAnim.value),
                    child: child,
                  ),
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 14, offset: const Offset(0, 5),
                      )],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.eco_rounded, color: AppColors.white, size: 42)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('AgriNexa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const SizedBox(height: 28),

                // Title and subtitle
                Text(l10n.createAccount,
                    style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(l10n.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13,
                        color: AppColors.textMedium, height: 1.5)),
                const SizedBox(height: 28),

                // First name & Last name
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.firstName,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(hintText: 'Ndiwane'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.required : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.lastName,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(hintText: 'Timothy'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.required : null,
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Phone number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: l10n.phoneHint,
                    labelText: l10n.phoneNumber,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.phoneRequired;
                    if (v.length < 9) return l10n.phoneInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l10n.emailHint,
                    labelText: l10n.email,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) return l10n.emailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    labelText: l10n.password,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                          color: AppColors.textLight),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.passwordRequired;
                    if (v.length < 6) return l10n.passwordWeak;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    labelText: l10n.confirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                          color: AppColors.textLight),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.passwordConfirmRequired;
                    if (v != _passwordController.text) return l10n.passwordNoMatch;
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _register(l10n),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l10n.register),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(l10n.orContinueWith,
                        style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ]),
                const SizedBox(height: 20),

                // Google Sign-In
                _isGoogleLoading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded,
                            color: Color(0xFFEA4335), size: 26),
                        label: Text(l10n.continueWithGoogle,
                            style: const TextStyle(color: AppColors.textDark,
                                fontWeight: FontWeight.w500, fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.alreadyAccount,
                        style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(l10n.loginLink,
                          style: const TextStyle(color: AppColors.primary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}