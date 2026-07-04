# Miejsca Pamięci Mobile — Production Readiness & Map-First UI Redesign Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Flutter app (memo_places_mobile) to production quality: modern map-first UI matching the web app's cyan/slate theme, hardened error handling and security, current SDK toolchain, and store-ready builds.

**Architecture:** Keep the existing Flutter + Provider + easy_localization stack, but introduce a thin service layer (`ApiClient` + `SessionStore`) that every screen goes through, a single design-token file that mirrors the web theme, and a full-screen map shell where every other surface is a floating overlay or bottom sheet on top of the map.

**Tech Stack:** Flutter ≥ 3.35 (Dart ≥ 3.9), google_maps_flutter, geolocator, provider, easy_localization, flutter_secure_storage, google_fonts (Manrope), http (with timeouts) — plus AGP 8.9 / Gradle 8.12 / Kotlin 2.1 / Java 17 on Android.

---

## Execution Log (state for continuing in a new session)

**Decisions (confirmed with product owner 2026-07-04):**
- Backend: **Option A** (.NET API + Cognito). Cognito pool **not deployed yet** → app built against placeholder config; real ids go into `env/dev.json`/`env/prod.json` via `--dart-define-from-file` (see README "Configuration").
- Dev API base is `http://10.0.2.2:5158` (BackendDotNet's local port per the web repo, not the 5000 the plan guessed).
- Android application ID: `pl.memoryplaces.mobile` (confirmed).

**Branches/PRs (one per phase; stacking corrected 2026-07-04):**
- Phase 0 → PR #1 (squash-merged to main).
- Phase 1 → PR #2 was merged into the *phase-0 branch* (stacked-PR mishap), not main.
- Phase 2 → PR #3 was merged into the *phase-1 branch*, not main.
- Recovery: PR #4 (`phase-1-api-auth` → main) carries **Phases 1+2 together**; main was tied in with an `-s ours` merge (main's squashed Phase 0 tree verified byte-identical to commit aa84fce in this branch's history — nothing lost). After PR #4 merges, all phase branches are fully contained in main and deleted.
- **Phases 0–2 complete; next session starts Phase 3 (Task 3.1) branched from `main`. Future phase PRs: base each on the previous phase branch only while unmerged; merge bottom-up (oldest first) and re-target the next PR to main after each merge — or simply merge each phase before starting the next.**

**Deviations from the written plan:**
- `mykey.jks` was never actually committed (B6 partly stale); the dangling signing config was removed. Release builds are **debug-signed until Task 6.4** (acknowledged on PR #1).
- Kotlin **2.2.20** instead of 2.1.20 (2.1.x K2 compiler crashes on google_maps_flutter_android's generated code).
- `minSdkVersion flutter.minSdkVersion` (owner's adjustment) instead of hardcoded 23.
- `carousel_slider` → plain `PageView` already in Task 0.4 (compilation forced it; Phase 4 still restyles).
- `googleSignInApi.dart` rewritten for google_sign_in 7.x to keep compiling; still deleted in Task 2.4 as planned.
- `apiConstants.dart` kept with a deprecation banner (old constants still have compiling-but-dead callers); shrinks/deletes as Phases 2/4 migrate screens.
- Locale keys `session_expired`/`no_connection_error` added during Task 1.3 (needed earlier than planned).
- `AuthService` exposes `isConfigured` (mirrors web's `isAmplifyConfigured`): with empty Cognito ids the app runs in anonymous map-browsing mode instead of crashing.
- `Session.user` from Cognito attributes carries `id: 0`; the backend numeric user id comes from `GET /api/v1/users/me` when needed (list filtering uses OData `$filter=userId eq N`).
- Repositories enrich models with category display values (id → localization key) via a cached `CatalogRepository`, because the .NET DTOs carry only ids and screens render `*Value` fields.
- Places/paths list endpoints are OData-paged (PageSize 25, MaxTop 100): repositories page with `$top=100&$skip=N`.

**Phase 2 deviations:**
- `mainPage.dart` → `main_page.dart` (not `main_shell.dart` — Phase 3 introduces `lib/map/map_shell.dart` as its replacement anyway).
- `custom_exception.dart` kept (renamed): the legacy edit/offline forms and `home.dart` still throw it; it dies with them in Phases 3/4.
- `test/UnitTests/distance_algorythm_test.dart` deleted in favor of `trail_math_test.dart` (tests `filterAndAccumulate` + `TrailAccumulator` in `lib/services/trail_math.dart`).
- Detail screens no longer render the "added by {username}" row — the .NET DTOs don't expose usernames.
- `POST_NOTIFICATIONS` added alongside the FOREGROUND_SERVICE permissions (Android 13+ requires it for the recording notification).
- Offline sync: when create succeeds but image upload fails, the place is NOT requeued (would duplicate); local image files are kept, photos re-addable from edit. Summary toast uses `sync_result`.
- Contact form sends the signed-in user's email or empty string for guests (Phase 4.4 adds a proper email field).
- Analyzer is at **0 issues** (beat the <20-infos target); no analyzer excludes were needed.
- New locale keys added ×4 languages: `location_services_off`, `open_settings`, `sync_result`, `recording_notification_title/text`, `keep_app_open_info`, `invalid_email`.

---

## Audit Summary (what the deep scan found)

### 🔴 Blockers — the app cannot ship as-is

| # | Problem | Where |
|---|---------|-------|
| B1 | **Compile errors on current Flutter**: `DialogTheme` passed where `DialogThemeData` is required (2 errors from `flutter analyze`) | `lib/Theme/theme.dart:28`, `lib/Theme/theme.dart:55` |
| B2 | **Release builds have no network access**: `android.permission.INTERNET` exists only in the *debug* manifest; the main manifest never declares it | `android/app/src/main/AndroidManifest.xml` |
| B3 | **API points at a dev machine over cleartext HTTP**: `http://localhost:8000/memo_places/` is hardcoded; Android 9+ and iOS ATS block cleartext by default, so even with a real host this fails | `lib/apiConstants.dart:2` |
| B4 | **Backend drift**: the web repo has migrated to a .NET API (`/api/v1/*`, `Authorization: Bearer <Cognito token>`, `201 Created` for creates). The Django API the mobile app targets no longer exists in the repos. Every endpoint, status-code check, and the `"JWT"` header are wrong against the live backend | all of `lib/apiConstants.dart`, every screen doing HTTP |
| B5 | **Writes are unauthenticated**: place/trail create, update and delete send **no auth header at all** (only `editProfile.dart` and the Google sign-in check attach one) | `lib/place_form.dart:102`, `lib/myPlaces.dart:134`, `lib/myTrails.dart:134`, `lib/placeEditForm.dart:100`, `lib/trailForm.dart:128` |
| B6 | **Play Store requirements**: `applicationId "com.example.memo_places_mobile"` (reserved namespace — Play rejects it), `targetSdkVersion 34` (Play requires 35+ since Aug 2025), release build signed with a committed debug keystore (`mykey.jks`, password `android` in the repo) | `android/app/build.gradle` |
| B7 | **Ancient Android toolchain**: AGP 7.3.0, Gradle 7.6.3, Kotlin 1.7.10, Java 1.8 — incompatible with compileSdk 35/36 and current plugin versions | `android/settings.gradle`, `android/gradle/wrapper/gradle-wrapper.properties` |

### 🟠 High-priority bugs

| # | Problem | Where |
|---|---------|-------|
| H1 | JWT stored **in plaintext SharedPreferences**, never refreshed, expiry never checked — after it expires, authenticated calls silently fail until manual sign-out | `lib/signIn.dart:86`, `lib/services/dataService.dart:189` |
| H2 | Loading dialog leaks forever on any network exception: only `CustomException` is caught, so a `SocketException`/timeout leaves the modal spinner up permanently | `lib/signIn.dart:62-103`, `lib/signUp.dart:62-101` |
| H3 | Permission-denied on location = **eternal spinner**: `_getCurrentLocation()` returns `Future.error(...)` but the `.then` chain has no error handler, so `_isLoading` never clears and nothing is shown | `lib/home.dart:55-65` |
| H4 | `late StreamSubscription` crash: if location permission is denied, `_positionStreamSubscription` is never assigned, and `dispose()` throws `LateInitializationError` | `lib/home.dart:71`, same pattern `lib/trailRecordPage.dart:49` |
| H5 | **Offline data loss**: `_syncPlaceData` deletes all locally saved places (`deleteLocalData('places')`) even when uploads failed | `lib/mainPage.dart:136` |
| H6 | Google sign-up crash: `user.copyWith(jwtToken: jsonDecode(secondResponse.body))` passes a `Map` where a `String` is required — runtime type error on the new-account path | `lib/services/googleSignInApi.dart:86` |
| H7 | `InternetChecker` races its own `late` fields: `user`/`welcomePageDisplayed` are set in `initState().then(...)` but read in `build()` via a *separate* `FutureBuilder` — `LateInitializationError` when the builder wins the race; it also writes prefs during build | `lib/internetChecker.dart:47-98` |
| H8 | Sign-out uses `Navigator.push` (not `pushReplacement`), so the back button returns to the logged-in profile | `lib/profile.dart:29-36` |
| H9 | `try/catch` around `.then()` catches nothing: async fetch errors in `PlaceDetails`/`PlaceForm` initState are unhandled → stuck spinners | `lib/placeDetails.dart:29-41`, `lib/place_form.dart:54-72` |
| H10 | Trail recording dies when the screen locks: no foreground service / background-location permission; distance uses raw GPS jitter (no `distanceFilter`/accuracy filter) so it over-counts; timer drifts (counts callbacks, not elapsed time) | `lib/trailRecordPage.dart` |
| H11 | No request timeouts anywhere; no `mounted` checks after `await` (dozens of `use_build_context_synchronously` analyzer warnings) | all HTTP call sites |
| H12 | `PopScope(canPop: false)` disables Android back entirely on the main page | `lib/mainPage.dart:169` |
| H13 | Connectivity check is one-shot and only accepts wifi/mobile — ethernet/VPN counts as "offline"; app never reacts to connectivity changes after launch | `lib/internetChecker.dart:68-90` |
| H14 | "Reset password" also logs the user out (removes stored user, navigates away) | `lib/editProfile.dart:46-69` |
| H15 | `_user!` null-assert races: profile and place form dereference `_user!` before the async load can finish | `lib/profile.dart:105`, `lib/place_form.dart:98` |

### 🟡 Hygiene / missing pieces

- `mockito` and `dartdoc` are in runtime `dependencies` (should be dev); `intl: any` and bare `provider:` are unpinned (`pubspec.yaml:56-59`).
- `carousel_slider` is discontinued (Flutter now ships `CarouselView`); `flutter_config` is abandoned (still wired into `ios/Runner/AppDelegate.swift:12`); `google_sign_in` 6.x is superseded by 7.x with breaking API changes.
- `WRITE_EXTERNAL_STORAGE`/`READ_EXTERNAL_STORAGE` are obsolete on API 33+ and unneeded by `image_picker` — they only add Play review friction.
- iOS: deprecated `NSLocationAlwaysUsageDescription`, generic English-only permission strings (App Store review risk), and **no `PrivacyInfo.xcprivacy`** (required since May 2024).
- No crash reporting, no CI, no release signing story, 261 `flutter analyze` findings, misspelled identifiers throughout (`customExeption`, `prewiewTrail`, `currnetObject`, `fechedPlaces`, `succes`), camelCase file names against Dart convention.
- The email endpoints mangle addresses (`.` → `&`) to satisfy a quirk of the dead Django API (`lib/apiConstants.dart:53,61`).
- Tests exist (unit + widget + integration) but assert against the old UI and old API flows — they will need updating alongside the redesign.

---

## Global Constraints

- Flutter ≥ 3.35 stable, Dart SDK constraint `^3.9.0` (machine has Flutter 3.38.4 / Dart 3.10.3 — fine).
- Android: `compileSdk 36`, `targetSdk 35`, `minSdk 23`, AGP 8.9.x, Gradle 8.12, Kotlin 2.1.x, Java 17.
- iOS: minimum deployment target 14.0.
- **Color parity with web** (`FrontendV2/src/app/theme.ts`): primary `#0891B2`; light = `#FFFFFF` bg / `#F1F5F9` surface / `#E2E8F0` divider / black text; dark = `#171717` bg / `#262626` surface / `#404040` divider / white text.
- **The map is the app.** It covers the full screen at all times on the home experience; every other home-screen element floats above it.
- All user-facing strings go through easy_localization (en/pl/de/ru) — no hardcoded literals (fixes e.g. `lib/signUp.dart:107`).
- No secrets in the repo: Maps API keys stay in `secrets.properties` (Android) / env (iOS); delete the committed `mykey.jks` and its passwords from `build.gradle`.
- Every HTTP call: 15 s timeout, catches `SocketException`/`TimeoutException`/`http.ClientException`, checks `mounted` before using `BuildContext` after `await`.
- Commit at the end of every task; `flutter analyze` must not add new warnings from a task's changes.

---

## ⚠️ Decision Gate (before Phase 1): which backend?

The web product now runs on the .NET API (`/api/v1/*`) with **AWS Cognito** auth (`Authorization: Bearer`). The Django API the mobile app calls does not exist in either repo anymore.

- **Recommended — Option A:** migrate the mobile app to the .NET API + Cognito (via `amplify_flutter`, same user pool as `FrontendV2/src/features/auth/amplify.ts`). Phase 1 below is written for this option.
- **Option B (only if the Django backend is still deployed somewhere):** keep the endpoints but you must still do everything else in Phase 1 (config by environment, timeouts, secure token storage, attach the auth header to every write, handle 201).

Confirm Option A/B with the product owner before starting Phase 1. Phases 0, 2, 3, 4 are valid either way.

---

# Phase 0 — Toolchain & Build Health (make it build and run everywhere)

**Outcome:** `flutter analyze` has 0 errors, `flutter build apk --release` and `flutter build ios --no-codesign` succeed, Play/App Store baseline requirements met.

### Task 0.1: Fix the two compile errors

**Files:**
- Modify: `lib/Theme/theme.dart:27-28`, `lib/Theme/theme.dart:54-55`

- [x] **Step 1:** Replace both occurrences:

```dart
// before (both light and dark themes):
dialogTheme:
    const DialogTheme().copyWith(surfaceTintColor: lightColorScheme.scrim),

// after:
dialogTheme: DialogThemeData(surfaceTintColor: lightColorScheme.scrim),
```

(and `darkColorScheme.scrim` in the dark theme block).

- [x] **Step 2:** Run `flutter analyze | grep error` → expected: no output.
- [x] **Step 3:** Commit: `fix: replace deprecated DialogTheme with DialogThemeData`

> Note: this file is fully replaced in Phase 3; this fix just unblocks builds until then.

### Task 0.2: Android manifest — permissions that match reality

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [x] **Step 1:** Add INTERNET and remove obsolete storage permissions. The permission block becomes exactly:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

(delete `WRITE_EXTERNAL_STORAGE` and `READ_EXTERNAL_STORAGE` — `image_picker` uses the system photo picker on modern Android and scoped storage elsewhere.)

- [x] **Step 2:** Build and install a **release** APK on a device/emulator (`flutter build apk --release`, `adb install ...`), open the app, confirm network calls fire (they will 4xx/timeout against localhost — that's fine, they must not fail with a permission error).
- [x] **Step 3:** Commit: `fix(android): declare INTERNET in main manifest, drop legacy storage permissions`

### Task 0.3: Upgrade the Android toolchain

**Files:**
- Modify: `android/settings.gradle`, `android/gradle/wrapper/gradle-wrapper.properties`, `android/app/build.gradle`, `android/gradle.properties`

- [x] **Step 1:** `android/gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
```

- [x] **Step 2:** `android/settings.gradle` plugins block:

```groovy
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.9.1" apply false
    id "org.jetbrains.kotlin.android" version "2.1.20" apply false
}
```

- [x] **Step 3:** `android/app/build.gradle` — new `android {}` core:

```groovy
android {
    namespace "pl.memoryplaces.mobile"   // final ID — coordinate with the web team's domain
    compileSdk 36

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = '17' }

    defaultConfig {
        applicationId "pl.memoryplaces.mobile"
        minSdkVersion 23
        targetSdkVersion 35
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
    // signing: see Task 6.4 — until then, debug-sign release locally but
    // DELETE the committed mykey.jks and the hardcoded signingConfigs block.
}
```

- [x] **Step 4:** Delete `android/app/mykey.jks` from the repo and add `*.jks` + `key.properties` to `.gitignore`. (The old keystore is debug-grade with a public password — treat it as compromised; a fresh upload key is created in Task 6.4.)
- [x] **Step 5:** `flutter clean && flutter build apk --release` → BUILD SUCCESSFUL.
- [x] **Step 6:** Commit: `chore(android): AGP 8.9 / Gradle 8.12 / Kotlin 2.1, SDK 36/35, real application id`

### Task 0.4: Dependency cleanup and upgrades

**Files:**
- Modify: `pubspec.yaml`, `ios/Runner/AppDelegate.swift`, `ios/Podfile`

- [x] **Step 1:** Rewrite the dependency blocks:

```yaml
environment:
  sdk: ^3.9.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.5.0
  google_maps_flutter: ^2.14.0
  geolocator: ^14.0.0
  shared_preferences: ^2.5.0        # non-sensitive prefs only
  flutter_secure_storage: ^9.2.4    # NEW: tokens live here
  jwt_decoder: ^2.0.1
  flutter_svg: ^2.2.0
  url_launcher: ^6.3.0
  intl: ^0.20.0
  fluttertoast: ^9.0.0
  google_sign_in: ^7.2.0
  flutter_slidable: ^4.0.0
  image_picker: ^1.2.0
  connectivity_plus: ^7.0.0
  easy_localization: ^3.0.8
  provider: ^6.1.0
  path_provider: ^2.1.5
  google_fonts: ^6.3.0              # NEW: Manrope display face (Phase 3)

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_launcher_icons: ^0.14.0
  flutter_lints: ^6.0.0
  mockito: ^5.5.0                   # moved out of runtime deps
```

Removed: `flutter_config` (abandoned), `carousel_slider` (discontinued → replace usages with Flutter's built-in `CarouselView` or a plain `PageView` in Phase 4), `dartdoc` and `cross_file` (unused as direct deps).

- [x] **Step 2:** `flutter pub get` → resolves. Fix any breaking-change compile errors it surfaces (notably `google_sign_in` 7.x: the singleton is `GoogleSignIn.instance`, init via `initialize(clientId: ...)`, sign-in via `authenticate()` — rewrite `lib/services/googleSignInApi.dart` accordingly; `geolocator` 14: `desiredAccuracy` → `LocationSettings`).
- [x] **Step 3:** iOS: remove `import flutter_config` from `ios/Runner/AppDelegate.swift` and replace the key lookup:

```swift
GMSServices.provideAPIKey(
  Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? "")
```

Add to `ios/Runner/Info.plist`: `<key>GMSApiKey</key><string>$(GOOGLE_MAPS_API_KEY)</string>` and define `GOOGLE_MAPS_API_KEY` in a git-ignored `ios/Flutter/Secrets.xcconfig` included from `Debug.xcconfig`/`Release.xcconfig`. Set `platform :ios, '14.0'` in `ios/Podfile`; run `pod install`.

- [x] **Step 4:** `flutter analyze` (no new errors), `flutter build ios --no-codesign` and `flutter build apk --release` both succeed.
- [x] **Step 5:** Commit: `chore(deps): upgrade to maintained packages, drop flutter_config/carousel_slider, secure iOS key injection`

---

# Phase 1 — API Layer, Config & Auth (Option A: .NET API + Cognito)

**Outcome:** one `ApiClient` used by every screen; base URL from `--dart-define`; tokens in secure storage with refresh; every request has a timeout and typed errors.

### Task 1.1: Environment configuration

**Files:**
- Create: `lib/config/app_config.dart`
- Create: `env/dev.json`, `env/prod.json` (git-ignored prod values)

- [x] **Step 1:**

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000', // Android-emulator loopback for local dev
  );
  static const bool isProd =
      bool.fromEnvironment('PROD', defaultValue: false);
}
```

```json
// env/dev.json
{ "API_BASE_URL": "http://10.0.2.2:5000", "PROD": false }
// env/prod.json
{ "API_BASE_URL": "https://<production-api-host>", "PROD": true }
```

Run configs become `flutter run --dart-define-from-file=env/dev.json`. Document both in `README.md`.

- [x] **Step 2:** Write test `test/UnitTests/app_config_test.dart` asserting the default value, run it, commit: `feat: environment-based API configuration via dart-define`

### Task 1.2: SessionStore — secure token handling

**Files:**
- Create: `lib/services/session_store.dart`
- Test: `test/UnitTests/session_store_test.dart`

**Interfaces (later tasks rely on exactly these):**
- `Future<Session?> SessionStore.load()`
- `Future<void> SessionStore.save(Session session)`
- `Future<void> SessionStore.clear()`
- `class Session { final String accessToken; final String refreshToken; final User user; bool get isExpired; }` (`isExpired` uses `JwtDecoder.isExpired(accessToken)`)

- [x] **Step 1:** Write failing tests: save→load round-trip (mock `FlutterSecureStorage` with an in-memory map), `load()` returns null when empty, `isExpired` true for an expired JWT literal.
- [x] **Step 2:** Implement with `FlutterSecureStorage` keys `session.access`, `session.refresh`, `session.user` (user JSON may stay in shared_preferences — it's not secret; tokens must not).
- [x] **Step 3:** Migration: on first `load()`, if legacy `SharedPreferences` key `user` exists, import its token into secure storage and delete the legacy key.
- [x] **Step 4:** Tests pass → commit: `feat: SessionStore with secure token storage and legacy migration`

### Task 1.3: Cognito auth (amplify_flutter)

**Files:**
- Create: `lib/services/auth_service.dart`, `lib/amplifyconfiguration.dart` (values copied from the web app's `FrontendV2/src/features/auth/amplify.ts` pool/client IDs — mobile needs its **own app client** in the same user pool, created in the Cognito console)
- Modify: `lib/main.dart` (Amplify.configure before runApp)
- Delete (at end of phase): `lib/services/googleSignInApi.dart`

**Interfaces:**
- `Future<Session> AuthService.signIn(String email, String password)`
- `Future<void> AuthService.signUp(String email, String username, String password)` (+ `confirmSignUp(email, code)`)
- `Future<Session> AuthService.signInWithGoogle()` (Cognito federated Google — replaces google_sign_in flow entirely)
- `Future<void> AuthService.resetPassword(String email)`
- `Future<String?> AuthService.currentAccessToken()` — returns a fresh token (Amplify auto-refreshes), null when signed out

- [x] **Step 1:** Add `amplify_flutter: ^2.6.0`, `amplify_auth_cognito: ^2.6.0` to pubspec.
- [x] **Step 2:** Implement `AuthService` wrapping `Amplify.Auth`; every method maps Amplify exceptions to `ApiException` (Task 1.4) with localized messages (`LocaleKeys.bad_credentials`, `LocaleKeys.account_exist`, `LocaleKeys.alert_error`).
- [ ] **Step 3:** Manual verification against the dev user pool: sign in with a test user, print `currentAccessToken()`, call `GET /api/v1/places` with it via curl → 200. *(BLOCKED 2026-07-04: Cognito pool not deployed yet — app runs with empty Cognito ids in anonymous mode; run this once real ids exist in `env/*.json`.)*
- [x] **Step 4:** Commit: `feat: Cognito auth via Amplify, replacing custom JWT + google_sign_in flows`

> **Option B fallback:** skip Amplify; `AuthService` keeps POSTing to the Django token endpoint but stores tokens via `SessionStore`, checks `isExpired` before each request, and signs the user out (with a toast) on expiry.

### Task 1.4: ApiClient — one way to talk to the backend

**Files:**
- Create: `lib/services/api_client.dart`, `lib/services/api_exception.dart`
- Test: `test/UnitTests/api_client_test.dart` (uses `http.MockClient`)
- Delete (once callers migrate): `lib/customExeption.dart`

**Interfaces:**
- `class ApiException implements Exception { final String message; final int? statusCode; }` — `message` is already localized.
- `class ApiClient { ApiClient(this._auth, {http.Client? inner}); Future<dynamic> get(String path); Future<dynamic> post(String path, {Object? body}); Future<dynamic> put(String path, {Object? body}); Future<void> delete(String path); Future<dynamic> multipart(String path, Map<String,String> fields, List<File> files, {String fileField = 'file'}); }`
- All methods: prefix `AppConfig.apiBaseUrl`, attach `Authorization: Bearer <token>` when `AuthService.currentAccessToken()` returns one, `Content-Type: application/json`, `.timeout(const Duration(seconds: 15))`, decode `utf8.decode(response.bodyBytes)`.
- Success = `statusCode >= 200 && < 300` (fixes the ubiquitous `== 200` checks; the .NET API returns 201/204).
- Failure mapping: `401` → clear session + throw `ApiException(LocaleKeys.session_expired.tr(), 401)`; RFC 7807 body → use its `detail`/`title`; `SocketException`/`TimeoutException` → `ApiException(LocaleKeys.no_connection_error.tr())`.

- [x] **Step 1:** Write failing tests: adds Bearer header when logged in; omits it when logged out; throws `ApiException` with problem-details message on 400; throws localized network error on `SocketException`; treats 201 and 204 as success.
- [x] **Step 2:** Implement; run tests → PASS.
- [x] **Step 3:** Add new locale keys `session_expired`, `no_connection_error` to all four files in `lib/assets/translations/` and regenerate (`dart run easy_localization:generate -S lib/assets/translations -O lib/translations -o locale_keys.g.dart -f keys`).
- [x] **Step 4:** Commit: `feat: ApiClient with timeouts, bearer auth, typed errors, 2xx handling`

### Task 1.5: Repositories against `/api/v1`

**Files:**
- Create: `lib/services/places_repository.dart`, `lib/services/trails_repository.dart`, `lib/services/catalog_repository.dart` (types/sortofs/periods → the .NET `Categories` endpoints), `lib/services/contact_repository.dart`
- Rewrite: `lib/apiConstants.dart` → shrink to path constants under `/api/v1` (`/api/v1/places`, `/api/v1/paths`, `/api/v1/place-images`, … — read the exact routes from `miejsca-pamieci-web/BackendDotNet/src/MemoryPlaces.Api/Features/*/​*Endpoints.cs` while implementing; delete the email-mangling `.`→`&` helpers)
- Modify: `lib/services/dataService.dart` → its fetch functions delegate to the repositories (then delete it once all callers are migrated in Phases 2/4)
- Test: `test/UnitTests/places_repository_test.dart`

**Interfaces:**
- `Future<List<Place>> PlacesRepository.getAll()` / `Future<Place> getById(int id)` / `Future<int> create(PlaceDraft draft)` / `Future<void> update(int id, PlaceDraft draft)` / `Future<void> delete(int id)` / `Future<void> uploadImages(int placeId, List<File> images)`
- Symmetric `TrailsRepository` for `/api/v1/paths`.
- `PlaceDraft` = the create/update body matching `CreatePlaceBody` (PlaceName, Description, Lng, Lat, TypeId, SortofId, PeriodId, WikiLink, TopicLink). **The user id is no longer sent — the backend derives it from the token.**

- [x] **Step 1:** For each repository: failing MockClient test (correct path + verb + body shape, DTO parsing from a captured real response) → implement → pass.
- [x] **Step 2:** Update `lib/Objects/place.dart`, `trail.dart`, etc. `fromJson` to the .NET DTO field casing (check `PlaceDetailDto` in the backend source; add tests with real JSON fixtures in `test/fixtures/`).
- [x] **Step 3:** Commit per repository.

---

# Phase 2 — Bug Fixes & Error-Handling Hardening

**Outcome:** every issue in the H-table above is fixed. Each task = red test (where feasible) → fix → green → commit. All of these are straightforward once Phase 1 exists, because screens now call repositories that throw a single exception type.

### Task 2.1: Kill the loading-dialog leaks (H2)

**Files:** Create `lib/shared/busy_overlay.dart`; modify `lib/signIn.dart`, `lib/signUp.dart`, `lib/forgotPasswordPage.dart`, `lib/contactUsForm.dart`

- [x] **Step 1:** Implement one helper used everywhere:

```dart
Future<T> runWithBusyOverlay<T>(
    BuildContext context, Future<T> Function() action) async {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()));
  try {
    return await action();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
```

- [x] **Step 2:** Rewrite `_login`/`_signUp`/submit handlers as:

```dart
try {
  final session = await runWithBusyOverlay(context, () =>
      context.read<AuthService>().signIn(email, password));
  if (!mounted) return;
  Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const InternetChecker()));
  showSuccesToast(LocaleKeys.succes_signed_in.tr());
} on ApiException catch (e) {
  showErrorToast(e.message);
}
```

(no more `setState` around navigation, no more uncaught `SocketException`, `mounted` checked after every await).

- [x] **Step 3:** Widget test: pump SignIn with an AuthService stub that throws `ApiException`; tap sign-in; assert no dialog remains (`find.byType(CircularProgressIndicator)` is empty) and screen is still interactive.
- [x] **Step 4:** Commit: `fix: loading overlays always dismissed; auth errors surfaced`

### Task 2.2: Location permission flow that can't hang (H3, H4)

**Files:** Create `lib/services/location_service.dart`; modify `lib/home.dart`, `lib/trailRecordPage.dart`

**Interfaces:** `Future<LocationResult> LocationService.getCurrent()` where `LocationResult` is a sealed class: `LocationOk(Position)`, `LocationDenied()`, `LocationDeniedForever()`, `LocationServicesOff()`.

- [x] **Step 1:** Implement `LocationService` (wraps the permission ladder currently in `home.dart:88-103`, plus `Geolocator.isLocationServiceEnabled()`; stream via `Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5))`).
- [x] **Step 2:** In `Home`: make the subscription nullable (`StreamSubscription<Position>? _positionStreamSubscription;` … `_positionStreamSubscription?.cancel();`), handle each `LocationResult` case — denied shows a full-screen explainer with an "Open settings" button (`Geolocator.openAppSettings()`) instead of an infinite spinner, and the map still loads centered on Poland (`LatLng(52.06, 19.48)`, zoom 6) so the app is usable without location.
- [x] **Step 3:** Widget test with a stub `LocationService` returning `LocationDeniedForever` → explainer shown, no spinner after pumpAndSettle.
- [x] **Step 4:** Commit: `fix: location denial shows guidance, map usable without GPS, no late-init crashes`

### Task 2.3: Offline sync must not destroy data (H5)

**Files:** Modify `lib/mainPage.dart` (extract sync into `lib/services/offline_sync_service.dart`)

- [x] **Step 1:** Test (repository stub): 2 offline places, second upload throws → service reports 1 success/1 failure and **only the successful one** is removed from local storage.
- [x] **Step 2:** Implement: iterate places; on success remove that single place from the persisted list (rewrite the `places` pref with the remainder) and delete its images; on failure keep it; afterwards toast a summary (`LocaleKeys.sync_result` with counts — add the key ×4 locales). Expect `201` via ApiClient (already handled).
- [x] **Step 3:** Commit: `fix: offline sync keeps failed uploads for retry`

### Task 2.4: Session & navigation fixes (H1, H6, H8, H12, H14)

**Files:** Modify `lib/profile.dart`, `lib/editProfile.dart`, `lib/mainPage.dart`; delete `lib/services/googleSignInApi.dart` (superseded by AuthService — its H6 crash disappears with it)

- [x] **Step 1:** `profile.dart`: sign-out → `await AuthService.signOut(); await SessionStore.clear();` then `Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const InternetChecker()), (r) => false);`
- [x] **Step 2:** `editProfile.dart`: `_resetPassword` calls `AuthService.resetPassword(email)` and shows the confirmation toast **without** clearing the session or navigating away.
- [x] **Step 3:** `mainPage.dart`: remove `PopScope(canPop: false)`; Android back should background the app normally from home.
- [x] **Step 4:** Manual check on emulator (sign out → back button does not resurrect the session; back on home exits). Commit: `fix: sign-out clears stack, reset password keeps session, restore back button` *(commit done; the emulator pass itself is still pending — fold it into the Phase 6.5 device pass)*

### Task 2.5: Async-state discipline in screens (H7, H9, H15)

**Files:** Modify `lib/internetChecker.dart`, `lib/placeDetails.dart`, `lib/trailDetails.dart`, `lib/place_form.dart`, `lib/profile.dart`, `lib/mainPage.dart`

- [x] **Step 1:** `internetChecker.dart`: replace the late-field/`FutureBuilder` race with a single future:

```dart
late final Future<_StartupState> _startup = _loadStartupState();

