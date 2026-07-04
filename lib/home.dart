import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memo_places_mobile/AppNavigation/adding_button.dart';
import 'package:memo_places_mobile/MainPageWidgets/preview_place.dart';
import 'package:memo_places_mobile/MainPageWidgets/preview_trail.dart';
import 'package:memo_places_mobile/Objects/selected_map_object.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/Theme/theme.dart';
import 'package:memo_places_mobile/Theme/theme_provider.dart';
import 'package:memo_places_mobile/api_constants.dart';
import 'package:memo_places_mobile/custom_exception.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/services/location_service.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  final LocationService locationService;

  /// Tests substitute the platform-view map with a plain widget.
  final Widget? mapOverride;

  const Home(
      {super.key,
      this.locationService = const LocationService(),
      this.mapOverride});

  @override
  State createState() => _GoogleMapsState();
}

class _GoogleMapsState extends State<Home> {
  /// Map center when the user's location is unavailable: Poland.
  static const _fallbackPosition = LatLng(52.06, 19.48);

  GoogleMapController? _mapController;
  late String _mapStyleString;
  User? _user;
  LatLng _position = _fallbackPosition;
  bool _hasLocation = false;
  bool _isLoading = true;
  LocationResult? _locationResult;
  bool _isSelectedPlace = false;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<Place> _places = [];
  List<Trail> _trails = [];
  late SelectedMapObject _selectedObject;
  StreamSubscription<Position>? _positionStreamSubscription;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _loadMapStyle();
    loadUserData().then((value) {
      if (mounted) setState(() => _user = value);
    });
    _resolveLocation();
    _fetchPlaces();
    _fetchTrails();
    _themeProvider.addListener(_loadMapStyle);
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
      _isLoading = false;
    });
    if (result is LocationOk) {
      _startLocationUpdates();
      _updateUserMarker();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _themeProvider.removeListener(_loadMapStyle);
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    String stylePath =
        Provider.of<ThemeProvider>(context, listen: false).themeData ==
                lightTheme
            ? 'lib/assets/map_styles/light_map_style.json'
            : 'lib/assets/map_styles/dark_map_style.json';
    _mapStyleString =
        await DefaultAssetBundle.of(context).loadString(stylePath);
    setState(() {});
  }

  void _startLocationUpdates() {
    _positionStreamSubscription =
        widget.locationService.positionStream().listen((Position position) {
      setState(() {
        _position = LatLng(position.latitude, position.longitude);
        _updateUserMarker();
      });
    });
  }

  void _updateUserMarker() async {
    final Uint8List markerIcon =
        await _getBytesFromAsset('lib/assets/markers/user_marker.PNG', 80);

    Set<Marker> updatedMarkers = _markers.union({
      Marker(
          markerId: const MarkerId("user_location"),
          position: _position,
          icon: BitmapDescriptor.bytes(markerIcon),
          anchor: const Offset(0.5, 0.5)),
    });

    setState(() {
      _markers = updatedMarkers;
    });
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void _setObject(Place? place, Trail? trail) {
    setState(() {
      _isSelectedPlace = true;
      if (place == null) {
        _selectedObject = SelectedMapObject(null, trail);
      } else {
        _selectedObject = SelectedMapObject(place, null);
      }
    });
  }

  void closePreview() {
    setState(() {
      _isSelectedPlace = false;
    });
  }

  Future<void> _fetchPlaces() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.placesEndpoint));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        final Uint8List markerIcon = await _getBytesFromAsset(
            'lib/assets/markers/unknown_marker.PNG', 150);
        var fetchedPlaces = <Place>[];
        for (var data in jsonData) {
          var place = Place.fromJson(data);
          fetchedPlaces.add(place);
        }

        setState(() {
          _places = fetchedPlaces;
          _markers.addAll(_places.map((place) {
            return Marker(
              markerId: MarkerId(place.id.toString()),
              position: LatLng(place.lat, place.lng),
              icon: BitmapDescriptor.bytes(markerIcon),
              consumeTapEvents: true,
              onTap: () => _setObject(place, null),
            );
          }).toSet());
        });
      } else {
        throw CustomException(LocaleKeys.failed_load_places.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    } on Exception {
      // Legacy endpoint — network failures must not break the map.
      showErrorToast(LocaleKeys.failed_load_places.tr());
    }
  }

  Future<void> _fetchTrails() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.trailsEndpoint));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        var fetchedTrails = <Trail>[];
        for (var data in jsonData) {
          var trail = Trail.fromJson(data);
          fetchedTrails.add(trail);
        }

        setState(() {
          _trails = fetchedTrails;
          _polylines.addAll(_trails.map((trail) {
            return Polyline(
              polylineId: PolylineId(trail.id.toString()),
              visible: true,
              points: trail.coordinates,
              width: 10,
              color: const Color.fromARGB(137, 33, 75, 243),
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              consumeTapEvents: true,
              onTap: () => _setObject(null, trail),
            );
          }).toSet());
        });
      } else {
        throw CustomException(LocaleKeys.failed_load_trails.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    } on Exception {
      showErrorToast(LocaleKeys.failed_load_trails.tr());
    }
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

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Card(
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
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _resolveLocation();
                    },
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget signInAccess = const SizedBox();

    if (_user != null) {
      signInAccess = AddingButton(_position);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.scrim),
                )
              : Stack(
                  children: [
                    widget.mapOverride ??
                        GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          initialCameraPosition: CameraPosition(
                              target: _position,
                              zoom: _hasLocation ? 12.0 : 6.0),
                          markers: _markers,
                          polylines: _polylines,
                          style: _mapStyleString,
                        ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        heroTag: 'locateMe',
                        onPressed: () {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(_position),
                          );
                        },
                        child: const Icon(Icons.location_searching),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: FloatingActionButton(
                        heroTag: 'toggleTheme',
                        onPressed: () {
                          Provider.of<ThemeProvider>(context, listen: false)
                              .toggleTheme();
                        },
                        child: Icon(
                            Provider.of<ThemeProvider>(context, listen: false)
                                        .themeData ==
                                    lightTheme
                                ? Icons.light_mode
                                : Icons.dark_mode),
                      ),
                    ),
                    _isSelectedPlace
                        ? Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _selectedObject.place == null
                                ? PreviewTrail(
                                    closePreview, _selectedObject.trail!)
                                : PreviewPlace(
                                    closePreview, _selectedObject.place!))
                        : signInAccess,
                    if (!_isSelectedPlace) _locationExplainer() ?? const SizedBox(),
                  ],
                ),
        ),
      ),
    );
  }
}
