import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:memo_places_mobile/MyPlacesAndTrailsWidgets/myPlaceBox.dart';
import 'package:memo_places_mobile/Objects/shortPlace.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/formWidgets/customTitle.dart';
import 'package:memo_places_mobile/placeDetails.dart';
import 'package:memo_places_mobile/placeEditForm.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class MyPlaces extends StatefulWidget {
  const MyPlaces({super.key});

  @override
  State<MyPlaces> createState() => _MyPlacesState();
}

class _MyPlacesState extends State<MyPlaces> {
  late List<ShortPlace> _places = [];
  late User? _user;
  late bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData().then(
      (user) => setState(() {
        _user = user;
        try {
          fetchUserPlaces(context, _user!.id.toString()).then(
            (places) => setState(() {
              _places = places;
              _isLoading = false;
            }),
          );
        } on CustomException catch (error) {
          showErrorToast(error.toString());
        }
      }),
    );
  }

  void _showDeleteDialog(int index) {
    BuildContext dialogContext;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context;

        return AlertDialog(
          title: Text(LocaleKeys.confirm.tr()),
          content: Text(
            LocaleKeys.delete_warning
                .tr(namedArgs: {'name': _places[index].placeName}),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                LocaleKeys.cancel.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.scrim),
              ),
            ),
            TextButton(
              onPressed: () {
                _deletePlace(index);
                Navigator.pop(dialogContext);
              },
              child: Text(
                LocaleKeys.delete.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.scrim),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(int index) {
    BuildContext dialogContext;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context;

        return AlertDialog(
          title: Text(LocaleKeys.confirm.tr()),
          content: Text(LocaleKeys.edit_info.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                LocaleKeys.cancel.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.scrim),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PlaceEditForm(_places[index].id.toString()),
                  ),
                );
              },
              child: Text(
                LocaleKeys.ok.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.scrim),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlace(int index) async {
    try {
      final response = await http.delete(Uri.parse(
          ApiConstants.placeByIdEndpoint(_places[index].id.toString())));
      if (response.statusCode == 200) {
        showSuccesToast(LocaleKeys.place_deleted.tr());
        setState(() {
          _places.removeAt(index);
        });
      } else {
        throw CustomException(LocaleKeys.alert_error.tr());
      }
    } on CustomException catch (error) {
      showErrorToast(error.toString());
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
            : Column(
                children: [
                  CustomTitle(title: LocaleKeys.your_places.tr()),
                  _places.isEmpty
                      ? Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 3,
                            ),
                            SizedBox(
                              width: 300,
                              child: Text(
                                LocaleKeys.no_place_added.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    overflow: TextOverflow.clip),
                              ),
                            ),
                          ],
                        )
                      : Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _places.length,
                              itemBuilder: (context, index) {
                                final place = _places[index];
                                return Slidable(
                                    startActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      extentRatio: 0.5,
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PlaceDetails(
                                                        place.id.toString()),
                                              ),
                                            );
                                          },
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          icon: Icons.arrow_forward,
                                          label: LocaleKeys.preview.tr(),
                                        )
                                      ],
                                    ),
                                    endActionPane: place.verified
                                        ? null
                                        : ActionPane(
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) {
                                                  _showEditDialog(index);
                                                },
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                icon: Icons
                                                    .edit_location_alt_outlined,
                                                label: LocaleKeys.edit.tr(),
                                              ),
                                              SlidableAction(
                                                onPressed: (context) {
                                                  _showDeleteDialog(index);
                                                },
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                icon: Icons.delete_outlined,
                                                label: LocaleKeys.delete.tr(),
                                              )
                                            ],
                                          ),
                                    child: MyPlaceBox(place: place));
                              },
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
