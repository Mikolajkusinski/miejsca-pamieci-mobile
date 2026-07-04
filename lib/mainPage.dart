import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/apiConstants.dart';
import 'package:memo_places_mobile/customExeption.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/offlinePlace.dart';
import 'package:memo_places_mobile/Objects/period.dart';
import 'package:memo_places_mobile/Objects/sortof.dart';
import 'package:memo_places_mobile/Objects/type.dart';
import 'package:memo_places_mobile/home.dart';
import 'package:memo_places_mobile/profile.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/signInOrSignUpPage.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Main> {
  late User? _user;
  int _currentIndex = 0;
  bool _isLogged = false;
  late List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens = [
      const Home(),
      const Profile(),
    ];
    loadUserData().then(
      (value) {
        _user = value;
        if (_user != null) {
          _isLogged = true;
          _syncTypeData();
          _syncPeriodsData();
          _syncSortofData();
          _syncPlaceData(_user!.id.toString());
        } else {
          _isLogged = false;
        }
      },
    );
  }

  void _incrementCounter(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  Future<void> _syncPlaceData(String userId) async {
    List<OfflinePlace> offlinePlaces = await loadOfflinePlacesFromDevice();
    if (offlinePlaces.isNotEmpty) {
      for (OfflinePlace offlinePlace in offlinePlaces) {
        List<Future<http.StreamedResponse>> uploadFutures = [];

        Map<String, String> placeData = {
          'place_name': offlinePlace.placeName,
          'lat': offlinePlace.lat.toString(),
          'lng': offlinePlace.lng.toString(),
          'type': offlinePlace.type.toString(),
          'sortof': offlinePlace.sortof.toString(),
          'period': offlinePlace.period.toString(),
          'description': offlinePlace.description,
          'wiki_link': offlinePlace.wikiLink,
          'topic_link': offlinePlace.topicLink,
          'user': userId,
        };
        try {
          var response = await http.post(
            Uri.parse(ApiConstants.placesEndpoint),
            body: placeData,
          );

          if (response.statusCode == 200 && offlinePlace.imagesPaths != null) {
            List<File> images = offlinePlace.imagesPaths!
                .map((imagePath) => File.fromUri(Uri.parse(imagePath)))
                .toList();

            Map<String, dynamic> responseData = jsonDecode(response.body);
            String id = responseData['id'].toString();
            for (final image in images) {
              if (await image.exists()) {
                var request = http.MultipartRequest(
                    'POST', Uri.parse(ApiConstants.placeImageEndpoint));

                request.fields['place'] = id;

                var multipartFile = http.MultipartFile(
                  'img',
                  http.ByteStream(image.openRead()),
                  await image.length(),
                  filename: path.basename(image.path),
                );

                request.files.add(multipartFile);
                uploadFutures.add(request.send());
              }
            }

            var responses = await Future.wait(uploadFutures);
            bool allSuccessful =
                responses.every((response) => response.statusCode == 200);

            if (allSuccessful) {
              for (final image in images) {
                if (await image.exists()) {
                  image.delete();
                }
              }
              showSuccesToast(LocaleKeys.place_added_succes.tr());
            } else {
              throw CustomException(LocaleKeys.alert_error.tr());
            }
          } else if (response.statusCode == 200) {
            showSuccesToast(LocaleKeys.place_added_succes.tr());
          } else {
            throw CustomException(LocaleKeys.alert_error.tr());
          }
        } on CustomException catch (error) {
          showErrorToast(error.toString());
        }
      }
      deleteLocalData('places');
      setState(() {});
    } else {
      return;
    }
  }

  Future<void> _syncTypeData() async {
    List<Type> cloudTypes = await fetchTypes(context);
    List<Map<String, dynamic>> typesJsonList =
        cloudTypes.map((type) => type.toJson()).toList();

    _incrementCounter("types", jsonEncode(typesJsonList));
  }

  Future<void> _syncPeriodsData() async {
    List<Period> cloudPeriods = await fetchPeriods(context);
    List<Map<String, dynamic>> periodsJsonList =
        cloudPeriods.map((period) => period.toJson()).toList();

    _incrementCounter("periods", jsonEncode(periodsJsonList));
  }

  Future<void> _syncSortofData() async {
    List<Sortof> cloudSortof = await fetchSortof(context);
    List<Map<String, dynamic>> sortofJsonList =
        cloudSortof.map((sortof) => sortof.toJson()).toList();

    _incrementCounter("sortofs", jsonEncode(sortofJsonList));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: _isLogged ? _screens[_currentIndex] : const Home(),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              label: LocaleKeys.home.tr(),
              icon: const Icon(Icons.home, size: 27),
            ),
            BottomNavigationBarItem(
              label: LocaleKeys.profile.tr(),
              icon: const Icon(Icons.account_box_outlined, size: 27),
            ),
          ],
          currentIndex: _currentIndex,
          onTap: (int index) {
            if (index == 1 && !_isLogged) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SignInOrSingUpPage()),
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}
