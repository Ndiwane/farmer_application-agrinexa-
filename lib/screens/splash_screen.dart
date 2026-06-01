import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../utils/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _leavesController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  final List<_Leaf> _leaves = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Generate falling leaves
    for (int i = 0; i < 18; i++) {
      _leaves.add(_Leaf(
        x: _random.nextDouble(),
        startY: -0.1 - _random.nextDouble() * 0.5,
        size: 10 + _random.nextDouble() * 18,
        speed: 0.3 + _random.nextDouble() * 0.5,
        sway: 0.03 + _random.nextDouble() * 0.05,
        swaySpeed: 1.0 + _random.nextDouble() * 2.0,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextBool() ? 1 : -1) *
            (0.5 + _random.nextDouble() * 1.5),
        opacity: 0.25 + _random.nextDouble() * 0.35,
        delay: _random.nextDouble() * 0.6,
      ));
    }

    // Logo animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    // Leaves continuous animation
    _leavesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // 6 seconds then navigate — with Firebase auth check
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        Navigator.pushReplacement(
          context,
          AppRouter.slide(
                user != null ? const HomeScreen() : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _leavesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Falling leaves layer
          AnimatedBuilder(
            animation: _leavesController,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: _LeavesPainter(
                  leaves: _leaves,
                  progress: _leavesController.value,
                ),
              );
            },
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.eco_rounded,
                                color: AppColors.primary, size: 64),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'AgriNexa',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The world\'s best agricultural\nmarketplace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.85),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: AppColors.white.withOpacity(0.7),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leaf {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double sway;
  final double swaySpeed;
  final double rotation;
  final double rotationSpeed;
  final double opacity;
  final double delay;

  _Leaf({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.sway,
    required this.swaySpeed,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.delay,
  });
}

class _LeavesPainter extends CustomPainter {
  final List<_Leaf> leaves;
  final double progress;

  _LeavesPainter({required this.leaves, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final leaf in leaves) {
      final t = ((progress - leaf.delay) % 1.0 + 1.0) % 1.0;
      final y = leaf.startY + t * (1.2 - leaf.startY) * (1 / leaf.speed);
      if (y < 0 || y > 1.15) continue;

      final x = leaf.x + sin(t * leaf.swaySpeed * 2 * pi) * leaf.sway;
      final rot = leaf.rotation + t * leaf.rotationSpeed * 2 * pi;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(rot);
      _drawLeaf(canvas, leaf.size, leaf.opacity);
      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, double size, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, -size / 2);
    path.cubicTo(size * 0.6, -size * 0.3, size * 0.6, size * 0.3, 0, size / 2);
    path.cubicTo(-size * 0.6, size * 0.3, -size * 0.6, -size * 0.3, 0, -size / 2);
    canvas.drawPath(path, paint);

    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.07;
    canvas.drawLine(Offset(0, -size * 0.4), Offset(0, size * 0.4), veinPaint);
  }

  @override
  bool shouldRepaint(_LeavesPainter old) => old.progress != progress;
}
