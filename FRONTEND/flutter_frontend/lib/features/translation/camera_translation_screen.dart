import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../settings/bloc/settings_bloc.dart';
import '../settings/settings_sheet.dart';
import '../shared/widgets/signlink_wordmark.dart';
import 'bloc/translation_bloc.dart';
import 'widgets/landmark_painter.dart';

class CameraTranslationScreen extends StatefulWidget {
  const CameraTranslationScreen({super.key});

  @override
  State<CameraTranslationScreen> createState() =>
      _CameraTranslationScreenState();
}

class _CameraTranslationScreenState extends State<CameraTranslationScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _isTranslating = true;

  // Frame-send throttle — send 1 frame every 100ms (≈10fps to backend)
  Timer? _frameTimer;
  static const _frameInterval = Duration(milliseconds: 100);

  // Confidence bar animation
  late AnimationController _confAnimCtrl;
  late Animation<double> _confAnim;
  double _targetConfidence = 0.0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _confAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _confAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _confAnimCtrl, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  // ── Camera lifecycle ──────────────────────────────────────────

  Future<void> _initCamera() async {
    final settings = context.read<SettingsBloc>().state;
    if (!settings.cameraEnabled) return;

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    await _startCamera(settings.useFrontCamera);
  }

  Future<void> _startCamera(bool useFront) async {
    await _cameraController?.dispose();
    _cameraController = null;
    if (mounted) setState(() => _cameraReady = false);

    final description = _selectCamera(useFront);
    if (description == null) return;

    final ctrl = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await ctrl.initialize();
    } catch (e) {
      return;
    }

    if (!mounted) {
      await ctrl.dispose();
      return;
    }

    _cameraController = ctrl;
    setState(() => _cameraReady = true);

    // Start translation & frame streaming
    _startTranslation();
  }

  CameraDescription? _selectCamera(bool useFront) {
    final lensDir =
        useFront ? CameraLensDirection.front : CameraLensDirection.back;
    try {
      return _cameras.firstWhere((c) => c.lensDirection == lensDir);
    } catch (_) {
      return _cameras.isNotEmpty ? _cameras.first : null;
    }
  }

  void _startTranslation() {
    if (!mounted) return;
    final lang = context.read<SettingsBloc>().state.language;
    context.read<TranslationBloc>().add(TranslationStarted(lang));

    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(_frameInterval, (_) => _captureAndSend());
    setState(() => _isTranslating = true);
  }

  void _stopTranslation() {
    _frameTimer?.cancel();
    context.read<TranslationBloc>().add(const TranslationStopped());
    setState(() => _isTranslating = false);
  }

  Future<void> _captureAndSend() async {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized || !_isTranslating) return;

    try {
      final xFile = await ctrl.takePicture();
      final bytes = await xFile.readAsBytes();
      if (mounted) {
        context.read<TranslationBloc>().add(FrameCaptured(bytes));
      }
    } catch (_) {
      // Frame capture failed (e.g. already capturing) — skip this tick
    }
  }

  void _toggleTranslation() {
    if (_isTranslating) {
      _stopTranslation();
    } else {
      _startTranslation();
    }
  }

  void _flipCamera() async {
    final bloc = context.read<SettingsBloc>();
    bloc.add(const CameraDirectionToggled());
    await _startCamera(!bloc.state.useFrontCamera);
  }

  // Called when settings change camera power
  Future<void> _handleCameraEnabled(bool enabled) async {
    if (enabled) {
      final settings = context.read<SettingsBloc>().state;
      await _startCamera(settings.useFrontCamera);
    } else {
      _stopTranslation();
      await _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  // ── App lifecycle ─────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _stopTranslation();
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(context.read<SettingsBloc>().state.useFrontCamera);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameTimer?.cancel();
    _cameraController?.dispose();
    _confAnimCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) => prev.cameraEnabled != curr.cameraEnabled ||
          prev.useFrontCamera != curr.useFrontCamera,
      listener: (context, settings) {
        if (settings.cameraEnabled) {
          _handleCameraEnabled(true);
        } else {
          _handleCameraEnabled(false);
        }
      },
      child: BlocListener<TranslationBloc, TranslationState>(
        listenWhen: (prev, curr) => prev.confidence != curr.confidence,
        listener: (context, state) {
          _targetConfidence = state.confidence;
          _confAnim = Tween<double>(
            begin: _confAnim.value,
            end: _targetConfidence,
          ).animate(
              CurvedAnimation(parent: _confAnimCtrl, curve: Curves.easeOut));
          _confAnimCtrl.forward(from: 0);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return BlocBuilder<TranslationBloc, TranslationState>(
          builder: (context, translation) {
            return Stack(
              children: [
                // ── Camera feed (base layer) ──────────────────
                _CameraLayer(
                  controller: _cameraController,
                  ready: _cameraReady,
                  cameraEnabled: settings.cameraEnabled,
                ),

                // ── Landmark overlay ──────────────────────────
                if (settings.showLandmarkOverlay &&
                    translation.landmarks.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LandmarkPainter(
                        landmarks: translation.landmarks,
                        previewSize: _cameraController != null
                            ? Size(
                                _cameraController!.value.previewSize!.width,
                                _cameraController!.value.previewSize!.height,
                              )
                            : Size.zero,
                      ),
                    ),
                  ),

                // ── Vignette ──────────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Frame guide ───────────────────────────────
                if (settings.showFrameGuide)
                  _FrameGuide(handsDetected: translation.landmarks.isNotEmpty),

                // ── Confidence bar (right edge) ───────────────
                if (settings.showConfidenceBar)
                  _ConfidenceBar(animation: _confAnim),

                // ── Top bar ───────────────────────────────────
                _TopBar(
                  isTranslating: _isTranslating,
                  statusLabel: translation.statusLabel,
                  onSettingsTap: () => showSettingsSheet(context),
                ),

                // ── Bottom panel ──────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomPanel(
                    translationText: translation.translationText,
                    textSize: settings.textSize,
                    isTranslating: _isTranslating,
                    onClear: () => context
                        .read<TranslationBloc>()
                        .add(const TranslationCleared()),
                    onFlip: _flipCamera,
                    onToggle: _toggleTranslation,
                    onCopy: () {
                      Clipboard.setData(
                          ClipboardData(text: translation.translationText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          content: Text('Copied to clipboard',
                              style: AppTextStyles.bodySm(context)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  CAMERA LAYER
// ════════════════════════════════════════════════════════════════
class _CameraLayer extends StatelessWidget {
  final CameraController? controller;
  final bool ready;
  final bool cameraEnabled;

  const _CameraLayer({
    required this.controller,
    required this.ready,
    required this.cameraEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraEnabled) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded,
                  color: AppColors.outline, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text('Camera is off',
                  style: AppTextStyles.bodyMd(context)
                      .copyWith(color: AppColors.outline)),
              const SizedBox(height: AppSpacing.sm),
              Text('Enable it from Settings',
                  style: AppTextStyles.bodySm(context)),
            ],
          ),
        ),
      );
    }

    if (!ready || controller == null) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.mint),
        ),
      );
    }

    return Positioned.fill(
      child: CameraPreview(controller!),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  TOP BAR
// ════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final bool isTranslating;
  final String statusLabel;
  final VoidCallback onSettingsTap;

  const _TopBar({
    required this.isTranslating,
    required this.statusLabel,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withOpacity(0.85),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // FPS badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('30FPS',
                    style: AppTextStyles.labelSm(context)
                        .copyWith(color: AppColors.tertiary, fontSize: 10)),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Wordmark
              const SignLinkWordmark(size: 18, showIcon: true),

              const Spacer(),

              // Live status pill
              _LivePill(isActive: isTranslating, label: statusLabel),

              const SizedBox(width: AppSpacing.sm),

              // Settings gear
              GestureDetector(
                onTap: onSettingsTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.whiteBorder10),
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: AppColors.onSurface, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePill extends StatefulWidget {
  final bool isActive;
  final String label;

  const _LivePill({required this.isActive, required this.label});

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: widget.isActive
              ? AppColors.mint.withOpacity(0.4)
              : AppColors.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppColors.mint
                        .withOpacity(0.5 + _pulse.value * 0.5)
                    : AppColors.outline,
                shape: BoxShape.circle,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: AppColors.mint
                              .withOpacity(0.4 * _pulse.value),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            widget.isActive ? 'LIVE' : 'PAUSED',
            style: AppTextStyles.labelSm(context).copyWith(
              color: widget.isActive ? AppColors.mint : AppColors.outline,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  FRAME GUIDE
// ════════════════════════════════════════════════════════════════
class _FrameGuide extends StatelessWidget {
  final bool handsDetected;

  const _FrameGuide({required this.handsDetected});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: handsDetected ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 600),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.72,
              heightFactor: 0.42,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.mint.withOpacity(0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      child: Text(
                        'POSITION HANDS WITHIN FRAME',
                        style: AppTextStyles.labelSm(context).copyWith(
                          color: AppColors.onSurfaceVariant.withOpacity(0.8),
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  CONFIDENCE BAR (right edge)
// ════════════════════════════════════════════════════════════════
class _ConfidenceBar extends StatelessWidget {
  final Animation<double> animation;

  const _ConfidenceBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AppSpacing.md,
      top: 100,
      bottom: 320, // above bottom panel
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RotatedBox(
            quarterTurns: -1,
            child: Text('Confidence',
                style: AppTextStyles.labelSm(context).copyWith(fontSize: 9)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, __) => FractionallySizedBox(
                  heightFactor: 1.0,
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: animation.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.primaryContainer, AppColors.mint],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  BOTTOM PANEL
// ════════════════════════════════════════════════════════════════
class _BottomPanel extends StatelessWidget {
  final String translationText;
  final int textSize;
  final bool isTranslating;
  final VoidCallback onClear;
  final VoidCallback onFlip;
  final VoidCallback onToggle;
  final VoidCallback onCopy;

  const _BottomPanel({
    required this.translationText,
    required this.textSize,
    required this.isTranslating,
    required this.onClear,
    required this.onFlip,
    required this.onToggle,
    required this.onCopy,
  });

  double get _fontSize {
    switch (textSize) {
      case 0: return 16.0;
      case 2: return 24.0;
      default: return 20.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        border: Border.all(color: AppColors.whiteBorder10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Translation header ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'TRANSLATION',
                  style: AppTextStyles.labelSm(context)
                      .copyWith(letterSpacing: 2),
                ),
                const Spacer(),
                BlocBuilder<TranslationBloc, TranslationState>(
                  builder: (context, state) => Text(
                    state.statusLabel,
                    style: AppTextStyles.labelSm(context)
                        .copyWith(color: AppColors.mint),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Translation text ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: _TranslationTextField(
                text: translationText,
                fontSize: _fontSize,
              ),
            ),
          ),

          // ── Divider ────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Divider(height: AppSpacing.lg),
          ),

          // ── Common sign chips ──────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => _Chip(label: _chips[i]),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Action bar ─────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flip camera
                  _ActionIcon(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: onFlip,
                    tooltip: 'Flip',
                  ),
                  // Clear
                  _ActionIcon(
                    icon: Icons.history_rounded,
                    onTap: onClear,
                    tooltip: 'Clear',
                  ),
                  // Start / Stop (primary FAB)
                  _MainFAB(
                    isTranslating: isTranslating,
                    onTap: onToggle,
                  ),
                  // Settings shortcut
                  _ActionIcon(
                    icon: Icons.settings_rounded,
                    onTap: () => showSettingsSheet(context),
                    tooltip: 'Settings',
                  ),
                  // Help
                  _ActionIcon(
                    icon: Icons.help_outline_rounded,
                    onTap: () => _showHelp(context),
                    tooltip: 'Help',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        content: Text(
          'Point camera at your hands and sign. Text appears automatically.',
          style: AppTextStyles.bodySm(context),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Translation text field with blinking cursor ───────────────
class _TranslationTextField extends StatefulWidget {
  final String text;
  final double fontSize;

  const _TranslationTextField({required this.text, required this.fontSize});

  @override
  State<_TranslationTextField> createState() => _TranslationTextFieldState();
}

class _TranslationTextFieldState extends State<_TranslationTextField>
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
    return SingleChildScrollView(
      reverse: true,
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.translationOutput(context).copyWith(
            fontSize: widget.fontSize,
          ),
          children: [
            TextSpan(
              text: widget.text.isEmpty
                  ? ''
                  : widget.text,
            ),
            WidgetSpan(
              child: AnimatedBuilder(
                animation: _blink,
                builder: (_, __) => Opacity(
                  opacity: _blink.value,
                  child: Container(
                    width: 3,
                    height: widget.fontSize * 1.2,
                    margin: const EdgeInsets.only(left: 2),
                    color: AppColors.mint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chips ────────────────────────────────────────────────────

const _chips = ['Hello', 'Thank you', 'Help', 'Emergency', 'Yes', 'No'];

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMd(context).copyWith(fontSize: 14),
      ),
    );
  }
}

// ── Action icons ─────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceBright,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
        ),
      ),
    );
  }
}

// ── Main FAB ──────────────────────────────────────────────────
class _MainFAB extends StatefulWidget {
  final bool isTranslating;
  final VoidCallback onTap;

  const _MainFAB({required this.isTranslating, required this.onTap});

  @override
  State<_MainFAB> createState() => _MainFABState();
}

class _MainFABState extends State<_MainFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ring,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isTranslating)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.mint
                        .withOpacity(0.2 + _ring.value * 0.4),
                    width: 2,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.isTranslating
                    ? AppColors.primaryContainer
                    : AppColors.surfaceBright,
                shape: BoxShape.circle,
                boxShadow: widget.isTranslating
                    ? [
                        BoxShadow(
                          color: AppColors.mint.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                widget.isTranslating
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                color: widget.isTranslating
                    ? Colors.white
                    : AppColors.onSurfaceVariant,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
