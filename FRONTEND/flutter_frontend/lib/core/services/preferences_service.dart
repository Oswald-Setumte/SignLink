import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences.
/// Stores and reads all persistent app settings.
class PreferencesService {
  PreferencesService._();
  static PreferencesService? _instance;
  static PreferencesService get instance {
    _instance ??= PreferencesService._();
    return _instance!;
  }

  static const _kCameraPermissionGranted = 'camera_permission_granted';
  static const _kCameraEnabled           = 'camera_enabled';
  static const _kUseFrontCamera          = 'use_front_camera';
  static const _kLanguage                = 'sign_language';
  static const _kTextSize                = 'translation_text_size';
  static const _kShowConfidenceBar       = 'show_confidence_bar';
  static const _kShowLandmarkOverlay     = 'show_landmark_overlay';
  static const _kShowFrameGuide          = 'show_frame_guide';
  static const _kHapticFeedback          = 'haptic_feedback';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Camera permission ────────────────────────────────────────
  bool get cameraPermissionGranted =>
      _prefs.getBool(_kCameraPermissionGranted) ?? false;

  Future<void> setCameraPermissionGranted(bool value) =>
      _prefs.setBool(_kCameraPermissionGranted, value);

  // ── Camera power (Settings toggle) ──────────────────────────
  bool get cameraEnabled =>
      _prefs.getBool(_kCameraEnabled) ?? true;

  Future<void> setCameraEnabled(bool value) =>
      _prefs.setBool(_kCameraEnabled, value);

  // ── Camera direction ─────────────────────────────────────────
  bool get useFrontCamera =>
      _prefs.getBool(_kUseFrontCamera) ?? true;

  Future<void> setUseFrontCamera(bool value) =>
      _prefs.setBool(_kUseFrontCamera, value);

  // ── Sign language ────────────────────────────────────────────
  String get language => _prefs.getString(_kLanguage) ?? 'ASL';

  Future<void> setLanguage(String value) =>
      _prefs.setString(_kLanguage, value);

  // ── Text size (0=Small, 1=Medium, 2=Large) ───────────────────
  int get textSize => _prefs.getInt(_kTextSize) ?? 1;

  Future<void> setTextSize(int value) =>
      _prefs.setInt(_kTextSize, value);

  // ── Overlays ─────────────────────────────────────────────────
  bool get showConfidenceBar =>
      _prefs.getBool(_kShowConfidenceBar) ?? true;
  Future<void> setShowConfidenceBar(bool v) =>
      _prefs.setBool(_kShowConfidenceBar, v);

  bool get showLandmarkOverlay =>
      _prefs.getBool(_kShowLandmarkOverlay) ?? true;
  Future<void> setShowLandmarkOverlay(bool v) =>
      _prefs.setBool(_kShowLandmarkOverlay, v);

  bool get showFrameGuide =>
      _prefs.getBool(_kShowFrameGuide) ?? true;
  Future<void> setShowFrameGuide(bool v) =>
      _prefs.setBool(_kShowFrameGuide, v);

  // ── Haptic feedback ──────────────────────────────────────────
  bool get hapticFeedback =>
      _prefs.getBool(_kHapticFeedback) ?? false;
  Future<void> setHapticFeedback(bool v) =>
      _prefs.setBool(_kHapticFeedback, v);
}
