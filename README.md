# FinLife Hub

FinLife Hub is a Flutter demo app for Android, iOS, macOS, and web, with a
focus on modular feature design and Flutter-to-native integration. The current
app includes a home dashboard, a simulated phone/OTP sign-in flow, QR/payment
demo screens, and an isolated habit-tracking module.

## Architecture

Feature code is organized by responsibility:

```text
lib/
  app/                 App composition, routing, and authentication redirects
  core/                Shared storage, platform channels, routing, and UI
  features/
    auth/              OTP flow, domain contracts, data sources, and UI
    home/              Dashboard, QR, payment, and support screens
    lifestyle/         Self-contained GetX habit-tracking module
```

The Home and Auth features use Riverpod for dependency wiring and state, with
GoRouter for navigation. The Lifestyle module uses GetX and is kept separate
from the rest of the app. Domain contracts are separated from their data
implementations where that boundary is useful.

## Platform integration

The Android, iOS, and macOS application shells expose device capabilities to
Dart over typed `MethodChannel` and `EventChannel` APIs:

- Battery percentage and battery-level updates.
- A per-install UUID and a platform device identifier.
- Network connectivity and connectivity-change updates.
- Screenshot protection where the native platform supports it.

The Dart wrappers are in `lib/core/platform/`. Battery readings use those
native channels on Android, iOS, and macOS, and `battery_plus` on web, Windows,
and Linux. Web battery reporting depends on the browser's Battery Status API:
Chrome may disable or omit it, in which case a web app cannot read the
computer's battery and the dashboard reports it as unavailable.

Location uses `geolocator` on Android, iOS, macOS, and web. It requests high
accuracy, subject to browser/device permissions and available location
hardware. Android, iOS, and macOS use their platform reverse-geocoders. On web,
the app sends the obtained coordinates to OpenStreetMap's public Nominatim
service to resolve an area name and displays the required attribution. This
public service is rate-limited and is suitable only for this demo; production
deployments should use an approved geocoding provider or backend. Browser
geolocation requires an allowed secure origin (localhost is considered
secure), plus browser and macOS location permission. Windows and Linux
location are not implemented by the current location plugin.

## Authentication and security scope

This repository is a runnable demo, not a production banking or payment app.
The OTP data source accepts the demo code `123456`, and the biometric data
source simulates availability and success. The app currently persists its
demo token pair with Hive; this storage is not encrypted and must not be used
for real credentials. Production authentication requires a backend, secure
platform-backed token storage, real biometric verification, and appropriate
server-side controls. `FLAG_SECURE` is a useful screen-capture mitigation, not
a substitute for protecting sensitive data throughout the app.

## Run and test

Install Flutter and the platform toolchain for the target you intend to run.
Then fetch packages and launch on a connected device or emulator:

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
```

The repository includes a GitHub Actions workflow that runs analysis, tests,
and an Android debug build on pushes and pull requests.
