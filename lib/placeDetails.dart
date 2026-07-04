import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/ObjectDetailsWidgets/sliderWithDots.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetails extends StatefulWidget {
  final String placeId;
  const PlaceDetails(this.placeId, {super.key});

  @override
  State<PlaceDetails> createState() => _PlaceDetailsState();
}

class _PlaceDetailsState extends State<PlaceDetails> {
  late Future<Place> _placeFuture = _load();

  Future<Place> _load() =>
      context.read<PlacesRepository>().getById(int.parse(widget.placeId));

  Future<void> _launchMaps(Place place) async {
    final url =
        Uri.parse(ApiConstants.googleSearchByLatLng(place.lat, place.lng));
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showErrorToast(LocaleKeys.google_maps_error.tr());
    }
  }

  Future<void> _launchLink(String link) async {
    final url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showErrorToast(LocaleKeys.link_error.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FutureBuilder<Place>(
          future: _placeFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      error is ApiException
                          ? error.message
                          : LocaleKeys.alert_error.tr(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  CustomButton(
                    onPressed: () => setState(() {
                      _placeFuture = _load();
                    }),
                    text: LocaleKeys.refresh.tr(),
                  ),
                ],
              );
            }
            final place = snapshot.data;
            if (place == null) {
              return const CircularProgressIndicator();
            }
            return _PlaceContent(
              place: place,
              onOpenMaps: () => _launchMaps(place),
              onOpenLink: _launchLink,
            );
          },
        ),
      ),
    );
  }
}

class _PlaceContent extends StatelessWidget {
  final Place place;
  final VoidCallback onOpenMaps;
  final void Function(String link) onOpenLink;

  const _PlaceContent(
      {required this.place,
      required this.onOpenMaps,
      required this.onOpenLink});

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 5.0,
            offset: const Offset(0, 3),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final images = place.images ?? const <String>[];
    return SingleChildScrollView(
      child: Column(
        children: [
          images.isNotEmpty ? SliderWithDots(images: images) : const SizedBox(),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            decoration: _cardDecoration(context),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        LocaleKeys.title.tr(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      place.placeName,
                      style: const TextStyle(
                          fontSize: 18, overflow: TextOverflow.clip),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: _cardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        LocaleKeys.info.tr(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Text(
                    LocaleKeys.type_info
                        .tr(namedArgs: {'type': place.typeValue.tr()}),
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    LocaleKeys.period_info
                        .tr(namedArgs: {'period': place.periodValue.tr()}),
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    LocaleKeys.sortof_info
                        .tr(namedArgs: {'sortof': place.sortofValue.tr()}),
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    LocaleKeys.date_info
                        .tr(namedArgs: {'date': place.creationDate}),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 300,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: _cardDecoration(context),
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        LocaleKeys.description.tr(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      place.description,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (place.wikiLink.isNotEmpty || place.topicLink.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: _cardDecoration(context),
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          LocaleKeys.links.tr(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (place.wikiLink.isNotEmpty)
                        GestureDetector(
                          onTap: () => onOpenLink(place.wikiLink),
                          child: Text(
                            LocaleKeys.wiki_link.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      if (place.topicLink.isNotEmpty)
                        GestureDetector(
                          onTap: () => onOpenLink(place.topicLink),
                          child: Text(
                            LocaleKeys.topic_link.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: CustomButton(
              onPressed: onOpenMaps,
              text: LocaleKeys.show_google_maps.tr(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
