import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/router/app_router.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_theme.dart';
import '../shared/widgets/signlink_wordmark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    // Force immersive / edge-to-edge on splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.8, curve: Curves.easeIn)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _ctrl.forward();

    // After 3 seconds → route based on permission state
    Future.delayed(const Duration(milliseconds: 3000), _navigate);
  }

  void _navigate() {
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final granted = PreferencesService.instance.cameraPermissionGranted;
    Navigator.of(context).pushReplacementNamed(
      granted ? AppRouter.translation : AppRouter.permission,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo + glow ───────────────────────────────────
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _iconOpacity.value,
                child: Transform.scale(
                  scale: _iconScale.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial glow
                      Opacity(
                        opacity: _glowOpacity.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [AppColors.mint, Colors.transparent],
                              stops: [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Icon circle
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.whiteBorder10,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: _HandIcon(size: 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Wordmark ─────────────────────────────────────
            AnimatedBuilder(
              animation: _textOpacity,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: Column(
                  children: [
                    const SignLinkWordmark(size: 32),
                    const SizedBox(height: AppSpacing.sm),
                    // Tagline — JetBrains Mono with blinking cursor
                    _BlinkingTagline(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Pulsing dot at bottom
      bottomSheet: Container(
        color: Colors.transparent,
        height: 60,
        child: Center(
          child: AnimatedBuilder(
            animation: _textOpacity,
            builder: (_, __) => Opacity(
              opacity: _textOpacity.value,
              child: const _PulsingDot(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hand icon (matches the logo from DESIGN.md) ───────────────
class _HandIcon extends StatelessWidget {
  final double size;
  const _HandIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HandPainter(),
    );
  }
}

class _HandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.fill;

    // Simplified hand silhouette matching the logo:
    // palm cup shape (bottom half) + one extended finger (index)
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Index finger — vertical rectangle, rounded top
    final fingerW = w * 0.22;
    final fingerX = w * 0.5 - fingerW / 2;
    path.addRRect(RRect.fromLTRBR(
      fingerX, h * 0.05,
      fingerX + fingerW, h * 0.55,
      Radius.circular(fingerW / 2),
    ));

    // Palm cup — rounded bottom
    path.moveTo(w * 0.1, h * 0.52);
    path.quadraticBezierTo(w * 0.1, h * 0.95, w * 0.5, h * 0.95);
    path.quadraticBezierTo(w * 0.9, h * 0.95, w * 0.9, h * 0.52);
    path.lineTo(w * 0.1, h * 0.52);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── "TRANSLATING SIGNS INTO WORDS" with blinking cursor ───────
class _BlinkingTagline extends StatefulWidget {
  @override
  State<_BlinkingTagline> createState() => _BlinkingTaglineState();
}

class _BlinkingTaglineState extends State<_BlinkingTagline>
    with SingleTickerProviderStateMixin {
  late AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TRANSLATING SIGNS INTO WORDS',
          style: AppTextStyles.labelSm(context),
          textAlign: TextAlign.center,
        ),
        AnimatedBuilder(
          animation: _blink,
          builder: (_, __) => Opacity(
            opacity: _blink.value,
            child: Text(
              '|',
              style: AppTextStyles.labelSm(context).copyWith(
                color: AppColors.mint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom pulsing dot ────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Opacity(
        opacity: 0.3 + _pulse.value * 0.7,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
