// Copyright 2017 The Chromium Authors. All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:

//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/user.dart';
import 'package:memo_places_mobile/mainPage.dart';
import 'package:memo_places_mobile/offlinePage.dart';
import 'package:memo_places_mobile/offlinePlaceAddingPage.dart';
import 'package:memo_places_mobile/services/dataService.dart';
import 'package:memo_places_mobile/welcomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InternetChecker extends StatefulWidget {
  const InternetChecker({super.key});

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> {
  late List<ConnectivityResult> connectivityResult = [];
  late User? user;
  late bool? welcomePageDisplayed;

  @override
  void initState() {
    super.initState();
    loadBoolLocalData('welcomePageDisplayed').then((value) {
      welcomePageDisplayed = value;
    });
    loadUserData().then((value) {
      user = value;
      _checkConnectivity();
    });
  }

  void _incrementCounter(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  Future<void> _checkConnectivity() async {
    var result = await (Connectivity().checkConnectivity());
    setState(() {
      connectivityResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          var content;

          if (!connectivityResult.contains(ConnectivityResult.wifi) &&
              !connectivityResult.contains(ConnectivityResult.mobile) &&
              user != null) {
            content = const OfflinePlaceAddingPage();
          } else if (!connectivityResult.contains(ConnectivityResult.wifi) &&
              !connectivityResult.contains(ConnectivityResult.mobile) &&
              user == null) {
            content = const OfflinePage();
          } else if (welcomePageDisplayed == null) {
            _incrementCounter('welcomePageDisplayed', true);
            content = const WelcomePage();
          } else {
            content = const Main();
          }

          return content;
        } else {
          return Scaffold(
              body: Center(
                  child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.scrim),
          )));
        }
      },
    );
  }
}
