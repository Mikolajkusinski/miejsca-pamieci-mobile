# Memory places (Mobile)

A project aimed at preserving the memory of historical places around the world. The application allows users to collectively create a database of forgotten or undiscovered places so that their cultural heritage is preserved for future generations. The software provides an interactive platform that allows users to add, edit and share information about historical places. Through this shared platform, history enthusiasts, travelers or simply those seeking historical knowledge will together contribute to documenting and preserving cultural heritage.

## Functionalities

- Place managamend(add, edit, delete);
- Place adding without internet connection;
- Login and register functionality;
- Logout functionality;
- Profile page;
- Google Maps Api connection;
- Navigation panel;
- Memory places marker functionality;
- Google Maps trail functionality;
- Live location;
- Adaptation for disabilities;
- Forum page;

## Installation

1. Download source code from this repo.</br>
2. Open downloaded project in your desired IDE(Android Studio, VSCode);</br>

### VSCode installation

3. Install from Extension menu Flutter and Dart extensions. </br>
4. On prompt appearing in the bottom right click <strong>download Flutter SDK</strong> and choose where to save flutter SDK folder.</br>
5. After a while click <strong>APP PATH</strong> to make sure that you have access from any point of current place to flutter library.</br>
   <strong>(at this moment you can check if you can call <strong>flutter doctor</strong> in your command prompt)</strong></br>
6. After that click button <strong>pub get</strong> to download updates for some old libraries/dependecies.</br>
7. If you'll have any trouble to this point install <strong>Flutter SDK</strong> from webpage from this [link](https://docs.flutter.dev/get-started/install)</br>
8. Click on the bottom right side to choose what device to use (by default should - if on windows <strong>Windows (windows-x64)</strong>).</br>
9. Then choose from menu to run <strong>Start flutter emulator</strong>.</br>
10. After a while you should see the app displayed on mobile emulator.</br>

### Android Studio

3. Install Flutter SDK from webpage from this [link](https://docs.flutter.dev/get-started/install)</br>
   <strong>(at this moment you can check if you can call flutter doctor in your command prompt)</strong></br>
4. In the Android Studio click <strong>settings</strong> -> <strong>plugins</strong> and find flutter extension and install it.</br>
5. On any displayed prompts click accept or install to make sure that all necessary dependencies are also installed.</br>
6. After that click <strong>Restart IDE</strong>.</br>
7. After restarting IDE go to your project folder and in the top right side of window click <strong>Device Manager</strong>.</br>
8. After that click you should see one added mobile emulator (If you don't have one click button <strong>Create Device</strong>).</br>
9. Click on the given mobile emulator in action section <strong>Launch this AVD in the emulator</strong>.</br>
10. After a while you should see the app displayed on mobile emulator.</br>

## Configuration

The app reads its backend configuration at build time via `--dart-define-from-file`:

```console
# Development (local BackendDotNet on http://localhost:5158, Android emulator loopback):
flutter run --dart-define-from-file=env/dev.json

# Production (copy env/prod.json.example to env/prod.json and fill in real values — git-ignored):
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

Keys: `API_BASE_URL`, `PROD`, `COGNITO_USER_POOL_ID`, `COGNITO_APP_CLIENT_ID`,
`COGNITO_REGION`, `COGNITO_DOMAIN` (Hosted UI, only needed for Google sign-in),
`SENTRY_DSN` (crash reporting — active only when `PROD` is true and the DSN is
non-empty; breadcrumbs carry request method/path/status, never bodies or tokens).
When the Cognito ids are empty the app still runs — map browsing is anonymous
and auth entry points disable themselves.

`API_BASE_URL` must be `https://` in production builds — `ApiClient` asserts
this in debug builds when `PROD` is true, and Android/iOS block cleartext HTTP
by default (no `usesCleartextTraffic`/ATS exceptions are configured).

Google Maps API keys live outside version control:

- Android: `android/secrets.properties` (`GOOGLE_MAPS_API_KEY=...`)
- iOS: `ios/Flutter/Secrets.xcconfig` (`GOOGLE_MAPS_API_KEY = ...`)

Before release (owner action, Google Cloud console): rotate any Maps key that
previously lived in a `flutter_config` `.env` file on a dev machine, and
restrict the replacements — the Android key by package name
`pl.memoryplaces.mobile` + the upload key's SHA-1 (created in the release
signing step), the iOS key by the bundle id.

## Tests

```console
# Static analysis (CI fails on warnings):
flutter analyze --fatal-warnings

# Unit + widget tests:
flutter test

# Happy-path integration test (needs a device or simulator; the backend is
# faked in-process, so no server or Cognito pool is required):
flutter test integration_test/happy_path_test.dart -d <device-id>
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add carousel_slider
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add intl
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add fluttertoast
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add google_sign_in
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add flutter_slidable
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add cross_file
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add image_picker
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add connectivity_plus easy_localization
```

```console
PS C:\PATH_TO_YOUR_PROJECT\memo_places_mobile> flutter pub add easy_localization
```

## Authors

- Sebastian Mackiewicz
- Mikołaj Kusiński
- Dariusz Karasiewicz
