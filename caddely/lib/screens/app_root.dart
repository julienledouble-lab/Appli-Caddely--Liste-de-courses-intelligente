import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_preferences_provider.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final appPreferences = context.watch<AppPreferencesProvider>();

    if (appPreferences.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!appPreferences.hasCompletedOnboarding) {
      return const OnboardingScreen();
    }

    return const MainShell();
  }
}
