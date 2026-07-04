import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/ObjectDetailsWidgets/slider_with_dots.dart';
import 'package:memo_places_mobile/Objects/trail.dart';
import 'package:memo_places_mobile/api_constants.dart';
import 'package:memo_places_mobile/formWidgets/custom_button.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/trails_repository.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TrailDetails extends StatefulWidget {
  final String trailId;
  const TrailDetails(this.trailId, {super.key});

  @override
  State<TrailDetails> createState() => _TrailDetailsState();
}

class _TrailDetailsState extends State<TrailDetails> {
  late Future<Trail> _trailFuture = _load();

  Future<Trail> _load() =>
      context.read<TrailsRepository>().getById(int.parse(widget.trailId));

  Future<void> _launchMaps(Trail trail) async {
    if (trail.coordinates.isEmpty) return;
    final url = Uri.parse(ApiConstants.googleSearchByLatLng(
        trail.coordinates[0].latitude, trail.coordinates[0].longitude));
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
        child: FutureBuilder<Trail>(
          future: _trailFuture,
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
                      _trailFuture = _load();
                    }),
                    text: LocaleKeys.refresh.tr(),
                  ),
                ],
              );
            }
            final trail = snapshot.data;
            if (trail == null) {
              return const CircularProgressIndicator();
            }
            return _TrailContent(
              trail: trail,
              onOpenMaps: () => _launchMaps(trail),
              onOpenLink: _launchLink,
            );
          },
        ),
      ),
    );
  }
}

class _TrailContent extends StatelessWidget {
  final Trail trail;
  final VoidCallback onOpenMaps;
  final void Function(String link) onOpenLink;

  const _TrailContent(
      {required this.trail,
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
    final images = trail.images ?? const <String>[];
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
                      trail.trailName,
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
                        .tr(namedArgs: {'type': trail.typeValue.tr()}),
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    LocaleKeys.period_info
                        .tr(namedArgs: {'period': trail.periodValue.tr()}),
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    LocaleKeys.date_info
                        .tr(namedArgs: {'date': trail.creationDate}),
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
                    Text(trail.description,
                        style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),
          if (trail.wikiLink.isNotEmpty || trail.topicLink.isNotEmpty)
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
                      if (trail.wikiLink.isNotEmpty)
                        GestureDetector(
                          onTap: () => onOpenLink(trail.wikiLink),
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
                      if (trail.topicLink.isNotEmpty)
                        GestureDetector(
                          onTap: () => onOpenLink(trail.topicLink),
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
              text: LocaleKeys.navigate_trail.tr(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