Future<_StartupState> _loadStartupState() async {
  final results = await Future.wait([
    loadBoolLocalData('welcomePageDisplayed'),
    SessionStore.load(),
    Connectivity().checkConnectivity(),
  ]);
  // decide OfflinePage / OfflinePlaceAddingPage / WelcomePage / Main here,
  // treating ethernet & vpn as online:
  // online = results contains wifi || mobile || ethernet || vpn
}
```

and a `FutureBuilder(future: _startup, ...)` in build. Move the `welcomePageDisplayed=true` write into `WelcomePage`'s continue button (not into build).

- [x] **Step 2:** Detail screens: replace `late Place _place; bool _isLoading` + `.then` with `late final Future<Place> _placeFuture = context.read<PlacesRepository>().getById(widget.placeId);` + `FutureBuilder` that renders a loading state, an **error state with a Retry button** (`setState(() => _placeFuture = ...)`) and the content state.
- [x] **Step 3:** Forms/profile: never `_user!` — screens that require a user receive it as a constructor argument from the shell (which by then knows the session), e.g. `PlaceForm(this.position, {required this.user})`.
- [x] **Step 4:** Widget tests: PlaceDetails with a throwing repository shows the retry state; retry with a succeeding repository shows content.
- [x] **Step 5:** Commit: `fix: deterministic async state — no late races, error+retry states everywhere`

### Task 2.6: Trail recording correctness (H10)

**Files:** Modify `lib/trailRecordPage.dart`; `android/app/src/main/AndroidManifest.xml`; `ios/Runner/Info.plist`

- [x] **Step 1:** Elapsed time from a `Stopwatch` started on record (display via a 1 s ticker reading `_stopwatch.elapsed`), not incrementing counters.
- [x] **Step 2:** Distance: ignore points with `position.accuracy > 25` m and jumps computed at > 30 m/s; use `Geolocator.distanceBetween` (delete the hand-rolled haversine `_calculateDistance`; keep `test/UnitTests/distance_algorythm_test.dart` but point it at a small pure helper `filterAndAccumulate(List<Position>)` in `lib/services/trail_math.dart`).
- [x] **Step 3:** Keep recording alive while the app is foregrounded: `WakelockPlus.enable()` during recording (`wakelock_plus: ^1.2.0`), and set `LocationSettings` per-platform (`AndroidSettings(foregroundNotificationConfig: ...)` from geolocator so Android keeps the stream alive with a visible notification; add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>` and `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>`). Full background recording (screen off, app switched) is explicitly **out of scope** — show "keep the app open while recording" copy on the record screen.
- [x] **Step 4:** Unit tests for `filterAndAccumulate` (jitter cluster ≈ 0 m; clean 100 m track ≈ 100 m ± 1). Commit: `fix: accurate trail recording (stopwatch time, jitter filter, foreground stream)`

