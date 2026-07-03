import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import 'bloc/settings_bloc.dart';

/// Called from the camera screen's gear icon.
/// Uses the inherited [SettingsBloc] — no need to create a new one.
void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<SettingsBloc>(),
      child: const _SettingsSheet(),
    ),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            children: [
              // ── Handle ────────────────────────────────────
              const SizedBox(height: AppSpacing.md),
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

              // ── Header ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Text('Settings',
                        style: AppTextStyles.headlineMd(context)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceBright,
                        foregroundColor: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),

              // ── Content ───────────────────────────────────
              Expanded(
                child: BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, settings) {
                    final bloc = context.read<SettingsBloc>();
                    return ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      children: [

                        // ── Camera Power ───────────────────────
                        _SettingsTile(
                          icon: Icons.power_settings_new_rounded,
                          iconColor: settings.cameraEnabled
                              ? AppColors.mint
                              : AppColors.outline,
                          title: 'Camera Power',
                          subtitle: 'Enable or disable camera feed',
                          subtitleMono: true,
                          trailing: Switch(
                            value: settings.cameraEnabled,
                            onChanged: (_) =>
                                bloc.add(const CameraEnabledToggled()),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // ── Camera direction ───────────────────
                        _SectionLabel('Camera'),
                        Text(
                          'Active input source',
                          style: AppTextStyles.labelSm(context),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SegmentedRow(
                          options: const ['Front', 'Back'],
                          selected: settings.useFrontCamera ? 0 : 1,
                          onTap: (i) {
                            if ((i == 0) != settings.useFrontCamera) {
                              bloc.add(const CameraDirectionToggled());
                            }
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ── Language ───────────────────────────
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          iconColor: AppColors.mint,
                          title: 'Language',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(settings.language,
                                  style: AppTextStyles.labelSmAccent(context)),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.outline, size: 18),
                            ],
                          ),
                          onTap: () => _showLanguagePicker(context, settings, bloc),
                        ),

                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('Translation Text Size'),
                        const SizedBox(height: AppSpacing.sm),
                        _SegmentedRow(
                          options: const ['Small', 'Medium', 'Large'],
                          selected: settings.textSize,
                          onTap: (i) => bloc.add(TextSizeChanged(i)),
                          monoFont: true,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ── Toggles ────────────────────────────
                        _SettingsTile(
                          icon: Icons.bar_chart_rounded,
                          iconColor: AppColors.mint,
                          title: 'Show Confidence Bar',
                          trailing: Switch(
                            value: settings.showConfidenceBar,
                            onChanged: (_) =>
                                bloc.add(const ConfidenceBarToggled()),
                          ),
                        ),

                        _SettingsTile(
                          icon: Icons.grid_view_rounded,
                          iconColor: AppColors.mint,
                          title: 'Show Landmark Overlay',
                          trailing: Switch(
                            value: settings.showLandmarkOverlay,
                            onChanged: (_) =>
                                bloc.add(const LandmarkOverlayToggled()),
                          ),
                        ),

                        _SettingsTile(
                          icon: Icons.crop_free_rounded,
                          iconColor: AppColors.mint,
                          title: 'Show Frame Guide',
                          trailing: Switch(
                            value: settings.showFrameGuide,
                            onChanged: (_) =>
                                bloc.add(const FrameGuideToggled()),
                          ),
                        ),

                        _SettingsTile(
                          icon: Icons.vibration_rounded,
                          iconColor: AppColors.mint,
                          title: 'Haptic Feedback',
                          trailing: Switch(
                            value: settings.hapticFeedback,
                            onChanged: (_) =>
                                bloc.add(const HapticFeedbackToggled()),
                          ),
                        ),

                        const Divider(height: AppSpacing.xl),

                        // ── Theme (locked) ─────────────────────
                        _SettingsTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: AppColors.outline,
                          title: 'Theme',
                          titleColor: AppColors.outline,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Dark',
                                  style: AppTextStyles.labelSm(context)),
                              const SizedBox(width: 4),
                              const Icon(Icons.lock_outline_rounded,
                                  size: 14, color: AppColors.outline),
                            ],
                          ),
                        ),

                        const Divider(height: AppSpacing.xl),

                        // ── About ──────────────────────────────
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: AppColors.onSurfaceVariant,
                          title: 'About SignLink',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.outline),
                          onTap: () => _showAbout(context),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    SettingsState settings,
    SettingsBloc bloc,
  ) {
    const languages = ['ASL', 'GSL', 'BSL', 'LSF', 'DGS'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('Select Sign Language',
              style: AppTextStyles.headlineMd(context)),
          const SizedBox(height: AppSpacing.md),
          ...languages.map((lang) => ListTile(
                title: Text(lang, style: AppTextStyles.bodyMd(context)),
                trailing: lang == settings.language
                    ? const Icon(Icons.check_rounded, color: AppColors.mint)
                    : null,
                onTap: () {
                  bloc.add(LanguageChanged(lang));
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('About SignLink', style: AppTextStyles.headlineMd(context)),
        content: Text(
          'SignLink v1.0.0 MVP\n\n'
          'Real-time sign language to text translation.\n\n'
          'Built with Flutter · MediaPipe · AI/ML\n\n'
          '© 2025 Team SignLink',
          style: AppTextStyles.bodyMd(context)
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: TextStyle(color: AppColors.mint)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared setting tile ──────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final bool subtitleMono;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleMono = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMd(context).copyWith(
            color: titleColor ?? AppColors.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: subtitleMono
                    ? AppTextStyles.labelSm(context)
                    : AppTextStyles.bodySm(context),
              )
            : null,
        trailing: trailing,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.headlineMd(context),
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  final List<String> options;
  final int selected;
  final void Function(int) onTap;
  final bool monoFont;

  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.onTap,
    this.monoFont = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md - 2),
                ),
                child: Center(
                  child: Text(
                    options[i],
                    style: monoFont
                        ? AppTextStyles.labelSm(context).copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                          )
                        : AppTextStyles.bodyMd(context).copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
