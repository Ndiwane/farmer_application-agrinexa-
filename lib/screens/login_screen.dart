import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../utils/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    _swingController.dispose();
    super.dispose();
  }

  Future<void> _updateUserProfile(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? 'AgriNexa User',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    }, SetOptions(merge: true));
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _updateUserProfile(userCredential.user!);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          AppRouter.slide(const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _forgotPassword(AppLocalizations l10n) {
    final emailController =
        TextEditingController(text: _emailController.text.trim());
    bool isSending = false;
    bool emailSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.resetPassword,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text(
                      emailSent ? l10n.resetSuccess : l10n.resetSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                          height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (!emailSent) ...[
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: l10n.emailHint,
                          labelText: l10n.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSending
                              ? null
                              : () async {
                                  final email = emailController.text.trim();
                                  if (email.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(l10n.emailRequired),
                                          backgroundColor: AppColors.danger),
                                    );
                                    return;
                                  }
                                  setSheetState(() => isSending = true);
                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email);
                                    setSheetState(() {
                                      isSending = false;
                                      emailSent = true;
                                    });
                                  } on FirebaseAuthException {
                                    setSheetState(() => isSending = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(l10n.emailInvalid),
                                            backgroundColor: AppColors.danger),
                                      );
                                    }
                                  }
                                },
                          child: isSending
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(l10n.sendResetLink),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(l10n.resetSent,
                                  style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.backToLogin),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (!emailSent)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel,
                            style:
                                TextStyle(color: AppColors.textLight)),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _updateUserProfile(userCredential.user!);
      if (mounted) {
        Navigator.pushReplacement(
            context, AppRouter.slide(const HomeScreen()));
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

  // Language selector widget
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primaryLighter,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Language selector ───────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildLanguageSelector(),
                ),
                const SizedBox(height: 16),

                // ── Swinging logo ───────────────────────────────────
                AnimatedBuilder(
                  animation: _swingAnim,
                  builder: (context, child) => Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.rotationZ(_swingAnim.value),
                    child: child,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.eco_rounded,
                              color: AppColors.white,
                              size: 46)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('AgriNexa',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const SizedBox(height: 36),

                // ── Title and subtitle ──────────────────────────────
                Text(l10n.loginTitle,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        height: 1.5)),
                const SizedBox(height: 32),

                // ── Email field ─────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l10n.emailHint,
                    labelText: l10n.email,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.emailRequired;
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return l10n.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password field ──────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    labelText: l10n.password,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textLight),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _forgotPassword(l10n),
                    child: Text(l10n.forgotPassword,
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Login button ────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l10n.login),
                ),
                const SizedBox(height: 20),

                // ── Divider ─────────────────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(l10n.orContinueWith,
                        style: TextStyle(
                            color: AppColors.textLight, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ]),
                const SizedBox(height: 20),

                // ── Google Sign-In button with image ────────────────
                _isGoogleLoading
                    ? const CircularProgressIndicator(
                        color: AppColors.primary)
                    : OutlinedButton(
                        onPressed: _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.continueWithGoogle,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 28),

                // ── Register link ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.noAccount,
                        style: TextStyle(
                            color: AppColors.textMedium, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          AppRouter.slide(const RegisterScreen())),
                      child: Text(l10n.registerLink,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
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