### Task 2.7: Lint zero-ing and renames

**Files:** whole `lib/` tree

- [x] **Step 1:** Rename files to `snake_case` and fix typos in one mechanical commit (IDE rename-refactor): `customExeption.dart`→deleted (Task 1.4), `prewiewTrail.dart`→`preview_trail.dart`, `currnetObject.dart`→`selected_map_object.dart`, `mainPage.dart`→`main_shell.dart`, etc. Fix `fechedPlaces`→`fetchedPlaces`, `showSuccesToast`→`showSuccessToast`, `_isPaswordHidden`→`_isPasswordHidden`, and the misnamed `_incrementCounter` copies → a single `Prefs.setString` helper.
- [x] **Step 2:** Delete the dead Chromium license header in `internetChecker.dart:1-27`; translate the hardcoded English validator message (`lib/signUp.dart:107`) via a new locale key.
- [x] **Step 3:** `flutter analyze` → target: 0 errors, 0 warnings, < 20 infos (generated files may keep naming infos — add `lib/translations/**` to the analyzer excludes in `analysis_options.yaml`).
- [x] **Step 4:** `flutter test` all green. Commit: `chore: snake_case files, typo fixes, analyzer near-zero`

---

# Phase 3 — Design System & Map-First Shell

**Outcome:** a token-driven Material 3 theme matching the web palette, and a new home experience where the map fills 100 % of the screen with floating controls and a draggable "memory sheet".

