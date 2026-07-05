import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

/// Startup dead end for signed-out users with no connection.
class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.wifi_off, size: 72, color: scheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.oops.tr(),
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.no_internet_info.tr(),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium!
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InternetChecker()),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: Text(LocaleKeys.refresh.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
