# CNG LIVE — Flutter Project (Foundation Build)

Community-powered live CNG pump status for Coimbatore drivers.

## What's in this archive

This is a **foundation-stage build** — everything approved through the
Core Layer and Data Layer (models, repository interfaces, repository
implementations, remote/local datasources). It does **not** yet include:

- Dependency Injection wiring (`config/di/service_locator.dart`)
- Routing (`config/routes/`)
- ViewModels
- Screens/Views (Splash, Onboarding, Login, Home, etc.)

`lib/app.dart` currently renders a single placeholder screen so the
project is buildable and runnable today, even though no product
screens exist yet. Those layers are the next modules to be reviewed
and added.

## Project structure

```
lib/
├── main.dart              # Entry point
├── app.dart                # MaterialApp shell (placeholder home screen)
├── firebase_options.dart   # PLACEHOLDER — regenerate via flutterfire configure
├── core/                   # Constants, theme, errors, network, logging, utils, extensions
└── data/
    ├── models/             # UserModel, PumpModel, StatusUpdateModel, ReportModel,
    │                       # NotificationModel, BadgeModel
    ├── repositories/       # Interfaces + Firebase-backed implementations
    └── datasources/
        ├── remote/         # Firebase Auth/Firestore access (only place Firebase is imported)
        └── local/           # Hive-backed offline queue
```

## Setup — from your Android phone (FlutLab.io)

1. Create a new Flutter project in FlutLab.
2. Upload/extract this archive's contents over the new project,
   replacing the default `lib/`, `pubspec.yaml`, and
   `analysis_options.yaml`.
3. In FlutLab's terminal, run:
   ```
   flutter pub get
   ```
4. **Firebase setup (required before running):**
   - Create a Firebase project at console.firebase.google.com (do this
     from any browser, including your phone's).
   - Enable **Authentication → Phone**, **Firestore Database**,
     **Storage**, and **Cloud Messaging**.
   - Install the FlutterFire CLI and run `flutterfire configure`
     (needs a machine with the Flutter SDK + Firebase CLI — FlutLab's
     terminal should support this; if not, this is the one step that
     may need a one-time desktop/cloud-shell session, e.g. Firebase
     Studio, since it writes `google-services.json` and regenerates
     `lib/firebase_options.dart`).
   - Until then, `lib/firebase_options.dart` will throw
     `UnsupportedError` if Firebase.initializeApp() is called — this
     is expected and intentional (no real config exists yet).
5. Run the app:
   ```
   flutter run
   ```
   You should see the CNG LIVE placeholder screen in your app's
   light/dark theme.

## Environment files

`.env.dev`, `.env.staging`, `.env.prod` are placeholders referenced by
`pubspec.yaml`'s asset list so `flutter pub get`/build doesn't fail on
a missing file. Fill in real values as `config/env/` (dev/staging/prod
config classes) gets built in a later module.

## Next steps (pending review)

1. Dependency Injection (`config/di/service_locator.dart`)
2. Routing (`config/routes/app_routes.dart`, `app_router.dart`)
3. Remaining repositories (`user_repository_impl.dart`,
   `notification_repository_impl.dart`, `badge_repository_impl.dart`,
   `report_repository_impl.dart`) + their remote datasources
4. ViewModels
5. Screens (Splash → Onboarding → Login → OTP → Home → ... → Settings)
