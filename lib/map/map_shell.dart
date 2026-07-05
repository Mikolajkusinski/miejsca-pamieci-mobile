import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/short_place.dart';
import 'package:memo_places_mobile/Objects/short_trail.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/map/map_fab_column.dart';
import 'package:memo_places_mobile/map/map_selection.dart';
import 'package:memo_places_mobile/map/map_top_bar.dart';
import 'package:memo_places_mobile/map/marker_factory.dart';
import 'package:memo_places_mobile/map/memory_sheet.dart';
import 'package:memo_places_mobile/place_form.dart';
import 'package:memo_places_mobile/profile.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/services/location_service.dart';
import 'package:memo_places_mobile/services/offline_sync_service.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/services/session_store.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/sign_in_or_sign_up_page.dart';
import 'package:memo_places_mobile/theme/app_colors.dart';
import 'package:memo_places_mobile/theme/theme_provider.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/trail_record_page.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The home experience: a full-bleed map with floating controls. Every other
/// surface (search, profile, details) is an overlay or sheet on top of it.
class MapShell extends StatefulWidget {
  final LocationService locationService;

  /// Tests substitute the platform-view map with a plain widget.
  final Widget? mapOverride;

  const MapShell(
      {super.key,
      this.locationService = const LocationService(),
      this.mapOverride});

  @override
  State<MapShell> createState() => _MapShellState();
}

class _MapShellState extends State<MapShell> {
  /// Map centre when the user's location is unavailable: Poland.
  static const _fallbackPosition = LatLng(52.06, 19.48);

  GoogleMapController? _mapController;
  String? _mapStyleString;
  late final ThemeProvider _themeProvider;

  Session? _session;
  List<ShortPlace> _places = [];
  Map<int, ShortTrail> _trails = {};
  Map<int, List<LatLng>> _trailCoordinates = {};
  MapSelection? _selection;
  bool _loadFailed = false;
  bool _markersReady = false;