## Design direction (decided, not optional)

- **Identity:** the app is a field companion for finding and documenting Polish places of memory. The web app is the archive; mobile is the terrain. So: the map is not a view *in* the app — it **is** the app.
- **Palette (exact web parity + map accents):**
  - `primary` #0891B2 (cyan-600), `onPrimary` #FFFFFF, pressed/containers #0E7490 / #CFFAFE
  - light: `surface` #FFFFFF, `surfaceContainer` #F1F5F9, `outlineVariant` #E2E8F0, `onSurface` #0F172A
  - dark: `surface` #171717, `surfaceContainer` #262626, `outlineVariant` #404040, `onSurface` #FFFFFF
  - semantic: error #DC2626, success #16A34A
  - trail polyline: #0891B2 @ 80 % over a 2 px white casing (replaces today's translucent blue #214BF3)
- **Type:** Manrope (google_fonts) for titles/labels — its geometric openness reads "modern cartography"; platform default (Roboto/SF) for body text. Title scale: 22/18/16 semi-bold; body 16/14. Kill today's 32 px bold app-bar titles and 20 px form text.
- **Shape & elevation:** 16 px radius sheets/cards, 28 px pill buttons/FABs, elevation ≤ 2 with `outlineVariant` hairlines — flat, luminous, like the web app.
- **Signature element — the Memory Sheet:** every map object opens a draggable bottom sheet (peek 25 % → half → full) with a drag handle, image carousel, and a **period chip** (e.g. "1939–1945") rendered in primary cyan. Details never navigate away from the map at peek/half height; the map stays visible and re-centers above the sheet.
- **Motion:** one orchestrated moment only — sheet spring-in and marker select pulse (200 ms). No page-level animation noise.

