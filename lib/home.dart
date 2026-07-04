import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memo_places_mobile/AppNavigation/addingButton.dart';
import 'package:memo_places_mobile/MainPageWidgets/previewPlace.dart';
import 'package:memo_places_mobile/MainPageWidgets/prewiewTrail.dart';
import 'package:memo_places_mobile/Objects/currnetObject.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/Theme/theme.dart';
import 'package:memo_places_mobile/Theme/themeProvider.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State createState() => _GoogleMapsState();
}

class _GoogleMapsState extends State {
  late GoogleMapController _mapController;
  late String _mapStyleString;
  late User? _user = null;
  late LatLng _position = const LatLng(0.0, 0.0);
  bool _isLoading = true;
  bool _isSelectedPlace = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Place> _places = [];
  List<Trail> _trails = [];
  late CurrentObject _selectedObject;
  late StreamSubscription<Position> _positionStreamSubscription;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _loadMapStyle();
    loadUserData().then((value) => _user = value);
    _getCurrentLocation().then((location) => {
          setState(() {
            _position = LatLng(location.latitude, location.longitude);
          }),
          _startLocationUpdates(),
          _fetchPlaces(),
          _fetchTrails(),
          setState(() {
            _isLoading = false;
          })
        });
    _themeProvider.addListener(_loadMapStyle);
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    _mapController.dispose();
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

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error(LocaleKeys.permissions_denied.tr());
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(LocaleKeys.permissions_permanently_denied.tr());
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _startLocationUpdates() {
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
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
          icon: BitmapDescriptor.fromBytes(markerIcon),
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
        _selectedObject = CurrentObject(null, trail);
      } else {
        _selectedObject = CurrentObject(place, null);
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
        var fechedPlaces = <Place>[];
        for (var data in jsonData) {
          var place = Place.fromJson(data);
          fechedPlaces.add(place);
        }

        setState(() {
          _places = fechedPlaces;
          _markers.addAll(_places.map((place) {
            return Marker(
              markerId: MarkerId(place.id.toString()),
              position: LatLng(place.lat, place.lng),
              icon: BitmapDescriptor.fromBytes(markerIcon),
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
    }
  }

  Future<void> _fetchTrails() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.trailsEndpoint));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        var fechedTrails = <Trail>[];
        for (var data in jsonData) {
          var trail = Trail.fromJson(data);
          fechedTrails.add(trail);
        }

        setState(() {
          _trails = fechedTrails;
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
        throw Exception(LocaleKeys.failed_load_trails.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    }
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
                    GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      initialCameraPosition:
                          CameraPosition(target: _position, zoom: 12.0),
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
                          _mapController.animateCamera(
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
                  ],
                ),
        ),
      ),
    );
  }
}
