import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Non-interactive 120 px mini-map showing the chosen position — replaces
/// raw lat/lng text in the form headers.
class LocationPreview extends StatelessWidget {
  final LatLng position;

  const LocationPreview({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: position, zoom: 15),
                liteModeEnabled:
                    defaultTargetPlatform == TargetPlatform.android,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            Center(
              child: Padding(
                // Optically centre the pin tip on the position.
                padding: const EdgeInsets.only(bottom: 24),
                child: Icon(Icons.place, size: 32, color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
