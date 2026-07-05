import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/internet_checker.dart';
import 'package:memo_places_mobile/offlineWidgets/offline_places_list.dart';
import 'package:memo_places_mobile/offline_place_form.dart';
import 'package:memo_places_mobile/services/location_service.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

/// Shown at startup when the device is offline but a user is signed in:
/// places can still be captured and queue for the next sync.
class OfflinePlaceAddingPage extends StatefulWidget {
  final LocationService locationService;

  const OfflinePlaceAddingPage(
      {super.key, this.locationService = const LocationService()});

  @override
  State<OfflinePlaceAddingPage> createState() => _OfflinePlaceAddingPageState();
}

class _OfflinePlaceAddingPageState extends State<OfflinePlaceAddingPage> {
  LatLng? _position;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    final result = await widget.locationService.getCurrent();
    if (!mounted) return;
    setState(() {
      if (result is LocationOk) {
        _position =
            LatLng(result.position.latitude, result.position.longitude);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final position = _position;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Icon(Icons.wifi_off,
                        size: 64, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      LocaleKeys.oops.tr(),
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${LocaleKeys.no_internet_info.tr()} '
                      '${LocaleKeys.still_add_places.tr()}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium!
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    if (position != null)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OfflinePlaceForm(position)),
                          );
                        },
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text(LocaleKeys.add_place.tr()),
                      ),
                    const SizedBox(height: 16),
                    const Expanded(child: OfflinePlacesList()),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const InternetChecker()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text(LocaleKeys.refresh.tr()),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
