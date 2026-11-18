import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/database.dart';
import 'state/call_controller.dart';
import 'state/detection_controller.dart';
import 'state/history_controller.dart';
import 'state/theme_controller.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/shell.dart';

class AuthentiCallApp extends StatelessWidget {
  const AuthentiCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(create: (_) => HistoryController()),
        ChangeNotifierProvider(create: (_) => DetectionController()),
        ChangeNotifierProxyProvider<DetectionController, CallController>(
          create: (context) =>
              CallController(context.read<DetectionController>())
                ..loadLastChannel(),
          update: (_, detection, controller) =>
              controller ?? CallController(detection),
        ),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'AuthentiCall AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          home: const AppRoot(),
        ),
      ),
    );
  }
}

/// Shows onboarding once, then the main shell.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late bool _onboarded = DatabaseService.instance
          .getSetting<bool>(SettingsKeys.onboarded, fallback: false) ??
      false;

  @override
  Widget build(BuildContext context) {
    if (_onboarded) return const AppShell();
    return OnboardingScreen(
      onFinished: () async {
        await DatabaseService.instance
            .setSetting(SettingsKeys.onboarded, true);
        setState(() => _onboarded = true);
      },
    );
  }
}
