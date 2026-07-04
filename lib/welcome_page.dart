import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/formWidgets/custom_button.dart';
import 'package:memo_places_mobile/main_page.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'lib/assets/images/logo_memory_places.png',
                      width: 300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    LocaleKeys.welcome.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 34),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    LocaleKeys.welcome_msg.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                      onPressed: () async {
                        // Persist only on explicit continue — not during build.
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('welcomePageDisplayed', true);
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Main(),
                          ),
                        );
                      },
                      text: LocaleKeys.continue_btn.tr())
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
