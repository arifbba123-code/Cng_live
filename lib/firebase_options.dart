// CNG LIVE — Firebase Options (PLACEHOLDER — NOT REAL CONFIG)
//
// This file must be regenerated against your actual Firebase project
// before the app can connect to Firebase Auth/Firestore/Storage/FCM.
//
// To generate the real file:
//   1. Install the FlutterFire CLI (`dart pub global activate flutterfire_cli`)
//   2. Run `flutterfire configure` from the project root
//   3. Select (or create) your Firebase project — recommend separate
//      dev/staging/prod projects per Step 22, Section 19
//   4. This file will be overwritten with real platform config values
//
// Do not commit real API keys/config for a production Firebase project
// to a public repository without appropriate care — Firebase config
// values are not secret in the traditional sense (they're safe to
// ship in a client app) but should still match your intended
// environment (dev vs prod) per branch/build.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Run `flutterfire configure` to generate real values.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Android yet. '
          'Run `flutterfire configure` to generate real values for this project.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android in this '
          'MVP (Step 1: Android-only, no laptop). Run `flutterfire configure` '
          'after adding other platforms.',
        );
    }
  }
}