### Task 3.1: Token file + Material 3 theme

**Files:**
- Create: `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`
- Delete: `lib/Theme/colors.dart`, `lib/Theme/theme.dart` (keep `themeProvider.dart`, moved to `lib/theme/theme_provider.dart` with a `ThemeMode` API: system/light/dark persisted in prefs)
- Test: `test/WidgetTests/theme_test.dart`

- [ ] **Step 1:**

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0891B2);
  static const primaryDark = Color(0xFF0E7490);
  static const primaryContainer = Color(0xFFCFFAFE);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFF1F5F9);
  static const lightOutline = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);

  static const darkSurface = Color(0xFF171717);
  static const darkSurfaceContainer = Color(0xFF262626);
  static const darkOutline = Color(0xFF404040);
  static const darkText = Color(0xFFFFFFFF);

  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const trail = Color(0xCC0891B2); // 80% cyan
}
```

```dart
// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData _build(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme(
    brightness: b,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer:
        dark ? AppColors.primaryDark : AppColors.primaryContainer,
    onPrimaryContainer: dark ? Colors.white : AppColors.lightText,
    secondary: AppColors.primaryDark,
    onSecondary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    surface: dark ? AppColors.darkSurface : AppColors.lightSurface,
    onSurface: dark ? AppColors.darkText : AppColors.lightText,
    surfaceContainerHighest:
        dark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer,
    outlineVariant: dark ? AppColors.darkOutline : AppColors.lightOutline,
    outline: dark ? AppColors.darkOutline : AppColors.lightOutline,
    onSurfaceVariant: dark ? Colors.white70 : const Color(0xFF475569),
  );

  final titles = GoogleFonts.manropeTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: ThemeData(brightness: b).textTheme.copyWith(
          titleLarge: titles.titleLarge!
              .copyWith(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: titles.titleMedium!
              .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          labelLarge: titles.labelLarge!
              .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      titleTextStyle: titles.titleMedium!
          .copyWith(fontSize: 18, fontWeight: FontWeight.w600,
                    color: scheme.onSurface),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.primary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(backgroundColor: scheme.surface),
  );
}

