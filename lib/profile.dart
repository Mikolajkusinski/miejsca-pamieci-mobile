import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/contact_us_form.dart';
import 'package:memo_places_mobile/edit_profile.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/my_places.dart';
import 'package:memo_places_mobile/my_trails.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/theme/theme_provider.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const _languages = [
    (Locale('en'), 'English'),
    (Locale('pl'), 'Polski'),
    (Locale('de'), 'Deutsch'),
    (Locale('ru'), 'Русский'),
  ];

  late final Future<User?> _userFuture = loadUserData();

  Future<void> _signOut() async {
    // Clears Amplify credentials and the stored session.
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const InternetChecker()),
      (route) => false,
    );
  }

  void _pickLanguage() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (locale, label) in _languages)
              ListTile(
                title: Text(label),
                trailing: context.locale == locale
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await context.setLocale(locale);
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickThemeMode() {
    final provider = context.read<ThemeProvider>();
    final entries = [
      (ThemeMode.system, LocaleKeys.theme_system.tr(), Icons.brightness_auto),
      (ThemeMode.light, LocaleKeys.theme_light.tr(), Icons.light_mode),
      (ThemeMode.dark, LocaleKeys.theme_dark.tr(), Icons.dark_mode),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (mode, label, icon) in entries)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: provider.themeMode == mode
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  provider.setThemeMode(mode);
                  Navigator.pop(sheetContext);
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, User user) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primary,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: textTheme.titleLarge!.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  user.email,
                  style: textTheme.bodyMedium!
                      .copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _currentLanguageLabel {
    for (final (locale, label) in _languages) {
      if (context.locale == locale) return label;
    }
    return _languages.first.$2;
  }

  String get _currentThemeLabel => switch (
          context.watch<ThemeProvider>().themeMode) {
        ThemeMode.system => LocaleKeys.theme_system.tr(),
        ThemeMode.light => LocaleKeys.theme_light.tr(),
        ThemeMode.dark => LocaleKeys.theme_dark.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.profile.tr())),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            // Session vanished (expired / cleared) — back to the entry flow.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: FilledButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InternetChecker()),
                    (route) => false,
                  ),
                  child: Text(LocaleKeys.sign_in.tr()),
                ),
              ),
            );
          }
          return ListView(
            children: [
              _header(context, user),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(LocaleKeys.language.tr()),
                subtitle: Text(_currentLanguageLabel),
                onTap: _pickLanguage,
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(LocaleKeys.theme_mode.tr()),
                subtitle: Text(_currentThemeLabel),
                onTap: _pickThemeMode,
              ),
              const Divider(height: 8),
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(LocaleKeys.edit_profile.tr()),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditProfile(user)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(LocaleKeys.my_places.tr()),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPlaces()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: Text(LocaleKeys.my_trails.tr()),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyTrails()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(LocaleKeys.contact_us.tr()),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactUsForm()),
                ),
              ),
              const Divider(height: 8),
              ListTile(
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text(
                  LocaleKeys.sign_out.tr(),
                  style: TextStyle(color: scheme.error),
                ),
                onTap: _signOut,
              ),
            ],
          );
        },
      ),
    );
  }
}
