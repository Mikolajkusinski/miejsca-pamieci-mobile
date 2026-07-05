import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/map/map_shell.dart';
import 'package:memo_places_mobile/offline_page.dart';
import 'package:memo_places_mobile/offline_place_adding_page.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/welcome_page.dart';

class _StartupState {
  final bool online;
  final bool welcomeSeen;
  final User? user;

  const _StartupState(
      {required this.online, required this.welcomeSeen, required this.user});
}

/// Startup router: decides between the offline pages, the welcome page and
/// the main shell from ONE future — no late fields racing the build.
class InternetChecker extends StatefulWidget {
  const InternetChecker({super.key});

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> {
  late final Future<_StartupState> _startup = _loadStartupState();

  Future<_StartupState> _loadStartupState() async {
    final welcomeSeen = await loadBoolLocalData('welcomePageDisplayed');
    final user = await loadUserData();
    final connectivity = await Connectivity().checkConnectivity();

    // Ethernet and VPN count as online too.
    const onlineKinds = {
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
      ConnectivityResult.vpn,
    };

    return _StartupState(
      online: connectivity.any(onlineKinds.contains),
      welcomeSeen: welcomeSeen ?? false,
      user: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupState>(
      future: _startup,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!state.online) {
          return state.user != null
              ? const OfflinePlaceAddingPage()
              : const OfflinePage();
        }
        if (!state.welcomeSeen) {
          return const WelcomePage();
        }
        return const MapShell();
      },
    );
  }
}