  LatLng _position = _fallbackPosition;
  bool _hasLocation = false;
  LocationResult? _locationResult;
  StreamSubscription<Position>? _positionSubscription;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _themeProvider = context.read<ThemeProvider>()..addListener(_loadMapStyle);
    _loadMapStyle();
    MarkerFactory.load().then((_) {
      if (mounted) setState(() => _markersReady = true);
    });
    _loadSession();
    _resolveLocation();
    _loadMapData();
    _watchConnectivity();
  }

  /// Offline is a banner on the map now, not a separate page — the app
  /// stays usable and data reloads once the connection returns.
  void _watchConnectivity() {
    const onlineKinds = {
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
      ConnectivityResult.vpn,
    };
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final nowOffline = !results.any(onlineKinds.contains);
      if (nowOffline == _offline) return;
      setState(() => _offline = nowOffline);
      if (!nowOffline && (_loadFailed || _places.isEmpty)) _loadMapData();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _mapController?.dispose();
    _themeProvider.removeListener(_loadMapStyle);
    _searchController.dispose();
    super.dispose();
  }

  bool get _isDarkMode {
    final mode = _themeProvider.themeMode;
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  Future<void> _loadMapStyle() async {
    final stylePath = _isDarkMode
        ? 'lib/assets/map_styles/dark_map_style.json'
        : 'lib/assets/map_styles/light_map_style.json';
    _mapStyleString =
        await DefaultAssetBundle.of(context).loadString(stylePath);
    if (mounted) setState(() {});
  }

  Future<void> _loadSession() async {
    final session = await context.read<SessionStore>().load();
    if (!mounted) return;
    setState(() => _session = session);
    if (session != null) {
      _syncCatalogData();
      _syncOfflinePlaces();
    }
  }

  Future<void> _syncOfflinePlaces() async {
    final service = OfflineSyncService(context.read<PlacesRepository>());
    final report = await service.syncPlaces();
    if (report.total == 0) return;
    if (report.failed == 0) {
      showSuccessToast(LocaleKeys.stored_places_upload_succes.tr());
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
          'types', jsonEncode([for (final t in types) t.toJson()]));
      if (!mounted) return;
      final List<Period> periods = await fetchPeriods(context);
      await prefs.setString(
          'periods', jsonEncode([for (final p in periods) p.toJson()]));
      if (!mounted) return;
      final List<Sortof> sortofs = await fetchSortof(context);
      await prefs.setString(
          'sortofs', jsonEncode([for (final s in sortofs) s.toJson()]));
    } on ApiException {
      // Offline or backend unavailable — keep the cached catalogs.
    }
  }

  Future<void> _loadMapData() async {
    setState(() => _loadFailed = false);
    final placesRepository = context.read<PlacesRepository>();
    final trailsRepository = context.read<TrailsRepository>();
    try {
      final places = await placesRepository.getAll();
      final trails = await trailsRepository.getAll();
      // The path list DTO carries no coordinates; the detail fetch does.
      final details = await Future.wait(
          trails.map((trail) => trailsRepository.getById(trail.id)));
      if (!mounted) return;
      setState(() {
        _places = places;
        _trails = {for (final trail in trails) trail.id: trail};
        _trailCoordinates = {
          for (final detail in details) detail.id: detail.coordinates
        };
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  Future<void> _resolveLocation() async {
    final result = await widget.locationService.getCurrent();
    if (!mounted) return;
    setState(() {
      _locationResult = result;
      if (result is LocationOk) {
        _position =
            LatLng(result.position.latitude, result.position.longitude);
        _hasLocation = true;
      }
    });
    if (result is LocationOk) {
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_position, 12));
      _positionSubscription =
          widget.locationService.positionStream().listen((position) {
        if (!mounted) return;
        setState(() {
          _position = LatLng(position.latitude, position.longitude);
        });
      });
    }
  }

  void _select(MapSelection selection) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selection = selection;
      _query = '';
      _searchController.clear();
    });
    final focus = selection.focus;
    if (focus != null) {
      // The sheet-height map padding keeps the pin in the top part of the
      // visible map when the camera centres on it.
      _mapController?.animateCamera(CameraUpdate.newLatLng(focus));
    }
  }

  void _clearSelection() {
    if (_selection == null) return;
    setState(() => _selection = null);
  }

  List<ShortPlace> get _searchResults {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _places
        .where((place) => place.placeName.toLowerCase().contains(query))
        .take(5)
        .toList();
  }

  int? get _selectedPlaceId => switch (_selection) {
        SelectedPlace(:final place) => place.id,
        _ => null,
      };

  int? get _selectedTrailId => switch (_selection) {
        SelectedTrail(:final trail) => trail.id,
        _ => null,
      };

  Set<Marker> _buildMarkers() {
    if (!_markersReady) return const {};
    return {
      for (final place in _places)
        Marker(
          markerId: MarkerId('place_${place.id}'),
          position: LatLng(place.lat, place.lng),
          icon: place.id == _selectedPlaceId
              ? MarkerFactory.placePinSelected
              : MarkerFactory.placePin,
          anchor: const Offset(0.5, 1.0),
          consumeTapEvents: true,
          onTap: () => _select(SelectedPlace(place)),
        ),
      if (_hasLocation)
        Marker(
          markerId: const MarkerId('user_location'),
          position: _position,
          icon: MarkerFactory.userDot,
          anchor: const Offset(0.5, 0.5),
        ),
    };
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    for (final entry in _trailCoordinates.entries) {
      if (entry.value.isEmpty) continue;
      final trail = _trails[entry.key];
      if (trail == null) continue;
      final selected = entry.key == _selectedTrailId;
      // White casing under the cyan line, like the web map.
      polylines.add(Polyline(
        polylineId: PolylineId('trail_${entry.key}_casing'),
        points: entry.value,
        width: selected ? 9 : 7,
        color: Colors.white,
        zIndex: 0,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));
      polylines.add(Polyline(
        polylineId: PolylineId('trail_${entry.key}'),
        points: entry.value,
        width: selected ? 7 : 5,
        color: selected ? AppColors.primaryDark : AppColors.trail,
        zIndex: 1,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        consumeTapEvents: true,
        onTap: () => _select(SelectedTrail(trail, entry.value)),
      ));
    }
    return polylines;
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _session != null
            ? const Profile()
            : const SignInOrSingUpPage(),
      ),
    );
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: Text(LocaleKeys.add_place_here.tr()),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlaceForm(_position)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: Text(LocaleKeys.record_trail.tr()),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          TrailRecordPage(startLocation: _position)),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget? _locationExplainer() {
    final result = _locationResult;
    final String message;
    VoidCallback? settingsAction;
    switch (result) {
      case LocationDenied():
        message = LocaleKeys.permissions_denied.tr();
        settingsAction = null;
      case LocationDeniedForever():
        message = LocaleKeys.permissions_permanently_denied.tr();
        settingsAction = () => widget.locationService.openAppSettings();
      case LocationServicesOff():
        message = LocaleKeys.location_services_off.tr();
        settingsAction = () => widget.locationService.openLocationSettings();
      case LocationOk():
      case null:
        return null;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _resolveLocation,
                  child: Text(LocaleKeys.refresh.tr()),
                ),
                if (settingsAction != null)
                  TextButton(
                    onPressed: settingsAction,
                    child: Text(LocaleKeys.open_settings.tr()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchResultsCard(List<ShortPlace> results) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final place in results)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(place.placeName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                _select(SelectedPlace(place));
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                    LatLng(place.lat, place.lng), 14));
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final sheetPadding =
        _selection == null ? 0.0 : MediaQuery.sizeOf(context).height * 0.25;
    final results = _searchResults;
    final explainer = _selection == null ? _locationExplainer() : null;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.mapOverride ??
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                      target: _position, zoom: _hasLocation ? 12 : 6),
                  style: _mapStyleString,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  markers: _buildMarkers(),
                  polylines: _buildPolylines(),
                  padding: EdgeInsets.only(bottom: sheetPadding),
                  onTap: (_) => _clearSelection(),
                ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                if (_offline)
                  MaterialBanner(
                    leading: const Icon(Icons.wifi_off),
                    content: Text(LocaleKeys.no_connection_error.tr()),
                    actions: [
                      TextButton(
                        onPressed: _loadMapData,
                        child: Text(LocaleKeys.refresh.tr()),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MapTopBar(
                    controller: _searchController,
                    onQueryChanged: (value) =>
                        setState(() => _query = value),
                    onAvatarTap: _openProfile,
                    userInitial: _session != null &&
                            _session!.user.username.isNotEmpty
                        ? _session!.user.username[0]
                        : null,
                  ),
                ),
                if (results.isNotEmpty) _searchResultsCard(results),
                  if (_loadFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: ActionChip(
                          avatar: const Icon(Icons.refresh, size: 18),
                          label: Text(LocaleKeys.map_load_failed.tr()),
                          onPressed: _loadMapData,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_selection == null)
            Positioned(
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 24),
                  child: MapFabColumn(
                    onLocate: () => _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_position, 14)),
                    onCycleTheme: _themeProvider.cycleThemeMode,
                    themeMode: themeMode,
                    onAdd: _session != null ? _openAddSheet : null,
                  ),
                ),
              ),
            ),
          if (explainer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: explainer,
                ),
              ),
            ),
          if (_selection != null)
            Positioned.fill(
              child: MemorySheet(
                key: ValueKey(_selection),
                selection: _selection!,
                userPosition: _hasLocation ? _position : null,
                onClose: _clearSelection,
              ),
            ),
        ],
      ),
    );
  }
}
