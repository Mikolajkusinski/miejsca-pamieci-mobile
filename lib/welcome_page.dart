import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/map/map_shell.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _continue(BuildContext context) async {
    // Persist only on explicit continue — not during build.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomePageDisplayed', true);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MapShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred map hero — the map is the app.
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Image.asset(
              'lib/assets/images/map_hero.png',
              fit: BoxFit.cover,
            ),
          ),
          // Scrim so the copy stays readable in both themes.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface.withValues(alpha: 0.55),
                  scheme.surface.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset(
                    'lib/assets/images/logo_memory_places.png',
                    width: 180,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    LocaleKeys.welcome.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LocaleKeys.welcome_tagline.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _continue(context),
                    child: Text(LocaleKeys.continue_btn.tr()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