final lightTheme = _build(Brightness.light);
final darkTheme = _build(Brightness.dark);
```

- [ ] **Step 2:** Update `ThemeProvider` to expose `ThemeMode themeMode` (persisted, defaults to `ThemeMode.system`) and update `MaterialApp` in `lib/main.dart`: `theme: lightTheme, darkTheme: darkTheme, themeMode: provider.themeMode`. Grep-fix every `colorScheme.scrim` (was abused as "brand cyan") → `colorScheme.primary`, every `colorScheme.onBackground` → `colorScheme.onSurface`, `colorScheme.onPrimary`-as-card-color → `surfaceContainerHighest`.
- [ ] **Step 3:** Theme test: builds both themes, asserts `lightTheme.colorScheme.primary == const Color(0xFF0891B2)` and dark surface `0xFF171717`.
- [ ] **Step 4:** App runs in light + dark; screenshot both. Commit: `feat(ui): web-parity design tokens and Material 3 theme`

### Task 3.2: Map style & markers to match the brand

**Files:**
- Modify: `lib/assets/map_styles/light_map_style.json`, `dark_map_style.json`
- Create: `lib/assets/markers/` new pin set (SVG-derived PNGs @2x/@3x): `place_pin.png` (cyan teardrop, white memorial-flame glyph), `place_pin_selected.png` (larger, `#0E7490`), `user_dot.png` (cyan dot, white ring, soft halo)
- Create: `lib/map/marker_factory.dart`

