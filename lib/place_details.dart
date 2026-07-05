import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/place.dart';
import 'package:memo_places_mobile/map/memory_detail_content.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

/// Thin wrapper over [MemoryDetailContent] — the same content the Memory
/// Sheet renders, for flows that open a place outside the map (My Places).
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Place>(
      future: _placeFuture,
      builder: (context, snapshot) {
        final place = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(place?.placeName ?? '')),
          body: SafeArea(
            bottom: false,
            child: Builder(builder: (context) {
              if (snapshot.hasError) {
                final error = snapshot.error;
                return Center(
                  child: Column(
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
                      TextButton(
                        onPressed: () => setState(() {
                          _placeFuture = _load();
                        }),
                        child: Text(LocaleKeys.refresh.tr()),
                      ),
                    ],
                  ),
                );
              }
              if (place == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child:
                    MemoryDetailContent(detail: MemoryDetail.fromPlace(place)),
              );
            }),
          ),
        );
      },
    );
  }
}
