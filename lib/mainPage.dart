import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/offline_sync_service.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/home.dart';
import 'package:memo_places_mobile/profile.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/signInOrSignUpPage.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Main> {
  late User? _user;
  int _currentIndex = 0;
  bool _isLogged = false;
  late List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens = [const Home(), const Profile()];
    loadUserData().then((value) {
      if (!mounted) return;
      setState(() {
        _user = value;
        _isLogged = _user != null;
      });
      if (_user != null) {
        _syncCatalogData();
        _syncOfflinePlaces();
      }
    });
  }

  Future<void> _syncOfflinePlaces() async {
    final service = OfflineSyncService(context.read<PlacesRepository>());
    final report = await service.syncPlaces();
    if (report.total == 0) return;
    if (report.failed == 0) {
      showSuccesToast(LocaleKeys.stored_places_upload_succes.tr());
    } else {
      showErrorToast(
        LocaleKeys.sync_result.tr(
          namedArgs: {
            'ok': report.succeeded.toString(),
            'failed': report.failed.toString(),
          },
        ),
      );
    }
  }

  /// Caches types/sortofs/periods for offline forms; failures are non-fatal
  /// (the previously cached catalogs stay in place).
  Future<void> _syncCatalogData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (!mounted) return;
      final List<Type> types = await fetchTypes(context);
      await prefs.setString(
        'types',
        jsonEncode([for (final t in types) t.toJson()]),
      );
      if (!mounted) return;
      final List<Period> periods = await fetchPeriods(context);
      await prefs.setString(
        'periods',
        jsonEncode([for (final p in periods) p.toJson()]),
      );
      if (!mounted) return;
      final List<Sortof> sortofs = await fetchSortof(context);
      await prefs.setString(
        'sortofs',
        jsonEncode([for (final s in sortofs) s.toJson()]),
      );
    } on ApiException {
      // Offline or backend unavailable — keep the cached catalogs.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLogged ? _screens[_currentIndex] : const Home(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            label: LocaleKeys.home.tr(),
            icon: const Icon(Icons.home, size: 27),
          ),
          BottomNavigationBarItem(
            label: LocaleKeys.profile.tr(),
            icon: const Icon(Icons.account_box_outlined, size: 27),
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (int index) {
          if (index == 1 && !_isLogged) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignInOrSingUpPage(),
              ),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