- [ ] **Step 1:** Regenerate styles from Google's styling wizard: light = desaturated slate base (`#F1F5F9` land, `#CBD5E1` water tint), POI icons off, road labels minimal; dark = `#171717` base, `#262626` roads, POI off. Both must keep the map quiet so cyan pins are the loudest element.
- [ ] **Step 2:** `MarkerFactory.load(BuildContext)` decodes each asset **once** (cache in a static; today `home.dart:115-130` re-decodes the PNG on every GPS tick) using `BitmapDescriptor.asset(const ImageConfiguration(devicePixelRatio: 3), path)`.
- [ ] **Step 3:** Replace usages in home/record pages; user marker updates by rebuilding the one `Marker` with the cached icon (fixes the `_markers.union` stale-marker bug at `home.dart:119`).
- [ ] **Step 4:** Visual check on device, light + dark. Commit: `feat(ui): branded map styles and cached marker set`

### Task 3.3: The MapShell — map covers everything

**Files:**
- Create: `lib/map/map_shell.dart` (replaces `lib/mainPage.dart`'s role as home), `lib/map/map_top_bar.dart`, `lib/map/map_fab_column.dart`, `lib/map/memory_sheet.dart`
- Modify: `lib/main.dart` / `internetChecker.dart` routing to land on `MapShell`
- Delete: `lib/AppNavigation/addingButton.dart`, `lib/MainPageWidgets/previewPlace.dart`, `lib/MainPageWidgets/prewiewTrail.dart` (superseded)

Layout (both orientations):

```
┌──────────────────────────────┐
│ ◉ search places…        (MK) │  ← MapTopBar: floating pill, 12px inset,
│                              │     surface @ 92% opacity, avatar opens Profile
│                              │
│           FULL-BLEED         │
│           GOOGLE MAP         │
│                        [◎]   │  ← locate me
│                        [☾]   │  ← theme cycle (system→light→dark)
│                              │
│            [＋]              │  ← primary FAB (cyan): add place / record trail
│╭────────────────────────────╮│
││ ───     Memory Sheet       ││  ← DraggableScrollableSheet (0 / .25 / .55 / .95)
│╰────────────────────────────╯│     only when an object is selected
└──────────────────────────────┘
```

- No `BottomNavigationBar` anymore — the map owns the screen; Profile lives behind the avatar (guests get the sign-in page there instead).
- The map is edge-to-edge: `Scaffold(extendBody: true)`, **no SafeArea around the GoogleMap** — SafeArea wraps only the floating controls; set `GoogleMap(padding:)` to keep Google's attribution visible above the sheet.

- [ ] **Step 1:** Build `MapShell` as a `Stack`: `GoogleMap` (full bleed, `myLocationButtonEnabled:false`, `zoomControlsEnabled:false`, style per theme) + `SafeArea(child: MapTopBar(...))` + `MapFabColumn` + conditional `MemorySheet`. State: `_places`, `_trails`, `_selected` (sealed: `SelectedPlace`/`SelectedTrail`/none), loaded via repositories with the Phase 2 error/retry pattern (errors surface as a floating retry chip under the top bar, map stays usable).
- [ ] **Step 2:** `MapTopBar`: pill `Container` (radius 28, `surface.withOpacity(.92)`, hairline `outlineVariant` border) with app glyph, a **search field** filtering loaded places by name (zooms to result on tap — this is a new capability the web app has and mobile lacked), and a `CircleAvatar` (user initial, or person icon for guests) → pushes `Profile`/`SignInOrSignUpPage`.
- [ ] **Step 3:** `MapFabColumn`: small FABs `locate` + `theme`, and the primary cyan FAB `＋` — tap opens a bottom sheet with two actions: "Add place here" (→ `PlaceForm`) and "Record a trail" (→ `TrailRecordPage`); hidden for guests (tap shows sign-in prompt sheet instead).
- [ ] **Step 4:** `MemorySheet`: `DraggableScrollableSheet` with snap sizes `[.25, .55, .95]`; peek shows title + period chip + distance-from-me; half adds image carousel (Flutter `CarouselView`) + description preview + "Open in Google Maps"; full is the complete details (subsumes `placeDetails.dart` content for map-opened objects). On open: `_mapController.animateCamera` so the pin sits in the top 40 % of the screen; marker swaps to `place_pin_selected`.
- [ ] **Step 5:** Widget tests: map shell renders top bar + FABs; selecting a stub place shows the sheet at peek; guests see no add-FAB. (`GoogleMap` needs a platform view stub in tests — wrap the map in an injectable builder so tests substitute a `SizedBox`.)
- [ ] **Step 6:** Run on device; screenshot light/dark, peek/half/full. Commit: `feat(ui): full-screen MapShell with floating controls and Memory Sheet`

---

# Phase 4 — Screen-by-Screen Redesign

**Outcome:** every remaining screen rebuilt on the Phase 3 tokens/components; zero references to the old widgets. Shared rules for **all** tasks in this phase: FilledButton (52 px pill) for primary actions, themed `TextFormField`s (no per-screen `InputDecoration` overrides — the theme does it), `titleMedium` app-bar titles, all strings localized, repository + error/retry pattern from Phase 2, widget test per screen updated.

### Task 4.1: Auth screens (`signIn.dart`, `signUp.dart`, `forgotPasswordPage.dart`, `signInOrSignUpPage.dart`, `welcomePage.dart`, `infoAfterSignUpPage.dart`)

- [ ] Compact logo (120 px) on `surfaceContainer` header band; form card on `surface`; live validation (`autovalidateMode: AutovalidateMode.onUserInteraction`) replacing validate-on-submit-only; the Google button becomes a full-width outlined button "Continue with Google" (Cognito federated); welcome page gets the map as a blurred hero image with the value proposition in one sentence.
- [ ] Password strength requirements rendered as a live checklist under the field (min 8, upper, lower, digit, symbol — matching `signUp.dart:118` regex, but as individual checks so users see *which* rule fails).
- [ ] Update `test/WidgetTests/hide_password_test.dart`, `sign_up_switch_button_test.dart`. Commit.

### Task 4.2: Place & trail forms (`place_form.dart`, `placeEditForm.dart`, `offlinePlaceForm.dart`, `trailForm.dart`, `trailEditForm.dart`)

- [ ] One shared `lib/forms/place_form_fields.dart` (name, type/sortof/period dropdowns fed by `CatalogRepository`, description, links, image picker grid) used by all five screens — today they are five near-copies (~1,850 lines → target ≤ 600).
- [ ] Image picking: 3-slot grid of 96 px rounded thumbnails with an add tile and per-image remove; replaces `FormPictureSlider`+`ImageInput`.
- [ ] Submit: busy overlay + repository + upload progress; on partial image-upload failure keep the form open with a "retry images" state (place already created — do **not** duplicate it on retry).
- [ ] The location header shows a 120 px static mini-map snapshot of the chosen position (non-interactive `GoogleMap` with `liteModeEnabled: true` on Android) instead of raw lat/lng text. Commit per screen group.

### Task 4.3: My Places / My Trails (`myPlaces.dart`, `myTrails.dart`, box widgets)

- [ ] Card list on `surfaceContainer` with leading 56 px thumbnail (first image), title, period chip, verification badge; swipe actions kept (flutter_slidable 4.x API) but destructive delete gets a confirm dialog; empty states get an illustration + "Add your first place" CTA that deep-links to the add flow.
- [ ] Pull-to-refresh (`RefreshIndicator`). Commit.

### Task 4.4: Details, profile, contact, offline (`placeDetails.dart`, `trailDetails.dart`, `profile.dart`, `editProfile.dart`, `contactUsForm.dart`, `offlinePage.dart`, `offlinePlaceAddingPage.dart`, `offlineWidgets/`)

- [ ] `placeDetails`/`trailDetails` become thin wrappers rendering the **same content widget as MemorySheet full state** (single source of truth for details UI).
- [ ] Profile: header card (avatar initial, username, email) + settings list tiles (language picker — currently missing UI despite 4 locales!, theme mode, edit profile, my places/trails, contact, sign out in red). Add the language picker: `context.setLocale(...)` bottom sheet.
- [ ] Offline pages: same visual system; the offline place list reuses the Task 4.3 card. Offline banner (`MaterialBanner`) appears on MapShell when `connectivity_plus` stream reports offline, instead of trapping the user on a separate page while the app is already open.
- [ ] Delete now-unused `lib/formWidgets/`, `lib/ProfileWidgets/`, `lib/SignInAndSignUpWidgets/` leftovers; `grep -rn "Colors.grey\|scrim" lib/` returns nothing. Update remaining widget tests. Commit.

---

# Phase 5 — Security & Privacy Hardening

**Outcome:** no plaintext secrets or tokens, correct platform privacy declarations, HTTPS everywhere.

### Task 5.1: Transport & token security sweep
- [ ] Verify prod config uses `https://` only; add a debug-only assertion in `ApiClient` rejecting non-HTTPS when `AppConfig.isProd`.
- [ ] Confirm no `usesCleartextTraffic` flag is added anywhere; Android network security config stays default (cleartext blocked).
- [ ] `grep -rn "SharedPreferences" lib/` → no token/session reads remain outside `SessionStore`.
- [ ] Rotate the Google Maps API keys (the old ones lived in committed config on dev machines) and restrict them: Android key by package name `pl.memoryplaces.mobile` + SHA-1, iOS key by bundle id.

### Task 5.2: iOS privacy compliance
- [ ] Create `ios/Runner/PrivacyInfo.xcprivacy` declaring: location (app functionality), photos (user content), UserDefaults API category `CA92.1`, file-timestamp `C617.1` (required-reason APIs pulled in by plugins).
- [ ] Replace deprecated `NSLocationAlwaysUsageDescription`; keep only `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` — each rewritten to say *why* ("Your location shows nearby places of memory and records trails you walk."), localized via `ios/Runner/{en,pl,de,ru}.lproj/InfoPlist.strings`.

### Task 5.3: Input & content safety
- [ ] URL fields (`wiki_link`, `topic_link`): validate scheme ∈ {http, https} before save and before `launchUrl` (currently any URI launches — `tel:`, `javascript:` etc. from server data); launch with `LaunchMode.externalApplication`.
- [ ] Text inputs: max lengths server-parity (name 255 / description 1000 already partially done); trim before submit.
- [ ] Image uploads: cap at 3 files ≤ 10 MB each client-side with a clear error toast.

---

# Phase 6 — Production Readiness

**Outcome:** observable, tested, signed, CI-verified, store-submittable.

### Task 6.1: Crash reporting & logging
- [ ] Add `sentry_flutter: ^9.0.0`; wrap `main()` in `SentryFlutter.init` (DSN via `--dart-define`, disabled when not `isProd`); breadcrumbs from `ApiClient` (method, path, status — never bodies or tokens).
- [ ] Replace stray `print`/silent catches with a tiny `log.dart` (`dart:developer log`) — `grep -rn "print(" lib/` → 0.

### Task 6.2: Test suite to green + coverage of the new core
- [ ] Fix/rewrite the existing tests in `test/` and `integration_test/` against the new screens (they currently target the old UI).
- [ ] Minimum bar: unit tests for `ApiClient`, `SessionStore`, repositories, `trail_math`, `OfflineSyncService`; widget tests for MapShell selection flow, auth error flow, form validation; one happy-path integration test (sign in → map → open place → sheet full).
- [ ] `flutter test` green; record commands in README.

### Task 6.3: CI
- [ ] Create `.github/workflows/ci.yml`: on PR/push → `flutter pub get`, `flutter analyze --fatal-warnings`, `flutter test`, `flutter build apk --debug --dart-define-from-file=env/dev.json`. Cache pub + gradle.

### Task 6.4: Release signing & store packaging
- [ ] Generate a fresh upload keystore **outside the repo**; `android/key.properties` (git-ignored) + standard `signingConfigs.release` block reading it; `buildTypes.release { signingConfig signingConfigs.release; minifyEnabled true; shrinkResources true }` with `proguard-rules.pro` keeping `com.google.android.gms.maps.**`.
- [ ] `flutter build appbundle --release --dart-define-from-file=env/prod.json` succeeds; `flutter build ipa` with the team's certs.
- [ ] Version bump flow documented: `version: 1.0.0+2` etc.
- [ ] Store checklist: app icons regenerated (`flutter_launcher_icons` — verify the 1024 px master has no alpha for iOS), splash screens, screenshots (map light/dark, sheet, record), privacy policy URL (must exist — coordinate with web team), Play Data Safety form (location: collected, not shared; photos: user-provided content), App Store privacy nutrition labels matching `PrivacyInfo.xcprivacy`.

### Task 6.5: Final verification gate (superpowers:verification-before-completion)
- [ ] `flutter analyze --fatal-warnings` → clean
- [ ] `flutter test` → all green
- [ ] Release build installed on a physical Android device: full pass through sign-up → add place with photos → record trail → offline add → resync → sign out.
- [ ] Same pass on iOS (TestFlight build).
- [ ] Dark + light screenshots reviewed against the web app side by side.

---

## Self-Review Notes

- **Spec coverage:** UI redesign (Phases 3–4, map-first constraint honored: no bottom nav, full-bleed map, overlays only), web color parity (tokens copied from `theme.ts`/`index.css` values), bugs & missings (audit tables B1–B7/H1–H15 each mapped to a Phase 0–2 task), safety & error handling (Phases 1, 2, 5), SDK/dependency updates (Phase 0, exact versions), production readiness (Phase 6), phased structure (0–6). Language picker and search were "missings" discovered and covered (Tasks 4.4, 3.2).
- **Known open decision:** backend Option A vs B — gated before Phase 1; everything else proceeds regardless.
- **Type consistency check:** `ApiException(message, statusCode)` is the single error type consumed in Phases 2 and 4; `SessionStore.load()/save()/clear()` and `AuthService.currentAccessToken()` signatures used consistently across Tasks 1.2–1.5 and 2.1/2.4.
