import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/preferences_service.dart';

// ─── State ────────────────────────────────────────────────────
class SettingsState extends Equatable {
  final bool cameraEnabled;
  final bool useFrontCamera;
  final String language;
  final int textSize; // 0=Small, 1=Medium, 2=Large
  final bool showConfidenceBar;
  final bool showLandmarkOverlay;
  final bool showFrameGuide;
  final bool hapticFeedback;

  const SettingsState({
    required this.cameraEnabled,
    required this.useFrontCamera,
    required this.language,
    required this.textSize,
    required this.showConfidenceBar,
    required this.showLandmarkOverlay,
    required this.showFrameGuide,
    required this.hapticFeedback,
  });

  SettingsState copyWith({
    bool? cameraEnabled,
    bool? useFrontCamera,
    String? language,
    int? textSize,
    bool? showConfidenceBar,
    bool? showLandmarkOverlay,
    bool? showFrameGuide,
    bool? hapticFeedback,
  }) {
    return SettingsState(
      cameraEnabled:      cameraEnabled      ?? this.cameraEnabled,
      useFrontCamera:     useFrontCamera     ?? this.useFrontCamera,
      language:           language           ?? this.language,
      textSize:           textSize           ?? this.textSize,
      showConfidenceBar:  showConfidenceBar  ?? this.showConfidenceBar,
      showLandmarkOverlay:showLandmarkOverlay?? this.showLandmarkOverlay,
      showFrameGuide:     showFrameGuide     ?? this.showFrameGuide,
      hapticFeedback:     hapticFeedback     ?? this.hapticFeedback,
    );
  }

  @override
  List<Object?> get props => [
    cameraEnabled, useFrontCamera, language, textSize,
    showConfidenceBar, showLandmarkOverlay, showFrameGuide, hapticFeedback,
  ];
}

// ─── Events ───────────────────────────────────────────────────
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override List<Object?> get props => [];
}

class SettingsLoaded            extends SettingsEvent { const SettingsLoaded(); }
class CameraEnabledToggled      extends SettingsEvent { const CameraEnabledToggled(); }
class CameraDirectionToggled    extends SettingsEvent { const CameraDirectionToggled(); }
class LanguageChanged           extends SettingsEvent {
  final String language;
  const LanguageChanged(this.language);
  @override List<Object?> get props => [language];
}
class TextSizeChanged           extends SettingsEvent {
  final int size;
  const TextSizeChanged(this.size);
  @override List<Object?> get props => [size];
}
class ConfidenceBarToggled      extends SettingsEvent { const ConfidenceBarToggled(); }
class LandmarkOverlayToggled    extends SettingsEvent { const LandmarkOverlayToggled(); }
class FrameGuideToggled         extends SettingsEvent { const FrameGuideToggled(); }
class HapticFeedbackToggled     extends SettingsEvent { const HapticFeedbackToggled(); }

// ─── BLoC ─────────────────────────────────────────────────────
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final PreferencesService _prefs;

  SettingsBloc({PreferencesService? prefs})
      : _prefs = prefs ?? PreferencesService.instance,
        super(SettingsState(
          cameraEnabled:       PreferencesService.instance.cameraEnabled,
          useFrontCamera:      PreferencesService.instance.useFrontCamera,
          language:            PreferencesService.instance.language,
          textSize:            PreferencesService.instance.textSize,
          showConfidenceBar:   PreferencesService.instance.showConfidenceBar,
          showLandmarkOverlay: PreferencesService.instance.showLandmarkOverlay,
          showFrameGuide:      PreferencesService.instance.showFrameGuide,
          hapticFeedback:      PreferencesService.instance.hapticFeedback,
        )) {
    on<SettingsLoaded>(_onLoaded);
    on<CameraEnabledToggled>(_onCameraEnabled);
    on<CameraDirectionToggled>(_onCameraDirection);
    on<LanguageChanged>(_onLanguage);
    on<TextSizeChanged>(_onTextSize);
    on<ConfidenceBarToggled>(_onConfidenceBar);
    on<LandmarkOverlayToggled>(_onLandmarkOverlay);
    on<FrameGuideToggled>(_onFrameGuide);
    on<HapticFeedbackToggled>(_onHaptic);
  }

  void _onLoaded(SettingsLoaded e, Emitter<SettingsState> emit) {
    emit(state.copyWith(
      cameraEnabled:       _prefs.cameraEnabled,
      useFrontCamera:      _prefs.useFrontCamera,
      language:            _prefs.language,
      textSize:            _prefs.textSize,
      showConfidenceBar:   _prefs.showConfidenceBar,
      showLandmarkOverlay: _prefs.showLandmarkOverlay,
      showFrameGuide:      _prefs.showFrameGuide,
      hapticFeedback:      _prefs.hapticFeedback,
    ));
  }

  void _onCameraEnabled(CameraEnabledToggled e, Emitter<SettingsState> emit) {
    final next = !state.cameraEnabled;
    _prefs.setCameraEnabled(next);
    emit(state.copyWith(cameraEnabled: next));
  }

  void _onCameraDirection(CameraDirectionToggled e, Emitter<SettingsState> emit) {
    final next = !state.useFrontCamera;
    _prefs.setUseFrontCamera(next);
    emit(state.copyWith(useFrontCamera: next));
  }

  void _onLanguage(LanguageChanged e, Emitter<SettingsState> emit) {
    _prefs.setLanguage(e.language);
    emit(state.copyWith(language: e.language));
  }

  void _onTextSize(TextSizeChanged e, Emitter<SettingsState> emit) {
    _prefs.setTextSize(e.size);
    emit(state.copyWith(textSize: e.size));
  }

  void _onConfidenceBar(ConfidenceBarToggled e, Emitter<SettingsState> emit) {
    final next = !state.showConfidenceBar;
    _prefs.setShowConfidenceBar(next);
    emit(state.copyWith(showConfidenceBar: next));
  }

  void _onLandmarkOverlay(LandmarkOverlayToggled e, Emitter<SettingsState> emit) {
    final next = !state.showLandmarkOverlay;
    _prefs.setShowLandmarkOverlay(next);
    emit(state.copyWith(showLandmarkOverlay: next));
  }

  void _onFrameGuide(FrameGuideToggled e, Emitter<SettingsState> emit) {
    final next = !state.showFrameGuide;
    _prefs.setShowFrameGuide(next);
    emit(state.copyWith(showFrameGuide: next));
  }

  void _onHaptic(HapticFeedbackToggled e, Emitter<SettingsState> emit) {
    final next = !state.hapticFeedback;
    _prefs.setHapticFeedback(next);
    emit(state.copyWith(hapticFeedback: next));
  }
}
