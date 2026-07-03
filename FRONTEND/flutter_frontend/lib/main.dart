import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/bloc/settings_bloc.dart';
import 'features/translation/bloc/translation_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status + nav bar (edge-to-edge)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Make system bars transparent
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Init persistent preferences
  await PreferencesService.instance.init();

  runApp(const SignLinkApp());
}

class SignLinkApp extends StatelessWidget {
  const SignLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc()..add(const SettingsLoaded()),
          lazy: false,
        ),
        BlocProvider<TranslationBloc>(
          create: (_) => TranslationBloc(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'SignLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark, // always dark — locked by design
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
