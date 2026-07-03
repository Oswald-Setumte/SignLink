import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/permission/camera_permission_screen.dart';
import '../../features/translation/camera_translation_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash     = '/';
  static const String permission = '/permission';
  static const String translation = '/translation';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      case permission:
        return _fadeRoute(const CameraPermissionScreen(), settings);
      case translation:
        return _fadeRoute(const CameraTranslationScreen(), settings);
      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
