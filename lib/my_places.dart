import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/empty_list_state.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/memory_card.dart';
import 'package:memo_places_mobile/Objects/short_place.dart';
import 'package:memo_places_mobile/place_details.dart';
import 'package:memo_places_mobile/place_edit_form.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/catalog_repository.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/services/places_repository.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class MyPlaces extends StatefulWidget {
  const MyPlaces({super.key});

  @override
  State<MyPlaces> createState() => _MyPlacesState();
}

class _MyPlacesState extends State<MyPlaces> {
  late Future<(List<ShortPlace>, Map<int, String>)> _future = _load();

  Future<(List<ShortPlace>, Map<int, String>)> _load() async {
    final userId = await fetchBackendUserId(context);
    if (!mounted) throw const ApiException('disposed');
    final places = await context.read<PlacesRepository>().getByUser(userId);
    if (!mounted) throw const ApiException('disposed');
    final periods = await context.read<CatalogRepository>().periodValues();
    return (places, periods);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next.catchError((_) => (const <ShortPlace>[], const <int, String>{}));
  }

  Future<void> _deletePlace(ShortPlace place) async {
    try {
      await context.read<PlacesRepository>().delete(place.id);
      showSuccessToast(LocaleKeys.place_deleted.tr());
      await _refresh();
    } on ApiException catch (error) {
      showErrorToast(error.message);
    }
  }

  void _confirmDelete(ShortPlace place) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.confirm.tr()),
        content: Text(
            LocaleKeys.delete_warning.tr(namedArgs: {'name': place.placeName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deletePlace(place);
            },
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmEdit(ShortPlace place) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.confirm.tr()),
        content: Text(LocaleKeys.edit_info.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PlaceEditForm(place.id.toString())),
              );
            },
            child: Text(LocaleKeys.ok.tr()),
          ),
        ],
      ),
    );
  }

  void _openDetails(ShortPlace place) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PlaceDetails(place.id.toString())),
    );
  }

  Widget _list(List<ShortPlace> places, Map<int, String> periods) {
    if (places.isEmpty) {
      return EmptyListState(
        message: LocaleKeys.no_place_added.tr(),
        ctaLabel: LocaleKeys.add_first_place.tr(),
        icon: Icons.place_outlined,
        // The add flow lives behind the map shell's + FAB.
        onCta: () => Navigator.popUntil(context, (route) => route.isFirst),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return Slidable(
          key: ValueKey(place.id),
          endActionPane: place.verified
              ? null
              : ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _confirmEdit(place),
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      icon: Icons.edit_location_alt_outlined,
                      label: LocaleKeys.edit.tr(),
                    ),
                    SlidableAction(
                      onPressed: (_) => _confirmDelete(place),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outlined,
                      label: LocaleKeys.delete.tr(),
                    ),
                  ],
                ),
          child: MemoryCard(
            title: place.placeName,
            periodLabel: periods[place.period],
            verified: place.verified,
            imagesFuture:
                context.read<PlacesRepository>().fetchImageUrls(place.id),
            onTap: () => _openDetails(place),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.your_places.tr())),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<(List<ShortPlace>, Map<int, String>)>(
          future: _future,
          builder: (context, snapshot) {
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
                      onPressed: _refresh,
                      child: Text(LocaleKeys.refresh.tr()),
                    ),
                  ],
                ),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _list(data.$1, data.$2),
            );
          },
        ),
      ),
    );
  }
}
