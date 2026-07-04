import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/formWidgets/customButtonWithIcon.dart';
import 'package:memo_places_mobile/internetChecker.dart';
import 'package:memo_places_mobile/offlinePlaceForm.dart';
import 'package:memo_places_mobile/offlineWidgets/offlinePlacesList.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class OfflinePlaceAddingPage extends StatefulWidget {
  const OfflinePlaceAddingPage({super.key});

  @override
  State<OfflinePlaceAddingPage> createState() => _OfflinePlaceAddingPageState();
}

class _OfflinePlaceAddingPageState extends State<OfflinePlaceAddingPage> {
  late LatLng _position;
  bool _isLoading = true;

  @override
  initState() {
    super.initState();

    _getCurrentLocation().then((location) => {
          if (mounted)
            {
              setState(() {
                _position = LatLng(location.latitude, location.longitude);
                _isLoading = false;
              })
            }
        });
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.scrim),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 100,
                    ),
                    Text(
                      LocaleKeys.oops.tr(),
                      style: const TextStyle(fontSize: 32),
                    ),
                    Text(
                      LocaleKeys.no_internet_info.tr(),
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LocaleKeys.but.tr(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LocaleKeys.still_add_places.tr(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    CustomButtonWithIcon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OfflinePlaceForm(_position)),
                          );
                        },
                        icon: Icons.add_location_alt_outlined,
                        text: LocaleKeys.add_place.tr()),
                    const SizedBox(
                      height: 30,
                    ),
                    const Expanded(child: OfflinePlacesList()),
                    const SizedBox(
                      height: 20,
                    ),
                    CustomButtonWithIcon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const InternetChecker()),
                          );
                        },
                        icon: Icons.refresh,
                        text: LocaleKeys.refresh.tr()),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
