import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/theme/app_theme.dart';
import 'package:memo_places_mobile/theme/theme_provider.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/services/api_client.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/contact_repository.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/translations/codegen_loader.g.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    await CognitoAuthService.configure();
  } on Exception catch (e) {
    // Auth stays unavailable but the map must still work.
    debugPrint('Amplify configuration failed: $e');
  }

  const sessionStore = SessionStore();
  final initialThemeMode = await ThemeProvider.loadSavedMode();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('pl'),
        Locale('de'),
        Locale('ru')
      ],
      assetLoader: const CodegenLoader(),
      path: 'lib/assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(initialMode: initialThemeMode),
          ),
          Provider<SessionStore>.value(value: sessionStore),
          Provider<AuthService>(
            create: (_) => CognitoAuthService(sessionStore),
          ),
          Provider<ApiClient>(
            create: (context) => ApiClient(
              context.read<AuthService>(),
              onUnauthorized: sessionStore.clear,
            ),
          ),
          Provider<CatalogRepository>(
            create: (context) => CatalogRepository(context.read<ApiClient>()),
          ),
          Provider<PlacesRepository>(
            create: (context) => PlacesRepository(
              context.read<ApiClient>(),
              context.read<CatalogRepository>(),
            ),
          ),
          Provider<TrailsRepository>(
            create: (context) => TrailsRepository(
              context.read<ApiClient>(),
              context.read<CatalogRepository>(),
            ),
          ),
          Provider<ContactRepository>(
            create: (context) => ContactRepository(context.read<ApiClient>()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,
      home: const InternetChecker(),
    );
  }
}
