import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/memory_card.dart';
import 'package:memo_places_mobile/Objects/offline_place.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/services/data_service.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Places queued on the device waiting for the next online sync.
class OfflinePlacesList extends StatefulWidget {
  const OfflinePlacesList({super.key});

  @override
  State<OfflinePlacesList> createState() => _OfflinePlacesListState();
}

class _OfflinePlacesListState extends State<OfflinePlacesList> {
  late final Future<(List<OfflinePlace>, List<Period>)> _future =
      Future.wait([loadOfflinePlacesFromDevice(), loadPeriodsFromDevice()])
          .then((results) => (
                results[0] as List<OfflinePlace>,
                results[1] as List<Period>,
              ));

  Future<void> _deletePlace(
      List<OfflinePlace> places, OfflinePlace place) async {
    final prefs = await SharedPreferences.getInstance();
    places.remove(place);
    await prefs.setString(
        'places', jsonEncode([for (final p in places) p.toJson()]));
    if (mounted) setState(() {});
  }

  void _confirmDelete(List<OfflinePlace> places, OfflinePlace place) {
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
              _deletePlace(places, place);
            },
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<OfflinePlace>, List<Period>)>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final (places, periods) = data;
        final periodLabels = {for (final p in periods) p.id: p.value};
        if (places.isEmpty) {
          return Center(
            child: Text(
              LocaleKeys.no_place_added.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return Slidable(
              key: ValueKey(place.placeName + index.toString()),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _confirmDelete(places, place),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outlined,
                    label: LocaleKeys.delete.tr(),
                  ),
                ],
              ),
              child: MemoryCard(
                title: place.placeName,
                periodLabel: periodLabels[place.period],
                verified: false,
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }
}
