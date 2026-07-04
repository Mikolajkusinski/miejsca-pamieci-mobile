import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/ObjectDetailsWidgets/sliderWithDots.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetails extends StatefulWidget {
  final String placeId;
  const PlaceDetails(this.placeId, {super.key});

  @override
  State<PlaceDetails> createState() => _PlaceDetailsState();
}

class _PlaceDetailsState extends State<PlaceDetails> {
  late List<String> _updatedImages;
  late bool _isLoading = true;
  late Place _place;

  @override
  void initState() {
    super.initState();
    try {
      fetchPlace(context, widget.placeId).then((place) {
        _place = place;
        _updatedImages = place.images!.map((image) {
          return ApiConstants.displayImageEndpoint(image);
        }).toList();
        setState(() {
          _isLoading = false;
        });
      });
    } on CustomException catch (error) {
      showErrorToast(error.toString());
    }
  }

  Future<void> _launchMaps(BuildContext context) async {
    final url =
        Uri.parse(ApiConstants.googleSearchByLatLng(_place.lat, _place.lng));
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showErrorToast(LocaleKeys.google_maps_error.tr());
    }
  }

  Future<void> _launchWikipedia(BuildContext context) async {
    final url = Uri.parse(_place.wikiLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showErrorToast(LocaleKeys.link_error.tr());
    }
  }

  Future<void> _launchTopicPage(BuildContext context) async {
    final url = Uri.parse(_place.topicLink);
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
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.scrim),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _place.images!.isNotEmpty
                        ? SliderWithDots(images: _updatedImages)
                        : const SizedBox(),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 5.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                _place.placeName,
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 5.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  LocaleKeys.info.tr(),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Text(
                              LocaleKeys.type_info.tr(
                                  namedArgs: {'type': _place.typeValue.tr()}),
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              LocaleKeys.period_info.tr(namedArgs: {
                                'period': _place.periodValue.tr()
                              }),
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              LocaleKeys.sortof_info.tr(namedArgs: {
                                'sortof': _place.sortofValue.tr()
                              }),
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              LocaleKeys.username_info
                                  .tr(namedArgs: {'username': _place.username}),
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              LocaleKeys.date_info
                                  .tr(namedArgs: {'date': _place.creationDate}),
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 5.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  LocaleKeys.description.tr(),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                _place.description,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 5.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  LocaleKeys.links.tr(),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              _place.wikiLink.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _launchWikipedia(context);
                                      },
                                      child: Text(
                                        LocaleKeys.wiki_link.tr(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.blue,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                              _place.topicLink.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _launchTopicPage(context);
                                      },
                                      child: Text(
                                        LocaleKeys.topic_link.tr(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.blue,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: CustomButton(
                        onPressed: () {
                          _launchMaps(context);
                        },
                        text: LocaleKeys.show_google_maps.tr(),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
