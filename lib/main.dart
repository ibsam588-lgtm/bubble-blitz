import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/game_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/store_screen.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/save_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await SaveService.instance.init();
  await AudioService.instance.init();
  // Fire-and-forget; these may fail on platforms without billing/ads
  AdsService.instance.init();
  IapService.instance.init();

  runApp(const BubbleBlitzApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/menu', builder: (_, __) => const MainMenuScreen()),
    GoRoute(path: '/levels', builder: (_, __) => const LevelSelectScreen()),
    GoRoute(
      path: '/game/:level',
      builder: (_, state) {
        final lvl = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
        return GameScreen(level: lvl);
      },
    ),
    GoRoute(path: '/store', builder: (_, __) => const StoreScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/loading', builder: (_, __) => const LoadingScreen()),
  ],
);

class BubbleBlitzApp extends StatelessWidget {
  const BubbleBlitzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.bubbleBlue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppConstants.uiDark,
        textTheme: GoogleFonts.fredokaTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
