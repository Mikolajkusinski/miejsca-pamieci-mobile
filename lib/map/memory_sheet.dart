import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/map/map_selection.dart';
import 'package:memo_places_mobile/map/memory_detail_content.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

/// Draggable bottom sheet for the selected map object: peek shows title +
/// distance from the user; half/full add the carousel and the complete
/// details (same content widget as the standalone detail screens). The map
/// stays visible behind it.
class MemorySheet extends StatefulWidget {
  final MapSelection selection;
  final LatLng? userPosition;
  final VoidCallback onClose;

  const MemorySheet({
    super.key,
    required this.selection,
    required this.onClose,
    this.userPosition,
  });

  @override
  State<MemorySheet> createState() => _MemorySheetState();
}

class _MemorySheetState extends State<MemorySheet> {
  late Future<MemoryDetail> _detail = _load();

  Future<MemoryDetail> _load() async {
    switch (widget.selection) {
      case SelectedPlace(:final place):
        final full = await context.read<PlacesRepository>().getById(place.id);
        return MemoryDetail.fromPlace(full);
      case SelectedTrail(:final trail):
        final full = await context.read<TrailsRepository>().getById(trail.id);
        return MemoryDetail.fromTrail(full);
    }
  }

  String? get _distanceAway {
    final user = widget.userPosition;
    final focus = widget.selection.focus;
    if (user == null || focus == null) return null;
    final km = Geolocator.distanceBetween(user.latitude, user.longitude,
            focus.latitude, focus.longitude) /
        1000;
    return LocaleKeys.distance_away
        .tr(namedArgs: {'distance': km.toStringAsFixed(1)});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final distance = _distanceAway;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.25, 0.55, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.selection.title,
                      style: textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (distance != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    distance,
                    style: textTheme.bodyMedium!
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              FutureBuilder<MemoryDetail>(
                future: _detail,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return Column(
                      children: [
                        Text(
                          error is ApiException
                              ? error.message
                              : LocaleKeys.alert_error.tr(),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _detail = _load();
                          }),
                          child: Text(LocaleKeys.refresh.tr()),
                        ),
                      ],
                    );
                  }
                  final detail = snapshot.data;
                  if (detail == null) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return MemoryDetailContent(detail: detail);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
