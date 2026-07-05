import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/ObjectDetailsWidgets/slider_with_dots.dart';
import 'package:memo_places_mobile/api_constants.dart';
import 'package:memo_places_mobile/map/map_selection.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Everything the sheet renders beyond the peek row, resolved from the
/// detail endpoint (the list DTOs carry only ids).
class _MemoryDetail {
  final String periodValue;
  final String typeValue;
  final String? sortofValue;
  final String description;
  final String wikiLink;
  final String topicLink;
  final List<String> images;

  const _MemoryDetail({
    required this.periodValue,
    required this.typeValue,
    required this.description,
    required this.wikiLink,
    required this.topicLink,
    required this.images,
    this.sortofValue,
  });
}

/// Draggable bottom sheet for the selected map object: peek shows title +
/// period chip + distance from the user; half/full add the carousel and the
/// complete details. The map stays visible behind it.
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
  late Future<_MemoryDetail> _detail = _load();

  Future<_MemoryDetail> _load() async {
    switch (widget.selection) {
      case SelectedPlace(:final place):
        final full = await context.read<PlacesRepository>().getById(place.id);
        return _MemoryDetail(
          periodValue: full.periodValue,
          typeValue: full.typeValue,
          sortofValue: full.sortofValue,
          description: full.description,
          wikiLink: full.wikiLink,
          topicLink: full.topicLink,
          images: full.images ?? const [],
        );
      case SelectedTrail(:final trail):
        final full = await context.read<TrailsRepository>().getById(trail.id);
        return _MemoryDetail(
          periodValue: full.periodValue,
          typeValue: full.typeValue,
          description: full.description,
          wikiLink: full.wikiLink,
          topicLink: full.topicLink,
          images: full.images ?? const [],
        );
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

  Future<void> _openMaps() async {
    final focus = widget.selection.focus;
    if (focus == null) return;
    final url = Uri.parse(
        ApiConstants.googleSearchByLatLng(focus.latitude, focus.longitude));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorToast(LocaleKeys.google_maps_error.tr());
    }
  }

  Future<void> _openLink(String link) async {
    final url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showErrorToast(LocaleKeys.link_error.tr());
    }
  }

  Widget _chip(BuildContext context, String label, {required bool primary}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontSize: 13,
              color: primary ? Colors.white : scheme.onSurface,
            ),
      ),
    );
  }

  List<Widget> _detailChildren(BuildContext context, _MemoryDetail detail) {
    final textTheme = Theme.of(context).textTheme;
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (detail.periodValue.isNotEmpty)
            _chip(context, detail.periodValue.tr(), primary: true),
          if (detail.typeValue.isNotEmpty)
            _chip(context, detail.typeValue.tr(), primary: false),
          if (detail.sortofValue != null && detail.sortofValue!.isNotEmpty)
            _chip(context, detail.sortofValue!.tr(), primary: false),
        ],
      ),
      const SizedBox(height: 16),
      if (detail.images.isNotEmpty) ...[
        SliderWithDots(images: detail.images),
        const SizedBox(height: 16),
      ],
      if (detail.description.isNotEmpty) ...[
        Text(detail.description, style: textTheme.bodyLarge),
        const SizedBox(height: 16),
      ],
      if (detail.wikiLink.isNotEmpty)
        TextButton.icon(
          onPressed: () => _openLink(detail.wikiLink),
          icon: const Icon(Icons.link),
          label: Text(LocaleKeys.wiki_link.tr()),
        ),
      if (detail.topicLink.isNotEmpty)
        TextButton.icon(
          onPressed: () => _openLink(detail.topicLink),
          icon: const Icon(Icons.link),
          label: Text(LocaleKeys.topic_link.tr()),
        ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _openMaps,
        child: Text(LocaleKeys.show_google_maps.tr()),
      ),
      const SizedBox(height: 24),
    ];
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
              FutureBuilder<_MemoryDetail>(
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
                          onPressed: () =>
                              setState(() => _detail = _load()),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _detailChildren(context, detail),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
