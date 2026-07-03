import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/router/app_router.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_theme.dart';
import '../shared/widgets/signlink_wordmark.dart';

class CameraPermissionScreen extends StatefulWidget {
  const CameraPermissionScreen({super.key});

  @override
  State<CameraPermissionScreen> createState() => _CameraPermissionScreenState();
}

class _CameraPermissionScreenState extends State<CameraPermissionScreen>
    with SingleTickerProviderStateMixin {
  bool _granted = false;
  bool _loading = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    // Pre-check in case permission was already granted before
    _checkExistingPermission();
  }

  Future<void> _checkExistingPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted && mounted) {
      setState(() => _granted = true);
      await PreferencesService.instance.setCameraPermissionGranted(true);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _loading = true);

    final status = await Permission.camera.request();

    if (!mounted) return;
    setState(() => _loading = false);

    if (status.isGranted) {
      await PreferencesService.instance.setCameraPermissionGranted(true);
      setState(() => _granted = true);

      // Navigate to translation screen after brief delay so user sees "Access Granted"
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.translation);
      }
    } else if (status.isPermanentlyDenied) {
      // User denied permanently — open app settings
      await openAppSettings();
    } else {
      // Denied but not permanent — show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceContainerHigh,
            content: Text(
              'Camera access is required for sign language translation.',
              style: AppTextStyles.bodySm(context).copyWith(color: AppColors.onSurface),
            ),
            action: SnackBarAction(
              label: 'Settings',
              textColor: AppColors.mint,
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  void _skip() {
    // Skip — app loads but camera won't work; user can grant later from settings
    Navigator.of(context).pushReplacementNamed(AppRouter.translation);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const SignLinkWordmark(size: 18, showIcon: true),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'SKIP',
                      style: AppTextStyles.labelSm(context).copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.06),

                    // ── Camera icon with glow ─────────────────
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.mint.withOpacity(0.18 * _glowAnim.value),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Icon circle
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _granted
                                      ? AppColors.mint.withOpacity(0.6)
                                      : AppColors.whiteBorder10,
                                  width: _granted ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _granted
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          key: const ValueKey('check'),
                                          color: AppColors.mint,
                                          size: 56,
                                        )
                                      : Icon(
                                          Icons.videocam_rounded,
                                          key: const ValueKey('cam'),
                                          color: AppColors.primary,
                                          size: 56,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Headline ─────────────────────────────
                    Text(
                      'SignLink needs\ncamera access',
                      style: AppTextStyles.headlineLgMobile(context),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Body text ─────────────────────────────
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.bodyMd(context).copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'To translate sign language in real time. For your privacy, video is processed ',
                          ),
                          TextSpan(
                            text: 'entirely on-device',
                            style: TextStyle(
                              color: AppColors.mint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: ' and never leaves your phone.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Privacy card ──────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppColors.mint,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Private by Design',
                                  style: AppTextStyles.bodyMd(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'All processing happens on-device.',
                                  style: AppTextStyles.labelSm(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Primary button ────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _granted
                            ? _GrantedButton(key: const ValueKey('granted'))
                            : _AllowButton(
                                key: const ValueKey('allow'),
                                loading: _loading,
                                onTap: _requestPermission,
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── "How does this work?" ──────────────────
                    TextButton(
                      onPressed: () => _showHowItWorks(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'How does this work?',
                            style: AppTextStyles.bodySm(context).copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.outline,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Bottom trust badges ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TrustBadge(
                          icon: Icons.lock_outline_rounded,
                          label: 'E2E Encrypted',
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        _TrustBadge(
                          icon: Icons.verified_user_outlined,
                          label: 'Privacy Certified',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('How SignLink Works',
                style: AppTextStyles.headlineMd(context)),
            const SizedBox(height: AppSpacing.md),
            _HowItWorksItem(
              icon: Icons.videocam_rounded,
              title: 'Camera captures your hands',
              body:
                  'The camera stream is processed locally on your device at 30fps.',
            ),
            _HowItWorksItem(
              icon: Icons.psychology_rounded,
              title: 'AI recognises sign gestures',
              body:
                  'MediaPipe detects 21 hand landmarks. A custom ML model classifies each sign.',
            ),
            _HowItWorksItem(
              icon: Icons.text_fields_rounded,
              title: 'Text appears in real time',
              body:
                  'Recognised signs are converted to words and displayed live below the camera feed.',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _AllowButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _AllowButton({super.key, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              'Allow Camera Access',
              style: AppTextStyles.bodyMd(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _GrantedButton extends StatelessWidget {
  const _GrantedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer.withOpacity(0.4),
        foregroundColor: AppColors.mint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.mint.withOpacity(0.4), width: 1),
        ),
        elevation: 0,
      ),
      icon: const Icon(Icons.check_rounded, color: AppColors.mint),
      label: Text(
        'Access Granted',
        style: AppTextStyles.bodyMd(context).copyWith(
          color: AppColors.mint,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.outline),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSm(context)),
      ],
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HowItWorksItem(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.mint, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMd(context)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.bodySm(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
