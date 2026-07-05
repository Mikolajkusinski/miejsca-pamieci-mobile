import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memo_places_mobile/ObjectDetailsWidgets/slider_with_dots.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/api_constants.dart';
import 'package:memo_places_mobile/shared/safe_url.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:url_launcher/url_launcher.dart';

/// Everything the detail surfaces render beyond the title, resolved from
/// the detail endpoints (the list DTOs carry only ids).
class MemoryDetail {
  final String periodValue;
  final String typeValue;
  final String? sortofValue;
  final String description;
  final String wikiLink;
  final String topicLink;
  final List<String> images;
  final LatLng? focus;

  const MemoryDetail({
    required this.periodValue,
    required this.typeValue,
    required this.description,
    required this.wikiLink,
    required this.topicLink,
    required this.images,
    this.sortofValue,
    this.focus,
  });

  factory MemoryDetail.fromPlace(Place place) => MemoryDetail(
        periodValue: place.periodValue,
        typeValue: place.typeValue,
        sortofValue: place.sortofValue,
        description: place.description,
        wikiLink: place.wikiLink,
        topicLink: place.topicLink,
        images: place.images ?? const [],
        focus: LatLng(place.lat, place.lng),
      );

  factory MemoryDetail.fromTrail(Trail trail) => MemoryDetail(
        periodValue: trail.periodValue,
        typeValue: trail.typeValue,
        description: trail.description,
        wikiLink: trail.wikiLink,
        topicLink: trail.topicLink,
        images: trail.images ?? const [],
        focus: trail.coordinates.isEmpty ? null : trail.coordinates.first,
      );
}

/// Single source of truth for the details UI — rendered by the Memory
/// Sheet's expanded state and by the standalone details screens.
class MemoryDetailContent extends StatelessWidget {
  final MemoryDetail detail;

  const MemoryDetailContent({super.key, required this.detail});

  Future<void> _openMaps() async {
    final focus = detail.focus;
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
    // Server data is not trusted: only plain http(s) URLs may launch.
    final url = parseSafeHttpUrl(link);
    if (url != null && await canLaunchUrl(url)) {
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (detail.periodValue.isNotEmpty)
              _chip(context, detail.periodValue.tr(), primary: true),
            if (detail.typeValue.isNotEmpty)
              _chip(context, detail.typeValue.tr(), primary: false),
            if (detail.sortofValue != null &&
                detail.sortofValue!.isNotEmpty)
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
        if (detail.focus != null)
          FilledButton(
            onPressed: _openMaps,
            child: Text(LocaleKeys.show_google_maps.tr()),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
