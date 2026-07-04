import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/Theme/theme.dart';
import 'package:memo_places_mobile/Theme/themeProvider.dart';
import 'package:memo_places_mobile/TrailRecordPageWidgets/recordMenu.dart';
import 'package:memo_places_mobile/services/location_service.dart';
import 'package:memo_places_mobile/services/trail_math.dart';
import 'package:memo_places_mobile/trailForm.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TrailRecordPage extends StatefulWidget {
  final LatLng startLocation;
  final LocationService locationService;

  const TrailRecordPage(
      {super.key,
      required this.startLocation,
      this.locationService = const LocationService()});

  @override
  State<StatefulWidget> createState() => _TrailRecordState();
}

class _TrailRecordState extends State<TrailRecordPage> {
  GoogleMapController? _mapController;
  late String _mapStyleString = '';
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late LatLng _currentPosition;
  final List<LatLng> _trailsPoints = [];
  bool _isRecording = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  TrailAccumulator _accumulator = TrailAccumulator();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _currentPosition = widget.startLocation;
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _ticker?.cancel();
    WakelockPlus.disable();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// A foreground-service notification keeps Android streaming while the app
  /// stays visible; full background recording is intentionally out of scope.
  LocationSettings _recordingSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: LocaleKeys.recording_notification_title.tr(),
          notificationText: LocaleKeys.recording_notification_text.tr(),
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
      );
    }
    return const LocationSettings(
        accuracy: LocationAccuracy.high, distanceFilter: 5);
  }

  void _startLocationUpdates() {
    _positionStreamSubscription = widget.locationService
        .positionStream(settings: _recordingSettings())
        .listen((Position position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateUserMarker();
        if (_isRecording && _accumulator.add(position)) {
          _trailsPoints.add(LatLng(position.latitude, position.longitude));
          _updateRecordedPolyline();
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

    if (!mounted) return;
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

  String _formatTime(int time) {
    return time.toString().padLeft(2, '0');
  }

  /// Wall-clock recording time from the stopwatch — immune to ticker drift.
  String get _formattedTime {
    final elapsed = _stopwatch.elapsed;
    return '${_formatTime(elapsed.inHours)}:'
        '${_formatTime(elapsed.inMinutes % 60)}:'
        '${_formatTime(elapsed.inSeconds % 60)}';
  }

  void _startRecording() {
    _accumulator = TrailAccumulator();
    _trailsPoints.clear();
    _stopwatch
      ..reset()
      ..start();
    // Refresh the clock display once a second; time comes from the stopwatch.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WakelockPlus.enable();
    setState(() {
      _isRecording = true;
    });
  }

  void _endRecording() {
    _stopwatch.stop();
    _ticker?.cancel();
    WakelockPlus.disable();
    setState(() {
      _isRecording = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => TrailForm(
                trailCoordinates: _trailsPoints,
                distance: _accumulator.totalKm.toStringAsFixed(3),
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
              if (_isRecording)
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        LocaleKeys.keep_app_open_info.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              RecordMenu(
                distance: _accumulator.totalKm.toStringAsFixed(3),
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
                    _mapController?.animateCamera(
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
