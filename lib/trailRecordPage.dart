import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/Theme/theme.dart';
import 'package:memo_places_mobile/Theme/themeProvider.dart';
import 'package:memo_places_mobile/TrailRecordPageWidgets/recordMenu.dart';
import 'package:memo_places_mobile/trailForm.dart';
import 'package:provider/provider.dart';

class TrailRecordPage extends StatefulWidget {
  final LatLng startLocation;

  const TrailRecordPage({super.key, required this.startLocation});

  @override
  State<StatefulWidget> createState() => _TrailRecordState();
}

class _TrailRecordState extends State<TrailRecordPage> {
  late GoogleMapController _mapController;
  late String _mapStyleString = '';
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late LatLng _currentPosition;
  late List<LatLng> _trailsPoints = [];
  bool _isRecording = false;
  late StreamSubscription<Position> _positionStreamSubscription;
  double _totalDistanceKm = 0.0;
  Timer? _timer;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _currentPosition = widget.startLocation;
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _startLocationUpdates() {
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateUserMarker();
        if (_isRecording == true) {
          _trailsPoints.add(LatLng(position.latitude, position.longitude));
          _updateRecordedPolyline();
          _updateDistance();
        }
      });
    });
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

  void _updateUserMarker() async {
    final Uint8List markerIcon =
        await _getBytesFromAsset('lib/assets/markers/user_marker.PNG', 80);
    Set<Marker> updatedMarkers = _markers.union({
      Marker(
        markerId: const MarkerId("user_location"),
        position: _currentPosition,
        icon: BitmapDescriptor.fromBytes(markerIcon),
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
      ),
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

  void _updateRecordedPolyline() {
    Set<Polyline> updatedPolylines = _polylines.union({
      Polyline(
          polylineId: const PolylineId("recorded_trail_polyline"),
          visible: true,
          points: _trailsPoints,
          width: 10,
          color: const Color.fromARGB(137, 33, 75, 243),
          startCap: Cap.roundCap,
          endCap: Cap.roundCap),
    });

    setState(() {
      _polylines = updatedPolylines;
    });
  }

  void _updateDistance() {
    if (_trailsPoints.length > 1) {
      double distance = _calculateDistance(
          _trailsPoints[_trailsPoints.length - 2], _trailsPoints.last);
      _totalDistanceKm += distance;
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371.0;

    double lat1 = start.latitude * pi / 180.0;
    double lon1 = start.longitude * pi / 180.0;
    double lat2 = end.latitude * pi / 180.0;
    double lon2 = end.longitude * pi / 180.0;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadius * c;
    return distance;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_seconds == 60) {
          _seconds = 0;
          _minutes++;
          if (_minutes == 60) {
            _minutes = 0;
            _hours++;
          }
        }
      });
    });
  }

  String _formatTime(int time) {
    return time.toString().padLeft(2, '0');
  }

  String get _formattedTime {
    return '${_formatTime(_hours)}:${_formatTime(_minutes)}:${_formatTime(_seconds)}';
  }

  void _startRecording() {
    _startTimer();
    setState(() {
      _isRecording = true;
    });
  }

  void _endRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => TrailForm(
                trailCoordinates: _trailsPoints,
                distance: _totalDistanceKm.toStringAsFixed(3),
                time: _formattedTime,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: _markers,
                polylines: _polylines,
                style: _mapStyleString,
                initialCameraPosition:
                    CameraPosition(target: _currentPosition, zoom: 16),
              ),
              RecordMenu(
                distance: _totalDistanceKm.toStringAsFixed(3),
                isRecording: _isRecording,
                time: _formattedTime,
                startRecording: _startRecording,
                endRecording: _endRecording,
              ),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'locateMe',
                  onPressed: () {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(_trailsPoints.isEmpty
                          ? widget.startLocation
                          : _trailsPoints.last),
                    );
                  },
                  child: const Icon(Icons.location_searching),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: FloatingActionButton(
                  heroTag: 'back',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
